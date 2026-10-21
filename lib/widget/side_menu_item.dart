import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../enums/enum_main_menu.dart';
import '../model/model_drawer_menu.dart';
import '../screens/home/controller_home.dart';
import '../service/service_locale.dart';

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

  /// PERMISSION / EXPANDABLE MENU (System, Purchase & Supplier, Reports,
  /// and any nested report category underneath Reports). Recurses to
  /// support any depth of nesting.
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
    final ServiceLocale localeService = Get.find();

    return Obx(() {
      final _ = localeService.rxLocale.value;
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

      // FILTER VISIBLE CHILDREN BY PERMISSION (recursive: a child that is
      // itself a category is visible if any of ITS children are visible)
      final visibleChildren = menuModel.visibleChildrenFor(perms);

      // If no children visible, hide the entire menu
      if (menuModel.children != null && visibleChildren.isEmpty) {
        return const SizedBox.shrink();
      }

      // COLLAPSED DRAWER -> behave like SIMPLE TILE or POPUP FLYOUT FOR EXPANDABLE MENUS
      if (collapsed) {
        final bool selected =
            controller.selectedMainMenu.value == menuModel.menu;

        return Builder(
          builder: (tileContext) {
            final tile = ListTile(
              leading: Icon(
                menuModel.icon,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: null,
              selected: selected,
              onTap: () {
                if (menuModel.children != null && visibleChildren.isNotEmpty) {
                  // Anchor flyout menu right next to the icon in collapsed rail
                  final RenderBox renderBox =
                      tileContext.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  final size = renderBox.size;

                  final List<PopupMenuEntry<EnumMainMenu>> items = [];

                  // Section header
                  items.add(PopupMenuItem<EnumMainMenu>(
                    enabled: false,
                    height: 32,
                    child: Text(
                      menuModel.titleKey.tr.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ));
                  items.add(const PopupMenuDivider(height: 4));

                  for (final child in visibleChildren) {
                    if (child.children != null && child.children!.isNotEmpty) {
                      items.add(PopupMenuItem<EnumMainMenu>(
                        enabled: false,
                        height: 28,
                        child: Text(
                          child.titleKey.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ));
                      for (final subChild in child.visibleChildrenFor(perms)) {
                        items.add(PopupMenuItem<EnumMainMenu>(
                          value: subChild.menu,
                          height: 36,
                          child: Row(
                            children: [
                              Icon(subChild.icon,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 10),
                              Text(subChild.titleKey.tr,
                                  style: const TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        ));
                      }
                    } else {
                      items.add(PopupMenuItem<EnumMainMenu>(
                        value: child.menu,
                        height: 38,
                        child: Row(
                          children: [
                            Icon(child.icon,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(child.titleKey.tr,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ));
                    }
                  }

                  showMenu<EnumMainMenu>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      offset.dx + size.width + 4,
                      offset.dy,
                      offset.dx + size.width + 260,
                      offset.dy + size.height,
                    ),
                    items: items,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ).then((chosen) {
                    if (chosen != null) {
                      controller.selectedMainMenu.value = chosen;
                    }
                  });
                } else {
                  final leaf = menuModel.firstVisibleLeaf(perms);
                  controller.selectedMainMenu.value =
                      leaf?.menu ?? menuModel.menu;
                }
              },
            );

            return Tooltip(message: menuModel.titleKey.tr, child: tile);
          },
        );
      }

      // EXPANDED DRAWER -> REAL EXPANSION TILE
      if (menuModel.children != null) {
        return ExpansionTile(
          leading: Icon(menuModel.icon),
          title: Text(menuModel.titleKey.tr),
          children: visibleChildren.map((child) {
            // A child that itself has children (e.g. "Sales Reports"
            // nested under "Reports") renders as its own nested
            // expandable menu instead of a flat, tappable ListTile.
            if (child.children != null && child.children!.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SideMenuItem.menu(modelMenu: child, permissions: perms),
              );
            }

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