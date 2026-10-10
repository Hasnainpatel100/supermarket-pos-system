import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_bill.dart';
import '../../../model/entity_bill_item.dart';
import '../../../model/entity_item.dart';
import '../../../model/entity_quotation.dart';
import '../../../model/entity_stock_transaction.dart';
import '../../../model/stock_txn_type.dart';
import '../../../objectbox.g.dart';
import '../../../service/service_object_box.dart';
import '../preview/activity_document_view.dart';
import '../preview/service_gst_pdf.dart';
import 'activity_create_quotation.dart';

class ControllerQuotations extends GetxController {
  late final Box<EntityQuotation> _boxQuotation;
  late final Box<EntityBill> _boxBill;
  late final Box<EntityBillItem> _boxBillItem;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityStockTransaction> _boxStockTxn;

  final RxList<EntityQuotation> rxQuotations = <EntityQuotation>[].obs;
  final RxString rxSearchQuery = ''.obs;
  final searchController = TextEditingController();
  final RxString rxStatusFilter = 'All'.obs; // All, Open, Converted, Expired
  final RxBool rxLoading = false.obs;

  // Pagination
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  List<EntityQuotation> get pagedQuotations {
    final start = currentPage.value * _pageSize;
    if (start >= rxQuotations.length) return [];
    final end = (start + _pageSize).clamp(0, rxQuotations.length);
    return rxQuotations.sublist(start, end);
  }

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxQuotation = ob.box<EntityQuotation>();
    _boxBill = ob.box<EntityBill>();
    _boxBillItem = ob.box<EntityBillItem>();
    _boxItem = ob.box<EntityItem>();
    _boxStockTxn = ob.box<EntityStockTransaction>();
    loadQuotations();
  }

  void loadQuotations() {
    rxLoading.value = true;
    try {
      final all = _boxQuotation.query().order(EntityQuotation_.id, flags: Order.descending).build().find();
      final q = rxSearchQuery.value.trim().toLowerCase();
      final status = rxStatusFilter.value;

      final filtered = all.where((item) {
        if (status != 'All' && item.status?.toLowerCase() != status.toLowerCase()) {
          return false;
        }
        if (q.isNotEmpty) {
          final noMatch = (item.quotationNo ?? '').toLowerCase().contains(q);
          final partyMatch = (item.customerName ?? '').toLowerCase().contains(q);
          final phoneMatch = (item.customerPhone ?? '').toLowerCase().contains(q);
          if (!noMatch && !partyMatch && !phoneMatch) return false;
        }
        return true;
      }).toList();

      rxQuotations.assignAll(filtered);
      totalCount.value = filtered.length;
      if (currentPage.value * _pageSize >= totalCount.value && totalCount.value > 0) {
        currentPage.value = 0;
      }
    } finally {
      rxLoading.value = false;
    }
  }

  void updateSearch(String q) {
    rxSearchQuery.value = q;
    currentPage.value = 0;
    loadQuotations();
  }

  void clearSearch() {
    searchController.clear();
    rxSearchQuery.value = '';
    currentPage.value = 0;
    loadQuotations();
  }

  void setSearch(String q) {
    updateSearch(q);
  }

  void setStatusFilter(String s) {
    rxStatusFilter.value = s;
    currentPage.value = 0;
    loadQuotations();
  }

  void openCreateQuotation({EntityQuotation? editQuotation}) async {
    await Get.dialog(
      ActivityCreateQuotation(editingQuotation: editQuotation),
      barrierDismissible: false,
    );
    loadQuotations();
  }

  void openDocumentView(EntityQuotation quote) {
    final List<GstPdfItem> pdfItems = [];
    int idx = 1;
    for (var item in quote.items) {
      pdfItems.add(GstPdfItem(
        sNo: idx++,
        name: item.itemName ?? 'Item',
        hsn: item.hsnCode ?? '',
        qty: item.qty ?? 1,
        unit: item.unit ?? 'Pcs',
        mrp: item.mrp ?? (item.price ?? 0.0),
        rate: item.price ?? 0.0,
        discount: item.discount ?? 0.0,
        taxPercent: item.taxRate ?? 0.0,
        taxAmount: item.tax ?? 0.0,
        total: item.total ?? 0.0,
      ));
    }

    final docModel = DocumentViewModel(
      type: DocumentType.quotation,
      title: 'Quotation / Estimate',
      docNumber: quote.quotationNo ?? '${quote.id}',
      docDate: quote.quotationDate ?? DateFormat('dd/MM/yyyy').format(DateTime.now()),
      validityDate: quote.validUntilDate,
      status: quote.status ?? 'Open',
      partyName: quote.customerName ?? 'Cash Sale',
      partyPhone: quote.customerPhone,
      partyAddress: quote.customerAddress,
      partyGstin: quote.customerGstin,
      items: pdfItems,
      subtotal: quote.subtotal ?? (quote.grandTotal ?? 0.0),
      discount: quote.discount ?? 0.0,
      taxAmount: quote.tax ?? 0.0,
      cgstAmount: quote.cgstAmount,
      sgstAmount: quote.sgstAmount,
      igstAmount: quote.igstAmount,
      additionalCharges: quote.additionalCharges,
      roundOff: quote.roundOff,
      grandTotal: quote.grandTotal ?? 0.0,
      notes: quote.note,
      termsConditions: quote.termsConditions,
    );

    Get.to(() => ActivityDocumentView(model: docModel));
  }

  void convertToInvoice(EntityQuotation quote) {
    if (quote.status == 'Converted') {
      Get.snackbar('Already Converted', 'This quotation has already been converted to an invoice.', backgroundColor: Colors.amber.shade800, colorText: Colors.white);
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Convert to Sales Invoice'),
        content: Text('Convert quotation #${quote.quotationNo} into a confirmed Sales Invoice? This will deduct stock and record realized revenue.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            onPressed: () {
              Get.back();
              _performConversion(quote);
            },
            child: const Text('Yes, Convert'),
          ),
        ],
      ),
    );
  }

  void _performConversion(EntityQuotation quote) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final count = _boxBill.count();
    final nextInvoiceNo = '${count + 1}';

    final bill = EntityBill(
      billNo: nextInvoiceNo,
      billDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      dueDate: quote.validUntilDate,
      customerName: quote.customerName,
      customerPhone: quote.customerPhone,
      customerAddress: quote.customerAddress,
      customerGstin: quote.customerGstin,
      totalAmount: quote.subtotal,
      discount: quote.discount,
      tax: quote.tax,
      taxableAmount: quote.taxableAmount,
      cgstAmount: quote.cgstAmount,
      sgstAmount: quote.sgstAmount,
      igstAmount: quote.igstAmount,
      additionalCharges: quote.additionalCharges,
      roundOff: quote.roundOff,
      grandTotal: quote.grandTotal,
      amountReceived: 0.0,
      dueAmount: quote.grandTotal,
      status: 'UNPAID',
      paymentMode: 'CREDIT',
      note: 'Converted from Quotation #${quote.quotationNo}. ${quote.note ?? ''}',
      termsConditions: quote.termsConditions,
      quotationNo: quote.quotationNo,
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );

    final billId = _boxBill.put(bill);
    final savedBill = _boxBill.get(billId)!;

    // Convert items & deduct stock
    for (var qItem in quote.items) {
      final billItem = EntityBillItem(
        itemName: qItem.itemName,
        itemBarcode: qItem.itemBarcode,
        hsnCode: qItem.hsnCode,
        unit: qItem.unit,
        mrp: qItem.mrp,
        price: qItem.price,
        qty: qItem.qty,
        discount: qItem.discount,
        taxRate: qItem.taxRate,
        tax: qItem.tax,
        total: qItem.total,
      );

      billItem.bill.target = savedBill;
      if (qItem.item.target != null) {
        billItem.item.target = qItem.item.target;
        final stockItem = qItem.item.target!;
        final soldQty = qItem.qty ?? 1;
        stockItem.totalQty = (stockItem.totalQty ?? 0) - soldQty;
        if (stockItem.totalQty! < 0) stockItem.totalQty = 0;
        stockItem.updatedAtUtcMs = now;
        _boxItem.put(stockItem);

        _boxStockTxn.put(EntityStockTransaction(
          itemId: stockItem.id ?? 0,
          type: StockTxnType.sell.index,
          quantity: -soldQty,
          referenceType: 'converted_quote',
          referenceId: savedBill.billNo ?? '',
          remarks: 'Sold via Invoice #${savedBill.billNo} from Quote #${quote.quotationNo}',
          createdAtUtcMs: now,
        ));
      }
      _boxBillItem.put(billItem);
    }

    quote.status = 'Converted';
    quote.convertedBillNo = nextInvoiceNo;
    quote.updatedAtUtcMs = now;
    _boxQuotation.put(quote);

    loadQuotations();

    Get.snackbar(
      'Converted Successfully',
      'Created Sales Invoice #$nextInvoiceNo from Quotation #${quote.quotationNo}',
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void deleteQuotation(EntityQuotation quote) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text('Delete quotation #${quote.quotationNo}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _boxQuotation.remove(quote.id);
              Get.back();
              loadQuotations();
              Get.snackbar('Deleted', 'Quotation removed', backgroundColor: Colors.red, colorText: Colors.white);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
