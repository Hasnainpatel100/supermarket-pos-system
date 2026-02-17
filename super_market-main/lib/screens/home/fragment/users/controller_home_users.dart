import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/entity_user.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

class ControllerHomeUsers extends GetxController {
  final EntityUser? entityUser;

  ControllerHomeUsers({this.entityUser});

  late Box<EntityUser> _boxUser;
  final RxList<EntityUser> rxListUser = <EntityUser>[].obs;

  @override
  void onInit() {
    final ob = Get.find<ServiceObjectBox>();
    _boxUser = ob.box<EntityUser>();
    loadUsers();
    super.onInit();
  }

  void loadUsers() async {
    var list = _boxUser.getAll();
    debugPrint("loadUsers size: ${list.length}");
    rxListUser.value = list;
  }
  void saveUser(EntityUser user) {
    _boxUser.put(user);       // Save into ObjectBox
    loadUsers();             // Refresh the UI list
  }


  void toggleActive(EntityUser user) {
    user.isActive = !(user.isActive ?? true);
    _boxUser.put(user);
    loadUsers();
  }
}
