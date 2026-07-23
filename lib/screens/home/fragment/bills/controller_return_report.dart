import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../model/entity_purchase_item.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_report_pdf.dart';
import '../../../../service/service_report_excel_import.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Return Report Types
// ═══════════════════════════════════════════════════════════════════════════

enum ReturnReportType {
  salesReturn,
  purchaseReturn,
}

extension ReturnReportTypeLabel on ReturnReportType {
  String get label => switch (this) {
    ReturnReportType.salesReturn    => 'Sales Return',
    ReturnReportType.purchaseReturn => 'Purchase Return',
  };

  IconData get icon => switch (this) {
    ReturnReportType.salesReturn    => Icons.assignment_return_rounded,
    ReturnReportType.purchaseReturn => Icons.keyboard_return_rounded,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Row Models
// ═══════════════════════════════════════════════════════════════════════════

class SalesReturnRow {
  final String date;
  final String billNo;
  final String customer;
  final int itemsCount;
  final double refundAmount;
  final String reason;
  final EntityBill bill;

  SalesReturnRow({
    required this.date,
    required this.billNo,
    required this.customer,
    required this.itemsCount,
    required this.refundAmount,
    required this.reason,
    required this.bill,
  });
}

class PurchaseReturnRow {
  final String date;
  final String purchaseNo;
  final String supplier;
  final double itemsCount;
  final double refundAmount;
  final String notes;
  final EntityPurchase purchase;

  PurchaseReturnRow({
    required this.date,
    required this.purchaseNo,
    required this.supplier,
    required this.itemsCount,
    required this.refundAmount,
    required this.notes,
    required this.purchase,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary Card Model
// ═══════════════════════════════════════════════════════════════════════════

class ReturnSummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  ReturnSummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════════════

class ControllerReturnReport extends GetxController {
  late final Box<EntityBill> _boxBill;
  late final Box<EntityPurchase> _boxPurchase;
  late final Box<EntityPurchaseItem> _boxPurchaseItem;

  // Report Type
  final Rx<ReturnReportType> rxReportType = ReturnReportType.salesReturn.obs;

  // Filters & State
  final RxString rxSearchQuery = ''.obs;
  Worker? _searchWorker;

  static const int _pageSize = 25;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  final RxString rxBranch = 'All Branches'.obs;

  // Date Range Filters
  final Rx<DateTime> rxStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> rxEndDate = DateTime.now().obs;

  // Data Observables
  final RxList<dynamic> rxRows = <dynamic>[].obs;
  final RxList<ReturnSummaryCardData> rxSummaryCards = <ReturnSummaryCardData>[].obs;
  final RxBool rxLoading = false.obs;

  // Pagination Properties
  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  // Internal full data lists
  List<dynamic> _fullRows = [];

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    _boxPurchase = ob.box<EntityPurchase>();
    _boxPurchaseItem = ob.box<EntityPurchaseItem>();

    loadData();

    _searchWorker = debounce(
      rxSearchQuery,
      (_) => loadData(),
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Setters & Actions
  // ═════════════════════════════════════════════════════════════════════════

  void setReportType(ReturnReportType type) {
    rxReportType.value = type;
    currentPage.value = 0;
    loadData();
  }

  void setSearchQuery(String q) => rxSearchQuery.value = q;

  void setDateRange(DateTime start, DateTime end) {
    rxStartDate.value = DateTime(start.year, start.month, start.day);
    rxEndDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59);
    loadData();
  }

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      _applyPagination();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      _applyPagination();
    }
  }

  String formatDateRange() {
    final fmt = DateFormat('dd MMM yyyy');
    final s = fmt.format(rxStartDate.value);
    final e = fmt.format(rxEndDate.value);
    return s == e ? s : '$s  →  $e';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Data Load
  // ═════════════════════════════════════════════════════════════════════════

  void loadData() {
    rxLoading.value = true;
    currentPage.value = 0;

    switch (rxReportType.value) {
      case ReturnReportType.salesReturn:
        _loadSalesReturn();
        break;
      case ReturnReportType.purchaseReturn:
        _loadPurchaseReturn();
        break;
    }

    _applyPagination();
    rxLoading.value = false;
  }

  void _applyPagination() {
    final start = currentPage.value * _pageSize;
    final end = (start + _pageSize).clamp(0, _fullRows.length);
    totalCount.value = _fullRows.length;
    if (start >= _fullRows.length) {
      rxRows.assignAll([]);
    } else {
      rxRows.assignAll(_fullRows.sublist(start, end));
    }
  }

  List<T> _filterSearch<T>(List<T> list, String Function(T) searchableField) {
    final q = rxSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((item) => searchableField(item).toLowerCase().contains(q)).toList();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. Sales Return Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadSalesReturn() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // Fetch bills in date range
    final qTotal = _boxBill.query(EntityBill_.createdAtUtcMs.between(startMs, endMs)).build();
    final totalCountInPeriod = qTotal.count();
    qTotal.close();

    // Query cancelled bills
    final qCancelled = _boxBill.query(
      EntityBill_.createdAtUtcMs.between(startMs, endMs)
          .and(EntityBill_.status.equals('CANCELLED')),
    ).build();
    final cancelledBills = qCancelled.find();
    qCancelled.close();

    int returnedItemsQty = 0;
    double refundedAmount = 0.0;
    final rows = <SalesReturnRow>[];
    final df = DateFormat('dd/MM/yyyy HH:mm');

    for (final bill in cancelledBills) {
      int itemQty = 0;
      for (final item in bill.items) {
        itemQty += (item.qty ?? 0);
      }
      returnedItemsQty += itemQty;
      refundedAmount += (bill.grandTotal ?? 0.0);

      final dateStr = bill.createdAtUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!))
          : '-';

      rows.add(SalesReturnRow(
        date: dateStr,
        billNo: bill.billNo ?? 'N/A',
        customer: bill.customerName ?? 'Walk-in Customer',
        itemsCount: itemQty,
        refundAmount: bill.grandTotal ?? 0.0,
        reason: bill.note ?? 'Customer Return',
        bill: bill,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => '${r.billNo} ${r.customer} ${r.reason}');
    _fullRows.sort((a, b) => (b as SalesReturnRow).bill.createdAtUtcMs!.compareTo((a as SalesReturnRow).bill.createdAtUtcMs!));

    final returnRate = totalCountInPeriod > 0 ? (cancelledBills.length / totalCountInPeriod) * 100 : 0.0;
    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

    rxSummaryCards.assignAll([
      ReturnSummaryCardData(
        label: 'Returned Bills',
        value: cancelledBills.length.toString(),
        icon: Icons.assignment_return_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      ReturnSummaryCardData(
        label: 'Returned Items',
        value: returnedItemsQty.toString(),
        icon: Icons.remove_circle_outline_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      ReturnSummaryCardData(
        label: 'Refund Amount',
        value: currFmt.format(refundedAmount),
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      ReturnSummaryCardData(
        label: 'Return Rate',
        value: '${returnRate.toStringAsFixed(1)}%',
        icon: Icons.pie_chart_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Purchase Return Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadPurchaseReturn() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // Fetch total POs in date range
    final qTotal = _boxPurchase.query(EntityPurchase_.purchaseDateUtcMs.between(startMs, endMs)).build();
    final totalCountInPeriod = qTotal.count();
    qTotal.close();

    // Query cancelled purchases (status == 4)
    final qCancelled = _boxPurchase.query(
      EntityPurchase_.purchaseDateUtcMs.between(startMs, endMs)
          .and(EntityPurchase_.status.equals(4)),
    ).build();
    final cancelledPurchases = qCancelled.find();
    qCancelled.close();

    double returnedItemsQty = 0.0;
    double refundedAmount = 0.0;
    final rows = <PurchaseReturnRow>[];
    final df = DateFormat('dd/MM/yyyy HH:mm');

    for (final po in cancelledPurchases) {
      // Fetch PO items to sum quantity
      final itemsQuery = _boxPurchaseItem.query(EntityPurchaseItem_.purchaseId.equals(po.id)).build();
      final items = itemsQuery.find();
      itemsQuery.close();

      double itemQty = 0.0;
      for (final item in items) {
        itemQty += (item.orderedQty ?? 0.0);
      }
      returnedItemsQty += itemQty;
      refundedAmount += (po.totalAmount ?? 0.0);

      final dateStr = po.purchaseDateUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(po.purchaseDateUtcMs!))
          : '-';

      rows.add(PurchaseReturnRow(
        date: dateStr,
        purchaseNo: po.purchaseNo ?? 'N/A',
        supplier: po.supplierName ?? 'Unknown Supplier',
        itemsCount: itemQty,
        refundAmount: po.totalAmount ?? 0.0,
        notes: po.notes ?? 'Supplier Return',
        purchase: po,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => '${r.purchaseNo} ${r.supplier} ${r.notes}');
    _fullRows.sort((a, b) => (b as PurchaseReturnRow).purchase.purchaseDateUtcMs!.compareTo((a as PurchaseReturnRow).purchase.purchaseDateUtcMs!));

    final returnRate = totalCountInPeriod > 0 ? (cancelledPurchases.length / totalCountInPeriod) * 100 : 0.0;
    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

    rxSummaryCards.assignAll([
      ReturnSummaryCardData(
        label: 'Returned POs',
        value: cancelledPurchases.length.toString(),
        icon: Icons.keyboard_return_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      ReturnSummaryCardData(
        label: 'Returned Items',
        value: returnedItemsQty.toString(),
        icon: Icons.remove_circle_outline_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      ReturnSummaryCardData(
        label: 'Refund Amount',
        value: currFmt.format(refundedAmount),
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      ReturnSummaryCardData(
        label: 'Return Rate',
        value: '${returnRate.toStringAsFixed(1)}%',
        icon: Icons.pie_chart_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Export Actions
  // ═════════════════════════════════════════════════════════════════════════

  void exportExcel() async {
    final type = rxReportType.value;
    final reportTitle = 'Return Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final fmt = DateFormat('dd MMM yyyy');
    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}',
      'Branch': rxBranch.value,
    };
    if (rxSearchQuery.value.isNotEmpty) {
      filters['Search Query'] = rxSearchQuery.value;
    }

    final summary = <String, dynamic>{};
    for (final card in rxSummaryCards) {
      summary[card.label] = card.value;
    }

    List<String> headers = [];
    List<List<dynamic>> exportRows = [];

    switch (type) {
      case ReturnReportType.salesReturn:
        headers = ['Return Date', 'Invoice No', 'Customer Name', 'Total Items', 'Refunded Amount', 'Reason / Notes'];
        for (final r in allRows) {
          if (r is SalesReturnRow) {
            exportRows.add([r.date, r.billNo, r.customer, r.itemsCount, r.refundAmount, r.reason]);
          }
        }
        break;
      case ReturnReportType.purchaseReturn:
        headers = ['Return Date', 'PO Number', 'Supplier Name', 'Total Items', 'Refund Value', 'Remarks / Notes'];
        for (final r in allRows) {
          if (r is PurchaseReturnRow) {
            exportRows.add([r.date, r.purchaseNo, r.supplier, r.itemsCount, r.refundAmount, r.notes]);
          }
        }
        break;
    }

    final excelService = ServiceItemExcel();
    await excelService.exportReport(
      title: reportTitle,
      headers: headers,
      rows: exportRows,
      appliedFilters: filters,
      summaryData: summary,
    );
  }

  // ── Import Excel (Development/Test Only) ──

  List<String> getHeadersForCurrentReport() {
    switch (rxReportType.value) {
      case ReturnReportType.salesReturn:
        return ['Return Date', 'Invoice No', 'Customer Name', 'Total Items', 'Refunded Amount', 'Reason / Notes'];
      case ReturnReportType.purchaseReturn:
        return ['Return Date', 'PO Number', 'Supplier Name', 'Total Items', 'Refund Value', 'Remarks / Notes'];
    }
  }

  Future<void> importTestExcel() async {
    final type = rxReportType.value;
    final expectedHeaders = getHeadersForCurrentReport();

    final rawRows = await ServiceReportExcelImport.importAndValidate(
      expectedHeaders: expectedHeaders,
    );
    if (rawRows == null) return;

    final testRows = <dynamic>[];
    switch (type) {
      case ReturnReportType.salesReturn:
        for (final raw in rawRows) {
          testRows.add(SalesReturnRow(
            date: raw['Return Date']?.toString() ?? '-',
            billNo: raw['Invoice No']?.toString() ?? '-',
            customer: raw['Customer Name']?.toString() ?? '-',
            itemsCount: int.tryParse(raw['Total Items']?.toString() ?? '0') ?? 0,
            refundAmount: double.tryParse(raw['Refunded Amount']?.toString() ?? '0') ?? 0.0,
            reason: raw['Reason / Notes']?.toString() ?? '-',
            bill: EntityBill(),
          ));
        }
        break;
      case ReturnReportType.purchaseReturn:
        for (final raw in rawRows) {
          testRows.add(PurchaseReturnRow(
            date: raw['Return Date']?.toString() ?? '-',
            purchaseNo: raw['PO Number']?.toString() ?? '-',
            supplier: raw['Supplier Name']?.toString() ?? '-',
            itemsCount: double.tryParse(raw['Total Items']?.toString() ?? '0') ?? 0.0,
            refundAmount: double.tryParse(raw['Refund Value']?.toString() ?? '0') ?? 0.0,
            notes: raw['Remarks / Notes']?.toString() ?? '-',
            purchase: EntityPurchase(),
          ));
        }
        break;
    }

    _fullRows = testRows;
    currentPage.value = 0;
    _recomputeSummaryCardsForTestRows();
    _applyPagination();
  }

  final _currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

  void _recomputeSummaryCardsForTestRows() {
    final type = rxReportType.value;
    switch (type) {
      case ReturnReportType.salesReturn:
        double totalRefund = 0;
        int totalItems = 0;
        for (final r in _fullRows.cast<SalesReturnRow>()) {
          totalRefund += r.refundAmount;
          totalItems += r.itemsCount;
        }
        rxSummaryCards.assignAll([
          ReturnSummaryCardData(
            label: 'Sales Returns',
            value: _fullRows.length.toString(),
            icon: Icons.assignment_return_rounded,
            gradientColors: [Colors.orange.shade500, Colors.red.shade500],
          ),
          ReturnSummaryCardData(
            label: 'Total Refunded',
            value: _currFmt.format(totalRefund),
            icon: Icons.money_off_rounded,
            gradientColors: [Colors.red.shade500, Colors.pink.shade500],
          ),
          ReturnSummaryCardData(
            label: 'Items Returned',
            value: totalItems.toString(),
            icon: Icons.inventory_2_rounded,
            gradientColors: [Colors.teal.shade500, Colors.blue.shade500],
          ),
        ]);
        break;
      case ReturnReportType.purchaseReturn:
        double totalRefund = 0;
        double totalItems = 0;
        for (final r in _fullRows.cast<PurchaseReturnRow>()) {
          totalRefund += r.refundAmount;
          totalItems += r.itemsCount;
        }
        rxSummaryCards.assignAll([
          ReturnSummaryCardData(
            label: 'Purchase Returns',
            value: _fullRows.length.toString(),
            icon: Icons.assignment_return_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
          ReturnSummaryCardData(
            label: 'Refund Received',
            value: _currFmt.format(totalRefund),
            icon: Icons.account_balance_wallet_rounded,
            gradientColors: [Colors.teal.shade500, Colors.green.shade500],
          ),
          ReturnSummaryCardData(
            label: 'Items Returned',
            value: totalItems.toStringAsFixed(0),
            icon: Icons.inventory_2_rounded,
            gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
          ),
        ]);
        break;
    }
  }

  void exportPdf() async {
    final type = rxReportType.value;
    final reportTitle = 'Return Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final fmt = DateFormat('dd MMM yyyy');
    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}',
      'Branch': rxBranch.value,
    };
    if (rxSearchQuery.value.isNotEmpty) {
      filters['Search Query'] = rxSearchQuery.value;
    }

    final summary = <String, dynamic>{};
    for (final card in rxSummaryCards) {
      summary[card.label] = card.value;
    }

    List<String> headers = [];
    List<List<dynamic>> exportRows = [];

    switch (type) {
      case ReturnReportType.salesReturn:
        headers = ['Return Date', 'Invoice No', 'Customer Name', 'Total Items', 'Refunded Amount', 'Reason / Notes'];
        for (final r in allRows) {
          if (r is SalesReturnRow) {
            exportRows.add([r.date, r.billNo, r.customer, r.itemsCount, r.refundAmount, r.reason]);
          }
        }
        break;
      case ReturnReportType.purchaseReturn:
        headers = ['Return Date', 'PO Number', 'Supplier Name', 'Total Items', 'Refund Value', 'Remarks / Notes'];
        for (final r in allRows) {
          if (r is PurchaseReturnRow) {
            exportRows.add([r.date, r.purchaseNo, r.supplier, r.itemsCount, r.refundAmount, r.notes]);
          }
        }
        break;
    }

    final pdfService = ServiceReportPdf();
    await pdfService.exportReport(
      title: reportTitle,
      headers: headers,
      rows: exportRows,
      appliedFilters: filters,
      summaryData: summary,
    );
  }
}
