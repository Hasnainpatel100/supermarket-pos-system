import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../model/entity_supplier.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_report_pdf.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Supplier Report Types
// ═══════════════════════════════════════════════════════════════════════════

enum SupplierReportType {
  purchaseHistory,
  outstanding,
}

extension SupplierReportTypeLabel on SupplierReportType {
  String get label => switch (this) {
    SupplierReportType.purchaseHistory => 'Supplier Purchase History',
    SupplierReportType.outstanding     => 'Supplier Outstanding Balance',
  };

  IconData get icon => switch (this) {
    SupplierReportType.purchaseHistory => Icons.history_rounded,
    SupplierReportType.outstanding     => Icons.account_balance_wallet_rounded,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Row Models
// ═══════════════════════════════════════════════════════════════════════════

class SupplierPurchaseHistoryRow {
  final String date;
  final String purchaseNo;
  final String supplierName;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final int status;
  final EntityPurchase purchase;

  SupplierPurchaseHistoryRow({
    required this.date,
    required this.purchaseNo,
    required this.supplierName,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.status,
    required this.purchase,
  });
}

class SupplierOutstandingRow {
  final String supplierName;
  final double totalPurchases;
  final double totalPaid;
  final double outstandingBalance;
  final int outstandingBillsCount;

  SupplierOutstandingRow({
    required this.supplierName,
    required this.totalPurchases,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.outstandingBillsCount,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary Card Model
// ═══════════════════════════════════════════════════════════════════════════

class SupplierSummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  SupplierSummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════════════

class ControllerSupplierReport extends GetxController {
  late final Box<EntityPurchase> _boxPurchase;
  late final Box<EntitySupplier> _boxSupplier;

  // Report Type
  final Rx<SupplierReportType> rxReportType = SupplierReportType.purchaseHistory.obs;

  // Filters & State
  final RxString rxSearchQuery = ''.obs;
  Worker? _searchWorker;

  static const int _pageSize = 25;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  final RxString rxBranch = 'All Branches'.obs;

  // Supplier List Dropdown Filter
  final RxList<EntitySupplier> rxSuppliersList = <EntitySupplier>[].obs;
  final Rx<int?> rxSelectedSupplierId = Rx<int?>(null);

  // Date Range Filters
  final Rx<DateTime> rxStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> rxEndDate = DateTime.now().obs;

  // Data Observables
  final RxList<dynamic> rxRows = <dynamic>[].obs;
  final RxList<SupplierSummaryCardData> rxSummaryCards = <SupplierSummaryCardData>[].obs;
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
    _boxPurchase = ob.box<EntityPurchase>();
    _boxSupplier = ob.box<EntitySupplier>();

    _loadSuppliers();
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

  void _loadSuppliers() {
    rxSuppliersList.assignAll(_boxSupplier.getAll());
  }

  void setReportType(SupplierReportType type) {
    rxReportType.value = type;
    currentPage.value = 0;
    loadData();
  }

  void setSelectedSupplier(int? supplierId) {
    rxSelectedSupplierId.value = supplierId;
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
      case SupplierReportType.purchaseHistory:
        _loadPurchaseHistory();
        break;
      case SupplierReportType.outstanding:
        _loadOutstanding();
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
  // 1. Supplier Purchase History Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadPurchaseHistory() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    Condition<EntityPurchase> cond = EntityPurchase_.purchaseDateUtcMs.between(startMs, endMs);
    if (rxSelectedSupplierId.value != null) {
      cond = cond.and(EntityPurchase_.supplierId.equals(rxSelectedSupplierId.value!));
    }

    final queryBuilder = _boxPurchase.query(cond);
    final query = queryBuilder.build();
    final purchases = query.find();
    query.close();

    double totalVal = 0.0;
    double totalPaid = 0.0;
    double totalDue = 0.0;
    int outstandingCount = 0;

    final rows = <SupplierPurchaseHistoryRow>[];
    final df = DateFormat('dd/MM/yyyy HH:mm');

    for (final po in purchases) {
      totalVal += (po.totalAmount ?? 0.0);
      totalPaid += (po.amountPaid ?? 0.0);
      final due = po.outstandingAmount;
      totalDue += due;
      if (due > 0) outstandingCount++;

      final dateStr = po.purchaseDateUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(po.purchaseDateUtcMs!))
          : '-';

      rows.add(SupplierPurchaseHistoryRow(
        date: dateStr,
        purchaseNo: po.purchaseNo ?? 'N/A',
        supplierName: po.supplierName ?? 'Unknown Supplier',
        totalAmount: po.totalAmount ?? 0.0,
        amountPaid: po.amountPaid ?? 0.0,
        amountDue: due,
        status: po.status ?? 0,
        purchase: po,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => '${r.purchaseNo} ${r.supplierName}');
    _fullRows.sort((a, b) => (b as SupplierPurchaseHistoryRow).purchase.purchaseDateUtcMs!.compareTo((a as SupplierPurchaseHistoryRow).purchase.purchaseDateUtcMs!));

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      SupplierSummaryCardData(
        label: 'Total POs',
        value: purchases.length.toString(),
        icon: Icons.history_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      SupplierSummaryCardData(
        label: 'Purchase Value',
        value: currFmt.format(totalVal),
        icon: Icons.shopping_cart_outlined,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      SupplierSummaryCardData(
        label: 'Paid Amount',
        value: currFmt.format(totalPaid),
        icon: Icons.payments_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      SupplierSummaryCardData(
        label: 'Outstanding Due',
        value: currFmt.format(totalDue),
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.red.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Supplier Outstanding Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadOutstanding() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    Condition<EntityPurchase> cond = EntityPurchase_.purchaseDateUtcMs.between(startMs, endMs);
    if (rxSelectedSupplierId.value != null) {
      cond = cond.and(EntityPurchase_.supplierId.equals(rxSelectedSupplierId.value!));
    }

    final queryBuilder = _boxPurchase.query(cond);
    final query = queryBuilder.build();
    final purchases = query.find();
    query.close();

    final Map<String, _OutstandingAgg> agg = {};

    for (final po in purchases) {
      final name = po.supplierName ?? 'Unknown Supplier';
      final due = po.outstandingAmount;
      final existing = agg[name];
      if (existing != null) {
        existing.totalPurchases += (po.totalAmount ?? 0.0);
        existing.totalPaid += (po.amountPaid ?? 0.0);
        existing.outstandingBalance += due;
        if (due > 0) existing.outstandingBillsCount++;
      } else {
        agg[name] = _OutstandingAgg(
          totalPurchases: po.totalAmount ?? 0.0,
          totalPaid: po.amountPaid ?? 0.0,
          outstandingBalance: due,
          outstandingBillsCount: due > 0 ? 1 : 0,
        );
      }
    }

    final rows = <SupplierOutstandingRow>[];
    double totalDue = 0.0;
    int totalOverdueBills = 0;

    for (final entry in agg.entries) {
      final val = entry.value;
      totalDue += val.outstandingBalance;
      totalOverdueBills += val.outstandingBillsCount;

      rows.add(SupplierOutstandingRow(
        supplierName: entry.key,
        totalPurchases: val.totalPurchases,
        totalPaid: val.totalPaid,
        outstandingBalance: val.outstandingBalance,
        outstandingBillsCount: val.outstandingBillsCount,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => r.supplierName);
    // Sort outstanding descending
    _fullRows.sort((a, b) => (b as SupplierOutstandingRow).outstandingBalance.compareTo((a as SupplierOutstandingRow).outstandingBalance));

    final countSuppliers = agg.length;
    final avgOutstanding = countSuppliers > 0 ? totalDue / countSuppliers : 0.0;

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      SupplierSummaryCardData(
        label: 'Suppliers Count',
        value: countSuppliers.toString(),
        icon: Icons.supervisor_account_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      SupplierSummaryCardData(
        label: 'Overdue POs',
        value: totalOverdueBills.toString(),
        icon: Icons.assignment_late_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      SupplierSummaryCardData(
        label: 'Total Outstanding',
        value: currFmt.format(totalDue),
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.red.shade500, Colors.pink.shade500],
      ),
      SupplierSummaryCardData(
        label: 'Avg Outstanding',
        value: currFmt.format(avgOutstanding),
        icon: Icons.analytics_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Export Actions
  // ═════════════════════════════════════════════════════════════════════════

  void exportExcel() async {
    final type = rxReportType.value;
    final reportTitle = 'Supplier Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final fmt = DateFormat('dd MMM yyyy');
    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}',
      'Branch': rxBranch.value,
    };
    if (rxSelectedSupplierId.value != null) {
      final supp = rxSuppliersList.firstWhereOrNull((s) => s.id == rxSelectedSupplierId.value);
      if (supp != null) filters['Supplier'] = supp.name ?? 'Supplier #${supp.id}';
    }
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
      case SupplierReportType.purchaseHistory:
        headers = ['PO Date', 'PO Number', 'Supplier', 'Total Amount', 'Paid Amount', 'Outstanding', 'Status'];
        for (final r in allRows) {
          if (r is SupplierPurchaseHistoryRow) {
            exportRows.add([r.date, r.purchaseNo, r.supplierName, r.totalAmount, r.amountPaid, r.amountDue, r.status]);
          }
        }
        break;
      case SupplierReportType.outstanding:
        headers = ['Supplier Name', 'Total Purchases', 'Total Paid', 'Outstanding Balance', 'Outstanding Bills'];
        for (final r in allRows) {
          if (r is SupplierOutstandingRow) {
            exportRows.add([r.supplierName, r.totalPurchases, r.totalPaid, r.outstandingBalance, r.outstandingBillsCount]);
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

  void exportPdf() async {
    final type = rxReportType.value;
    final reportTitle = 'Supplier Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final fmt = DateFormat('dd MMM yyyy');
    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}',
      'Branch': rxBranch.value,
    };
    if (rxSelectedSupplierId.value != null) {
      final supp = rxSuppliersList.firstWhereOrNull((s) => s.id == rxSelectedSupplierId.value);
      if (supp != null) filters['Supplier'] = supp.name ?? 'Supplier #${supp.id}';
    }
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
      case SupplierReportType.purchaseHistory:
        headers = ['PO Date', 'PO Number', 'Supplier', 'Total Amount', 'Paid Amount', 'Outstanding', 'Status'];
        for (final r in allRows) {
          if (r is SupplierPurchaseHistoryRow) {
            exportRows.add([r.date, r.purchaseNo, r.supplierName, r.totalAmount, r.amountPaid, r.amountDue, r.status]);
          }
        }
        break;
      case SupplierReportType.outstanding:
        headers = ['Supplier Name', 'Total Purchases', 'Total Paid', 'Outstanding Balance', 'Outstanding Bills'];
        for (final r in allRows) {
          if (r is SupplierOutstandingRow) {
            exportRows.add([r.supplierName, r.totalPurchases, r.totalPaid, r.outstandingBalance, r.outstandingBillsCount]);
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

// ── Aggregation helper class ──
class _OutstandingAgg {
  double totalPurchases;
  double totalPaid;
  double outstandingBalance;
  int outstandingBillsCount;
  _OutstandingAgg({
    required this.totalPurchases,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.outstandingBillsCount,
  });
}
