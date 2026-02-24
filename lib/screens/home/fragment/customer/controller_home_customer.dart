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

    // Debounce search — waits 300ms after last keystroke before querying
    debounce(
      searchQuery,
      (_) => loadCustomers(),
      time: const Duration(milliseconds: 300),
    );
  }

  void loadCustomers() {
    final query = _boxCustomer.query(
      EntityCustomer_.name
          .contains(searchQuery.value, caseSensitive: false)
          .or(EntityCustomer_.phone.contains(searchQuery.value)),
    )..order(EntityCustomer_.name);

    rxListCustomer.assignAll(query.build().find());
  }

  /// Called from TextField onChanged — only updates the observable,
  /// debounce handles calling loadCustomers after 300ms
  void updateSearch(String val) {
    searchQuery.value = val;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadCustomers(); // immediate clear
  }

  void toggleActive(EntityCustomer customer) {
    customer.isActive = !(customer.isActive ?? true);
    customer.updatedAtUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    _boxCustomer.put(customer);
    loadCustomers();
  }

  void deleteCustomer(EntityCustomer customer) {
    final id = customer.id;
    if (id != null && id != 0) {
      _boxCustomer.remove(id);
      loadCustomers();
    }
  }
}
