import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_bill.dart';
import '../../../model/entity_bill_item.dart';
import '../../../objectbox.g.dart';
import '../../../service/service_object_box.dart';
import '../preview/activity_document_view.dart';
import '../preview/service_gst_pdf.dart';
import 'activity_create_sales_invoice.dart';

enum InvoiceDateRange {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  last365Days,
  all,
}

extension InvoiceDateRangeLabel on InvoiceDateRange {
  String get label => switch (this) {
    InvoiceDateRange.today => 'Today',
    InvoiceDateRange.yesterday => 'Yesterday',
    InvoiceDateRange.thisWeek => 'This Week',
    InvoiceDateRange.thisMonth => 'This Month',
    InvoiceDateRange.last365Days => 'Last 365 Days',
    InvoiceDateRange.all => 'All Time',
  };
}

class ControllerSalesInvoices extends GetxController {
  late final Box<EntityBill> _boxBill;

  final RxList<EntityBill> rxInvoices = <EntityBill>[].obs;
  final RxString rxSearchQuery = ''.obs;
  final searchController = TextEditingController();
  final Rx<InvoiceDateRange> rxDateRange = InvoiceDateRange.last365Days.obs;
  final RxSet<int> rxSelectedIds = <int>{}.obs;

  // Cached in-memory bills for lightning-fast, zero-lag search
  List<EntityBill> _allBills = [];
  Worker? _searchWorker;

  // Pagination
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  List<EntityBill> get pagedInvoices {
    final start = currentPage.value * _pageSize;
    if (start >= rxInvoices.length) return [];
    final end = (start + _pageSize).clamp(0, rxInvoices.length);
    return rxInvoices.sublist(start, end);
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

  // KPI Metrics
  final RxDouble rxTotalSales = 0.0.obs;
  final RxDouble rxTotalPaid = 0.0.obs;
  final RxDouble rxTotalUnpaid = 0.0.obs;
  final RxDouble rxCancelledAmount = 0.0.obs;
  final RxInt rxCancelledCount = 0.obs;
  final RxBool rxLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();

    // Debounce search query to prevent lag/hang while typing
    _searchWorker = debounce(
      rxSearchQuery,
      (_) => _filterInvoices(),
      time: const Duration(milliseconds: 250),
    );

    loadInvoices();
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// Loads bills from ObjectBox, optionally recomputes KPI metrics, and applies filters.
  void loadInvoices({bool recomputeMetrics = true}) {
    rxLoading.value = true;
    try {
      _allBills = _boxBill.query().order(EntityBill_.id, flags: Order.descending).build().find();

      if (recomputeMetrics) {
        _computeMetrics(_allBills);
      }

      _filterInvoices();
    } finally {
      rxLoading.value = false;
    }
  }

  void _computeMetrics(List<EntityBill> bills) {
    double total = 0.0;
    double paid = 0.0;
    double unpaid = 0.0;
    int cancelled = 0;
    double cancelledAmt = 0.0;

    for (var b in bills) {
      if (b.status == 'CANCELLED') {
        cancelled++;
        cancelledAmt += (b.grandTotal ?? 0.0);
        continue;
      }
      final grand = b.grandTotal ?? 0.0;
      final rec = b.amountReceived ?? (b.status == 'PAID' ? grand : 0.0);
      final due = b.dueAmount ?? (grand - rec).clamp(0.0, double.infinity);

      total += grand;
      paid += rec;
      unpaid += due;
    }

    rxTotalSales.value = total;
    rxTotalPaid.value = paid;
    rxTotalUnpaid.value = unpaid;
    rxCancelledCount.value = cancelled;
    rxCancelledAmount.value = cancelledAmt;
  }

  /// Fast in-memory filtering that supports flexible invoice number formatting
  /// (e.g. BIL/123 matches BIL-123, spaces, dashes, slashes, or raw numbers).
  void _filterInvoices() {
    final now = DateTime.now();
    DateTime? filterFrom;

    switch (rxDateRange.value) {
      case InvoiceDateRange.today:
        filterFrom = DateTime(now.year, now.month, now.day);
        break;
      case InvoiceDateRange.yesterday:
        filterFrom = DateTime(now.year, now.month, now.day - 1);
        break;
      case InvoiceDateRange.thisWeek:
        filterFrom = now.subtract(Duration(days: now.weekday - 1));
        break;
      case InvoiceDateRange.thisMonth:
        filterFrom = DateTime(now.year, now.month, 1);
        break;
      case InvoiceDateRange.last365Days:
        filterFrom = now.subtract(const Duration(days: 365));
        break;
      case InvoiceDateRange.all:
        filterFrom = null;
        break;
    }

    final query = rxSearchQuery.value.trim();
    final bool isSpecificBillSearch = query.isNotEmpty &&
        (query.toLowerCase().startsWith('bil') ||
            RegExp(r'\d{5,}').hasMatch(query));

    final effectiveFilterFrom = isSpecificBillSearch ? null : filterFrom;

    // 1. Try filtering with both date range and search query
    List<EntityBill> filtered = _allBills.where((bill) {
      // Date check
      if (effectiveFilterFrom != null && bill.createdAtUtcMs != null) {
        final billTime = DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!, isUtc: true).toLocal();
        if (billTime.isBefore(effectiveFilterFrom)) return false;
      }

      // Search check
      if (query.isNotEmpty) {
        if (!_matchesBill(bill, query)) return false;
      }

      return true;
    }).toList();

    // 2. Intelligent search fallback: if searching specifically by text / invoice number
    // and no matches were found within the active date range, search across ALL bills.
    if (filtered.isEmpty && query.isNotEmpty && filterFrom != null) {
      filtered = _allBills.where((bill) => _matchesBill(bill, query)).toList();
    }

    rxInvoices.assignAll(filtered);
    totalCount.value = filtered.length;
    currentPage.value = 0;
  }

