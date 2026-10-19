import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_bill.dart';
import '../../../model/entity_bill_item.dart';
import '../../../model/entity_customer.dart';
import '../../../model/entity_item.dart';
import '../../../model/entity_stock_transaction.dart';
import '../../../model/stock_txn_type.dart';
import '../../../objectbox.g.dart';
import '../../../service/service_object_box.dart';
import '../preview/activity_document_view.dart';
import '../preview/service_gst_pdf.dart';

class InvoiceItemRow {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController hsnCtrl = TextEditingController();
  final TextEditingController mrpCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController priceCtrl = TextEditingController(text: '0');
  final TextEditingController discountCtrl = TextEditingController(text: '0');
  final TextEditingController taxRateCtrl = TextEditingController(text: '0');

  EntityItem? selectedItem;
  double lineTotal = 0.0;
  double lineTaxAmount = 0.0;

  void calculate() {
    final qty = int.tryParse(qtyCtrl.text) ?? 1;
    final price = double.tryParse(priceCtrl.text) ?? 0.0;
    final discount = double.tryParse(discountCtrl.text) ?? 0.0;
    final taxRate = double.tryParse(taxRateCtrl.text) ?? 0.0;

    final base = (qty * price) - discount;
    lineTaxAmount = (base * taxRate) / 100.0;
    lineTotal = base + lineTaxAmount;
    if (lineTotal < 0) lineTotal = 0.0;
  }
}

class ControllerCreateSalesInvoice extends GetxController {
  final EntityBill? editingBill;

  ControllerCreateSalesInvoice({this.editingBill});

  late final Box<EntityBill> _boxBill;
  late final Box<EntityBillItem> _boxBillItem;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityCustomer> _boxCustomer;
  late final Box<EntityStockTransaction> _boxStockTxn;

  // Header Details
  final invoiceNoCtrl = TextEditingController();
  final invoiceDateCtrl = TextEditingController();
  final paymentTermsCtrl = TextEditingController(text: '30');
  final dueDateCtrl = TextEditingController();
  final poNoCtrl = TextEditingController();
  final ewayBillCtrl = TextEditingController();
  final vehicleNoCtrl = TextEditingController();

  // Party / Customer
  final Rxn<EntityCustomer> rxCustomer = Rxn<EntityCustomer>();
  final customerNameCtrl = TextEditingController();
  final customerPhoneCtrl = TextEditingController();
  final customerAddressCtrl = TextEditingController();
  final customerGstinCtrl = TextEditingController();

  // Line items
  final RxList<InvoiceItemRow> rxRows = <InvoiceItemRow>[].obs;
  final RxList<EntityItem> rxAvailableItems = <EntityItem>[].obs;
  final RxList<EntityCustomer> rxAvailableCustomers = <EntityCustomer>[].obs;

  // Bottom Section
  final notesCtrl = TextEditingController();
  final termsCtrl = TextEditingController(text: '1. Goods once sold will not be taken back or exchanged.\n2. All disputes subject to local jurisdiction only.');
  final additionalChargesCtrl = TextEditingController(text: '0');
  final extraDiscountCtrl = TextEditingController(text: '0');
  final amountReceivedCtrl = TextEditingController(text: '0');

  final RxBool rxAutoRoundOff = false.obs;
  final RxBool rxMarkFullyPaid = true.obs;
  final RxString rxPaymentMode = 'Cash'.obs;

  // Calculated totals
  final RxDouble rxSubtotal = 0.0.obs;
  final RxDouble rxTaxableAmount = 0.0.obs;
  final RxDouble rxTaxAmount = 0.0.obs;
  final RxDouble rxTotalDiscount = 0.0.obs;
  final RxDouble rxGrandTotal = 0.0.obs;
  final RxDouble rxBalanceAmount = 0.0.obs;
  final RxBool isSaving = false.obs;
  int? _savedBillId;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    _boxBillItem = ob.box<EntityBillItem>();
    _boxItem = ob.box<EntityItem>();
    _boxCustomer = ob.box<EntityCustomer>();
    _boxStockTxn = ob.box<EntityStockTransaction>();

