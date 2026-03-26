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

  // ── Pagination ──
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      loadCustomers();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      loadCustomers();
    }
  }

  @override
  void onInit() {
    super.onInit();
    _boxCustomer = Get.find<ServiceObjectBox>().box<EntityCustomer>();
    loadCustomers();

    // Debounce search — waits 300ms after last keystroke before querying
    debounce(
      searchQuery,
      (_) {
        currentPage.value = 0;
        loadCustomers();
      },
      time: const Duration(milliseconds: 300),
    );
  }

  void loadCustomers() {
    final queryBuilder = _boxCustomer.query(
      EntityCustomer_.name
          .contains(searchQuery.value, caseSensitive: false)
          .or(EntityCustomer_.phone.contains(searchQuery.value)),
    )..order(EntityCustomer_.name);

    final query = queryBuilder.build();
    totalCount.value = query.count();
    
    query
      ..offset = currentPage.value * _pageSize
      ..limit = _pageSize;

    rxListCustomer.assignAll(query.find());
    query.close();
  }

  /// Called from TextField onChanged — only updates the observable,
  /// debounce handles calling loadCustomers after 300ms
  void updateSearch(String val) {
    searchQuery.value = val;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 0;
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
