import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_customer.dart';
import '../../../model/entity_item.dart';
import '../../../model/entity_quotation.dart';
import '../../../model/entity_quotation_item.dart';
import '../../../objectbox.g.dart';
import '../../../service/service_object_box.dart';
import '../invoice/controller_create_sales_invoice.dart';
import '../preview/activity_document_view.dart';
import '../preview/service_gst_pdf.dart';

class ControllerCreateQuotation extends GetxController {
  final EntityQuotation? editingQuotation;

  ControllerCreateQuotation({this.editingQuotation});

  late final Box<EntityQuotation> _boxQuotation;
  late final Box<EntityQuotationItem> _boxQuotationItem;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityCustomer> _boxCustomer;

  final prefixCtrl = TextEditingController(text: 'KI/26-27/');
  final quotationNoCtrl = TextEditingController();
  final quotationDateCtrl = TextEditingController();
  final validDaysCtrl = TextEditingController(text: '30');
  final validityDateCtrl = TextEditingController();
  final poNoCtrl = TextEditingController();
  final ewayBillCtrl = TextEditingController();
  final vehicleNoCtrl = TextEditingController();

  final Rxn<EntityCustomer> rxCustomer = Rxn<EntityCustomer>();
  final customerNameCtrl = TextEditingController();
  final customerPhoneCtrl = TextEditingController();
  final customerAddressCtrl = TextEditingController();
  final customerGstinCtrl = TextEditingController();

  final RxList<InvoiceItemRow> rxRows = <InvoiceItemRow>[].obs;
  final RxList<EntityItem> rxAvailableItems = <EntityItem>[].obs;
  final RxList<EntityCustomer> rxAvailableCustomers = <EntityCustomer>[].obs;

  final notesCtrl = TextEditingController();
  final termsCtrl = TextEditingController(
    text:
        '1. Quotation valid for 30 days from date of issue.\n2. Prices subject to change without prior notice.\n3. Goods once sold will not be taken back.',
  );
  final additionalChargesCtrl = TextEditingController(text: '0');
  final extraDiscountCtrl = TextEditingController(text: '0');

  final RxBool rxAutoRoundOff = false.obs;

  final RxDouble rxSubtotal = 0.0.obs;
  final RxDouble rxTaxableAmount = 0.0.obs;
  final RxDouble rxTaxAmount = 0.0.obs;
  final RxDouble rxTotalDiscount = 0.0.obs;
  final RxDouble rxGrandTotal = 0.0.obs;
  final RxBool isSaving = false.obs;
  int? _savedQuotationId;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxQuotation = ob.box<EntityQuotation>();
    _boxQuotationItem = ob.box<EntityQuotationItem>();
    _boxItem = ob.box<EntityItem>();
    _boxCustomer = ob.box<EntityCustomer>();

    rxAvailableItems.assignAll(_boxItem.getAll());
    rxAvailableCustomers.assignAll(_boxCustomer.getAll());

    final now = DateTime.now();
    final df = DateFormat('dd MMM yyyy');
    quotationDateCtrl.text = df.format(now);
    validityDateCtrl.text = df.format(now.add(const Duration(days: 30)));

    if (editingQuotation != null) {
      _loadExistingQuotation(editingQuotation!);
    } else {
      quotationNoCtrl.text = _generateNextQuotationNo();
      addRow();
    }

