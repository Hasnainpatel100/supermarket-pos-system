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

  final searchController = TextEditingController();
  final rxSearchQuery = ''.obs;

  // Pagination
  final int pageSize = 10;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * pageSize < totalCount.value;

  @override
  void onInit() {
    final ob = Get.find<ServiceObjectBox>();
    _boxUser = ob.box<EntityUser>();

    // Debounce search
    debounce(
      rxSearchQuery,
      (_) {
        currentPage.value = 0;
        loadUsers();
      },
      time: const Duration(milliseconds: 300),
    );

    loadUsers();
    super.onInit();
  }

  void loadUsers() async {
    final query = _boxUser
        .query(
          EntityUser_.username
              .contains(rxSearchQuery.value, caseSensitive: false)
              .or(
                EntityUser_.first.contains(
                  rxSearchQuery.value,
                  caseSensitive: false,
                ),
              )
              .or(
                EntityUser_.last.contains(
                  rxSearchQuery.value,
                  caseSensitive: false,
                ),
              ),
        )
        .order(EntityUser_.username)
        .build();

    totalCount.value = query.count();
    
    final offset = currentPage.value * pageSize;
    rxListUser.assignAll(query.find()
        .skip(offset)
        .take(pageSize)
        .toList());
    
    query.close();
  }

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      loadUsers();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      loadUsers();
    }
  }

  void clearSearch() {
    searchController.clear();
    rxSearchQuery.value = '';
  }

  void saveUser(EntityUser user) {
    _boxUser.put(user); // Save into ObjectBox
    loadUsers(); // Refresh the UI list
  }

  void toggleActive(EntityUser user) {
    user.isActive = !(user.isActive ?? true);
    _boxUser.put(user);
    loadUsers();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
