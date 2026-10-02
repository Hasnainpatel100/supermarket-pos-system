import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../commons/loader.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../repository/repo_storage.dart';
import '../../service/service_brand_context.dart';
import '../../util/app_route.dart';
import '../../util/snackbar_util.dart';
import '../../util/my_date_time.dart';
import '../../util/util_device.dart';
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

    // ── Enforce Plan Expiry Check (Block login only if plan has expired) ──
    if (Get.isRegistered<ServiceBrandContext>()) {
      final brandCtx = Get.find<ServiceBrandContext>();
      final branch = brandCtx.selectedBranch;
      final plan = branch?.planDetails;
      if (plan != null && brandCtx.isPlanExpired) {
        Loader.hideLoader();
        if (Get.isRegistered<AuthRepository>()) {
          await Get.find<AuthRepository>().logout();
        }
        await _repoStorage.logout();
        if (Get.context != null) {
          DialogPlanExpiredBlock.show(Get.context!, branch: branch, plan: plan);
        }
        return;
      }
    }

    if (kDebugMode) {
      debugPrint('✅ LOGIN SUCCESS (Server) - appType: $appType, userType: $userType');
    }

    final user = result.user!;

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
