import 'package:flutter/material.dart';

import '../core/auth/app_permissions.dart';
import '../enums/enum_main_menu.dart';
import '../model/entity_user.dart';
import '../model/model_drawer_menu.dart';
import '../widget/brand_branch_card.dart';
import '../widget/side_menu_header.dart';
import '../widget/side_menu_item.dart';

class RepoDrawer {
  static Widget drawerList(EntityUser entityUser) {
    final permissions = entityUser.permissions ?? [];
    final role = (entityUser.role ?? '').trim().toUpperCase().replaceAll('_', '');
    final isSuperAdmin = role == 'SUPERADMIN';

    // Top-level menu visibility (Dashboard & Settings)
    final hasDashboard = isSuperAdmin || permissions.contains(AppPermissions.dashboardView);
    final hasSettings = isSuperAdmin || permissions.contains(AppPermissions.systemManageConfig);

    return Material(
      elevation: 4,
      child: Column(
        children: [
          const SideMenuHeader(),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              children: [
                if (hasDashboard) ...[
                  const SideMenuItem.simple(
                    icon: Icons.dashboard_outlined,
                    titleKey: 'dashboard',
                    menu: EnumMainMenu.dashboard,
                  ),
                  const Divider(),
                ],

                ...buildSideMenus(permissions, isSuperAdmin: isSuperAdmin),
                const Divider(),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Brand / Branch context card ───────────────────────────────────
          const BrandBranchCard(),

          if (hasSettings)
            const SideMenuItem.simple(
              icon: Icons.settings_outlined,
              titleKey: 'settings',
              menu: EnumMainMenu.settings,
            ),

          const SideMenuItem.simple(
            icon: Icons.logout,
            titleKey: 'logout',
            menu: EnumMainMenu.logout,
          ),
        ],
      ),
    );
  }

  static List<Widget> buildSideMenus(List<String> permissions, {bool isSuperAdmin = false}) {
    // If superAdmin, show all menus. Otherwise filter strictly by backend permissions.
    final visibleMenus = isSuperAdmin
        ? mainMenus
        : mainMenus.where((menu) => menu.isVisibleFor(permissions)).toList();

    return visibleMenus
        .map(
          (menu) => SideMenuItem.menu(
            modelMenu: menu,
            permissions: isSuperAdmin ? _allPermissionNames : permissions,
          ),
        )
        .toList();
  }

  static const List<String> _allPermissionNames = AppPermissions.posPermissions;

  static List<ModelDrawerMenu> mainMenus = [
    // 1. Point of Sale (Billing) - Primary Daily Cashier Operation
    ModelDrawerMenu(
      menu: EnumMainMenu.pos,
      titleKey: 'pos',
      icon: Icons.point_of_sale_rounded,
      permissions: const [
        AppPermissions.orderCreate,
      ],
    ),

    // 2. Sales (Invoices, Quotations, Sales Returns)
    ModelDrawerMenu(
      menu: EnumMainMenu.salesGroup,
      titleKey: 'sales',
      icon: Icons.receipt_long_rounded,
      permissions: const [
        AppPermissions.orderRead,
        AppPermissions.orderList,
        AppPermissions.orderRefund,
      ],
      children: [
        ModelDrawerMenu(
          menu: EnumMainMenu.salesInvoices,
          titleKey: 'sales_invoices',
          icon: Icons.description_outlined,
          permissions: const [
            AppPermissions.orderRead,
            AppPermissions.orderList,
          ],
        ),
        ModelDrawerMenu(
          menu: EnumMainMenu.quotationEstimate,
          titleKey: 'quotation_estimate',
          icon: Icons.request_quote_outlined,
          permissions: const [
            AppPermissions.orderCreate,
            AppPermissions.orderRead,
          ],
        ),
        ModelDrawerMenu(
          menu: EnumMainMenu.salesReturn,
          titleKey: 'sales_return',
          icon: Icons.assignment_return_outlined,
          permissions: const [
            AppPermissions.orderRefund,
            AppPermissions.refundProcess,
          ],
        ),
      ],
    ),

    // 3. Accounts & Register (Day/Shift Management, Cash In / Out)
    ModelDrawerMenu(
      menu: EnumMainMenu.account,
      titleKey: 'account',
      icon: Icons.account_balance_wallet_rounded,
      permissions: const [
        AppPermissions.accountRead,
        AppPermissions.accountManage,
        AppPermissions.accountCreate,
      ],
    ),

    // 4. Products & Catalog (Items)
    ModelDrawerMenu(
      menu: EnumMainMenu.item,
      titleKey: 'item',
      icon: Icons.inventory_2_rounded,
      permissions: const [
        AppPermissions.inventoryRead,
        AppPermissions.inventoryCreate,
        AppPermissions.inventoryUpdate,
      ],
    ),

    // 5. Stock & Inventory History
    ModelDrawerMenu(
      menu: EnumMainMenu.stocks,
      titleKey: 'stocks history',
      icon: Icons.warehouse_rounded,
      permissions: const [
        AppPermissions.inventoryRead,
        AppPermissions.stockAdjust,
      ],
    ),

    // 6. Purchases & Suppliers
    ModelDrawerMenu(
      menu: EnumMainMenu.purchaseSupplier,
      titleKey: 'purchase_supplier',
      icon: Icons.shopping_bag_outlined,
      permissions: const [
        AppPermissions.purchaseRead,
        AppPermissions.purchaseCreate,
        AppPermissions.supplierRead,
        AppPermissions.supplierCreate,
        AppPermissions.inventoryCreate,
      ],
      children: [
        ModelDrawerMenu(
          menu: EnumMainMenu.purchase,
          titleKey: 'purchase',
          icon: Icons.shopping_cart_outlined,
          permissions: const [
            AppPermissions.purchaseRead,
            AppPermissions.purchaseCreate,
            AppPermissions.inventoryCreate,
          ],
        ),
        ModelDrawerMenu(
          menu: EnumMainMenu.supplier,
          titleKey: 'supplier',
          icon: Icons.supervisor_account_outlined,
          permissions: const [
            AppPermissions.supplierRead,
            AppPermissions.supplierCreate,
            AppPermissions.inventoryRead,
          ],
        ),
      ],
    ),

    // 7. Customers & CRM
    ModelDrawerMenu(
      menu: EnumMainMenu.customer,
      titleKey: 'customer',
      icon: Icons.people_alt_outlined,
      permissions: const [
        AppPermissions.customerRead,
        AppPermissions.customerList,
        AppPermissions.customerCreate,
        AppPermissions.orderRead,
      ],
    ),

    // 8. Store Expenses
    ModelDrawerMenu(
      menu: EnumMainMenu.expenses,
      titleKey: 'Expenses',
      icon: Icons.payments_outlined,
      permissions: const [
        AppPermissions.expenseRead,
        AppPermissions.expenseCreate,
      ],
    ),

    // 9. Reports & Analytics
    buildReportsMenu(),

    // 10. System Maintenance
    ModelDrawerMenu(
      menu: EnumMainMenu.system,
      titleKey: 'system',
      icon: Icons.admin_panel_settings_outlined,
      permissions: const [
        AppPermissions.systemBackup,
        AppPermissions.systemViewLogs,
        AppPermissions.systemMaintenance,
      ],
      children: [
        ModelDrawerMenu(
          menu: EnumMainMenu.backup,
          titleKey: 'Backup & Recovery',
          icon: Icons.backup_outlined,
          permissions: const [AppPermissions.systemBackup],
        ),
        ModelDrawerMenu(
          menu: EnumMainMenu.auditLogs,
          titleKey: 'audit_logs',
          icon: Icons.history_rounded,
          permissions: const [
            AppPermissions.systemViewLogs,
            AppPermissions.reportViewUserActivity,
          ],
        ),
      ],
    ),
  ];

  // -------------------------------------------------------------------
  // REPORTS CONFIGURATION
  // -------------------------------------------------------------------

  static const List<ReportCategory> reportCategories = [
    ReportCategory(
      menu: EnumMainMenu.reportGroupSales,
      titleKey: 'sales reports',
      icon: Icons.point_of_sale_outlined,
      permission: AppPermissions.reportViewSales,
      reports: [],
    ),
    ReportCategory(
      menu: EnumMainMenu.reportGroupInventory,
      titleKey: 'inventory reports',
      icon: Icons.inventory_2_outlined,
      permission: AppPermissions.inventoryRead,
      reports: [],
    ),
    ReportCategory(
      menu: EnumMainMenu.reportGroupPurchase,
      titleKey: 'purchase reports',
      icon: Icons.shopping_cart_outlined,
      permission: AppPermissions.purchaseRead,
      reports: [],
    ),
    ReportCategory(
      menu: EnumMainMenu.reportGroupProfit,
      titleKey: 'profit reports',
      icon: Icons.trending_up,
      permission: AppPermissions.reportViewFinancial,
      reports: [],
    ),
    ReportCategory(
      menu: EnumMainMenu.reportGroupReturn,
      titleKey: 'return reports',
      icon: Icons.assignment_return_outlined,
      permission: AppPermissions.orderRefund,
      reports: [],
    ),
    ReportCategory(
      menu: EnumMainMenu.reportGroupSupplier,
      titleKey: 'supplier reports',
      icon: Icons.local_shipping_outlined,
      permission: AppPermissions.supplierRead,
      reports: [],
    ),
    ReportCategory(
      menu: EnumMainMenu.reportGroupCashier,
      titleKey: 'cashier reports',
      icon: Icons.badge_outlined,
      permission: AppPermissions.accountRead,
      reports: [],
    ),
    ReportCategory(
      menu: EnumMainMenu.reportGroupFinancial,
      titleKey: 'financial reports',
      icon: Icons.account_balance_outlined,
      permission: AppPermissions.reportViewFinancial,
      reports: [],
    ),
  ];

  /// Builds the "Reports" `ModelDrawerMenu` from [reportCategories].
  static ModelDrawerMenu buildReportsMenu() {
    return ModelDrawerMenu(
      menu: EnumMainMenu.reports,
      titleKey: 'reports',
      icon: Icons.bar_chart_outlined,
      permissions: [
        AppPermissions.reportView,
        AppPermissions.reportViewSales,
        AppPermissions.reportViewFinancial,
        AppPermissions.reportViewUserActivity,
      ],
      children: reportCategories
          .map(
            (category) => ModelDrawerMenu(
              menu: category.menu,
              titleKey: category.titleKey,
              icon: category.icon,
              permissions: [category.permission, AppPermissions.reportView],
              children: category.reports
                  .map(
                    (report) => ModelDrawerMenu(
                      menu: report.menu,
                      titleKey: report.titleKey,
                      icon: report.icon,
                      permissions: [category.permission, AppPermissions.reportView],
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}

class ReportPage {
  final EnumMainMenu menu;
  final String titleKey;
  final IconData icon;

  const ReportPage({
    required this.menu,
    required this.titleKey,
    required this.icon,
  });
}

class ReportCategory {
  final EnumMainMenu menu;
  final String titleKey;
  final IconData icon;
  final String permission;
  final List<ReportPage> reports;

  const ReportCategory({
    required this.menu,
    required this.titleKey,
    required this.icon,
    required this.permission,
    required this.reports,
  });
}