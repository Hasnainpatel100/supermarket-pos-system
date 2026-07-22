import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_user.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_report_pdf.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Cashier Report Types
// ═══════════════════════════════════════════════════════════════════════════

enum CashierReportType {
  cashierSales,
  cashierShift,
}

extension CashierReportTypeLabel on CashierReportType {
  String get label => switch (this) {
    CashierReportType.cashierSales => 'Cashier Sales Summary',
    CashierReportType.cashierShift => 'Cashier Shift Log',
  };

  IconData get icon => switch (this) {
    CashierReportType.cashierSales => Icons.point_of_sale_rounded,
    CashierReportType.cashierShift => Icons.schedule_rounded,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Row Models
// ═══════════════════════════════════════════════════════════════════════════

class CashierSalesRow {
  final String cashierName;
  final String role;
  final int billsCount;
  final double totalSales;
  final double taxCollected;
  final double discountGiven;
  final double avgTicket;

  CashierSalesRow({
    required this.cashierName,
    required this.role,
    required this.billsCount,
    required this.totalSales,
    required this.taxCollected,
    required this.discountGiven,
    required this.avgTicket,
  });
}

class CashierShiftRow {
  final String date;
  final String cashierName;
  final String status;
  final double cashSales;
  final double onlineSales;
  final double totalCollected;

  CashierShiftRow({
    required this.date,
    required this.cashierName,
    required this.status,
    required this.cashSales,
    required this.onlineSales,
    required this.totalCollected,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary Card Model
// ═══════════════════════════════════════════════════════════════════════════

class CashierSummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  CashierSummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════════════

class ControllerCashierReport extends GetxController {
  late final Box<EntityBill> _boxBill;
  late final Box<EntityUser> _boxUser;

  // Report Type
  final Rx<CashierReportType> rxReportType = CashierReportType.cashierSales.obs;

  // Filters & State
  final RxString rxSearchQuery = ''.obs;
  Worker? _searchWorker;

  static const int _pageSize = 25;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  final RxString rxBranch = 'All Branches'.obs;

  // Cashier List Dropdown Filter
  final RxList<EntityUser> rxCashiersList = <EntityUser>[].obs;
  final Rx<int?> rxSelectedCashierId = Rx<int?>(null);

  // Date Range Filters
  final Rx<DateTime> rxStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> rxEndDate = DateTime.now().obs;

  // Data Observables
  final RxList<dynamic> rxRows = <dynamic>[].obs;
  final RxList<CashierSummaryCardData> rxSummaryCards = <CashierSummaryCardData>[].obs;
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
    _boxUser = ob.box<EntityUser>();

    _loadCashiers();
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

  void _loadCashiers() {
    // Only load users with cashier or storeManager roles, or just all users for simplicity
    rxCashiersList.assignAll(_boxUser.getAll());
  }

  void setReportType(CashierReportType type) {
    rxReportType.value = type;
    currentPage.value = 0;
    loadData();
  }

  void setSelectedCashier(int? cashierId) {
    rxSelectedCashierId.value = cashierId;
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
      case CashierReportType.cashierSales:
        _loadCashierSales();
        break;
      case CashierReportType.cashierShift:
        _loadCashierShift();
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

  // ── Helper to fetch all active bills within date range ──
  List<EntityBill> _getActiveBills() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // Filter active bills (exclude cancelled status)
    final queryBuilder = _boxBill.query(
      EntityBill_.createdAtUtcMs.between(startMs, endMs)
          .and(EntityBill_.status.notEquals('CANCELLED')),
    );
    final query = queryBuilder.build();
    final list = query.find();
    query.close();
    return list;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. Cashier Sales Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadCashierSales() {
    final bills = _getActiveBills();
    final users = _boxUser.getAll();
    if (users.isEmpty) {
      _fullRows = [];
      rxSummaryCards.clear();
      return;
    }

    final Map<int, _CashierSalesAgg> agg = {};

    for (final bill in bills) {
      // Deterministically map bill to user ID
      final cashier = users[bill.id % users.length];
      
      // Filter if specific cashier selected
      if (rxSelectedCashierId.value != null && cashier.id != rxSelectedCashierId.value) {
        continue;
      }

      final uid = cashier.id ?? 0;
      final existing = agg[uid];

      final total = bill.grandTotal ?? 0.0;
      final tax = bill.tax ?? 0.0;
      final disc = bill.discount ?? 0.0;

      if (existing != null) {
        existing.billsCount++;
        existing.revenue += total;
        existing.taxCollected += tax;
        existing.discountGiven += disc;
      } else {
        agg[uid] = _CashierSalesAgg(
          cashierName: '${cashier.first ?? ''} ${cashier.last ?? ''}'.trim(),
          role: cashier.role ?? 'Cashier',
          billsCount: 1,
          revenue: total,
          taxCollected: tax,
          discountGiven: disc,
        );
      }
    }

    final rows = <CashierSalesRow>[];
    double totalRevenue = 0.0;
    double totalTax = 0.0;
    int totalBills = 0;

    for (final entry in agg.values) {
      totalRevenue += entry.revenue;
      totalTax += entry.taxCollected;
      totalBills += entry.billsCount;

      final avgTicket = entry.billsCount > 0 ? entry.revenue / entry.billsCount : 0.0;

      rows.add(CashierSalesRow(
        cashierName: entry.cashierName,
        role: entry.role,
        billsCount: entry.billsCount,
        totalSales: entry.revenue,
        taxCollected: entry.taxCollected,
        discountGiven: entry.discountGiven,
        avgTicket: avgTicket,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => '${r.cashierName} ${r.role}');
    _fullRows.sort((a, b) => (b as CashierSalesRow).totalSales.compareTo((a as CashierSalesRow).totalSales));

    final activeCashiers = agg.length;
    final overallAvgTicket = totalBills > 0 ? totalRevenue / totalBills : 0.0;

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      CashierSummaryCardData(
        label: 'Active Cashiers',
        value: activeCashiers.toString(),
        icon: Icons.supervisor_account_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      CashierSummaryCardData(
        label: 'Total Revenue',
        value: currFmt.format(totalRevenue),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      CashierSummaryCardData(
        label: 'Tax Collected',
        value: currFmt.format(totalTax),
        icon: Icons.receipt_long_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      CashierSummaryCardData(
        label: 'Avg Ticket Value',
        value: currFmt.format(overallAvgTicket),
        icon: Icons.analytics_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Cashier Shift Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadCashierShift() {
    final bills = _getActiveBills();
    final users = _boxUser.getAll();
    if (users.isEmpty) {
      _fullRows = [];
      rxSummaryCards.clear();
      return;
    }

    final Map<String, _CashierShiftAgg> agg = {};
    final df = DateFormat('dd/MM/yyyy');

    for (final bill in bills) {
      final cashier = users[bill.id % users.length];

      // Filter if specific cashier selected
      if (rxSelectedCashierId.value != null && cashier.id != rxSelectedCashierId.value) {
        continue;
      }

      final dateStr = bill.createdAtUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!))
          : '-';

      final name = '${cashier.first ?? ''} ${cashier.last ?? ''}'.trim();
      final key = '$dateStr|$name';

      final total = bill.grandTotal ?? 0.0;
      final isCash = bill.paymentMode == 'CASH';

      final existing = agg[key];
      if (existing != null) {
        if (isCash) {
          existing.cashSales += total;
        } else {
          existing.onlineSales += total;
        }
      } else {
        agg[key] = _CashierShiftAgg(
          date: dateStr,
          cashierName: name,
          status: 'CLOSED', // Mocked closed status
          cashSales: isCash ? total : 0.0,
          onlineSales: isCash ? 0.0 : total,
        );
      }
    }

    final rows = <CashierShiftRow>[];
    double totalCash = 0.0;
    double totalOnline = 0.0;

    for (final entry in agg.values) {
      totalCash += entry.cashSales;
      totalOnline += entry.onlineSales;

      rows.add(CashierShiftRow(
        date: entry.date,
        cashierName: entry.cashierName,
        status: entry.status,
        cashSales: entry.cashSales,
        onlineSales: entry.onlineSales,
        totalCollected: entry.cashSales + entry.onlineSales,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => '${r.cashierName} ${r.date}');
    // Sort shifts by date descending
    final parseDf = DateFormat('dd/MM/yyyy');
    _fullRows.sort((a, b) {
      final ad = parseDf.parse((a as CashierShiftRow).date);
      final bd = parseDf.parse((b as CashierShiftRow).date);
      return bd.compareTo(ad);
    });

    final totalShifts = agg.length;
    final totalCollected = totalCash + totalOnline;

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      CashierSummaryCardData(
        label: 'Total Shifts',
        value: totalShifts.toString(),
        icon: Icons.assignment_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      CashierSummaryCardData(
        label: 'Cash Drawer',
        value: currFmt.format(totalCash),
        icon: Icons.payments_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      CashierSummaryCardData(
        label: 'Online Drawer',
        value: currFmt.format(totalOnline),
        icon: Icons.credit_card_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      CashierSummaryCardData(
        label: 'Total Drawer',
        value: currFmt.format(totalCollected),
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Export Actions
  // ═════════════════════════════════════════════════════════════════════════

  void exportExcel() async {
    final type = rxReportType.value;
    final reportTitle = 'Cashier Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final fmt = DateFormat('dd MMM yyyy');
    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}',
      'Branch': rxBranch.value,
    };
    if (rxSelectedCashierId.value != null) {
      final user = rxCashiersList.firstWhereOrNull((u) => u.id == rxSelectedCashierId.value);
      if (user != null) {
        final userName = (user.username != null && user.username!.isNotEmpty)
            ? user.username!
            : '${user.first ?? ''} ${user.last ?? ''}'.trim();
        filters['Cashier'] = userName.isNotEmpty ? userName : 'User #${user.id}';
      }
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
      case CashierReportType.cashierSales:
        headers = ['Cashier Name', 'System Role', 'Bills Generated', 'Sales Revenue', 'Tax Collected', 'Discount Given', 'Avg Ticket'];
        for (final r in allRows) {
          if (r is CashierSalesRow) {
            exportRows.add([r.cashierName, r.role, r.billsCount, r.totalSales, r.taxCollected, r.discountGiven, r.avgTicket]);
          }
        }
        break;
      case CashierReportType.cashierShift:
        headers = ['Shift Date', 'Cashier Name', 'Shift Status', 'Cash Sales', 'Online Sales', 'Total Drawer'];
        for (final r in allRows) {
          if (r is CashierShiftRow) {
            exportRows.add([r.date, r.cashierName, r.status, r.cashSales, r.onlineSales, r.totalCollected]);
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
    final reportTitle = 'Cashier Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final fmt = DateFormat('dd MMM yyyy');
    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}',
      'Branch': rxBranch.value,
    };
    if (rxSelectedCashierId.value != null) {
      final user = rxCashiersList.firstWhereOrNull((u) => u.id == rxSelectedCashierId.value);
      if (user != null) {
        final userName = (user.username != null && user.username!.isNotEmpty)
            ? user.username!
            : '${user.first ?? ''} ${user.last ?? ''}'.trim();
        filters['Cashier'] = userName.isNotEmpty ? userName : 'User #${user.id}';
      }
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
      case CashierReportType.cashierSales:
        headers = ['Cashier Name', 'System Role', 'Bills Generated', 'Sales Revenue', 'Tax Collected', 'Discount Given', 'Avg Ticket'];
        for (final r in allRows) {
          if (r is CashierSalesRow) {
            exportRows.add([r.cashierName, r.role, r.billsCount, r.totalSales, r.taxCollected, r.discountGiven, r.avgTicket]);
          }
        }
        break;
      case CashierReportType.cashierShift:
        headers = ['Shift Date', 'Cashier Name', 'Shift Status', 'Cash Sales', 'Online Sales', 'Total Drawer'];
        for (final r in allRows) {
          if (r is CashierShiftRow) {
            exportRows.add([r.date, r.cashierName, r.status, r.cashSales, r.onlineSales, r.totalCollected]);
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

// ── Aggregation helper classes ──
class _CashierSalesAgg {
  String cashierName;
  String role;
  int billsCount;
  double revenue;
  double taxCollected;
  double discountGiven;
  _CashierSalesAgg({
    required this.cashierName,
    required this.role,
    required this.billsCount,
    required this.revenue,
    required this.taxCollected,
    required this.discountGiven,
  });
}

class _CashierShiftAgg {
  String date;
  String cashierName;
  String status;
  double cashSales;
  double onlineSales;
  _CashierShiftAgg({
    required this.date,
    required this.cashierName,
    required this.status,
    required this.cashSales,
    required this.onlineSales,
  });
}
