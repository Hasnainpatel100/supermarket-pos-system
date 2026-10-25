import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../model/entity_customer.dart';
import '../../../../service/service_object_box.dart';
import '../../../../objectbox.g.dart';
import '../pos/controller_home_pos.dart';

class ControllerHomeCustomer extends GetxController {
  late Box<EntityCustomer> _boxCustomer;
  final RxList<EntityCustomer> rxListCustomer = <EntityCustomer>[].obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // ── Pagination ──
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  // ── Inline Customer Create/Edit Form State ──
  final RxBool rxShowCreateForm = false.obs;
  final RxBool rxIsSaving = false.obs;
  final Rx<EntityCustomer?> rxEditingCustomer = Rx<EntityCustomer?>(null);
  final GlobalKey<FormState> createFormKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final RxBool rxIsVip = false.obs;

  bool get isEditing => rxEditingCustomer.value != null;
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

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipController.dispose();
    notesController.dispose();
    super.onClose();
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

  void resetSearch() {
    if (searchQuery.value.isNotEmpty || searchController.text.isNotEmpty) {
      clearSearch();
    }
  }

  // ── Inline Form Actions ──
  void openCreateForm([EntityCustomer? customer]) {
    rxEditingCustomer.value = customer;
    if (customer != null) {
      nameController.text = customer.name ?? '';
      phoneController.text = customer.phone ?? '';
      emailController.text = customer.email ?? '';
      addressController.text = customer.address ?? '';
      cityController.text = customer.city ?? '';
      stateController.text = customer.state ?? '';
      zipController.text = customer.zipCode ?? '';
      notesController.text = customer.notes ?? '';
      rxIsVip.value = customer.isVip ?? false;
    } else {
      clearCreateForm();
    }
    rxShowCreateForm.value = true;
  }

  void closeCreateForm() {
    rxShowCreateForm.value = false;
    rxEditingCustomer.value = null;
    clearCreateForm();
  }

  void toggleCreateForm() {
    if (rxShowCreateForm.value) {
      closeCreateForm();
    } else {
      openCreateForm();
    }
  }

  void clearCreateForm() {
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    zipController.clear();
    notesController.clear();
    rxIsVip.value = false;
  }

  Future<void> saveCustomerFromForm() async {
    if (!(createFormKey.currentState?.validate() ?? false)) {
      Get.snackbar(
        'Required',
        'Please enter the customer name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.15),
        colorText: Colors.red.shade700,
      );
      return;
    }

    final phone = phoneController.text.trim();
    if (phone.isNotEmpty && phone.length != 10) {
      Get.snackbar(
        'Invalid Phone',
        'Phone number must be exactly 10 digits',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.15),
        colorText: Colors.red.shade700,
      );
      return;
    }

    final email = emailController.text.trim();
    if (email.isNotEmpty && !email.endsWith('@gmail.com')) {
      Get.snackbar(
        'Invalid Email',
        'Email must end with @gmail.com',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.15),
        colorText: Colors.red.shade700,
      );
      return;
    }

    rxIsSaving.value = true;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final customer = rxEditingCustomer.value ??
        EntityCustomer(isActive: true, createdAtUtcMs: now);

    customer.name = nameController.text.trim();
    customer.phone = phoneController.text.trim();
    customer.email = emailController.text.trim();
    customer.address = addressController.text.trim();
    customer.city = cityController.text.trim();
    customer.state = stateController.text.trim();
    customer.zipCode = zipController.text.trim();
    customer.notes = notesController.text.trim();
    customer.isVip = rxIsVip.value;
    customer.updatedAtUtcMs = now;

    try {
      _boxCustomer.put(customer);
      loadCustomers();

      // Refresh POS customer list if registered
      if (Get.isRegistered<ControllerHomePos>()) {
        Get.find<ControllerHomePos>().loadCustomers();
      }

      final isEdit = rxEditingCustomer.value != null;
      closeCreateForm();

      Get.snackbar(
        'Success',
        'Customer ${isEdit ? 'updated' : 'added'} successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.15),
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save customer: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.15),
        colorText: Colors.red.shade700,
      );
    } finally {
      rxIsSaving.value = false;
    }
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
