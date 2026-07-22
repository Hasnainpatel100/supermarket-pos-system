import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_report_pdf.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Report-type enum
// ═══════════════════════════════════════════════════════════════════════════

enum SalesReportType {
  salesSummary,
  salesDetail,
  itemSales,
  categorySales,
  paymentReport,
  hourWiseSales,
}

extension SalesReportTypeLabel on SalesReportType {
  String get label => switch (this) {
    SalesReportType.salesSummary   => 'Sales Summary',
    SalesReportType.salesDetail    => 'Sales Detail',
    SalesReportType.itemSales      => 'Item Sales',
    SalesReportType.categorySales  => 'Category Sales',
    SalesReportType.paymentReport  => 'Payment Report',
    SalesReportType.hourWiseSales  => 'Hour-wise Sales',
  };

  IconData get icon => switch (this) {
    SalesReportType.salesSummary   => Icons.summarize_rounded,
    SalesReportType.salesDetail    => Icons.receipt_long_rounded,
    SalesReportType.itemSales      => Icons.inventory_2_rounded,
    SalesReportType.categorySales  => Icons.category_rounded,
    SalesReportType.paymentReport  => Icons.payments_rounded,
    SalesReportType.hourWiseSales  => Icons.schedule_rounded,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Date filter enum (reused from existing report)
// ═══════════════════════════════════════════════════════════════════════════

enum SalesDateFilter { today, yesterday, thisWeek, thisMonth, custom }

// ═══════════════════════════════════════════════════════════════════════════
// Lightweight row models for each report type
// ═══════════════════════════════════════════════════════════════════════════

class SalesSummaryRow {
  final String date;
  final int orders;
  final double totalSales;
  final double discount;
  final double tax;
  final double netSales;
  SalesSummaryRow({
    required this.date,
    required this.orders,
    required this.totalSales,
    required this.discount,
    required this.tax,
    required this.netSales,
  });
}

class SalesDetailRow {
  final String dateTime;
  final String billNo;
  final String customer;
  final String payment;
  final int items;
  final double total;
  final String status;
  final EntityBill bill;
  SalesDetailRow({
    required this.dateTime,
    required this.billNo,
    required this.customer,
    required this.payment,
    required this.items,
    required this.total,
    required this.status,
    required this.bill,
  });
}

class ItemSalesRow {
  final String itemName;
  final String barcode;
  final String unit;
  final int qtySold;
  final double revenue;
  final double avgPrice;
  ItemSalesRow({
    required this.itemName,
    required this.barcode,
    required this.unit,
    required this.qtySold,
    required this.revenue,
    required this.avgPrice,
  });
}

class CategorySalesRow {
  final String category;
  final int itemCount;
  final int qtySold;
  final double revenue;
  final double percentOfTotal;
  CategorySalesRow({
    required this.category,
    required this.itemCount,
    required this.qtySold,
    required this.revenue,
    required this.percentOfTotal,
  });
}

class PaymentReportRow {
  final String paymentMode;
  final int transactions;
  final double totalAmount;
  final double percentShare;
  PaymentReportRow({
    required this.paymentMode,
    required this.transactions,
    required this.totalAmount,
    required this.percentShare,
  });
}

class HourWiseSalesRow {
  final String hourSlot;
  final int orders;
  final double totalSales;
  final double avgBill;
  final bool isPeak;
  HourWiseSalesRow({
    required this.hourSlot,
    required this.orders,
    required this.totalSales,
    required this.avgBill,
    required this.isPeak,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary card model
// ═══════════════════════════════════════════════════════════════════════════

class SummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════════════

class ControllerSalesReport extends GetxController {
  late final Box<EntityBill> _boxBill;
  late final Box<EntityBillItem> _boxBillItem;

  // ── Report type ─────────────────────────────────────────────────────────
  final Rx<SalesReportType> rxReportType = SalesReportType.salesSummary.obs;

  // ── Date filter ─────────────────────────────────────────────────────────
  final Rx<SalesDateFilter> rxDateFilter = SalesDateFilter.today.obs;
  final Rx<DateTime> rxStartDate = DateTime.now().obs;
  final Rx<DateTime> rxEndDate = DateTime.now().obs;

  // ── Branch (placeholder for future multi-branch) ───────────────────────
  final RxString rxBranch = 'All Branches'.obs;

  // ── Search ──────────────────────────────────────────────────────────────
  final RxString rxSearchQuery = ''.obs;
  Worker? _searchWorker;

  // ── Pagination ──────────────────────────────────────────────────────────
  static const int _pageSize = 25;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  // ── Report data (generic — cast in UI) ──────────────────────────────────
  final RxList<dynamic> rxRows = <dynamic>[].obs;

  // ── Summary cards ───────────────────────────────────────────────────────
  final RxList<SummaryCardData> rxSummaryCards = <SummaryCardData>[].obs;

  // ── Loading state ───────────────────────────────────────────────────────
  final RxBool rxLoading = false.obs;

  // ── Internal cache ──────────────────────────────────────────────────────
  List<EntityBill> _allFilteredBills = [];
  List<String> _matchingDateStrings = [];

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    _boxBillItem = ob.box<EntityBillItem>();
    _setDateFilter(SalesDateFilter.today);

    _searchWorker = debounce(
      rxSearchQuery,
      (_) => loadData(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Public API
  // ═════════════════════════════════════════════════════════════════════════

  void setReportType(SalesReportType type) {
    rxReportType.value = type;
    currentPage.value = 0;
    loadData();
  }

  void setSearchQuery(String q) => rxSearchQuery.value = q;

  void setDateFilter(SalesDateFilter type) => _setDateFilter(type);

  void setCustomRange(DateTime start, DateTime end) {
    rxDateFilter.value = SalesDateFilter.custom;
    rxStartDate.value = DateTime(start.year, start.month, start.day);
    rxEndDate.value = DateTime(end.year, end.month, end.day);
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

  // ── Export stubs ────────────────────────────────────────────────────────
  // ── Export ───────────────────────────────────────────────────────────────
  void exportExcel() async {
    final type = rxReportType.value;
    final reportTitle = 'Sales Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': formatDateRange(),
      'Date Filter': rxDateFilter.value.name,
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
      case SalesReportType.salesSummary:
        headers = ['Date', 'Orders', 'Total Sales', 'Discount', 'Tax', 'Net Sales'];
        for (final r in allRows) {
          if (r is SalesSummaryRow) {
            exportRows.add([r.date, r.orders, r.totalSales, r.discount, r.tax, r.netSales]);
          }
        }
        break;
      case SalesReportType.salesDetail:
        headers = ['Date & Time', 'Bill No', 'Customer', 'Payment', 'Items', 'Total', 'Status'];
        for (final r in allRows) {
          if (r is SalesDetailRow) {
            exportRows.add([r.dateTime, r.billNo, r.customer, r.payment, r.items, r.total, r.status]);
          }
        }
        break;
      case SalesReportType.itemSales:
        headers = ['Item Name', 'Barcode', 'Unit', 'Qty Sold', 'Revenue', 'Avg Price'];
        for (final r in allRows) {
          if (r is ItemSalesRow) {
            exportRows.add([r.itemName, r.barcode, r.unit, r.qtySold, r.revenue, r.avgPrice]);
          }
        }
        break;
      case SalesReportType.categorySales:
        headers = ['Category', 'Items', 'Qty Sold', 'Revenue', '% of Total'];
        for (final r in allRows) {
          if (r is CategorySalesRow) {
            exportRows.add([r.category, r.itemCount, r.qtySold, r.revenue, '${r.percentOfTotal.toStringAsFixed(1)}%']);
          }
        }
        break;
      case SalesReportType.paymentReport:
        headers = ['Payment Mode', 'Transactions', 'Total Amount', '% Share'];
        for (final r in allRows) {
          if (r is PaymentReportRow) {
            exportRows.add([r.paymentMode, r.transactions, r.totalAmount, '${r.percentShare.toStringAsFixed(1)}%']);
          }
        }
        break;
      case SalesReportType.hourWiseSales:
        headers = ['Hour Slot', 'Orders', 'Total Sales', 'Avg Bill', 'Peak'];
        for (final r in allRows) {
          if (r is HourWiseSalesRow) {
            exportRows.add([r.hourSlot, r.orders, r.totalSales, r.avgBill, r.isPeak ? 'Yes' : 'No']);
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
    final reportTitle = 'Sales Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': formatDateRange(),
      'Date Filter': rxDateFilter.value.name,
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
      case SalesReportType.salesSummary:
        headers = ['Date', 'Orders', 'Total Sales', 'Discount', 'Tax', 'Net Sales'];
        for (final r in allRows) {
          if (r is SalesSummaryRow) {
            exportRows.add([r.date, r.orders, r.totalSales, r.discount, r.tax, r.netSales]);
          }
        }
        break;
      case SalesReportType.salesDetail:
        headers = ['Date & Time', 'Bill No', 'Customer', 'Payment', 'Items', 'Total', 'Status'];
        for (final r in allRows) {
          if (r is SalesDetailRow) {
            exportRows.add([r.dateTime, r.billNo, r.customer, r.payment, r.items, r.total, r.status]);
          }
        }
        break;
      case SalesReportType.itemSales:
        headers = ['Item Name', 'Barcode', 'Unit', 'Qty Sold', 'Revenue', 'Avg Price'];
        for (final r in allRows) {
          if (r is ItemSalesRow) {
            exportRows.add([r.itemName, r.barcode, r.unit, r.qtySold, r.revenue, r.avgPrice]);
          }
        }
        break;
      case SalesReportType.categorySales:
        headers = ['Category', 'Items', 'Qty Sold', 'Revenue', '% of Total'];
        for (final r in allRows) {
          if (r is CategorySalesRow) {
            exportRows.add([r.category, r.itemCount, r.qtySold, r.revenue, '${r.percentOfTotal.toStringAsFixed(1)}%']);
          }
        }
        break;
      case SalesReportType.paymentReport:
        headers = ['Payment Mode', 'Transactions', 'Total Amount', '% Share'];
        for (final r in allRows) {
          if (r is PaymentReportRow) {
            exportRows.add([r.paymentMode, r.transactions, r.totalAmount, '${r.percentShare.toStringAsFixed(1)}%']);
          }
        }
        break;
      case SalesReportType.hourWiseSales:
        headers = ['Hour Slot', 'Orders', 'Total Sales', 'Avg Bill', 'Peak'];
        for (final r in allRows) {
          if (r is HourWiseSalesRow) {
            exportRows.add([r.hourSlot, r.orders, r.totalSales, r.avgBill, r.isPeak ? 'Yes' : 'No']);
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

  // ═════════════════════════════════════════════════════════════════════════
  // Internal — date filter logic
  // ═════════════════════════════════════════════════════════════════════════

  void _setDateFilter(SalesDateFilter type) {
    rxDateFilter.value = type;
    final now = DateTime.now();

    switch (type) {
      case SalesDateFilter.today:
        rxStartDate.value = DateTime(now.year, now.month, now.day);
        rxEndDate.value = DateTime(now.year, now.month, now.day);
        break;
      case SalesDateFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        rxStartDate.value = DateTime(y.year, y.month, y.day);
        rxEndDate.value = DateTime(y.year, y.month, y.day);
        break;
      case SalesDateFilter.thisWeek:
        final ws = now.subtract(Duration(days: now.weekday - 1));
        rxStartDate.value = DateTime(ws.year, ws.month, ws.day);
        rxEndDate.value = DateTime(now.year, now.month, now.day);
        break;
      case SalesDateFilter.thisMonth:
        rxStartDate.value = DateTime(now.year, now.month, 1);
        rxEndDate.value = DateTime(now.year, now.month, now.day);
        break;
      case SalesDateFilter.custom:
        break; // keep existing
    }
    loadData();
  }

  List<String> _buildDateStrings(DateTime start, DateTime end) {
    final fmt = DateFormat('d/MM/yyyy');
    final dates = <String>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDay)) {
      dates.add(fmt.format(current));
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Data loading — queries ObjectBox, then dispatches to builder
  // ═════════════════════════════════════════════════════════════════════════

  void loadData() {
    rxLoading.value = true;
    currentPage.value = 0;
    _matchingDateStrings = _buildDateStrings(rxStartDate.value, rxEndDate.value);

    // ── Build query ────────────────────────────────────────────────────────
    Condition<EntityBill>? dateCondition;
    if (_matchingDateStrings.length == 1) {
      dateCondition = EntityBill_.billDate.equals(_matchingDateStrings.first);
    } else if (_matchingDateStrings.length > 1) {
      dateCondition = EntityBill_.billDate.oneOf(_matchingDateStrings);
    }

    // Exclude cancelled bills from reports
    final notCancelled = EntityBill_.status.notEquals('CANCELLED');
    Condition<EntityBill>? combined;
    if (dateCondition != null) {
      combined = dateCondition.and(notCancelled);
    } else {
      combined = notCancelled;
    }

    final qb = _boxBill.query(combined);
    qb.order(EntityBill_.id, flags: Order.descending);
    final query = qb.build();
    _allFilteredBills = query.find();
    query.close();

    // ── Build report-specific rows ────────────────────────────────────────
    _buildReport();
    rxLoading.value = false;
  }

  void _buildReport() {
    switch (rxReportType.value) {
      case SalesReportType.salesSummary:
        _buildSalesSummary();
        break;
      case SalesReportType.salesDetail:
        _buildSalesDetail();
        break;
      case SalesReportType.itemSales:
        _buildItemSales();
        break;
      case SalesReportType.categorySales:
        _buildCategorySales();
        break;
      case SalesReportType.paymentReport:
        _buildPaymentReport();
        break;
      case SalesReportType.hourWiseSales:
        _buildHourWiseSales();
        break;
    }
    _applyPagination();
  }

  // ── Pagination slice ───────────────────────────────────────────────────
  List<dynamic> _fullRows = [];

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

  // ═════════════════════════════════════════════════════════════════════════
  // Report builders
  // ═════════════════════════════════════════════════════════════════════════

  final _currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

  // ── 1. Sales Summary (grouped by date) ──────────────────────────────────

  void _buildSalesSummary() {
    final Map<String, List<EntityBill>> grouped = {};
    for (final b in _allFilteredBills) {
      final key = b.billDate ?? 'Unknown';
      grouped.putIfAbsent(key, () => []).add(b);
    }

    double totalSales = 0, totalDiscount = 0, totalTax = 0, totalNet = 0;
    int totalOrders = 0;

    final rows = <SalesSummaryRow>[];
    for (final entry in grouped.entries) {
      final bills = entry.value;
      double daySales = 0, dayDisc = 0, dayTax = 0, dayNet = 0;
      for (final b in bills) {
        daySales += b.grandTotal ?? 0;
        dayDisc += b.discount ?? 0;
        dayTax += b.tax ?? 0;
        dayNet += (b.grandTotal ?? 0);
      }
      rows.add(SalesSummaryRow(
        date: entry.key,
        orders: bills.length,
        totalSales: daySales,
        discount: dayDisc,
        tax: dayTax,
        netSales: dayNet,
      ));
      totalSales += daySales;
      totalDiscount += dayDisc;
      totalTax += dayTax;
      totalNet += dayNet;
      totalOrders += bills.length;
    }

    // Sort by date descending
    rows.sort((a, b) => b.date.compareTo(a.date));

    _fullRows = _applySearch(rows, (r) => (r as SalesSummaryRow).date);

    rxSummaryCards.assignAll([
      SummaryCardData(
        label: 'Total Sales',
        value: _currFmt.format(totalSales),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      SummaryCardData(
        label: 'Total Orders',
        value: totalOrders.toString(),
        icon: Icons.receipt_long_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      SummaryCardData(
        label: 'Avg Bill',
        value: _currFmt.format(totalOrders > 0 ? totalSales / totalOrders : 0),
        icon: Icons.analytics_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      SummaryCardData(
        label: 'Total Tax',
        value: _currFmt.format(totalTax),
        icon: Icons.account_balance_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ── 2. Sales Detail (per bill) ──────────────────────────────────────────

  void _buildSalesDetail() {
    final dtFmt = DateFormat('dd/MM/yyyy HH:mm');
    double totalSales = 0;
    int paidCount = 0, dueCount = 0;

    final rows = <SalesDetailRow>[];
    for (final b in _allFilteredBills) {
      String formattedDt = b.billDate ?? '-';
      if (b.createdAtUtcMs != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(b.createdAtUtcMs!, isUtc: true);
        formattedDt = dtFmt.format(dt);
      }
      final itemCount = b.items.length;
      rows.add(SalesDetailRow(
        dateTime: formattedDt,
        billNo: b.billNo ?? '-',
        customer: b.customerName ?? 'Walk-in',
        payment: b.paymentMode ?? '-',
        items: itemCount,
        total: b.grandTotal ?? 0,
        status: b.status ?? 'PAID',
        bill: b,
      ));
      totalSales += b.grandTotal ?? 0;
      if (b.status == 'PAID') paidCount++;
      if (b.status == 'DUE') dueCount++;
    }

    _fullRows = _applySearch(rows, (r) {
      final row = r as SalesDetailRow;
      return '${row.billNo} ${row.customer}'.toLowerCase();
    });

    rxSummaryCards.assignAll([
      SummaryCardData(
        label: 'Total Sales',
        value: _currFmt.format(totalSales),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      SummaryCardData(
        label: 'Total Bills',
        value: _allFilteredBills.length.toString(),
        icon: Icons.receipt_long_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      SummaryCardData(
        label: 'Paid Bills',
        value: paidCount.toString(),
        icon: Icons.check_circle_rounded,
        gradientColors: [Colors.green.shade500, Colors.teal.shade500],
      ),
      SummaryCardData(
        label: 'Due Bills',
        value: dueCount.toString(),
        icon: Icons.pending_actions_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
    ]);
  }

  // ── 3. Item Sales ───────────────────────────────────────────────────────

  void _buildItemSales() {
    final Map<String, _ItemAgg> agg = {};
    for (final b in _allFilteredBills) {
      for (final item in b.items) {
        final key = item.itemBarcode ?? item.itemName ?? 'Unknown';
        final existing = agg[key];
        if (existing != null) {
          existing.qty += item.qty ?? 0;
          existing.revenue += item.total ?? 0;
        } else {
          agg[key] = _ItemAgg(
            name: item.itemName ?? 'Unknown',
            barcode: item.itemBarcode ?? '-',
            unit: item.unit ?? '-',
            qty: item.qty ?? 0,
            revenue: item.total ?? 0,
          );
        }
      }
    }

    double totalRevenue = 0;
    int totalQty = 0;
    String topItem = '-';
    double topRevenue = 0;

    final rows = <ItemSalesRow>[];
    for (final e in agg.entries) {
      final a = e.value;
      rows.add(ItemSalesRow(
        itemName: a.name,
        barcode: a.barcode,
        unit: a.unit,
        qtySold: a.qty,
        revenue: a.revenue,
        avgPrice: a.qty > 0 ? a.revenue / a.qty : 0,
      ));
      totalRevenue += a.revenue;
      totalQty += a.qty;
      if (a.revenue > topRevenue) {
        topRevenue = a.revenue;
        topItem = a.name;
      }
    }

    // Sort by revenue descending
    rows.sort((a, b) => b.revenue.compareTo(a.revenue));

    _fullRows = _applySearch(rows, (r) {
      final row = r as ItemSalesRow;
      return '${row.itemName} ${row.barcode}'.toLowerCase();
    });

    rxSummaryCards.assignAll([
      SummaryCardData(
        label: 'Items Sold',
        value: totalQty.toString(),
        icon: Icons.inventory_2_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      SummaryCardData(
        label: 'Total Revenue',
        value: _currFmt.format(totalRevenue),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      SummaryCardData(
        label: 'Top Item',
        value: topItem.length > 14 ? '${topItem.substring(0, 14)}…' : topItem,
        icon: Icons.emoji_events_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      SummaryCardData(
        label: 'Avg Price',
        value: _currFmt.format(totalQty > 0 ? totalRevenue / totalQty : 0),
        icon: Icons.analytics_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ── 4. Category Sales ───────────────────────────────────────────────────

  void _buildCategorySales() {
    final Map<String, _CatAgg> agg = {};
    for (final b in _allFilteredBills) {
      for (final item in b.items) {
        final cat = item.item.target?.category ?? 'Uncategorized';
        final existing = agg[cat];
        if (existing != null) {
          existing.qty += item.qty ?? 0;
          existing.revenue += item.total ?? 0;
          existing.items.add(item.itemName ?? '');
        } else {
          agg[cat] = _CatAgg(
            qty: item.qty ?? 0,
            revenue: item.total ?? 0,
            items: {item.itemName ?? ''},
          );
        }
      }
    }

    double totalRevenue = agg.values.fold(0.0, (s, a) => s + a.revenue);
    String topCat = '-';
    double topRev = 0;

    final rows = <CategorySalesRow>[];
    for (final e in agg.entries) {
      final a = e.value;
      final pct = totalRevenue > 0 ? (a.revenue / totalRevenue) * 100 : 0.0;
      rows.add(CategorySalesRow(
        category: e.key,
        itemCount: a.items.length,
        qtySold: a.qty,
        revenue: a.revenue,
        percentOfTotal: pct,
      ));
      if (a.revenue > topRev) {
        topRev = a.revenue;
        topCat = e.key;
      }
    }

    rows.sort((a, b) => b.revenue.compareTo(a.revenue));

    _fullRows = _applySearch(rows, (r) => (r as CategorySalesRow).category.toLowerCase());

    rxSummaryCards.assignAll([
      SummaryCardData(
        label: 'Categories',
        value: agg.length.toString(),
        icon: Icons.category_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      SummaryCardData(
        label: 'Total Revenue',
        value: _currFmt.format(totalRevenue),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      SummaryCardData(
        label: 'Top Category',
        value: topCat.length > 14 ? '${topCat.substring(0, 14)}…' : topCat,
        icon: Icons.emoji_events_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      SummaryCardData(
        label: 'Avg / Category',
        value: _currFmt.format(agg.isNotEmpty ? totalRevenue / agg.length : 0),
        icon: Icons.analytics_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ── 5. Payment Report ───────────────────────────────────────────────────

  void _buildPaymentReport() {
    final Map<String, _PayAgg> agg = {};
    double grandTotal = 0;

    for (final b in _allFilteredBills) {
      final mode = b.paymentMode ?? 'Unknown';
      final amt = b.grandTotal ?? 0;
      final existing = agg[mode];
      if (existing != null) {
        existing.count++;
        existing.total += amt;
      } else {
        agg[mode] = _PayAgg(count: 1, total: amt);
      }
      grandTotal += amt;
    }

    double cashAmt = 0, onlineAmt = 0;
    int splitCount = 0;

    final rows = <PaymentReportRow>[];
    for (final e in agg.entries) {
      final a = e.value;
      final pct = grandTotal > 0 ? (a.total / grandTotal) * 100 : 0.0;
      rows.add(PaymentReportRow(
        paymentMode: e.key,
        transactions: a.count,
        totalAmount: a.total,
        percentShare: pct,
      ));
      if (e.key == 'CASH') cashAmt = a.total;
      if (e.key == 'UPI' || e.key == 'NETBANKING' || e.key == 'CARD') onlineAmt += a.total;
      if (e.key == 'SPLIT') splitCount = a.count;
    }

    rows.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    _fullRows = rows;

    rxSummaryCards.assignAll([
      SummaryCardData(
        label: 'Total Collected',
        value: _currFmt.format(grandTotal),
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      SummaryCardData(
        label: 'Cash Amount',
        value: _currFmt.format(cashAmt),
        icon: Icons.money_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      SummaryCardData(
        label: 'Online Amount',
        value: _currFmt.format(onlineAmt),
        icon: Icons.smartphone_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      SummaryCardData(
        label: 'Split Payments',
        value: splitCount.toString(),
        icon: Icons.call_split_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ── 6. Hour-wise Sales ──────────────────────────────────────────────────

  void _buildHourWiseSales() {
    final Map<int, _HourAgg> agg = {};

    for (final b in _allFilteredBills) {
      if (b.createdAtUtcMs == null) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(b.createdAtUtcMs!, isUtc: true).toLocal();
      final hour = dt.hour;
      final existing = agg[hour];
      final amt = b.grandTotal ?? 0;
      if (existing != null) {
        existing.count++;
        existing.total += amt;
      } else {
        agg[hour] = _HourAgg(count: 1, total: amt);
      }
    }

    // Find peak hour
    int peakHour = -1;
    int peakOrders = 0;
    double totalSales = 0;

    for (final e in agg.entries) {
      totalSales += e.value.total;
      if (e.value.count > peakOrders) {
        peakOrders = e.value.count;
        peakHour = e.key;
      }
    }

    final rows = <HourWiseSalesRow>[];
    final sortedHours = agg.keys.toList()..sort();
    for (final h in sortedHours) {
      final a = agg[h]!;
      rows.add(HourWiseSalesRow(
        hourSlot: '${h.toString().padLeft(2, '0')}:00 – ${(h + 1).toString().padLeft(2, '0')}:00',
        orders: a.count,
        totalSales: a.total,
        avgBill: a.count > 0 ? a.total / a.count : 0,
        isPeak: h == peakHour,
      ));
    }

    _fullRows = rows;

    String peakLabel = peakHour >= 0
        ? '${peakHour.toString().padLeft(2, '0')}:00'
        : '-';

    // Find busiest period (3-hour window)
    String busiestPeriod = '-';
    if (sortedHours.length >= 3) {
      int bestStart = sortedHours.first;
      int bestCount = 0;
      for (int i = 0; i < sortedHours.length - 2; i++) {
        int cnt = 0;
        for (int j = i; j < i + 3 && j < sortedHours.length; j++) {
          cnt += agg[sortedHours[j]]!.count;
        }
        if (cnt > bestCount) {
          bestCount = cnt;
          bestStart = sortedHours[i];
        }
      }
      busiestPeriod = '${bestStart.toString().padLeft(2, '0')}:00–${(bestStart + 3).toString().padLeft(2, '0')}:00';
    }

    rxSummaryCards.assignAll([
      SummaryCardData(
        label: 'Peak Hour',
        value: peakLabel,
        icon: Icons.flash_on_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      SummaryCardData(
        label: 'Total Sales',
        value: _currFmt.format(totalSales),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      SummaryCardData(
        label: 'Busiest Period',
        value: busiestPeriod,
        icon: Icons.local_fire_department_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      SummaryCardData(
        label: 'Avg Hourly',
        value: _currFmt.format(agg.isNotEmpty ? totalSales / agg.length : 0),
        icon: Icons.schedule_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═════════════════════════════════════════════════════════════════════════

  List<dynamic> _applySearch(List<dynamic> rows, String Function(dynamic) toSearchable) {
    final q = rxSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) => toSearchable(r).contains(q)).toList();
  }
}

// ── Internal aggregation helpers ──────────────────────────────────────────
class _ItemAgg {
  String name, barcode, unit;
  int qty;
  double revenue;
  _ItemAgg({
    required this.name,
    required this.barcode,
    required this.unit,
    required this.qty,
    required this.revenue,
  });
}

class _CatAgg {
  int qty;
  double revenue;
  Set<String> items;
  _CatAgg({required this.qty, required this.revenue, required this.items});
}

class _PayAgg {
  int count;
  double total;
  _PayAgg({required this.count, required this.total});
}

class _HourAgg {
  int count;
  double total;
  _HourAgg({required this.count, required this.total});
}
