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
        .where((menu) {
          // Parent visible if:
          // - it has no children AND has permission
          // - OR any child is visible
          if (menu.children == null) {
            return menu.permissions.any((p) => permissions.contains(p.name));
          }
          return menu.children!.any(
            (c) => c.permissions.any((p) => permissions.contains(p.name)),
          );
        })
        .map(
          (menu) =>
              SideMenuItem.menu(modelMenu: menu, permissions: permissions),
        )
        .toList();
  }

  static List<ModelDrawerMenu> mainMenus = [
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

    // ModelDrawerMenu(
    //   menu: EnumMainMenu.system,
    //   titleKey: 'pos',
    //   icon: Icons.edit_note_rounded,
    //   permissions: [
    //     EnumPermission.userCreate,
    //     EnumPermission.userUpdate,
    //     EnumPermission.userDisable,
    //     EnumPermission.roleAssign,
    //     EnumPermission.systemSettingsUpdate,
    //     EnumPermission.dataSyncManual,
    //     EnumPermission.auditLogView,
    //   ],
    //
    //   children: [
    //     ModelDrawerMenu(
    //       menu: EnumMainMenu.systemUsers,
    //       titleKey: 'bill',
    //       icon: Icons.people_outline,
    //       permissions: [
    //         EnumPermission.posBillCreate,
    //         EnumPermission.posBillHold,
    //         EnumPermission.posBillResume,
    //         EnumPermission.posBillCancel,
    //         EnumPermission.posBillVoid
    //       ],
    //     ),
    //     ModelDrawerMenu(
    //       menu: EnumMainMenu.systemSettings,
    //       titleKey: 'payment',
    //       icon: Icons.settings_outlined,
    //       permissions: [EnumPermission.posPaymentCollect],
    //     ),
    //     ModelDrawerMenu(
    //       menu: EnumMainMenu.auditLogs,
    //       titleKey: 'return',
    //       icon: Icons.undo,
    //       permissions: [EnumPermission.posBillReturnSameDay],
    //     ),
    //   ],
    // ),

    ModelDrawerMenu(
      menu: EnumMainMenu.inventory,
      titleKey: 'inventory',
      icon: Icons.inventory_2_outlined,
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
      children: [
        ModelDrawerMenu(
          menu: EnumMainMenu.item,
          titleKey: 'item',
          icon: Icons.widgets_rounded,
          permissions: [
            EnumPermission.itemCreate,
            EnumPermission.itemUpdate,
            EnumPermission.itemView,
          ],
        ),
        ModelDrawerMenu(
          menu: EnumMainMenu.stocks,
          titleKey: 'stocks',
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
      ],
    ),
    ModelDrawerMenu(
      menu: EnumMainMenu.pricingDiscount,
      titleKey: 'pricing_discount',
      icon: Icons.local_offer_outlined,
      permissions: [
        EnumPermission.priceView,
        EnumPermission.priceUpdate,
        EnumPermission.discountApply,
        EnumPermission.discountOverride,
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
    ),
    ModelDrawerMenu(
      menu: EnumMainMenu.reports,
      titleKey: 'reports',
      icon: Icons.assessment_outlined,
      permissions: [
        EnumPermission.reportSalesView,
        EnumPermission.reportStockView,
        EnumPermission.reportProfitView,
        EnumPermission.reportTaxView,
        EnumPermission.reportExport,
      ],
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
        EnumPermission.systemSettingsUpdate,
        EnumPermission.dataSyncManual,
        EnumPermission.auditLogView,
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
          menu: EnumMainMenu.systemSettings,
          titleKey: 'system_settings',
          icon: Icons.settings_outlined,
          permissions: [EnumPermission.systemSettingsUpdate],
        ),
        ModelDrawerMenu(
          menu: EnumMainMenu.auditLogs,
          titleKey: 'audit_logs',
          icon: Icons.history,
          permissions: [EnumPermission.auditLogView],
        ),
      ],
    ),
  ];

  /*
  static Widget drawerList(EntityUser entityUser) {
    var listPermissions = entityUser.permissions!;
    return ListView(
      children: [
        // Dashboard (always visible)
        dashboardItem,

        const Divider(),

        // Permission-based menus
        buildPermissionMenu(
              titleKey: 'pos',
              icon: Icons.edit_note_rounded,
              config: posMenuConfig,
              permissions: listPermissions,
            ) ??
            const SizedBox(),

        buildPermissionMenu(
              titleKey: 'inventory',
              icon: Icons.inventory_2_outlined,
              config: inventoryMenuConfig,
              permissions: listPermissions,
            ) ??
            const SizedBox(),

        buildPermissionMenu(
              titleKey: 'pricing_discount',
              icon: Icons.local_offer_outlined,
              config: pricingMenuConfig,
              permissions: listPermissions,
            ) ??
            const SizedBox(),

        buildPermissionMenu(
              titleKey: 'purchase_supplier',
              icon: Icons.shopping_cart_outlined,
              config: purchaseMenuConfig,
              permissions: listPermissions,
            ) ??
            const SizedBox(),

        buildPermissionMenu(
              titleKey: 'reports',
              icon: Icons.assessment_outlined,
              config: reportMenuConfig,
              permissions: listPermissions,
            ) ??
            const SizedBox(),

        buildPermissionMenu(
              titleKey: 'system',
              icon: Icons.admin_panel_settings_outlined,
              config: systemMenuConfig,
              permissions: listPermissions,
            ) ??
            const SizedBox(),

        const Divider(),

        // Settings
        settingsItem,

        // Logout
        logoutItem,
      ],
    );
  }

  static Widget? buildPermissionMenu({
    required String titleKey,
    required IconData icon,
    required List<DrawerPermissionItem> config,
    required List<String> permissions,
  })
  {
    final allowedItems = config
        .where((item) => permissions.contains(item.permission.name))
        .toList();

    if (allowedItems.isEmpty) return null;

    return ExpansionTile(
      title: Text(titleKey.tr),
      leading: Icon(icon),
      children: allowedItems.map((item) {
        return ListTile(
          title: Text(item.titleKey.tr),
          trailing: const Icon(Icons.keyboard_arrow_right_sharp),
          onTap: item.onTap,
        );
      }).toList(),
    );
  }

  static final dashboardItem = buildStaticDrawerItem(
    titleKey: 'dashboard',
    icon: Icons.dashboard_outlined,
    onTap: () {
      // Navigate to dashboard
    },
  );
  static final settingsItem = buildStaticDrawerItem(
    titleKey: 'settings',
    icon: Icons.settings_outlined,
    onTap: () {
      // Navigate to settings
    },
  );

  static final logoutItem = buildStaticDrawerItem(
    titleKey: 'logout',
    icon: Icons.logout,
    onTap: () {
      // Clear session & navigate to login
    },
  );

  static ListTile buildStaticDrawerItem({
    required String titleKey,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(titleKey.tr),
      trailing: const Icon(Icons.keyboard_arrow_right_sharp),
      onTap: onTap,
    );
  }

  static const List<DrawerPermissionItem> posMenuConfig = [
    DrawerPermissionItem(
      permission: EnumPermission.posBillCreate,
      titleKey: 'bill_create',
      icon: Icons.add,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.posBillHold,
      titleKey: 'bill_hold',
      icon: Icons.pause,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.posBillResume,
      titleKey: 'bill_resume',
      icon: Icons.play_arrow,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.posBillCancel,
      titleKey: 'bill_cancel',
      icon: Icons.cancel,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.posBillVoid,
      titleKey: 'bill_void',
      icon: Icons.block,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.posBillReturnSameDay,
      titleKey: 'bill_return',
      icon: Icons.undo,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.posPaymentCollect,
      titleKey: 'payment_collect',
      icon: Icons.payments,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.posBillReprint,
      titleKey: 'bill_reprint',
      icon: Icons.print,
    ),
  ];
  static const List<DrawerPermissionItem> inventoryMenuConfig = [
    DrawerPermissionItem(
      permission: EnumPermission.itemCreate,
      titleKey: 'item_create',
      icon: Icons.add_box,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.itemUpdate,
      titleKey: 'item_update',
      icon: Icons.edit,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.itemView,
      titleKey: 'item_view',
      icon: Icons.visibility,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.stockIn,
      titleKey: 'stock_in',
      icon: Icons.call_received,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.stockOut,
      titleKey: 'stock_out',
      icon: Icons.call_made,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.stockAdjust,
      titleKey: 'stock_adjust',
      icon: Icons.tune,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.stockCount,
      titleKey: 'stock_count',
      icon: Icons.fact_check,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.stockView,
      titleKey: 'stock_view',
      icon: Icons.inventory,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.expiryManage,
      titleKey: 'expiry_manage',
      icon: Icons.event_busy,
    ),
  ];
  static const List<DrawerPermissionItem> pricingMenuConfig = [
    DrawerPermissionItem(
      permission: EnumPermission.priceView,
      titleKey: 'price_view',
      icon: Icons.visibility,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.priceUpdate,
      titleKey: 'price_update',
      icon: Icons.edit,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.discountApply,
      titleKey: 'discount_apply',
      icon: Icons.percent,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.discountOverride,
      titleKey: 'discount_override',
      icon: Icons.lock_open,
    ),
  ];
  static const List<DrawerPermissionItem> purchaseMenuConfig = [
    DrawerPermissionItem(
      permission: EnumPermission.purchaseCreate,
      titleKey: 'purchase_create',
      icon: Icons.add_shopping_cart,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.purchaseReceive,
      titleKey: 'purchase_receive',
      icon: Icons.inventory_2,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.supplierManage,
      titleKey: 'supplier_manage',
      icon: Icons.local_shipping,
    ),
  ];
  static const List<DrawerPermissionItem> reportMenuConfig = [
    DrawerPermissionItem(
      permission: EnumPermission.reportSalesView,
      titleKey: 'report_sales',
      icon: Icons.bar_chart,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.reportStockView,
      titleKey: 'report_stock',
      icon: Icons.inventory_2,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.reportProfitView,
      titleKey: 'report_profit',
      icon: Icons.trending_up,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.reportTaxView,
      titleKey: 'report_tax',
      icon: Icons.receipt_long,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.reportExport,
      titleKey: 'report_export',
      icon: Icons.file_download,
    ),
  ];
  static const List<DrawerPermissionItem> systemMenuConfig = [
    DrawerPermissionItem(
      permission: EnumPermission.userCreate,
      titleKey: 'user_create',
      icon: Icons.person_add,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.userUpdate,
      titleKey: 'user_update',
      icon: Icons.manage_accounts,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.userDisable,
      titleKey: 'user_disable',
      icon: Icons.person_off,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.roleAssign,
      titleKey: 'role_assign',
      icon: Icons.security,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.systemSettingsUpdate,
      titleKey: 'system_settings',
      icon: Icons.settings,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.dataSyncManual,
      titleKey: 'data_sync',
      icon: Icons.sync,
    ),
    DrawerPermissionItem(
      permission: EnumPermission.auditLogView,
      titleKey: 'audit_log',
      icon: Icons.history,
    ),
  ];
  */
}
