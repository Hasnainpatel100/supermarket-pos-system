import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../service/service_storage.dart';
import '../../../../service/service_whatsapp.dart';

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
  final rxIsTestingWhatsApp = false.obs;
  final rxWhatsAppTestResult = ''.obs;
  final rxWhatsAppTestSuccess = false.obs;

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

  /// Whether to show tax rate next to each item in the receipt item list (default: false, clean restaurant style)
  final rxShowTaxInItemList = false.obs;

  /// Whether to show the GST Breakup table (Taxable, CGST, SGST, CESS, Total) at the bottom of the bill
  final rxShowGstBreakup = true.obs;

  /// Whether to show the Code128 barcode of Bill No at the bottom of the bill
  final rxShowBillBarcode = true.obs;

  /// Custom bill return policy / terms & conditions text
  final rxBillTerms = 'Goods once sold can be exchanged within 7 days with bill'.obs;
  final billTermsController = TextEditingController();

  /// Custom bill footer tagline
  final rxBillFooterTagline = 'Thank You! Visit Again'.obs;
  final billFooterTaglineController = TextEditingController();

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

  Future<void> testWhatsAppCredentials() async {
    final token = whatsAppTokenController.text.trim();
    final phoneId = whatsAppPhoneIdController.text.trim();

    if (token.isEmpty || phoneId.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter both Phone Number ID and Access Token to test.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    rxIsTestingWhatsApp.value = true;
    rxWhatsAppTestResult.value = '';
    rxWhatsAppTestSuccess.value = false;

    try {
      final res = await ServiceWhatsApp.testConnection(
        accessToken: token,
        phoneNumberId: phoneId,
      );
      final phone = res['display_phone_number'] ?? phoneId;
      final name = res['verified_name'] ?? 'Verified';
      rxWhatsAppTestSuccess.value = true;
      rxWhatsAppTestResult.value = 'Connected successfully! Verified Name: $name ($phone)';
      Get.snackbar(
        'Connected',
        'WhatsApp Cloud API is active ($phone)',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      rxWhatsAppTestSuccess.value = false;
      rxWhatsAppTestResult.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Connection Failed',
        rxWhatsAppTestResult.value,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      rxIsTestingWhatsApp.value = false;
    }
  }

  Future<void> clearWhatsAppCredentials() async {
    whatsAppTokenController.clear();
    whatsAppPhoneIdController.clear();
    rxWhatsAppToken.value = '';
    rxWhatsAppPhoneId.value = '';
    rxWhatsAppTestResult.value = '';
    rxWhatsAppTestSuccess.value = false;
    await _storage.writeString('wa_token', '');
    await _storage.writeString('wa_phone_id', '');
    Get.snackbar(
      'Cleared',
      'WhatsApp API credentials removed',
      backgroundColor: Colors.orange.shade800,
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
    rxShowTaxInItemList.value     = _storage.readBool('printer_show_tax_in_item_list') ?? false;
    rxShowGstBreakup.value        = _storage.readBool('printer_show_gst_breakup') ?? true;
    rxShowBillBarcode.value       = _storage.readBool('printer_show_bill_barcode') ?? true;
    rxBillTerms.value             = _storage.readString('printer_bill_terms') ?? 'Goods once sold can be exchanged within 7 days with bill';
    billTermsController.text      = rxBillTerms.value;
    rxBillFooterTagline.value     = _storage.readString('printer_bill_footer_tagline') ?? 'Thank You! Visit Again';
    billFooterTaglineController.text = rxBillFooterTagline.value;

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
    await _storage.writeBool('printer_show_tax_in_item_list', rxShowTaxInItemList.value);
    await _storage.writeBool('printer_show_gst_breakup',     rxShowGstBreakup.value);
    await _storage.writeBool('printer_show_bill_barcode',    rxShowBillBarcode.value);
    await _storage.writeString('printer_bill_terms',         rxBillTerms.value);
    await _storage.writeString('printer_bill_footer_tagline', rxBillFooterTagline.value);

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

  /// Saves Bill & Receipt Preview settings (GST breakdown, barcode, terms, taglines)
  Future<void> saveBillSettings() async {
    rxBillTerms.value = billTermsController.text.trim();
    rxBillFooterTagline.value = billFooterTaglineController.text.trim();

    await _storage.writeBool('printer_show_gst_breakup',     rxShowGstBreakup.value);
    await _storage.writeBool('printer_show_bill_barcode',    rxShowBillBarcode.value);
    await _storage.writeBool('printer_show_tax_in_item_list', rxShowTaxInItemList.value);
    await _storage.writeBool('printer_auto_print_bill',      rxAutoPrintBill.value);
    await _storage.writeString('printer_thermal_paper_size', rxThermalPaperSize.value);
    await _storage.writeString('printer_bill_terms',         rxBillTerms.value);
    await _storage.writeString('printer_bill_footer_tagline', rxBillFooterTagline.value);

    Get.snackbar(
      'Saved',
      'Bill & receipt preview settings saved successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// Generates a realistic sample bill with inclusive & exclusive items for preview
  EntityBill createSampleBill() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final bill = EntityBill(
      id: 999,
      billNo: 'BIL-1792831688290',
      customerName: 'Hasnain',
      customerPhone: '',
      createdAtUtcMs: nowMs,
      status: 'PAID',
      paymentMode: 'CASH',
      totalAmount: 75120.0,
      tax: 3756.0,
      discount: 0.0,
      grandTotal: 78876.0,
      amountReceived: 78876.0,
      changeReturned: 0.0,
    );

    final item1 = EntityBillItem(
      id: 1,
      itemName: 'iPhone 17',
      price: 75000.0,
      qty: 1,
      taxRate: 5.0,
      total: 75000.0,
    );

    final item2 = EntityBillItem(
      id: 2,
      itemName: 'Odonil [B: 1]',
      price: 120.0,
      qty: 1,
      taxRate: 5.0,
      total: 120.0,
    );

    bill.items.addAll([item1, item2]);
    return bill;
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
    billTermsController.dispose();
    billFooterTaglineController.dispose();
    super.onClose();
  }
}