    rxAvailableItems.assignAll(_boxItem.getAll());
    rxAvailableCustomers.assignAll(_boxCustomer.getAll());

    final now = DateTime.now();
    final df = DateFormat('dd MMM yyyy');
    invoiceDateCtrl.text = df.format(now);
    dueDateCtrl.text = df.format(now.add(const Duration(days: 30)));

    if (editingBill != null) {
      _loadExistingBill(editingBill!);
    } else {
      invoiceNoCtrl.text = _generateNextInvoiceNo();
      addRow();
    }

    calculateTotals();
  }

  String _generateNextInvoiceNo() {
    final all = _boxBill.getAll();
    if (all.isEmpty) return '1';

    int maxNum = 0;
    for (var b in all) {
      final no = (b.billNo ?? '').trim();
      if (no.isEmpty) continue;

      final parsed = int.tryParse(no);
      if (parsed != null && parsed > maxNum) {
        maxNum = parsed;
      } else {
        final digits = RegExp(r'\d+').allMatches(no);
        if (digits.isNotEmpty) {
          final lastDigit = int.tryParse(digits.last.group(0) ?? '') ?? 0;
          if (lastDigit > maxNum) maxNum = lastDigit;
        }
      }
      if (b.id > maxNum) maxNum = b.id;
    }

    int candidate = maxNum + 1;
    while (true) {
      final testNo = '$candidate';
      final exists = _boxBill
          .query(EntityBill_.billNo.equals(testNo))
          .build()
          .findFirst();
      if (exists == null) {
        return '$candidate';
      }
      candidate++;
    }
  }

  static String normalizePaymentMode(String? mode) {
    if (mode == null || mode.trim().isEmpty) return 'Cash';
    final m = mode.trim().toUpperCase();
    switch (m) {
      case 'CASH':
        return 'Cash';
      case 'UPI':
        return 'UPI';
      case 'CARD':
        return 'Card';
      case 'NETBANKING':
      case 'BANK':
      case 'BANK TRANSFER':
        return 'Netbanking';
      case 'CREDIT':
      case 'STORE CREDIT':
        return 'Credit';
      default:
        return 'Cash';
    }
  }

  void _loadExistingBill(EntityBill bill) {
    invoiceNoCtrl.text = bill.billNo ?? '${bill.id}';
    invoiceDateCtrl.text = bill.billDate ?? '';
    paymentTermsCtrl.text = '${bill.paymentTerms ?? 30}';
    dueDateCtrl.text = bill.dueDate ?? '';
    poNoCtrl.text = bill.poNo ?? '';
    ewayBillCtrl.text = bill.ewayBillNo ?? '';
    vehicleNoCtrl.text = bill.vehicleNo ?? '';

    customerNameCtrl.text = bill.customerName ?? '';
    customerPhoneCtrl.text = bill.customerPhone ?? '';
    customerAddressCtrl.text = bill.customerAddress ?? '';
    customerGstinCtrl.text = bill.customerGstin ?? '';

    notesCtrl.text = bill.note ?? '';
    if (bill.termsConditions != null) termsCtrl.text = bill.termsConditions!;
    additionalChargesCtrl.text = '${bill.additionalCharges ?? 0}';
    final grand = bill.grandTotal ?? 0.0;
    final rec = bill.amountReceived ?? (bill.status == 'PAID' ? grand : 0.0);
    final due = bill.dueAmount ?? (grand - rec).clamp(0.0, double.infinity);

    amountReceivedCtrl.text = rec.toStringAsFixed(2);
    rxMarkFullyPaid.value = due <= 0 && rec >= grand && grand > 0;
    rxPaymentMode.value = normalizePaymentMode(bill.paymentMode);

    rxRows.clear();
    for (var item in bill.items) {
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
    customerAddressCtrl.text = [customer.address, customer.city, customer.state].where((e) => e != null && e.isNotEmpty).join(', ');
    customerGstinCtrl.text = customer.notes ?? '';
  }

  void addRow() {
    final row = InvoiceItemRow();
    rxRows.add(row);
    calculateTotals();
  }

  void removeRow(int index) {
    if (index >= 0 && index < rxRows.length) {
      if (rxRows.length > 1) {
        rxRows.removeAt(index);
      } else {
        // If it's the only row, reset it cleanly so user can start fresh
        rxRows.clear();
        rxRows.add(InvoiceItemRow());
      }
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

    if (rxMarkFullyPaid.value) {
      amountReceivedCtrl.text = grand.toStringAsFixed(2);
      rxBalanceAmount.value = 0.0;
    } else {
      final rec = double.tryParse(amountReceivedCtrl.text) ?? 0.0;
      rxBalanceAmount.value = (grand - rec).clamp(0.0, double.infinity);
    }
    rxRows.refresh();
  }

  void onAmountReceivedChanged(String val) {
    final rec = double.tryParse(val) ?? 0.0;
    rxBalanceAmount.value = (rxGrandTotal.value - rec).clamp(0.0, double.infinity);
    if (rec >= rxGrandTotal.value) {
      rxMarkFullyPaid.value = true;
    } else {
      rxMarkFullyPaid.value = false;
    }
  }

  void toggleFullyPaid(bool? val) {
    rxMarkFullyPaid.value = val ?? false;
    if (rxMarkFullyPaid.value) {
      amountReceivedCtrl.text = rxGrandTotal.value.toStringAsFixed(2);
      rxBalanceAmount.value = 0.0;
    } else {
      amountReceivedCtrl.text = '0.00';
      rxBalanceAmount.value = rxGrandTotal.value;
    }
  }

  Future<bool> saveInvoice() async {
    if (isSaving.value) return false;

    final targetInvoiceNo = invoiceNoCtrl.text.trim();
    if (targetInvoiceNo.isEmpty) {
      Get.snackbar('Error'.tr, 'Please enter Invoice Number'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    final validRows = rxRows.where((r) => r.nameCtrl.text.trim().isNotEmpty).toList();
    if (validRows.isEmpty) {
      Get.snackbar('Error'.tr, 'Please add at least one item'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    // Check duplicate invoice number before ObjectBox throws UniqueViolationException
    final targetId = editingBill?.id ?? _savedBillId ?? 0;
    final existingWithSameNo = _boxBill
        .query(EntityBill_.billNo.equals(targetInvoiceNo))
        .build()
        .findFirst();

    if (existingWithSameNo != null && existingWithSameNo.id != targetId) {
      Get.snackbar(
        'Duplicate Invoice Number'.tr,
        'Invoice number "$targetInvoiceNo" already exists. Please choose a different number.'.tr,
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
      final rec = double.tryParse(amountReceivedCtrl.text) ?? 0.0;
      final due = rxBalanceAmount.value;

      String status = 'PAID';
      if (due > 0 && rec > 0) {
        status = 'PARTIALLY_PAID';
      } else if (due > 0 && rec == 0) {
        status = 'UNPAID';
      }

      EntityBill bill;
      if (editingBill != null) {
        bill = editingBill!;
      } else if (_savedBillId != null && _savedBillId! > 0) {
        bill = _boxBill.get(_savedBillId!) ?? EntityBill();
      } else {
        bill = EntityBill();
      }

      bill.billNo = targetInvoiceNo;
      bill.billDate = invoiceDateCtrl.text.trim();
      bill.paymentTerms = int.tryParse(paymentTermsCtrl.text) ?? 30;
      bill.dueDate = dueDateCtrl.text.trim();
      bill.poNo = poNoCtrl.text.trim();
      bill.ewayBillNo = ewayBillCtrl.text.trim();
      bill.vehicleNo = vehicleNoCtrl.text.trim();

      bill.customerName = customerNameCtrl.text.trim().isEmpty ? 'Cash Sale' : customerNameCtrl.text.trim();
      bill.customerPhone = customerPhoneCtrl.text.trim();
      bill.customerAddress = customerAddressCtrl.text.trim();
      bill.customerGstin = customerGstinCtrl.text.trim();

      bill.totalAmount = rxSubtotal.value;
      bill.discount = rxTotalDiscount.value;
      bill.tax = rxTaxAmount.value;
      bill.taxableAmount = rxTaxableAmount.value;
      bill.cgstAmount = rxTaxAmount.value / 2.0;
      bill.sgstAmount = rxTaxAmount.value / 2.0;
      bill.additionalCharges = double.tryParse(additionalChargesCtrl.text) ?? 0.0;
      bill.grandTotal = rxGrandTotal.value;
      bill.amountReceived = rec;
      bill.dueAmount = due;
      bill.status = status;
      bill.paymentMode = rxPaymentMode.value.toUpperCase();
      bill.note = notesCtrl.text.trim();
      bill.termsConditions = termsCtrl.text.trim();

      bill.createdAtUtcMs ??= now;
      bill.updatedAtUtcMs = now;

      // Save Bill
      final billId = _boxBill.put(bill);
      _savedBillId = billId;
      final savedBill = _boxBill.get(billId)!;

      // Clean up previous items if editing
      if (savedBill.items.isNotEmpty) {
        final oldItemIds = savedBill.items.map((i) => i.id).toList();
        _boxBillItem.removeMany(oldItemIds);
        savedBill.items.clear();
      }

      // Save Line items & deduct stock
      for (var r in validRows) {
        final qty = int.tryParse(r.qtyCtrl.text) ?? 1;
        final price = double.tryParse(r.priceCtrl.text) ?? 0.0;
        final mrp = double.tryParse(r.mrpCtrl.text) ?? price;
        final disc = double.tryParse(r.discountCtrl.text) ?? 0.0;
        final taxRate = double.tryParse(r.taxRateCtrl.text) ?? 0.0;

        final billItem = EntityBillItem(
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

        billItem.bill.target = savedBill;
        if (r.selectedItem != null) {
          billItem.item.target = r.selectedItem;
        }
        _boxBillItem.put(billItem);

        // Deduct stock if linked to item
        if (r.selectedItem != null && editingBill == null) {
          final stockItem = r.selectedItem!;
          stockItem.totalQty = (stockItem.totalQty ?? 0) - qty;
          if (stockItem.totalQty! < 0) stockItem.totalQty = 0;
          stockItem.updatedAtUtcMs = now;
          _boxItem.put(stockItem);

          _boxStockTxn.put(EntityStockTransaction(
            itemId: stockItem.id ?? 0,
            type: StockTxnType.sell.index,
            quantity: -qty,
            referenceType: 'sales_invoice',
            referenceId: savedBill.billNo ?? '',
            remarks: 'Sold via Sales Invoice #${savedBill.billNo}',
            createdAtUtcMs: now,
          ));
        }
      }

      return true;
    } on UniqueViolationException catch (_) {
      Get.snackbar(
        'Duplicate Invoice Number'.tr,
        'Invoice number "$targetInvoiceNo" already exists. Please choose a different number.'.tr,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to save invoice: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void previewInvoice() {
    calculateTotals();
    final List<GstPdfItem> items = [];
    int sNo = 1;
    for (var r in rxRows.where((e) => e.nameCtrl.text.isNotEmpty)) {
      items.add(GstPdfItem(
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
      ));
    }

    final docModel = DocumentViewModel(
      type: DocumentType.salesInvoice,
      title: 'Sales Invoice',
      docNumber: invoiceNoCtrl.text.isEmpty ? 'DRAFT' : invoiceNoCtrl.text,
      docDate: invoiceDateCtrl.text,
      docTime: DateFormat('hh:mm a').format(DateTime.now()),
      dueDate: dueDateCtrl.text,
      status: rxBalanceAmount.value <= 0 ? 'Paid' : 'Unpaid',
      partyName: customerNameCtrl.text.isEmpty ? 'Cash Sale' : customerNameCtrl.text,
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
      amountReceived: double.tryParse(amountReceivedCtrl.text),
      balanceDue: rxBalanceAmount.value,
      paymentMode: rxPaymentMode.value,
      notes: notesCtrl.text,
      termsConditions: termsCtrl.text,
    );

    Get.to(() => ActivityDocumentView(model: docModel));
  }
}
