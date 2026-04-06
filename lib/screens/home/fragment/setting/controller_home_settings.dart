import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../service/service_storage.dart';

class ControllerHomeSettings extends GetxController {
  final ServiceStorage _storage = Get.find<ServiceStorage>();

  // ─── Store Info ───────────────────────────────────────────────────────────
  final rxStoreName    = ''.obs;
  final rxStoreAddress = ''.obs;
  final rxStorePhone   = ''.obs;
  final rxStoreEmail   = ''.obs;
  final rxStoreGstin   = ''.obs;

  // WhatsApp Cloud API credentials
  final rxWhatsAppToken   = ''.obs;
  final rxWhatsAppPhoneId = ''.obs;

  final storeNameController    = TextEditingController();
  final storeAddressController = TextEditingController();
  final storePhoneController   = TextEditingController();
  final storeEmailController   = TextEditingController();
  final storeGstinController   = TextEditingController();
  final whatsAppTokenController   = TextEditingController();
  final whatsAppPhoneIdController = TextEditingController();

  // ─── Printer / Barcode Settings ──────────────────────────────────────────

  /// List of printer names fetched from the OS
  final rxAvailablePrinters = <String>[].obs;

  /// Currently selected default printer name ('' = system default)
  final rxDefaultPrinter = ''.obs;

  /// '1D' = Code128 barcode | '2D' = QR code
  final rxBarcodeType = '1D'.obs;

  /// '58mm' | '80mm' | 'A4' | 'custom'
  final rxPaperSize = '58mm'.obs;

  final rxShowName  = true.obs;
  final rxShowPrice = false.obs;

  /// Additional text line printed below the barcode
  final rxExtraInfo = ''.obs;

  final extraInfoController = TextEditingController();

  /// Whether a printer fetch is in progress
  final rxFetchingPrinters = false.obs;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadStoreDetails();
    _loadPrinterSettings();
    fetchPrinters();
  }

  // ── Store Details ─────────────────────────────────────────────────────────

  void _loadStoreDetails() {
    rxStoreName.value    = _storage.readString('store_name')    ?? 'Super Market';
    rxStoreAddress.value = _storage.readString('store_address') ?? '123 Market St, City';
    rxStorePhone.value   = _storage.readString('store_phone')   ?? '+91 9876543210';
    rxStoreEmail.value   = _storage.readString('store_email')   ?? 'contact@supermarket.com';
    rxStoreGstin.value   = _storage.readString('store_gstin')   ?? '';
    rxWhatsAppToken.value   = _storage.readString('wa_token')    ?? '';
    rxWhatsAppPhoneId.value = _storage.readString('wa_phone_id') ?? '';

    storeNameController.text    = rxStoreName.value;
    storeAddressController.text = rxStoreAddress.value;
    storePhoneController.text   = rxStorePhone.value;
    storeEmailController.text   = rxStoreEmail.value;
    storeGstinController.text   = rxStoreGstin.value;
    whatsAppTokenController.text   = rxWhatsAppToken.value;
    whatsAppPhoneIdController.text = rxWhatsAppPhoneId.value;
  }

  Future<void> saveStoreDetails() async {
    rxStoreName.value    = storeNameController.text;
    rxStoreAddress.value = storeAddressController.text;
    rxStorePhone.value   = storePhoneController.text;
    rxStoreEmail.value   = storeEmailController.text;
    rxStoreGstin.value   = storeGstinController.text;

    await _storage.writeString('store_name',    rxStoreName.value);
    await _storage.writeString('store_address', rxStoreAddress.value);
    await _storage.writeString('store_phone',   rxStorePhone.value);
    await _storage.writeString('store_email',   rxStoreEmail.value);
    await _storage.writeString('store_gstin',   rxStoreGstin.value);

    Get.snackbar(
      'Success',
      'Store details updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> saveWhatsAppCredentials() async {
    rxWhatsAppToken.value   = whatsAppTokenController.text.trim();
    rxWhatsAppPhoneId.value = whatsAppPhoneIdController.text.trim();

    await _storage.writeString('wa_token',    rxWhatsAppToken.value);
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

  // ── Printer Settings ──────────────────────────────────────────────────────

  void _loadPrinterSettings() {
    rxDefaultPrinter.value = _storage.readString('printer_default') ?? '';
    rxBarcodeType.value    = _storage.readString('printer_barcode_type') ?? '1D';
    rxPaperSize.value      = _storage.readString('printer_paper_size')   ?? '58mm';
    rxShowName.value       = _storage.readBool('printer_show_name')  ?? true;
    rxShowPrice.value      = _storage.readBool('printer_show_price') ?? false;
    rxExtraInfo.value      = _storage.readString('printer_extra_info') ?? '';
    extraInfoController.text = rxExtraInfo.value;
  }

  /// Fetches available printers from the OS using the `printing` package.
  Future<void> fetchPrinters() async {
    rxFetchingPrinters.value = true;
    try {
      final printers = await Printing.listPrinters();
      final names = printers.map((p) => p.name).toList();
      rxAvailablePrinters.assignAll(names);

      // If the saved printer is no longer available, clear it
      if (rxDefaultPrinter.value.isNotEmpty &&
          !names.contains(rxDefaultPrinter.value)) {
        rxDefaultPrinter.value = '';
      }
    } catch (_) {
      // If listing fails (e.g., unsupported platform), keep the list empty
      rxAvailablePrinters.clear();
    } finally {
      rxFetchingPrinters.value = false;
    }
  }

  Future<void> savePrinterSettings() async {
    rxExtraInfo.value = extraInfoController.text.trim();

    await _storage.writeString('printer_default',      rxDefaultPrinter.value);
    await _storage.writeString('printer_barcode_type', rxBarcodeType.value);
    await _storage.writeString('printer_paper_size',   rxPaperSize.value);
    await _storage.writeBool('printer_show_name',      rxShowName.value);
    await _storage.writeBool('printer_show_price',     rxShowPrice.value);
    await _storage.writeString('printer_extra_info',   rxExtraInfo.value);

    Get.snackbar(
      'Saved',
      'Printer settings saved successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    storeNameController.dispose();
    storeAddressController.dispose();
    storePhoneController.dispose();
    storeEmailController.dispose();
    storeGstinController.dispose();
    whatsAppTokenController.dispose();
    whatsAppPhoneIdController.dispose();
    extraInfoController.dispose();
    super.onClose();
  }
}
