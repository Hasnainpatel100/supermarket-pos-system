import '../../service/service_object_box.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../commons/loader.dart';
import '../../core/storage/token_storage.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../core/app_type/app_type_service.dart';
import '../../model/model_branch.dart';
import '../../repository/repo_storage.dart';
import '../../service/service_brand_context.dart';
import '../../util/app_route.dart';
import '../../util/snackbar_util.dart';
import '../../util/my_date_time.dart';
import '../../util/util_device.dart';
import '../../widget/dialog_plan_expired_block.dart';
import '../home/controller_home.dart';
import '../home/fragment/account/controller_home_account.dart';
import '../home/fragment/pos/controller_home_pos.dart';
import '../home/fragment/item/controller_home_item.dart';
import '../home/fragment/dashboard/controller_home_dashboard.dart';

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

    // ── Enforce supported appType check (all 7 verticals allowed) ──
    final appType = (result.authResponse?.appType ?? '').trim().toUpperCase();
    final userType = (result.authResponse?.userType ?? '').trim().toUpperCase();
    final supportedTypes = ['STEEL', 'MARKET', 'APPAREL', 'ELECTRONICS', 'JEWELLERY', 'OPTICAL', 'FOOTWEAR'];

    if (!supportedTypes.contains(appType) && appType.isNotEmpty) {
      Loader.hideLoader();
      SnackbarUtil.showError(
        'Access denied: Unsupported appType "$appType".',
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

    // Update login metadata
    user.lastLoginAt = MyDateTime.getCurrentDateTimeUtc();
    user.lastLoginDevice = await UtilDevice.getDeviceName();
    user.lastLoginIp = await UtilDevice.getIpAddress();

    // ── Switch Local Database for this brand (Multi-Brand Isolation) ──
    final loggedInBrandId = (result.authResponse?.brandId ?? '').trim();
    if (loggedInBrandId.isNotEmpty && Get.isRegistered<ServiceObjectBox>()) {
      await Get.find<ServiceObjectBox>().switchBrandDatabase(loggedInBrandId);
    }

    // ── Apply Business Vertical (POS-wide Architecture) ──
    final resolvedAppType = (result.authResponse?.appType ?? 'MARKET').trim();
    await Get.find<AppTypeService>().applyAppType(resolvedAppType);

    // Persist user session in RepoStorage
    await _repoStorage.setUser(json.encode(user.toMap()));

    // Reset home controllers so fresh login triggers Start Day / Shift dialog
    if (Get.isRegistered<ControllerHome>()) {
      Get.delete<ControllerHome>(force: true);
    }
    if (Get.isRegistered<ControllerHomeAccount>()) {
      Get.delete<ControllerHomeAccount>(force: true);
    }
    if (Get.isRegistered<ControllerHomePos>()) {
      Get.delete<ControllerHomePos>(force: true);
    }
    if (Get.isRegistered<ControllerHomeItem>()) {
      Get.delete<ControllerHomeItem>(force: true);
    }
    if (Get.isRegistered<ControllerHomeDashboard>()) {
      Get.delete<ControllerHomeDashboard>(force: true);
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
