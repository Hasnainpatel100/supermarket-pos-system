import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../service/service_storage.dart';

class ControllerHomeSettings extends GetxController {
  final ServiceStorage _storage = Get.find<ServiceStorage>();
  final formKey = GlobalKey<FormState>();

  // ─── Store Info ───────────────────────────────────────────────────────────
  final rxStoreName    = ''.obs;
  final rxStoreAddress = ''.obs;
  final rxStorePhone   = ''.obs;
  final rxStoreEmail   = ''.obs;
  final rxStoreGstin   = ''.obs;
  final rxStoreUpiId   = 'patelhusnain02-1@oksbi'.obs;
  final rxStoreAlternateUpiId = ''.obs;

  // WhatsApp Cloud API credentials
  final rxWhatsAppToken   = ''.obs;
  final rxWhatsAppPhoneId = ''.obs;

  final storeNameController    = TextEditingController();
  final storeAddressController = TextEditingController();
  final storePhoneController   = TextEditingController();
  final storeEmailController   = TextEditingController();
  final storeGstinController   = TextEditingController();
  final storeUpiIdController   = TextEditingController();
  final storeAlternateUpiIdController = TextEditingController();
  final whatsAppTokenController   = TextEditingController();
  final whatsAppPhoneIdController = TextEditingController();

  // ─── Thermal Receipt Printer Settings (POS Billing) ──────────────────────
  /// Dedicated printer for POS Customer Receipts ('' = system default)
  final rxDefaultThermalPrinter = ''.obs;

  /// Default thermal paper width: '80mm' | '58mm' | 'A4'
  final rxThermalPaperSize = '80mm'.obs;

  /// Whether to auto-print receipt upon bill settlement
  final rxAutoPrintBill = false.obs;

  /// Whether to announce payment aloud like a soundbox upon bill settlement
  final rxVoiceAnnouncement = true.obs;

  // ─── Barcode & Label Printer Settings (Product Labels) ────────────────────

  /// List of printer names fetched from the OS
  final rxAvailablePrinters = <String>[].obs;

  /// Currently selected default barcode printer name ('' = system default)
  final rxDefaultPrinter = ''.obs;

  /// '1D' = Code128 barcode | '2D' = QR code
  final rxBarcodeType = '1D'.obs;

  /// '58mm' | '80mm' | 'A4' | 'custom' (for barcode labels)
  final rxPaperSize = '58mm'.obs;

  final rxShowName  = true.obs;
  final rxShowPrice = false.obs;

  /// Additional text line printed below the barcode
  final rxExtraInfo = ''.obs;

  final extraInfoController = TextEditingController();

  /// A4 layout settings (only used when paper size is 'A4')
  final rxA4Columns = 3.obs; // barcodes per line
  final rxA4Rows = 8.obs;    // lines per page

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

    final savedUpi = _storage.readString('store_upi_id');
    rxStoreUpiId.value = (savedUpi != null && savedUpi.trim().isNotEmpty)
        ? savedUpi.trim()
        : 'patelhusnain02-1@oksbi';

    rxStoreAlternateUpiId.value = _storage.readString('store_alternate_upi_id') ?? '';
    rxWhatsAppToken.value   = _storage.readString('wa_token')    ?? '';
    rxWhatsAppPhoneId.value = _storage.readString('wa_phone_id') ?? '';

