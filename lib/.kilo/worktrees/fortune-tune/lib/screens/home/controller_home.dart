import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../enums/enum_main_menu.dart';
import '../../enums/enum_permission.dart';
import '../../model/entity_user.dart';
import '../../repository/repo_storage.dart';

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
    var mapUser = json.decode(strUser);
    EntityUser entityUser = EntityUser.fromMap(mapUser);
    rxUser.value = entityUser;
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
