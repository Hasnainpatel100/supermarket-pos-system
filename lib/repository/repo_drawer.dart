import 'package:flutter/material.dart';

import '../enums/enum_main_menu.dart';
import '../enums/enum_permission.dart';
import '../model/entity_user.dart';
import '../model/model_drawer_menu.dart';
import '../widget/side_menu_header.dart';
import '../widget/side_menu_item.dart';

class RepoDrawer {
  static Widget drawerList(EntityUser entityUser) {
    final permissions = entityUser.permissions ?? [];

    return Material(
      elevation: 4,
      child: Column(
        children: [
          const SideMenuHeader(),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              children: [
                const SideMenuItem.simple(
                  icon: Icons.dashboard_outlined,
                  titleKey: 'dashboard',
                  menu: EnumMainMenu.dashboard,
                ),

                const Divider(),

                ...buildSideMenus(permissions),
                const Divider(),
              ],
            ),
          ),

          const Divider(height: 1),

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

  static List<Widget> buildSideMenus(List<String> permissions) {
    return mainMenus
        .where((menu) => menu.isVisibleFor(permissions))
        .map(
          (menu) =>
          SideMenuItem.menu(modelMenu: menu, permissions: permissions),
    )
        .toList();
  }

  static List<ModelDrawerMenu> mainMenus = [
    ModelDrawerMenu(
      menu: EnumMainMenu.item,
      titleKey: 'item',
      icon: Icons.widgets_rounded,
      permissions: [
        EnumPermission.itemCreate,
        EnumPermission.itemUpdate,
        EnumPermission.itemView,
        EnumPermission.stockIn,
        EnumPermission.stockOut,
        EnumPermission.stockAdjust,
        EnumPermission.stockCount,
        EnumPermission.stockView,
        EnumPermission.expiryManage,
      ],
    ),
    ModelDrawerMenu(
      menu: EnumMainMenu.pos,
      titleKey: 'pos',
      icon: Icons.edit_note_rounded,
      permissions: [
        EnumPermission.posBillCreate,
        EnumPermission.posBillHold,
        EnumPermission.posBillResume,
        EnumPermission.posBillCancel,
        EnumPermission.posBillVoid,
        EnumPermission.posBillReturnSameDay,
        EnumPermission.posPaymentCollect,
        EnumPermission.posBillReprint,
      ],
    ),

    ModelDrawerMenu(
      menu: EnumMainMenu.stocks,
      titleKey: 'stocks history',
      icon: Icons.inventory,
      permissions: [
        EnumPermission.stockAdjust,
        EnumPermission.stockCount,
        EnumPermission.stockAdjust,
        EnumPermission.stockIn,
        EnumPermission.stockOut,
        EnumPermission.stockView,
      ],
    ),

    ModelDrawerMenu(
      menu: EnumMainMenu.customer,
      titleKey: 'customer',
      icon: Icons.local_offer_outlined,
      permissions: [
        EnumPermission.priceView,
        EnumPermission.priceUpdate,
        EnumPermission.discountApply,
        EnumPermission.discountOverride,
        EnumPermission.customerEdit,
        EnumPermission.customerEdit,
        EnumPermission.customerDelete,
      ],
    ),

    ModelDrawerMenu(
      menu: EnumMainMenu.purchaseSupplier,
      titleKey: 'purchase_supplier',
      icon: Icons.shopping_cart_outlined,
      permissions: [
        EnumPermission.purchaseCreate,
        EnumPermission.purchaseReceive,
        EnumPermission.supplierManage,
      ],
      children: [
        ModelDrawerMenu(
          menu: EnumMainMenu.purchase,
          titleKey: 'purchase',
          icon: Icons.shopping_cart,
          permissions: [
            EnumPermission.purchaseCreate,
            EnumPermission.purchaseReceive,
          ],
        ),
        ModelDrawerMenu(
          menu: EnumMainMenu.supplier,
          titleKey: 'supplier',
          icon: Icons.supervisor_account,
          permissions: [EnumPermission.supplierManage],
        ),
      ],
    ),

    // Reports: built from `reportCategories` below. To add a new report,
    // add one `_ReportPage` entry to its category's `reports` list. To add
    // a whole new category, add a new `EnumMainMenu` value for it (and one
    // per report inside it), plus a new `EnumPermission` to gate it, then
    // add a `_ReportCategory` entry here. Nothing else needs to change —
    // the drawer nesting, permission filtering, and navigation are all
    // generated from this config.
    buildReportsMenu(),

    ModelDrawerMenu(
      menu: EnumMainMenu.expenses,
      titleKey: 'Expenses',
      icon: Icons.payment_outlined,
      permissions: [EnumPermission.expenses],
    ),
    ModelDrawerMenu(
      menu: EnumMainMenu.system,
      titleKey: 'system',
      icon: Icons.admin_panel_settings_outlined,
      permissions: [
        EnumPermission.userCreate,
        EnumPermission.userUpdate,
        EnumPermission.userDisable,
        EnumPermission.roleAssign,
        EnumPermission.backupRestore,
      ],

      children: [
        ModelDrawerMenu(
          menu: EnumMainMenu.systemUsers,
          titleKey: 'users',
          icon: Icons.people_outline,
          permissions: [
            EnumPermission.userCreate,
            EnumPermission.userUpdate,
            EnumPermission.userDisable,
            EnumPermission.roleAssign,
          ],
        ),
        ModelDrawerMenu(
          menu: EnumMainMenu.backup,
          titleKey: 'Backup & Recovery',
          icon: Icons.backup_outlined,
          permissions: [EnumPermission.backupRestore],
        ),
      ],
    ),
  ];

  // -------------------------------------------------------------------
  // REPORTS CONFIGURATION
  // -------------------------------------------------------------------

  static const List<_ReportCategory> reportCategories = [
    _ReportCategory(
      menu: EnumMainMenu.reportGroupSales,
      titleKey: 'sales reports',
      icon: Icons.point_of_sale_outlined,
      permission: EnumPermission.reportSalesView,
      reports: [],
    ),

    _ReportCategory(
      menu: EnumMainMenu.reportGroupInventory,
      titleKey: 'inventory reports',
      icon: Icons.inventory_2_outlined,
      permission: EnumPermission.reportStockView,
      reports: [],
    ),

    _ReportCategory(
      menu: EnumMainMenu.reportGroupPurchase,
      titleKey: 'purchase reports',
      icon: Icons.shopping_cart_outlined,
      permission: EnumPermission.reportPurchaseView,
      reports: [],
    ),

    _ReportCategory(
      menu: EnumMainMenu.reportGroupProfit,
      titleKey: 'profit reports',
      icon: Icons.trending_up,
      permission: EnumPermission.reportProfitView,
      reports: [],
    ),

    _ReportCategory(
      menu: EnumMainMenu.reportGroupReturn,
      titleKey: 'return reports',
      icon: Icons.assignment_return_outlined,
      permission: EnumPermission.reportReturnView,
      reports: [],
    ),

    // _ReportCategory(
    //   menu: EnumMainMenu.reportGroupCustomer,
    //   titleKey: 'customer',
    //   icon: Icons.people_outline,
    //   permission: EnumPermission.reportCustomerView,
    //   reports: [
    //     _ReportPage(
    //       menu: EnumMainMenu.reportCustomerPurchaseHistory,
    //       titleKey: 'customer purchase history',
    //       icon: Icons.history,
    //     ),
    //     _ReportPage(
    //       menu: EnumMainMenu.reportTopCustomers,
    //       titleKey: 'top customers',
    //       icon: Icons.emoji_events_outlined,
    //     ),
    //     _ReportPage(
    //       menu: EnumMainMenu.reportCustomerOutstanding,
    //       titleKey: 'customer outstanding',
    //       icon: Icons.account_balance_wallet_outlined,
    //     ),
    //   ],
    // ),

    _ReportCategory(
      menu: EnumMainMenu.reportGroupSupplier,
      titleKey: 'supplier reports',
      icon: Icons.local_shipping_outlined,
      permission: EnumPermission.reportSupplierView,
      reports: [],
    ),

    _ReportCategory(
      menu: EnumMainMenu.reportGroupCashier,
      titleKey: 'cashier reports',
      icon: Icons.badge_outlined,
      permission: EnumPermission.reportCashierView,
      reports: [],
    ),

    _ReportCategory(
      menu: EnumMainMenu.reportGroupFinancial,
      titleKey: 'financial reports',
      icon: Icons.account_balance_outlined,
      permission: EnumPermission.reportFinancialView,
      reports: [],
    ),
  ];
  /// Builds the "Reports" `ModelDrawerMenu` (with nested category and
  /// report children) from [reportCategories].
  static ModelDrawerMenu buildReportsMenu() {
    return ModelDrawerMenu(
      menu: EnumMainMenu.reports,
      titleKey: 'reports',
      icon: Icons.bar_chart_outlined,
      permissions: reportCategories.map((c) => c.permission).toList(),
      children: reportCategories
          .map(
            (category) => ModelDrawerMenu(
          menu: category.menu,
          titleKey: category.titleKey,
          icon: category.icon,
          permissions: [category.permission],
          children: category.reports
              .map(
                (report) => ModelDrawerMenu(
              menu: report.menu,
              titleKey: report.titleKey,
              icon: report.icon,
              permissions: [category.permission],
            ),
          )
              .toList(),
        ),
      )
          .toList(),
    );
  }

/*
  ... [unchanged legacy commented-out block from the original file stays here as-is] ...
  */
}

class _ReportPage {
  final EnumMainMenu menu;
  final String titleKey;
  final IconData icon;

  const _ReportPage({
    required this.menu,
    required this.titleKey,
    required this.icon,
  });
}

class _ReportCategory {
  final EnumMainMenu menu;
  final String titleKey;
  final IconData icon;
  final EnumPermission permission;
  final List<_ReportPage> reports;

  const _ReportCategory({
    required this.menu,
    required this.titleKey,
    required this.icon,
    required this.permission,
    required this.reports,
  });
}