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

  // WhatsApp Cloud API credentials
  final rxWhatsAppToken = ''.obs;
  final rxWhatsAppPhoneId = ''.obs;

  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final storePhoneController = TextEditingController();
  final storeEmailController = TextEditingController();
  final storeGstinController = TextEditingController();

  final whatsAppTokenController = TextEditingController();
  final whatsAppPhoneIdController = TextEditingController();

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
    rxWhatsAppToken.value = _storage.readString('wa_token') ?? '';
    rxWhatsAppPhoneId.value = _storage.readString('wa_phone_id') ?? '';

    storeNameController.text = rxStoreName.value;
    storeAddressController.text = rxStoreAddress.value;
    storePhoneController.text = rxStorePhone.value;
    storeEmailController.text = rxStoreEmail.value;
    storeGstinController.text = rxStoreGstin.value;
    whatsAppTokenController.text = rxWhatsAppToken.value;
    whatsAppPhoneIdController.text = rxWhatsAppPhoneId.value;
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

  Future<void> saveWhatsAppCredentials() async {
    rxWhatsAppToken.value = whatsAppTokenController.text.trim();
    rxWhatsAppPhoneId.value = whatsAppPhoneIdController.text.trim();

    await _storage.writeString('wa_token', rxWhatsAppToken.value);
    await _storage.writeString('wa_phone_id', rxWhatsAppPhoneId.value);

    Get.snackbar(
      'Saved',
      'WhatsApp API credentials saved',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  bool get hasWhatsAppCredentials =>
      rxWhatsAppToken.value.isNotEmpty && rxWhatsAppPhoneId.value.isNotEmpty;

  @override
  void onClose() {
    storeNameController.dispose();
    storeAddressController.dispose();
    storePhoneController.dispose();
    storeEmailController.dispose();
    storeGstinController.dispose();
    whatsAppTokenController.dispose();
    whatsAppPhoneIdController.dispose();
    super.onClose();
  }
}
