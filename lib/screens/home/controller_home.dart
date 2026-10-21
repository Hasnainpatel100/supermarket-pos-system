import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/auth/app_permissions.dart';
import '../../core/performance/plan_expiry_guard.dart';
import '../../enums/enum_main_menu.dart';
import '../../enums/enum_permission.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../model/entity_user.dart';
import '../../model/model_drawer_menu.dart';
import '../../repository/repo_drawer.dart';
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
  var selectedMainMenu = EnumMainMenu.dashboard.obs;
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

      rxUser.value = entityUser;

      // Dynamically select the first accessible landing menu based on granted permissions
      _selectInitialLandingMenu(entityUser);
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

    // ✅ Prompt for Start Day & Shift ONLY if user has register/account/pos access
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

    // ✅ Schedule precision plan-expiry check (one-shot timer, not periodic polling)
    if (Get.isRegistered<PlanExpiryGuard>()) {
      Get.find<PlanExpiryGuard>().scheduleExpiryCheck();
    }
  }

  /// Automatically picks the initial landing screen based on what the user is allowed to access
  void _selectInitialLandingMenu(EntityUser user) {
    if (isSuperAdmin) {
      selectedMainMenu.value = EnumMainMenu.dashboard;
      return;
    }

    final permissions = user.permissions ?? [];
    if (permissions.isEmpty) {
      return;
    }

    // Prefer Dashboard if granted
    if (permissions.contains(AppPermissions.dashboardView)) {
      selectedMainMenu.value = EnumMainMenu.dashboard;
      return;
    }

    // Prefer POS if granted
    if (permissions.contains(AppPermissions.orderCreate)) {
      selectedMainMenu.value = EnumMainMenu.pos;
      return;
    }

    // Otherwise, pick the first visible leaf from drawer menus
    for (final menu in RepoDrawer.mainMenus) {
      final leaf = menu.firstVisibleLeaf(permissions);
      if (leaf != null) {
        selectedMainMenu.value = leaf.menu;
        return;
      }
    }
  }

  static bool isPromptingDayShift = false;

  void checkAndPromptDayShift(BuildContext context) {
    if (isPromptingDayShift) return;

    // Only prompt for day/shift register if user has billing or register permission
    if (!isSuperAdmin &&
        !hasPermission(AppPermissions.orderCreate) &&
        !hasPermission(AppPermissions.accountManage) &&
        !hasPermission(AppPermissions.accountRead)) {
      return;
    }

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
      selectedMainMenu.value = hasPermission(AppPermissions.orderCreate)
          ? EnumMainMenu.pos
          : EnumMainMenu.dashboard;
    }
  }

  // ── RBAC Checks ───────────────────────────────────────────────────────────

  bool get isSuperAdmin {
    final role = (rxUser.value?.role ?? '').trim().toUpperCase().replaceAll('_', '');
    return role == 'SUPERADMIN';
  }

  bool get hasNoPermissions {
    if (isSuperAdmin) return false;
    final user = rxUser.value;
    return user == null || user.permissions == null || user.permissions!.isEmpty;
  }

  /// Single permission check (String)
  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    final user = rxUser.value;
    if (user == null || user.isActive == false) return false;
    return user.permissions?.contains(permission) ?? false;
  }

  /// Multiple permissions (ANY)
  bool hasAnyPermission(List<String> permissions) {
    if (isSuperAdmin) return true;
    return permissions.any(hasPermission);
  }

  /// Multiple permissions (ALL)
  bool hasAllPermissions(List<String> permissions) {
    if (isSuperAdmin) return true;
    return permissions.every(hasPermission);
  }

  /// Backward-compatible check supporting String and legacy EnumPermission
  bool can(dynamic permission) {
    if (isSuperAdmin) return true;
    if (permission is String) {
      return hasPermission(permission);
    }
    if (permission is EnumPermission) {
      return hasPermission(_mapEnumPermissionToString(permission));
    }
    return false;
  }

  /// Multiple permissions (ANY) - backward compatible
  bool canAny(List<dynamic> permissions) {
    if (isSuperAdmin) return true;
    return permissions.any(can);
  }

  /// Multiple permissions (ALL) - backward compatible
  bool canAll(List<dynamic> permissions) {
    if (isSuperAdmin) return true;
    return permissions.every(can);
  }

  String _mapEnumPermissionToString(EnumPermission p) {
    switch (p) {
      case EnumPermission.userCreate: return AppPermissions.userCreate;
      case EnumPermission.userUpdate: return AppPermissions.userUpdate;
      case EnumPermission.userDisable: return AppPermissions.userDelete;
      case EnumPermission.roleAssign: return AppPermissions.userManageRoles;
      case EnumPermission.auditLogView: return AppPermissions.systemViewLogs;
      case EnumPermission.backupRestore: return AppPermissions.systemBackup;
      case EnumPermission.brandManage: return AppPermissions.brandUpdate;
      case EnumPermission.brandCreate: return AppPermissions.brandCreate;
      case EnumPermission.brandView: return AppPermissions.brandRead;
      case EnumPermission.branchManage: return AppPermissions.branchUpdate;
      case EnumPermission.branchCreate: return AppPermissions.branchCreate;
      case EnumPermission.branchView: return AppPermissions.branchRead;
      case EnumPermission.posBillCreate: return AppPermissions.orderCreate;
      case EnumPermission.salesInvoiceView: return AppPermissions.orderRead;
      case EnumPermission.account: return AppPermissions.accountRead;
      case EnumPermission.expenses: return AppPermissions.expenseRead;
      default: return p.name;
    }
  }
}
