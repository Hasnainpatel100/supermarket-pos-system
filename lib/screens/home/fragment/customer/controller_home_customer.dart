import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../model/entity_customer.dart';
import '../../../../service/service_object_box.dart';
import '../../../../objectbox.g.dart';

class ControllerHomeCustomer extends GetxController {
  late Box<EntityCustomer> _boxCustomer;
  final RxList<EntityCustomer> rxListCustomer = <EntityCustomer>[].obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _boxCustomer = Get.find<ServiceObjectBox>().box<EntityCustomer>();
    loadCustomers();
  }

  void loadCustomers() {
    final query = _boxCustomer.query(
      EntityCustomer_.name
          .contains(searchQuery.value, caseSensitive: false)
          .or(EntityCustomer_.phone.contains(searchQuery.value)),
    )..order(EntityCustomer_.name);

    rxListCustomer.assignAll(query.build().find());
  }

  void updateSearch(String val) {
    searchQuery.value = val;
    loadCustomers();
  }

  void clearSearch() {
    searchController.clear();
    updateSearch('');
  }

  void toggleActive(EntityCustomer customer) {
    customer.isActive = !(customer.isActive ?? true);
    customer.updatedAtUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    _boxCustomer.put(customer);
    loadCustomers();
  }
}
