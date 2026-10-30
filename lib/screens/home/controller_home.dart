import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/auth/app_permissions.dart';
import '../../core/performance/plan_expiry_guard.dart';
import '../../enums/enum_main_menu.dart';
import '../../enums/enum_permission.dart';
import '../../core/app_type/app_type_service.dart';
import '../../core/storage/token_storage.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../model/entity_user.dart';
import '../../model/model_drawer_menu.dart';
import '../../repository/repo_drawer.dart';
import '../../repository/repo_storage.dart';
import '../../service/service_brand_context.dart';
import '../../service/service_device_guard.dart';
import '../../util/app_route.dart';
import '../../widget/dialog_device_limit_block.dart';
import '../../widget/dialog_plan_expired_block.dart';
import '../../widget/dialog_plan_expiry.dart';

import 'fragment/account/controller_home_account.dart';
import 'fragment/account/dialog_start_day_shift.dart';
import 'fragment/item/controller_home_item.dart';
import 'fragment/stocks/controller_home_stock.dart';
import 'fragment/purchase_supplier/purchase/controller_home_purchase.dart';
import 'fragment/purchase_supplier/supplier/controller_home_supplier.dart';
import 'fragment/pos/controller_home_pos.dart';
import 'fragment/customer/controller_home_customer.dart';
import '../sales/invoice/controller_sales_invoices.dart';
import '../sales/quotation/controller_quotations.dart';
import '../sales/returns/controller_sales_returns.dart';
import 'fragment/bills/controller_sales_report.dart';

class ControllerHome extends GetxController {
  final RepoStorage _repoStorage = Get.find();
  Rx<EntityUser?> rxUser = Rx<EntityUser?>(null);
  var selectedMainMenu = EnumMainMenu.dashboard.obs;
  late final isDrawerCollapsed = (_repoStorage.getDrawerCollapsed()).obs;

  @override
  void onInit() {
    ever(isDrawerCollapsed, (bool collapsed) {
      _repoStorage.setDrawerCollapsed(collapsed);
    });
    ever(selectedMainMenu, (EnumMainMenu _) {
      resetAllScreenSearches();
    });
    getUserDetails();
    super.onInit();
  }

  /// Automatically clears search text and filters whenever switching between screens
  void resetAllScreenSearches() {
    // 1. Item screen
    if (Get.isRegistered<ControllerHomeItem>()) {
      Get.find<ControllerHomeItem>().resetSearch();
    }
    // 2. Stock ledger screen
    if (Get.isRegistered<ControllerHomeStock>()) {
      Get.find<ControllerHomeStock>().resetSearch();
    }
    // 3. Purchase screen
    if (Get.isRegistered<ControllerHomePurchase>()) {
      Get.find<ControllerHomePurchase>().resetSearch();
    }
    // 4. Supplier screen
    if (Get.isRegistered<ControllerHomeSupplier>()) {
      Get.find<ControllerHomeSupplier>().resetSearch();
    }
    // 5. Sales screens
    if (Get.isRegistered<ControllerHomePos>()) {
      Get.find<ControllerHomePos>().resetSearch();
    }
    if (Get.isRegistered<ControllerSalesInvoices>()) {
      Get.find<ControllerSalesInvoices>().resetSearch();
    }
    if (Get.isRegistered<ControllerQuotations>()) {
      Get.find<ControllerQuotations>().resetSearch();
    }
    if (Get.isRegistered<ControllerSalesReturns>()) {
      Get.find<ControllerSalesReturns>().resetSearch();
    }
    if (Get.isRegistered<ControllerSalesReport>()) {
      Get.find<ControllerSalesReport>().resetSearch();
    }
    // Customer screen
    if (Get.isRegistered<ControllerHomeCustomer>()) {
      Get.find<ControllerHomeCustomer>().resetSearch();
    }
  }