    calculateTotals();
  }

  String _generateNextQuotationNo() {
    final all = _boxQuotation.getAll();
    if (all.isEmpty) return '1';

    final prefix = prefixCtrl.text.trim();
    int maxNum = 0;
    for (var q in all) {
      final no = (q.quotationNo ?? '').trim();
      if (no.isEmpty) continue;

      String numPart = no;
      if (prefix.isNotEmpty && numPart.startsWith(prefix)) {
        numPart = numPart.substring(prefix.length);
      }

      final parsed = int.tryParse(numPart);
      if (parsed != null && parsed > maxNum) {
        maxNum = parsed;
      } else {
        final digits = RegExp(r'\d+').allMatches(no);
        if (digits.isNotEmpty) {
          final lastDigit = int.tryParse(digits.last.group(0) ?? '') ?? 0;
          if (lastDigit > maxNum) maxNum = lastDigit;
        }
      }
      if (q.id > maxNum) maxNum = q.id;
    }

    int candidate = maxNum + 1;
    while (true) {
      final testNo = prefix.isNotEmpty ? '$prefix$candidate' : '$candidate';
      final exists = _boxQuotation
          .query(EntityQuotation_.quotationNo.equals(testNo))
          .build()
          .findFirst();
      if (exists == null) {
        return '$candidate';
      }
      candidate++;
    }
  }

  void _loadExistingQuotation(EntityQuotation q) {
    prefixCtrl.text = q.prefix ?? 'KI/26-27/';
    final fullNo = q.quotationNo ?? '${q.id}';
    final pfx = prefixCtrl.text.trim();
    if (pfx.isNotEmpty && fullNo.startsWith(pfx)) {
      quotationNoCtrl.text = fullNo.substring(pfx.length);
    } else {
      quotationNoCtrl.text = fullNo;
    }
    quotationDateCtrl.text = q.quotationDate ?? '';
    validDaysCtrl.text = '${q.validDays ?? 30}';
    validityDateCtrl.text = q.validUntilDate ?? '';
    poNoCtrl.text = q.poNo ?? '';
    ewayBillCtrl.text = q.ewayBillNo ?? '';
    vehicleNoCtrl.text = q.vehicleNo ?? '';

    customerNameCtrl.text = q.customerName ?? '';
    customerPhoneCtrl.text = q.customerPhone ?? '';
    customerAddressCtrl.text = q.customerAddress ?? '';
    customerGstinCtrl.text = q.customerGstin ?? '';

    notesCtrl.text = q.note ?? '';
    if (q.termsConditions != null) termsCtrl.text = q.termsConditions!;
    additionalChargesCtrl.text = '${q.additionalCharges ?? 0}';
    extraDiscountCtrl.text = '${q.discount ?? 0}';

    rxRows.clear();
    for (var item in q.items) {
      final row = InvoiceItemRow();
      row.nameCtrl.text = item.itemName ?? '';
      row.hsnCtrl.text = item.hsnCode ?? '';
      row.mrpCtrl.text = '${item.mrp ?? item.price ?? 0}';
      row.qtyCtrl.text = '${item.qty ?? 1}';
      row.priceCtrl.text = '${item.price ?? 0}';
      row.discountCtrl.text = '${item.discount ?? 0}';
      row.taxRateCtrl.text = '${item.taxRate ?? 0}';
      row.selectedItem = item.item.target;
      row.calculate();
      rxRows.add(row);
    }
    if (rxRows.isEmpty) addRow();
  }

  void selectCustomer(EntityCustomer customer) {
    rxCustomer.value = customer;
    customerNameCtrl.text = customer.name ?? '';
    customerPhoneCtrl.text = customer.phone ?? '';
    customerAddressCtrl.text = [
      customer.address,
      customer.city,
      customer.state,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
    customerGstinCtrl.text = customer.notes ?? '';
  }

  void addRow() {
    rxRows.add(InvoiceItemRow());
    calculateTotals();
  }

  void removeRow(int index) {
    if (rxRows.length > 1) {
      rxRows.removeAt(index);
      calculateTotals();
    }
  }

  void onItemPicked(InvoiceItemRow row, EntityItem item) {
    row.selectedItem = item;
    row.nameCtrl.text = item.name ?? '';
    row.hsnCtrl.text = item.hsnCode ?? '';
    row.mrpCtrl.text = '${item.sellingPrice ?? 0}';
    row.priceCtrl.text = '${item.sellingPrice ?? 0}';
    row.taxRateCtrl.text = '${item.taxRate ?? 0}';
    row.calculate();
    calculateTotals();
  }

  void calculateTotals() {
    double sub = 0.0;
    double tax = 0.0;
    double itemDisc = 0.0;

    for (var row in rxRows) {
      row.calculate();
      final q = int.tryParse(row.qtyCtrl.text) ?? 1;
      final p = double.tryParse(row.priceCtrl.text) ?? 0.0;
      final d = double.tryParse(row.discountCtrl.text) ?? 0.0;

      sub += (q * p);
      itemDisc += d;
      tax += row.lineTaxAmount;
    }

    final extraDisc = double.tryParse(extraDiscountCtrl.text) ?? 0.0;
    final addCharges = double.tryParse(additionalChargesCtrl.text) ?? 0.0;

    final totalDisc = itemDisc + extraDisc;
    final taxable = (sub - totalDisc).clamp(0.0, double.infinity);
    double grand = taxable + tax + addCharges;

    if (rxAutoRoundOff.value) {
      grand = grand.roundToDouble();
    }

    rxSubtotal.value = sub;
    rxTaxableAmount.value = taxable;
    rxTotalDiscount.value = totalDisc;
    rxTaxAmount.value = tax;
    rxGrandTotal.value = grand;
    rxRows.refresh();
  }

  Future<bool> saveQuotation() async {
    if (isSaving.value) return false;

    if (quotationNoCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'Please enter Quotation Number'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    final validRows = rxRows
        .where((r) => r.nameCtrl.text.trim().isNotEmpty)
        .toList();
    if (validRows.isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'Please add at least one item'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    final rawNo = quotationNoCtrl.text.trim();
    final prefix = prefixCtrl.text.trim();
    final finalQuotationNo = (prefix.isNotEmpty && !rawNo.startsWith(prefix))
        ? '$prefix$rawNo'
        : rawNo;

    // Check duplicate quotation number before ObjectBox throws UniqueViolationException
    final targetId = editingQuotation?.id ?? _savedQuotationId ?? 0;
    final existingWithSameNo = _boxQuotation
        .query(EntityQuotation_.quotationNo.equals(finalQuotationNo))
        .build()
        .findFirst();

    if (existingWithSameNo != null && existingWithSameNo.id != targetId) {
      Get.snackbar(
        'Duplicate Quotation Number'.tr,
        'Quotation number "$finalQuotationNo" already exists. Please choose a different number.'
            .tr,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    isSaving.value = true;
    calculateTotals();

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      EntityQuotation quote;
      if (editingQuotation != null) {
        quote = editingQuotation!;
      } else if (_savedQuotationId != null && _savedQuotationId! > 0) {
        quote = _boxQuotation.get(_savedQuotationId!) ?? EntityQuotation();
      } else {
        quote = EntityQuotation();
      }

      quote.prefix = prefix;
      quote.quotationNo = finalQuotationNo;
      quote.quotationDate = quotationDateCtrl.text.trim();
      quote.validDays = int.tryParse(validDaysCtrl.text) ?? 30;
      quote.validUntilDate = validityDateCtrl.text.trim();
      quote.poNo = poNoCtrl.text.trim();
      quote.ewayBillNo = ewayBillCtrl.text.trim();
      quote.vehicleNo = vehicleNoCtrl.text.trim();

      quote.customerName = customerNameCtrl.text.trim().isEmpty
          ? 'Cash Sale'
          : customerNameCtrl.text.trim();
      quote.customerPhone = customerPhoneCtrl.text.trim();
      quote.customerAddress = customerAddressCtrl.text.trim();
      quote.customerGstin = customerGstinCtrl.text.trim();

      quote.subtotal = rxSubtotal.value;
      quote.discount = rxTotalDiscount.value;
      quote.tax = rxTaxAmount.value;
      quote.taxableAmount = rxTaxableAmount.value;
      quote.cgstAmount = rxTaxAmount.value / 2.0;
      quote.sgstAmount = rxTaxAmount.value / 2.0;
      quote.additionalCharges =
          double.tryParse(additionalChargesCtrl.text) ?? 0.0;
      quote.grandTotal = rxGrandTotal.value;
      quote.status = quote.status ?? 'Open';
      quote.note = notesCtrl.text.trim();
      quote.termsConditions = termsCtrl.text.trim();

      quote.createdAtUtcMs ??= now;
      quote.updatedAtUtcMs = now;

      final quoteId = _boxQuotation.put(quote);
      _savedQuotationId = quoteId;
      final savedQuote = _boxQuotation.get(quoteId)!;

      // Clean up previous items if updating
      if (savedQuote.items.isNotEmpty) {
        final oldItemIds = savedQuote.items.map((i) => i.id).toList();
        _boxQuotationItem.removeMany(oldItemIds);
        savedQuote.items.clear();
      }

      for (var r in validRows) {
        final qty = int.tryParse(r.qtyCtrl.text) ?? 1;
        final price = double.tryParse(r.priceCtrl.text) ?? 0.0;
        final mrp = double.tryParse(r.mrpCtrl.text) ?? price;
        final disc = double.tryParse(r.discountCtrl.text) ?? 0.0;
        final taxRate = double.tryParse(r.taxRateCtrl.text) ?? 0.0;

        final item = EntityQuotationItem(
          itemName: r.nameCtrl.text.trim(),
          hsnCode: r.hsnCtrl.text.trim(),
          itemBarcode: r.selectedItem?.barcode ?? '',
          unit: r.selectedItem?.unit ?? 'Pcs',
          mrp: mrp,
          price: price,
          qty: qty,
          discount: disc,
          taxRate: taxRate,
          tax: r.lineTaxAmount,
          total: r.lineTotal,
        );

        item.quotation.target = savedQuote;
        if (r.selectedItem != null) {
          item.item.target = r.selectedItem;
        }
        _boxQuotationItem.put(item);
      }

      return true;
    } on UniqueViolationException catch (_) {
      Get.snackbar(
        'Duplicate Quotation Number'.tr,
        'Quotation number "$finalQuotationNo" already exists. Please choose a different number.'
            .tr,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to save quotation: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void previewQuotation() {
    calculateTotals();
    final List<GstPdfItem> items = [];
    int sNo = 1;
    for (var r in rxRows.where((e) => e.nameCtrl.text.isNotEmpty)) {
      items.add(
        GstPdfItem(
          sNo: sNo++,
          name: r.nameCtrl.text,
          hsn: r.hsnCtrl.text,
          qty: int.tryParse(r.qtyCtrl.text) ?? 1,
          unit: r.selectedItem?.unit ?? 'Pcs',
          mrp: double.tryParse(r.mrpCtrl.text) ?? 0.0,
          rate: double.tryParse(r.priceCtrl.text) ?? 0.0,
          discount: double.tryParse(r.discountCtrl.text) ?? 0.0,
          taxPercent: double.tryParse(r.taxRateCtrl.text) ?? 0.0,
          taxAmount: r.lineTaxAmount,
          total: r.lineTotal,
        ),
      );
    }

    final docModel = DocumentViewModel(
      type: DocumentType.quotation,
      title: 'Quotation / Estimate',
      docNumber: '${prefixCtrl.text}${quotationNoCtrl.text}',
      docDate: quotationDateCtrl.text,
      validityDate: validityDateCtrl.text,
      status: 'Open',
      partyName: customerNameCtrl.text.isEmpty
          ? 'Cash Sale'
          : customerNameCtrl.text,
      partyPhone: customerPhoneCtrl.text,
      partyAddress: customerAddressCtrl.text,
      partyGstin: customerGstinCtrl.text,
      items: items,
      subtotal: rxSubtotal.value,
      discount: rxTotalDiscount.value,
      taxAmount: rxTaxAmount.value,
      cgstAmount: rxTaxAmount.value / 2,
      sgstAmount: rxTaxAmount.value / 2,
      additionalCharges: double.tryParse(additionalChargesCtrl.text),
      grandTotal: rxGrandTotal.value,
      notes: notesCtrl.text,
      termsConditions: termsCtrl.text,
    );

    Get.to(() => ActivityDocumentView(model: docModel));
  }
}