  /// Comprehensive matcher that handles delimiter differences (/ vs -),
  /// punctuation stripping, direct contains, customer name, phone, and bill ID.
  bool _matchesBill(EntityBill bill, String query) {
    if (query.isEmpty) return true;

    final qLower = query.toLowerCase().trim();
    final billNoRaw = (bill.billNo ?? '').toLowerCase().trim();

    // 1. Direct contains check
    if (billNoRaw.contains(qLower)) return true;

    // 2. Delimiter swap: / replaced with - and vice-versa
    final qSwapHyphen = qLower.replaceAll('/', '-');
    if (billNoRaw.contains(qSwapHyphen)) return true;

    final qSwapSlash = qLower.replaceAll('-', '/');
    if (billNoRaw.contains(qSwapSlash)) return true;

    // 3. Alphanumeric stripped check:
    // Strips non-alphanumeric chars (/, -, _, #, spaces) so "BIL/1792776259243"
    // matches "BIL-1792776259243" or "BIL 1792776259243" perfectly.
    final qAlphaNum = qLower.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final billNoAlphaNum = billNoRaw.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (qAlphaNum.isNotEmpty && billNoAlphaNum.isNotEmpty) {
      if (billNoAlphaNum.contains(qAlphaNum)) return true;
    }

    // 4. Match by ObjectBox entity ID
    final idStr = bill.id.toString();
    if (idStr == qAlphaNum || idStr.contains(qAlphaNum)) return true;

    // 5. Customer Name & Phone
    final custName = (bill.customerName ?? '').toLowerCase();
    if (custName.contains(qLower)) return true;

    final custPhone = (bill.customerPhone ?? '').toLowerCase();
    if (custPhone.contains(qLower)) return true;

    // 6. E-Way Bill & Payment Mode
    final eway = (bill.ewayBillNo ?? '').toLowerCase();
    if (eway.contains(qLower)) return true;

    return false;
  }

