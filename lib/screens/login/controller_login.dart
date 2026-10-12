import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../commons/loader.dart';
import '../../core/storage/token_storage.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../model/entity_user.dart';
import '../../model/model_branch.dart';
import '../../model/model_registered_device.dart';
import '../../repository/repo_storage.dart';
import '../../service/service_brand_context.dart';
import '../../util/app_route.dart';
import '../../util/snackbar_util.dart';
import '../../util/my_date_time.dart';
import '../../util/util_device.dart';
import '../../widget/dialog_device_limit.dart';
import '../../widget/dialog_plan_expired_block.dart';
import '../home/controller_home.dart';
import '../home/fragment/account/controller_home_account.dart';


class ControllerLogin extends GetxController {
  final RepoStorage _repoStorage = Get.find();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void login() async {
    Loader.showLoader();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      Loader.hideLoader();
      SnackbarUtil.showError('field_empty'.tr);
      return;
    }

    // ── Server-based authentication via AuthRepository ──
    if (!Get.isRegistered<AuthRepository>()) {
      Loader.hideLoader();
      SnackbarUtil.showError('Authentication service is not available. Please restart the app.');
      return;
    }

    final authRepo = Get.find<AuthRepository>();
    final result = await authRepo.login(username: email, pin: password);

    if (!result.success || result.user == null) {
      Loader.hideLoader();
      SnackbarUtil.showError(result.errorMessage ?? 'invalid_credentials'.tr);
      return;
    }

    // ── Enforce strict MARKET check (only MARKET accounts allowed) ──
    final appType = (result.authResponse?.appType ?? '').trim().toUpperCase();
    final userType = (result.authResponse?.userType ?? '').trim().toUpperCase();

    if (appType != 'MARKET') {
      Loader.hideLoader();
      SnackbarUtil.showError(
        'Access denied: Only accounts with appType "MARKET" are authorized to login.',
      );
      // Clear tokens since this user shouldn't be logged in
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().logout();
      }
      return;
    }

    // ── Enforce Plan Expiry Check (Block login if plan has expired in UTC) ──
    ModelBranch? branchToCheck;
    if (Get.isRegistered<ServiceBrandContext>()) {
      branchToCheck = Get.find<ServiceBrandContext>().selectedBranch;
    }
    if (branchToCheck == null && Get.isRegistered<TokenStorage>()) {
      try {
        final bJson = Get.find<TokenStorage>().getBranchJson();
        if (bJson != null && bJson.isNotEmpty) {
          branchToCheck = ModelBranch.fromJson(jsonDecode(bJson) as Map<String, dynamic>);
        }
      } catch (_) {}
    }

    final plan = branchToCheck?.planDetails;
    if (plan != null && plan.isExpired) {
      Loader.hideLoader();
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().logout();
      }
      await _repoStorage.logout();
      if (Get.context != null) {
        DialogPlanExpiredBlock.show(Get.context!, branch: branchToCheck, plan: plan);
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('✅ LOGIN SUCCESS (Server) - appType: $appType, userType: $userType');
    }

    final user = result.user!;

    // ── Enforce POS Device Limit Check ──
    final deviceAllowed = await _checkAndEnforceDeviceLimit(
      branch: branchToCheck,
      plan: plan,
      user: user,
    );
    if (!deviceAllowed) {
      Loader.hideLoader();
      return;
    }

    await _proceedToHome(user);
  }

  /// Checks whether this device is registered for the branch or if an available
  /// device slot allows auto-registration. If limit reached, hard-blocks login
  /// and presents [DialogDeviceLimit].
  Future<bool> _checkAndEnforceDeviceLimit({
    required ModelBranch? branch,
    required BranchPlanDetails? plan,
    required EntityUser user,
  }) async {
    if (!Get.isRegistered<TokenStorage>()) {
      return true;
    }

    final tokenStorage = Get.find<TokenStorage>();
    final branchId = branch?.id ?? branch?.remoteId;
    final currentDeviceId = await UtilDevice.getDeviceId();
    final currentDeviceName = await UtilDevice.getDeviceName();
    final registeredDevices = tokenStorage.getRegisteredDevices(branchId);

    // 1. If this device is already registered, allow login
    final alreadyRegistered =
        registeredDevices.any((d) => d.deviceId == currentDeviceId);
    if (alreadyRegistered) {
      return true;
    }

    // 2. Check maximum allowed POS devices (default to 2 if not configured)
    final maxDevices = (plan?.maxPosDevices != null && plan!.maxPosDevices > 0)
        ? plan.maxPosDevices
        : 2;

    // 3. If slot is available, automatically register this device and proceed
    if (registeredDevices.length < maxDevices) {
      final newDevice = ModelRegisteredDevice(
        deviceId: currentDeviceId,
        deviceName: currentDeviceName,
        registeredAt: DateTime.now().toIso8601String(),
        ipAddress: await UtilDevice.getIpAddress(),
      );
      await tokenStorage.saveRegisteredDevices(
        [...registeredDevices, newDevice],
        branchId,
      );
      return true;
    }

    // 4. Limit reached -> Hard block login and display device management dialog
    Loader.hideLoader();
    if (Get.context != null) {
      DialogDeviceLimit.show(
        Get.context!,
        branch: branch,
        maxPosDevices: maxDevices,
        currentDeviceId: currentDeviceId,
        currentDeviceName: currentDeviceName,
        onDeviceActivated: () async {
          Loader.showLoader();
          await _proceedToHome(user);
        },
        onCancel: () async {
          if (Get.isRegistered<AuthRepository>()) {
            await Get.find<AuthRepository>().logout();
          }
          await _repoStorage.logout();
        },
      );
    }
    return false;
  }

  /// Updates login metadata, persists session, resets controllers, and routes to home.
  Future<void> _proceedToHome(EntityUser user) async {
    // Update login metadata
    user.lastLoginAt = MyDateTime.getCurrentDateTimeUtc();
    user.lastLoginDevice = await UtilDevice.getDeviceName();
    user.lastLoginIp = await UtilDevice.getIpAddress();

    // Persist user session in RepoStorage
    await _repoStorage.setUser(json.encode(user.toMap()));

    // Reset home controllers so fresh login triggers Start Day / Shift dialog
    if (Get.isRegistered<ControllerHome>()) {
      Get.delete<ControllerHome>(force: true);
    }
    if (Get.isRegistered<ControllerHomeAccount>()) {
      Get.delete<ControllerHomeAccount>(force: true);
    }

    Loader.hideLoader();
    Get.offAllNamed(AppRoute.home);
  }


  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