  void toggleDrawer() {
    isDrawerCollapsed.toggle();
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

    // ✅ Restore the persisted business vertical (MARKET by default) so the
    // correct toolbar slot, print format, and KPIs are active on resume.
    if (Get.isRegistered<TokenStorage>() && Get.isRegistered<AppTypeService>()) {
      final savedAppType = Get.find<TokenStorage>().getAppType();
      if (savedAppType != null && savedAppType.trim().isNotEmpty) {
        await Get.find<AppTypeService>().applyAppType(savedAppType);
      }
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

      // ✅ Enforce maxPosDevices terminal quota
      if (branch != null && Get.isRegistered<ServiceDeviceGuard>()) {
        final deviceGuard = Get.find<ServiceDeviceGuard>();
        final authResult = await deviceGuard.verifyDevice(branch);
        if (!authResult.isAuthorized && Get.context != null) {
          DialogDeviceLimitBlock.show(
            Get.context!,
            branch: branch,
            result: authResult,
          );
          return;
        }
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

  bool _deviceCheckInProgress = false;
  bool _deviceAuthorized = false;

  /// Verifies if this physical machine is authorized under maxPosDevices
  Future<void> checkDeviceLimit(BuildContext context) async {
    if (_deviceAuthorized || _deviceCheckInProgress) return;
    if (!Get.isRegistered<ServiceBrandContext>() || !Get.isRegistered<ServiceDeviceGuard>()) return;
    final brandCtx = Get.find<ServiceBrandContext>();
    final branch = brandCtx.selectedBranch;
    if (branch == null) return;

    _deviceCheckInProgress = true;
    try {
      final deviceGuard = Get.find<ServiceDeviceGuard>();
      final authResult = await deviceGuard.verifyDevice(branch);
      if (authResult.isAuthorized) {
        _deviceAuthorized = true;
      } else if (context.mounted) {
        DialogDeviceLimitBlock.show(
          context,
          branch: branch,
          result: authResult,
        );
      }
    } finally {
      _deviceCheckInProgress = false;
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
    return role == 'SUPERADMIN' ||
        role == 'ADMIN' ||
        role == 'STOREADMIN' ||
        role == 'OWNER' ||
        role == 'MANAGER';
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
    final userPerms = user.permissions;
    // In standalone or unconfigured single-store POS environments where permissions array is empty,
    // do not lock out authenticated store staff from standard POS and customer tasks
    if (userPerms == null || userPerms.isEmpty) {
      final role = (user.role ?? '').trim().toUpperCase().replaceAll('_', '');
      if (role == 'CASHIER' || role == 'STAFF' || role.isEmpty) {
        return true;
      }
      return false;
    }

    final target = permission.trim().toUpperCase().replaceAll(':', '_').replaceAll('.', '_');
    for (final p in userPerms) {
      final current = p.trim().toUpperCase().replaceAll(':', '_').replaceAll('.', '_');
      if (current == target) return true;
      if (current == '*' || current == 'ALL' || current == 'MANAGE_ALL') return true;

      // Handle wildcard / broad resource permissions (e.g. CUSTOMERS, CUSTOMER_MANAGE, CUSTOMERS_ALL)
      if (target.contains('CUSTOMER') &&
          (current.contains('CUSTOMER') ||
              current == 'CUSTOMERS' ||
              current == 'CUSTOMER_MANAGE' ||
              current == 'CUSTOMERS_ALL')) {
        return true;
      }

      // Handle inverted action-resource names (e.g. CREATE_CUSTOMER <-> CUSTOMER_CREATE)
      if (target.contains('_')) {
        final parts = target.split('_');
        if (parts.length == 2 && current == '${parts[1]}_${parts[0]}') {
          return true;
        }
      }
    }
    return false;
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

  /// Checks whether the current user is authorized to view a specific menu fragment
  bool canAccessMenu(EnumMainMenu menu) {
    if (isSuperAdmin) return true;
    if (menu == EnumMainMenu.logout) return true;
    if (menu == EnumMainMenu.dashboard) {
      return hasPermission(AppPermissions.dashboardView);
    }
    if (menu == EnumMainMenu.settings) {
      return hasPermission(AppPermissions.systemManageConfig);
    }

    final permissions = rxUser.value?.permissions ?? [];
    if (permissions.isEmpty) return false;

    ModelDrawerMenu? findMenu(List<ModelDrawerMenu> list) {
      for (final item in list) {
        if (item.menu == menu) return item;
        if (item.children != null && item.children!.isNotEmpty) {
          final found = findMenu(item.children!);
          if (found != null) return found;
        }
      }
      return null;
    }

    final target = findMenu(RepoDrawer.mainMenus);
    if (target != null) {
      return target.isVisibleFor(permissions);
    }

    return true;
  }
}
