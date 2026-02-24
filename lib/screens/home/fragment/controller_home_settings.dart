import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../service/service_storage.dart';

class ControllerHomeSettings extends GetxController {
  final ServiceStorage _storage = Get.find<ServiceStorage>();

  final rxStoreName = ''.obs;
  final rxStoreAddress = ''.obs;
  final rxStorePhone = ''.obs;
  final rxStoreEmail = ''.obs;
  final rxStoreGstin = ''.obs;

  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final storePhoneController = TextEditingController();
  final storeEmailController = TextEditingController();
  final storeGstinController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadStoreDetails();
  }

  void _loadStoreDetails() {
    rxStoreName.value = _storage.readString('store_name') ?? 'Super Market';
    rxStoreAddress.value =
        _storage.readString('store_address') ?? '123 Market St, City';
    rxStorePhone.value = _storage.readString('store_phone') ?? '+91 9876543210';
    rxStoreEmail.value =
        _storage.readString('store_email') ?? 'contact@supermarket.com';
    rxStoreGstin.value = _storage.readString('store_gstin') ?? '';

    storeNameController.text = rxStoreName.value;
    storeAddressController.text = rxStoreAddress.value;
    storePhoneController.text = rxStorePhone.value;
    storeEmailController.text = rxStoreEmail.value;
    storeGstinController.text = rxStoreGstin.value;
  }

  Future<void> saveStoreDetails() async {
    rxStoreName.value = storeNameController.text;
    rxStoreAddress.value = storeAddressController.text;
    rxStorePhone.value = storePhoneController.text;
    rxStoreEmail.value = storeEmailController.text;
    rxStoreGstin.value = storeGstinController.text;

    await _storage.writeString('store_name', rxStoreName.value);
    await _storage.writeString('store_address', rxStoreAddress.value);
    await _storage.writeString('store_phone', rxStorePhone.value);
    await _storage.writeString('store_email', rxStoreEmail.value);
    await _storage.writeString('store_gstin', rxStoreGstin.value);

    Get.snackbar(
      'Success',
      'Store details updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    storeNameController.dispose();
    storeAddressController.dispose();
    storePhoneController.dispose();
    storeEmailController.dispose();
    storeGstinController.dispose();
    super.onClose();
  }
}
