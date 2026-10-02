import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../enums/enum_main_menu.dart';
import '../../enums/enum_permission.dart';
import '../../model/entity_user.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../repository/repo_storage.dart';
import '../../service/service_brand_context.dart';
import '../../util/app_route.dart';
import '../../widget/dialog_plan_expired_block.dart';
import '../../widget/dialog_plan_expiry.dart';

import 'fragment/account/controller_home_account.dart';
import 'fragment/account/dialog_start_day_shift.dart';

class ControllerHome extends GetxController {
  final RepoStorage _repoStorage = Get.find();
  Rx<EntityUser?> rxUser = Rx<EntityUser?>(null);
  var selectedMainMenu = EnumMainMenu.account.obs;
  final isDrawerCollapsed = false.obs;

  @override
  void onInit() {
    getUserDetails();
    super.onInit();
  }

  Future<void> getUserDetails() async {
    String strUser = await _repoStorage.getUser();
    debugPrint("getUserDetails: $strUser");
    if (strUser.isNotEmpty) {
      var mapUser = json.decode(strUser);
      EntityUser entityUser = EntityUser.fromMap(mapUser);

      // ✅ Ensure superAdmin has all permissions (including newly added ones) on session restore
      final roleNormalized = entityUser.role?.toUpperCase().replaceAll('_', '') ?? '';
      final isSuperAdmin = roleNormalized == 'SUPERADMIN';
      if (isSuperAdmin) {
        final allPermissions = EnumPermission.values.map((e) => e.name).toList();
        entityUser.permissions ??= [];
        for (var p in allPermissions) {
          if (!entityUser.permissions!.contains(p)) {
            entityUser.permissions!.add(p);
          }
        }
      } else {
        // ✅ Ensure all local operational POS permissions (items, customers, pos, stocks, reports, expenses) are present
        const Set<String> restrictedPermissions = {
          'superVendorAccess',
          'brandManage',
          'brandCreate',
          'brandUpdate',
          'brandDelete',
          'brandView',
          'branchManage',
          'branchCreate',
          'branchUpdate',
          'branchDelete',
          'branchView',
          'userCreate',
          'userUpdate',
          'userDisable',
          'roleAssign',
          'apiUserManage',
        };

        entityUser.permissions ??= [];
        final operational = EnumPermission.values
            .map((e) => e.name)
            .where((p) => !restrictedPermissions.contains(p));
        for (final op in operational) {
          if (!entityUser.permissions!.contains(op)) {
            entityUser.permissions!.add(op);
          }
        }
      }

      rxUser.value = entityUser;
    }

    // ✅ Ensure active Brand and Branch context is restored / fetched
    if (Get.isRegistered<AuthRepository>()) {
      await Get.find<AuthRepository>().restoreSessionContext();
    }

    // ✅ Load user's saved Expiry Alarm Days setting and enforce expiry check
    if (Get.isRegistered<ServiceBrandContext>()) {
      final brandCtx = Get.find<ServiceBrandContext>();
      final alarmDays = await _repoStorage.getExpiryAlarmDays();
      brandCtx.setExpiryAlarmDays(alarmDays);

      final branch = brandCtx.selectedBranch;
      final plan = branch?.planDetails;
      if (plan != null && brandCtx.isPlanExpired) {
        if (Get.context != null) {
          DialogPlanExpiredBlock.show(Get.context!, branch: branch, plan: plan);
        }
        if (Get.isRegistered<AuthRepository>()) {
          await Get.find<AuthRepository>().logout();
        }
        await _repoStorage.logout();
        Get.offAllNamed(AppRoute.login);
        return;
      }
    }

    // ✅ Initialize Account Controller and prompt for Start Day & Shift if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        checkAndPromptDayShift(Get.context!);
      }
    });

    // ✅ Prompt user if branch plan is expiring soon based on configured expiry alarm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        DialogPlanExpiry.showIfExpiringSoon(Get.context!);
      }
    });
  }

  static bool isPromptingDayShift = false;

  void checkAndPromptDayShift(BuildContext context) {
    if (isPromptingDayShift) return;

    if (!Get.isRegistered<ControllerHomeAccount>()) {
      Get.put(ControllerHomeAccount(), permanent: true);
    }
    final accountCtrl = Get.find<ControllerHomeAccount>();
    accountCtrl.refreshAll();

    if (!accountCtrl.isDayOpen) {
      selectedMainMenu.value = EnumMainMenu.account;
      isPromptingDayShift = true;
      DialogStartDayShift.show(context, isShiftOnly: false).then((_) {
        isPromptingDayShift = false;
      });
    } else if (!accountCtrl.isShiftOpen) {
      selectedMainMenu.value = EnumMainMenu.account;
      isPromptingDayShift = true;
      DialogStartDayShift.show(context, isShiftOnly: true).then((_) {
        isPromptingDayShift = false;
      });
    } else if (selectedMainMenu.value == EnumMainMenu.logout) {
      selectedMainMenu.value = EnumMainMenu.pos;
    }
  }

  /// Single permission check
  bool can(EnumPermission permission) {
    final user = rxUser.value;
    if (user == null) {
      return false;
    }
    if (user.isActive == false) {
      return false;
    }
    // Fix: Handle null permissions list safely
    if (user.permissions == null) {
      return false;
    }
    return user.permissions!.contains(permission.name);
  }

  /// Multiple permissions (ANY)
  bool canAny(List<EnumPermission> permissions) {
    return permissions.any(can);
  }

  /// Multiple permissions (ALL)
  bool canAll(List<EnumPermission> permissions) {
    return permissions.every(can);
  }
}
