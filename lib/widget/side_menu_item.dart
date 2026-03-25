import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../enums/enum_main_menu.dart';
import '../model/model_drawer_menu.dart';
import '../screens/home/controller_home.dart';

class SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final EnumMainMenu menu;

  final ModelDrawerMenu? modelMenu;
  final List<String>? permissions;

  /// SIMPLE MENU (Dashboard / Settings / Logout)
  const SideMenuItem.simple({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.menu,
  }) : modelMenu = null,
       permissions = null;

  /// PERMISSION / EXPANDABLE MENU (System)
  SideMenuItem.menu({
    super.key,
    required this.modelMenu,
    required this.permissions,
  }) : icon = modelMenu!.icon,
       titleKey = modelMenu.titleKey,
       menu = modelMenu.menu;

  @override
  Widget build(BuildContext context) {
    final ControllerHome controller = Get.find();

    return Obx(() {
      final bool collapsed = controller.isDrawerCollapsed.value;
      // SIMPLE MENU (always clickable, always visible)
      if (modelMenu == null) {
        final bool selected = controller.selectedMainMenu.value == menu;

        final tile = ListTile(
          leading: Icon(
            icon,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
          title: collapsed ? null : Text(titleKey.tr),
          selected: selected,
          onTap: () {
            controller.selectedMainMenu.value = menu;
          },
        );

        return collapsed ? Tooltip(message: titleKey.tr, child: tile) : tile;
      }

      final ModelDrawerMenu menuModel = modelMenu!;
      final List<String> perms = permissions!;

      // FILTER VISIBLE CHILDREN BY PERMISSION
      final visibleChildren = menuModel.children
          ?.where((c) => c.permissions.any((p) => perms.contains(p.name)))
          .toList();

      // If no children visible, hide the entire menu
      if (menuModel.children != null &&
          (visibleChildren == null || visibleChildren.isEmpty)) {
        return const SizedBox.shrink();
      }

      // COLLAPSED DRAWER -> behave like SIMPLE TILE + TOOLTIP
      if (collapsed) {
        final bool selected =
            controller.selectedMainMenu.value == menuModel.menu;

        final tile = ListTile(
          leading: Icon(
            menuModel.icon,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
          title: null,
          selected: selected,
          onTap: () {
            // Default behavior: open first visible child
            if (visibleChildren != null && visibleChildren.isNotEmpty) {
              controller.selectedMainMenu.value = visibleChildren.first.menu;
            } else {
              controller.selectedMainMenu.value = menuModel.menu;
            }
          },
        );

        return Tooltip(message: menuModel.titleKey.tr, child: tile);
      }

      // EXPANDED DRAWER -> REAL EXPANSION TILE
      if (menuModel.children != null) {
        return ExpansionTile(
          leading: Icon(menuModel.icon),
          title: Text(menuModel.titleKey.tr),
          children: visibleChildren!.map((child) {
            final bool selected =
                controller.selectedMainMenu.value == child.menu;

            return ListTile(
              leading: Icon(
                child.icon,
                size: 18,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(child.titleKey.tr),
              selected: selected,
              onTap: () {
                controller.selectedMainMenu.value = child.menu;
              },
            );
          }).toList(),
        );
      }

      // FALLBACK (non-expandable permission menu)
      final bool selected = controller.selectedMainMenu.value == menuModel.menu;

      return ListTile(
        leading: Icon(
          menuModel.icon,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: collapsed ? null : Text(menuModel.titleKey.tr),
        selected: selected,
        onTap: () {
          controller.selectedMainMenu.value = menuModel.menu;
        },
      );
    });
  }
}
