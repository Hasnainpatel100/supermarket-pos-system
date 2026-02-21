import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_customer.dart';
import '../../objectbox.g.dart';
import '../../service/service_object_box.dart';

class ControllerCustomerForm extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController zipController;
  late TextEditingController notesController;

  final EntityCustomer? editingCustomer;
  late Box<EntityCustomer> _boxCustomer;

  ControllerCustomerForm({this.editingCustomer});

  @override
  void onInit() {
    super.onInit();
    _boxCustomer = Get.find<ServiceObjectBox>().box<EntityCustomer>();

    // Initialize controllers with existing data or empty
    nameController = TextEditingController(text: editingCustomer?.name ?? '');
    phoneController = TextEditingController(text: editingCustomer?.phone ?? '');
    emailController = TextEditingController(text: editingCustomer?.email ?? '');
    addressController = TextEditingController(
      text: editingCustomer?.address ?? '',
    );
    cityController = TextEditingController(text: editingCustomer?.city ?? '');
    stateController = TextEditingController(text: editingCustomer?.state ?? '');
    zipController = TextEditingController(text: editingCustomer?.zipCode ?? '');
    notesController = TextEditingController(text: editingCustomer?.notes ?? '');
  }

  @override
  void onClose() {
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

  void saveCustomer() {
    if (!formKey.currentState!.validate()) {
      Get.snackbar(
        "Required",
        "Please fill the required fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    final phone = phoneController.text.trim();
    if (phone.isNotEmpty && phone.length != 10) {
      Get.snackbar(
        "Invalid Phone",
        "Phone number must be exactly 10 digits",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    final email = emailController.text.trim();
    if (email.isNotEmpty && !email.endsWith("@gmail.com")) {
      Get.snackbar(
        "Invalid Email",
        "Email must end with @gmail.com",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final customer =
        editingCustomer ?? EntityCustomer(isActive: true, createdAtUtcMs: now);

    // Update fields
    customer.name = nameController.text.trim();
    customer.phone = phoneController.text.trim();
    customer.email = emailController.text.trim();
    customer.address = addressController.text.trim();
    customer.city = cityController.text.trim();
    customer.state = stateController.text.trim();
    customer.zipCode = zipController.text.trim();
    customer.notes = notesController.text.trim();
    customer.updatedAtUtcMs = now;

    try {
      _boxCustomer.put(customer);
      Get.back();
      Get.snackbar(
        "Success",
        "Customer ${editingCustomer != null ? 'updated' : 'added'} successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save customer: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }
}