    storeNameController.text           = rxStoreName.value;
    storeAddressController.text        = rxStoreAddress.value;
    storePhoneController.text          = rxStorePhone.value;
    storeEmailController.text          = rxStoreEmail.value;
    storeGstinController.text          = rxStoreGstin.value;
    storeUpiIdController.text          = rxStoreUpiId.value;
    storeAlternateUpiIdController.text = rxStoreAlternateUpiId.value;
    whatsAppTokenController.text       = rxWhatsAppToken.value;
    whatsAppPhoneIdController.text     = rxWhatsAppPhoneId.value;
  }

  Future<void> saveStoreDetails() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar(
        'Validation Error',
        'Please correct the store details errors',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    rxStoreName.value    = storeNameController.text.trim();
    rxStoreAddress.value = storeAddressController.text.trim();
    rxStorePhone.value   = storePhoneController.text.trim();
    rxStoreEmail.value   = storeEmailController.text.trim();
    rxStoreGstin.value   = storeGstinController.text.trim();

    final enteredUpi = storeUpiIdController.text.trim();
    rxStoreUpiId.value = enteredUpi.isNotEmpty ? enteredUpi : 'patelhusnain02-1@oksbi';
    rxStoreAlternateUpiId.value = storeAlternateUpiIdController.text.trim();

    await _storage.writeString('store_name',             rxStoreName.value);
    await _storage.writeString('store_address',          rxStoreAddress.value);
    await _storage.writeString('store_phone',            rxStorePhone.value);
    await _storage.writeString('store_email',            rxStoreEmail.value);
    await _storage.writeString('store_gstin',            rxStoreGstin.value);
    await _storage.writeString('store_upi_id',           rxStoreUpiId.value);
    await _storage.writeString('store_alternate_upi_id', rxStoreAlternateUpiId.value);

    Get.snackbar(
      'Success',
      'Store & UPI payment details updated successfully',
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
    // Thermal Receipt Printer Settings
    rxDefaultThermalPrinter.value = _storage.readString('printer_thermal_default') ?? '';
    rxThermalPaperSize.value      = _storage.readString('printer_thermal_paper_size') ?? '80mm';
    rxAutoPrintBill.value         = _storage.readBool('printer_auto_print_bill') ?? false;
    rxVoiceAnnouncement.value     = _storage.readBool('pos_voice_announcement') ?? true;

    // Barcode & Label Printer Settings
    rxDefaultPrinter.value = _storage.readString('printer_default') ?? '';
    rxBarcodeType.value    = _storage.readString('printer_barcode_type') ?? '1D';
    rxPaperSize.value      = _storage.readString('printer_paper_size')   ?? '58mm';
    rxShowName.value       = _storage.readBool('printer_show_name')  ?? true;
    rxShowPrice.value      = _storage.readBool('printer_show_price') ?? false;
    rxExtraInfo.value      = _storage.readString('printer_extra_info') ?? '';
    extraInfoController.text = rxExtraInfo.value;
    rxA4Columns.value      = _storage.readInt('printer_a4_columns')    ?? 3;
    rxA4Rows.value         = _storage.readInt('printer_a4_rows')       ?? 8;
  }

  /// Fetches available printers from the OS using the `printing` package.
  Future<void> fetchPrinters() async {
    rxFetchingPrinters.value = true;
    try {
      final printers = await Printing.listPrinters();
      final names = printers.map((p) => p.name).toList();
      rxAvailablePrinters.assignAll(names);

      // If saved thermal printer is no longer available, clear it
      if (rxDefaultThermalPrinter.value.isNotEmpty &&
          !names.contains(rxDefaultThermalPrinter.value)) {
        rxDefaultThermalPrinter.value = '';
      }

      // If saved barcode printer is no longer available, clear it
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

    // Save Thermal Receipt Printer Settings
    await _storage.writeString('printer_thermal_default',    rxDefaultThermalPrinter.value);
    await _storage.writeString('printer_thermal_paper_size', rxThermalPaperSize.value);
    await _storage.writeBool('printer_auto_print_bill',      rxAutoPrintBill.value);
    await _storage.writeBool('pos_voice_announcement',       rxVoiceAnnouncement.value);

    // Save Barcode Label Printer Settings
    await _storage.writeString('printer_default',      rxDefaultPrinter.value);
    await _storage.writeString('printer_barcode_type', rxBarcodeType.value);
    await _storage.writeString('printer_paper_size',   rxPaperSize.value);
    await _storage.writeBool('printer_show_name',      rxShowName.value);
    await _storage.writeBool('printer_show_price',     rxShowPrice.value);
    await _storage.writeString('printer_extra_info',   rxExtraInfo.value);
    await _storage.writeInt('printer_a4_columns',      rxA4Columns.value);
    await _storage.writeInt('printer_a4_rows',         rxA4Rows.value);

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
    storeUpiIdController.dispose();
    storeAlternateUpiIdController.dispose();
    whatsAppTokenController.dispose();
    whatsAppPhoneIdController.dispose();
    extraInfoController.dispose();
    super.onClose();
  }
}
