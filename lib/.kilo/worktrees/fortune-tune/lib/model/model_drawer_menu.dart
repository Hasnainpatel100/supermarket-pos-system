import 'package:flutter/material.dart';

import '../enums/enum_main_menu.dart';
import '../enums/enum_permission.dart';

class ModelDrawerMenu {
  final EnumMainMenu menu;
  final String titleKey;
  final IconData icon;
  final List<EnumPermission> permissions;
  final List<ModelDrawerMenu>? children;

  ModelDrawerMenu({
    required this.menu,
    required this.titleKey,
    required this.icon,
    required this.permissions,
    this.children,
  });
}
