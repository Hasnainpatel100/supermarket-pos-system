import 'package:flutter/material.dart';

import '../enums/enum_main_menu.dart';

class ModelDrawerMenu {
  final EnumMainMenu menu;
  final String titleKey;
  final IconData icon;
  final List<String> permissions;
  final List<ModelDrawerMenu>? children;

  ModelDrawerMenu({
    required this.menu,
    required this.titleKey,
    required this.icon,
    this.permissions = const [],
    this.children,
  });
}

/// Recursive permission-visibility helpers.
///
/// A leaf menu (no children) is visible if the user holds ANY of its own
/// permissions. A parent menu (has children — e.g. a report category, or
/// "Reports" itself) is visible if ANY descendant at ANY depth is visible.
/// This lets the drawer nest to any depth without each new level needing
/// bespoke visibility logic in the drawer or the widget.
extension ModelDrawerMenuVisibility on ModelDrawerMenu {
  bool isVisibleFor(List<String> grantedPermissions) {
    if (grantedPermissions.isEmpty) {
      return false;
    }
    if (children == null || children!.isEmpty) {
      if (permissions.isEmpty) return false;
      return permissions.any((p) => grantedPermissions.contains(p));
    }
    return children!.any((c) => c.isVisibleFor(grantedPermissions));
  }

  List<ModelDrawerMenu> visibleChildrenFor(List<String> grantedPermissions) {
    return (children ?? [])
        .where((c) => c.isVisibleFor(grantedPermissions))
        .toList();
  }

  /// Walks down to the first visible leaf (a menu with no children).
  /// Used when a collapsed drawer icon or a category itself is tapped,
  /// so we always land on an actual content screen.
  ModelDrawerMenu? firstVisibleLeaf(List<String> grantedPermissions) {
    if (!isVisibleFor(grantedPermissions)) return null;
    if (children == null || children!.isEmpty) return this;
    for (final child in children!) {
      final leaf = child.firstVisibleLeaf(grantedPermissions);
      if (leaf != null) return leaf;
    }
    return null;
  }
}