  void updateSearch(String q) {
    String sanitized = q.replaceAll('\r', '').replaceAll('\n', '');
    if (sanitized.contains('/')) {
      sanitized = sanitized.replaceAll('/', '-');
      searchController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
    rxSearchQuery.value = sanitized;
  }

  void onSearchSubmitted(String q) {
    String sanitized = q.replaceAll('\r', '').replaceAll('\n', '').replaceAll('/', '-').trim();
    if (searchController.text != sanitized) {
      searchController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
    rxSearchQuery.value = sanitized;
    // Trigger immediate search without debounce wait
    _searchWorker?.dispose();
    _filterInvoices();
    _searchWorker = debounce(
      rxSearchQuery,
      (_) => _filterInvoices(),
      time: const Duration(milliseconds: 200),
    );
  }

  void clearSearch() {
    searchController.clear();
    rxSearchQuery.value = '';
    _filterInvoices();
  }

  void resetSearch() {
    if (rxSearchQuery.value.isNotEmpty || searchController.text.isNotEmpty) {
      clearSearch();
    }
  }

  void setSearch(String q) {
    final sanitized = q.replaceAll('/', '-').trim();
    searchController.text = sanitized;
    rxSearchQuery.value = sanitized;
  }

  void setDateRange(InvoiceDateRange range) {
    rxDateRange.value = range;
    _filterInvoices();
  }

  void toggleSelectAll(bool? value) {
    if (value == true) {
      rxSelectedIds.assignAll(rxInvoices.map((e) => e.id));
    } else {
      rxSelectedIds.clear();
    }
  }

  void toggleSelect(int id) {
    if (rxSelectedIds.contains(id)) {
      rxSelectedIds.remove(id);
    } else {
      rxSelectedIds.add(id);
    }
  }

  void openCreateInvoice({EntityBill? editBill}) async {
    await Get.dialog(
      ActivityCreateSalesInvoice(editingBill: editBill),
      barrierDismissible: false,
    );
    loadInvoices();
  }

  void openDocumentView(EntityBill bill) {
    final List<GstPdfItem> pdfItems = [];
    int idx = 1;
    for (var item in bill.items) {
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

    String? docTime;
    if (bill.createdAtUtcMs != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!, isUtc: true).toLocal();
      docTime = DateFormat('hh:mm a').format(dt);
    }

    final docModel = DocumentViewModel(
      type: DocumentType.salesInvoice,
      title: 'Sales Invoice',
      docNumber: bill.billNo ?? '${bill.id}',
      docDate: bill.billDate ?? DateFormat('dd/MM/yyyy').format(DateTime.now()),
      docTime: docTime,
      dueDate: bill.dueDate,
      status: bill.status ?? 'Paid',
      partyName: bill.customerName ?? 'Cash Sale',
      partyPhone: bill.customerPhone,
      partyAddress: bill.customerAddress,
      partyGstin: bill.customerGstin,
      items: pdfItems,
      subtotal: bill.totalAmount ?? (bill.grandTotal ?? 0.0),
      discount: bill.discount ?? 0.0,
      taxAmount: bill.tax ?? 0.0,
      cgstAmount: bill.cgstAmount,
      sgstAmount: bill.sgstAmount,
      igstAmount: bill.igstAmount,
      additionalCharges: bill.additionalCharges,
      roundOff: bill.roundOff,
      grandTotal: bill.grandTotal ?? 0.0,
      amountReceived: bill.amountReceived,
      balanceDue: bill.dueAmount,
      paymentMode: bill.paymentMode,
      notes: bill.note,
      termsConditions: bill.termsConditions,
    );

    Get.to(() => ActivityDocumentView(model: docModel));
  }

  void cancelInvoice(EntityBill bill) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Invoice'),
        content: Text('Are you sure you want to cancel invoice #${bill.billNo}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              bill.status = 'CANCELLED';
              bill.updatedAtUtcMs = DateTime.now().millisecondsSinceEpoch;
              _boxBill.put(bill);
              Get.back();
              loadInvoices();
              Get.snackbar(
                'Cancelled',
                'Invoice #${bill.billNo} marked as cancelled.',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void deleteInvoice(EntityBill bill) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Delete invoice #${bill.billNo} permanently?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _boxBill.remove(bill.id);
              Get.back();
              loadInvoices();
              Get.snackbar(
                'Deleted',
                'Invoice removed.',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void duplicateInvoice(EntityBill bill) {
    final nextNo = _generateNextBillNo();
    final dup = EntityBill(
      billNo: nextNo,
      customerName: bill.customerName,
      customerPhone: bill.customerPhone,
      customerAddress: bill.customerAddress,
      customerGstin: bill.customerGstin,
      totalAmount: bill.totalAmount,
      discount: bill.discount,
      tax: bill.tax,
      grandTotal: bill.grandTotal,
      status: 'UNPAID',
      paymentMode: bill.paymentMode,
      amountReceived: 0.0,
      dueAmount: bill.grandTotal,
      billDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      createdAtUtcMs: DateTime.now().millisecondsSinceEpoch,
      updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
    );

    final id = _boxBill.put(dup);
    final saved = _boxBill.get(id)!;
    final itemBox = Get.find<ServiceObjectBox>().box<EntityBillItem>();

    for (var it in bill.items) {
      final copyItem = EntityBillItem(
        itemName: it.itemName,
        itemBarcode: it.itemBarcode,
        hsnCode: it.hsnCode,
        unit: it.unit,
        mrp: it.mrp,
        price: it.price,
        qty: it.qty,
        taxRate: it.taxRate,
        tax: it.tax,
        discount: it.discount,
        total: it.total,
      );
      copyItem.bill.target = saved;
      itemBox.put(copyItem);
    }

    loadInvoices();
    Get.snackbar(
      'Duplicated',
      'Invoice duplicated as #$nextNo',
      backgroundColor: Colors.indigo,
      colorText: Colors.white,
    );
  }

  String _generateNextBillNo() {
    final count = _boxBill.count();
    return '${count + 1}';
  }
}
