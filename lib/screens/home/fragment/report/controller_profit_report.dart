import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_item.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Profit Report Types
// ═══════════════════════════════════════════════════════════════════════════

enum ProfitReportType {
  profitSummary,
  itemProfit,
  categoryProfit,
  brandProfit,
  dailyProfit,
  monthlyProfit,
}

extension ProfitReportTypeLabel on ProfitReportType {
  String get label => switch (this) {
    ProfitReportType.profitSummary   => 'Profit Summary',
    ProfitReportType.itemProfit      => 'Item-wise Profit',
    ProfitReportType.categoryProfit  => 'Category-wise Profit',
    ProfitReportType.brandProfit     => 'Brand-wise Profit',
    ProfitReportType.dailyProfit     => 'Daily Profit',
    ProfitReportType.monthlyProfit   => 'Monthly Profit',
  };

  IconData get icon => switch (this) {
    ProfitReportType.profitSummary   => Icons.summarize_rounded,
    ProfitReportType.itemProfit      => Icons.inventory_2_rounded,
    ProfitReportType.categoryProfit  => Icons.category_rounded,
    ProfitReportType.brandProfit     => Icons.branding_watermark_rounded,
    ProfitReportType.dailyProfit     => Icons.calendar_today_rounded,
    ProfitReportType.monthlyProfit   => Icons.calendar_view_month_rounded,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Row Models
// ═══════════════════════════════════════════════════════════════════════════

class ProfitSummaryRow {
  final String metric;
  final double value;
  final String details;
  ProfitSummaryRow({
    required this.metric,
    required this.value,
    required this.details,
  });
}

class ItemProfitRow {
  final String sku;
  final String itemName;
  final double quantitySold;
  final double revenue;
  final double cost;
  final double grossProfit;
  final double margin;
  ItemProfitRow({
    required this.sku,
    required this.itemName,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.margin,
  });
}

class CategoryProfitRow {
  final String categoryName;
  final double quantitySold;
  final double revenue;
  final double cost;
  final double grossProfit;
  final double margin;
  CategoryProfitRow({
    required this.categoryName,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.margin,
  });
}

class BrandProfitRow {
  final String brandName;
  final double quantitySold;
  final double revenue;
  final double cost;
  final double grossProfit;
  final double margin;
  BrandProfitRow({
    required this.brandName,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.margin,
  });
}

class DailyProfitRow {
  final String date;
  final double revenue;
  final double cost;
  final double grossProfit;
  final double margin;
  DailyProfitRow({
    required this.date,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.margin,
  });
}

class MonthlyProfitRow {
  final String month;
  final double revenue;
  final double cost;
  final double grossProfit;
  final double margin;
  MonthlyProfitRow({
    required this.month,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.margin,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary Card Model
// ═══════════════════════════════════════════════════════════════════════════

class ProfitSummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  ProfitSummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════════════

class ControllerProfitReport extends GetxController {
  late final Box<EntityBill> _boxBill;
  late final Box<EntityItem> _boxItem;

  // Report Type
  final Rx<ProfitReportType> rxReportType = ProfitReportType.profitSummary.obs;

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
  final RxList<ProfitSummaryCardData> rxSummaryCards = <ProfitSummaryCardData>[].obs;
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
    _boxItem = ob.box<EntityItem>();

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

  void setReportType(ProfitReportType type) {
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
      case ProfitReportType.profitSummary:
        _loadProfitSummary();
        break;
      case ProfitReportType.itemProfit:
        _loadItemProfit();
        break;
      case ProfitReportType.categoryProfit:
        _loadCategoryProfit();
        break;
      case ProfitReportType.brandProfit:
        _loadBrandProfit();
        break;
      case ProfitReportType.dailyProfit:
        _loadDailyProfit();
        break;
      case ProfitReportType.monthlyProfit:
        _loadMonthlyProfit();
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
          .and(EntityBill_.status.notEquals('cancelled')),
    );
    final query = queryBuilder.build();
    final list = query.find();
    query.close();
    return list;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. Profit Summary Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadProfitSummary() {
    final bills = _getActiveBills();

    double revenue = 0.0;
    double cost = 0.0;

    for (final bill in bills) {
      for (final item in bill.items) {
        final qty = item.qty ?? 0;
        final price = item.price ?? 0.0;
        final totalItemRevenue = item.total ?? (qty * price);

        // Fetch cost price or default to 70% of price
        final itemMaster = _boxItem.get(item.item.targetId);
        final unitCost = itemMaster?.costPrice ?? (price * 0.70);
        final itemCost = qty * unitCost;

        revenue += totalItemRevenue;
        cost += itemCost;
      }
    }

    final grossProfit = revenue - cost;
    final margin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;

    final rows = <ProfitSummaryRow>[
      ProfitSummaryRow(metric: 'Total Sales Revenue', value: revenue, details: 'Gross retail invoice totals'),
      ProfitSummaryRow(metric: 'Total Product Cost', value: cost, details: 'Combined cost asset value of products sold'),
      ProfitSummaryRow(metric: 'Gross Profit', value: grossProfit, details: 'Net revenue minus costs'),
      ProfitSummaryRow(metric: 'Profit Margin', value: margin, details: 'Profit percentage of total sales revenue'),
    ];

    _fullRows = _filterSearch(rows, (r) => r.metric);

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      ProfitSummaryCardData(
        label: 'Overall Revenue',
        value: currFmt.format(revenue),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      ProfitSummaryCardData(
        label: 'Product Cost',
        value: currFmt.format(cost),
        icon: Icons.shopping_bag_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      ProfitSummaryCardData(
        label: 'Gross Profit',
        value: currFmt.format(grossProfit),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      ProfitSummaryCardData(
        label: 'Profit Margin',
        value: '${margin.toStringAsFixed(1)}%',
        icon: Icons.pie_chart_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Item Profit Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadItemProfit() {
    final bills = _getActiveBills();
    final Map<String, _ProfitAgg> agg = {};

    for (final bill in bills) {
      for (final item in bill.items) {
        final barcode = item.itemBarcode ?? '-';
        final name = item.itemName ?? 'Unknown Item';
        final qty = item.qty ?? 0;
        final price = item.price ?? 0.0;
        final totalItemRevenue = item.total ?? (qty * price);

        final itemMaster = _boxItem.get(item.item.targetId);
        final unitCost = itemMaster?.costPrice ?? (price * 0.70);
        final itemCost = qty * unitCost;

        final key = '$barcode|$name';
        final existing = agg[key];

        if (existing != null) {
          existing.qtySold += qty;
          existing.revenue += totalItemRevenue;
          existing.cost += itemCost;
        } else {
          agg[key] = _ProfitAgg(
            qtySold: qty.toDouble(),
            revenue: totalItemRevenue,
            cost: itemCost,
          );
        }
      }
    }

    final rows = <ItemProfitRow>[];
    for (final entry in agg.entries) {
      final parts = entry.key.split('|');
      final barcode = parts[0];
      final name = parts[1];
      final val = entry.value;

      final profit = val.revenue - val.cost;
      final margin = val.revenue > 0 ? (profit / val.revenue) * 100 : 0.0;

      rows.add(ItemProfitRow(
        sku: barcode,
        itemName: name,
        quantitySold: val.qtySold,
        revenue: val.revenue,
        cost: val.cost,
        grossProfit: profit,
        margin: margin,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => '${r.itemName} ${r.sku}');

    // Sort by profit descending by default
    _fullRows.sort((a, b) => (b as ItemProfitRow).grossProfit.compareTo((a as ItemProfitRow).grossProfit));

    _rebuildSummaryCardsFromGroupTotals(agg);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Category Profit Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadCategoryProfit() {
    final bills = _getActiveBills();
    final Map<String, _ProfitAgg> agg = {};

    for (final bill in bills) {
      for (final item in bill.items) {
        final itemMaster = _boxItem.get(item.item.targetId);
        final category = itemMaster?.category ?? 'Uncategorized';
        final qty = item.qty ?? 0;
        final price = item.price ?? 0.0;
        final totalItemRevenue = item.total ?? (qty * price);

        final unitCost = itemMaster?.costPrice ?? (price * 0.70);
        final itemCost = qty * unitCost;

        final existing = agg[category];
        if (existing != null) {
          existing.qtySold += qty;
          existing.revenue += totalItemRevenue;
          existing.cost += itemCost;
        } else {
          agg[category] = _ProfitAgg(
            qtySold: qty.toDouble(),
            revenue: totalItemRevenue,
            cost: itemCost,
          );
        }
      }
    }

    final rows = <CategoryProfitRow>[];
    for (final entry in agg.entries) {
      final val = entry.value;
      final profit = val.revenue - val.cost;
      final margin = val.revenue > 0 ? (profit / val.revenue) * 100 : 0.0;

      rows.add(CategoryProfitRow(
        categoryName: entry.key,
        quantitySold: val.qtySold,
        revenue: val.revenue,
        cost: val.cost,
        grossProfit: profit,
        margin: margin,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => r.categoryName);
    _fullRows.sort((a, b) => (b as CategoryProfitRow).grossProfit.compareTo((a as CategoryProfitRow).grossProfit));

    _rebuildSummaryCardsFromGroupTotals(agg);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. Brand Profit Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadBrandProfit() {
    final bills = _getActiveBills();
    final Map<String, _ProfitAgg> agg = {};

    for (final bill in bills) {
      for (final item in bill.items) {
        final itemName = item.itemName ?? 'Unknown';
        final brand = itemName.split(' ').first; // Extract first word
        final qty = item.qty ?? 0;
        final price = item.price ?? 0.0;
        final totalItemRevenue = item.total ?? (qty * price);

        final itemMaster = _boxItem.get(item.item.targetId);
        final unitCost = itemMaster?.costPrice ?? (price * 0.70);
        final itemCost = qty * unitCost;

        final existing = agg[brand];
        if (existing != null) {
          existing.qtySold += qty;
          existing.revenue += totalItemRevenue;
          existing.cost += itemCost;
        } else {
          agg[brand] = _ProfitAgg(
            qtySold: qty.toDouble(),
            revenue: totalItemRevenue,
            cost: itemCost,
          );
        }
      }
    }

    final rows = <BrandProfitRow>[];
    for (final entry in agg.entries) {
      final val = entry.value;
      final profit = val.revenue - val.cost;
      final margin = val.revenue > 0 ? (profit / val.revenue) * 100 : 0.0;

      rows.add(BrandProfitRow(
        brandName: entry.key,
        quantitySold: val.qtySold,
        revenue: val.revenue,
        cost: val.cost,
        grossProfit: profit,
        margin: margin,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => r.brandName);
    _fullRows.sort((a, b) => (b as BrandProfitRow).grossProfit.compareTo((a as BrandProfitRow).grossProfit));

    _rebuildSummaryCardsFromGroupTotals(agg);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 5. Daily Profit Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadDailyProfit() {
    final bills = _getActiveBills();
    final Map<String, _ProfitAgg> agg = {};
    final df = DateFormat('dd/MM/yyyy');

    for (final bill in bills) {
      final dateStr = bill.createdAtUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!))
          : '-';

      double billRevenue = 0.0;
      double billCost = 0.0;

      for (final item in bill.items) {
        final qty = item.qty ?? 0;
        final price = item.price ?? 0.0;
        final totalItemRevenue = item.total ?? (qty * price);

        final itemMaster = _boxItem.get(item.item.targetId);
        final unitCost = itemMaster?.costPrice ?? (price * 0.70);
        final itemCost = qty * unitCost;

        billRevenue += totalItemRevenue;
        billCost += itemCost;
      }

      final existing = agg[dateStr];
      if (existing != null) {
        existing.revenue += billRevenue;
        existing.cost += billCost;
      } else {
        agg[dateStr] = _ProfitAgg(
          qtySold: 0,
          revenue: billRevenue,
          cost: billCost,
        );
      }
    }

    final rows = <DailyProfitRow>[];
    for (final entry in agg.entries) {
      final val = entry.value;
      final profit = val.revenue - val.cost;
      final margin = val.revenue > 0 ? (profit / val.revenue) * 100 : 0.0;

      rows.add(DailyProfitRow(
        date: entry.key,
        revenue: val.revenue,
        cost: val.cost,
        grossProfit: profit,
        margin: margin,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => r.date);
    // Sort dates descending by parsing back to datetime
    final parseDf = DateFormat('dd/MM/yyyy');
    _fullRows.sort((a, b) {
      final ad = parseDf.parse((a as DailyProfitRow).date);
      final bd = parseDf.parse((b as DailyProfitRow).date);
      return bd.compareTo(ad);
    });

    _rebuildSummaryCardsFromGroupTotals(agg);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 6. Monthly Profit Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadMonthlyProfit() {
    final bills = _getActiveBills();
    final Map<String, _ProfitAgg> agg = {};
    final df = DateFormat('MMMM yyyy');

    for (final bill in bills) {
      final dateStr = bill.createdAtUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!))
          : '-';

      double billRevenue = 0.0;
      double billCost = 0.0;

      for (final item in bill.items) {
        final qty = item.qty ?? 0;
        final price = item.price ?? 0.0;
        final totalItemRevenue = item.total ?? (qty * price);

        final itemMaster = _boxItem.get(item.item.targetId);
        final unitCost = itemMaster?.costPrice ?? (price * 0.70);
        final itemCost = qty * unitCost;

        billRevenue += totalItemRevenue;
        billCost += itemCost;
      }

      final existing = agg[dateStr];
      if (existing != null) {
        existing.revenue += billRevenue;
        existing.cost += billCost;
      } else {
        agg[dateStr] = _ProfitAgg(
          qtySold: 0,
          revenue: billRevenue,
          cost: billCost,
        );
      }
    }

    final rows = <MonthlyProfitRow>[];
    for (final entry in agg.entries) {
      final val = entry.value;
      final profit = val.revenue - val.cost;
      final margin = val.revenue > 0 ? (profit / val.revenue) * 100 : 0.0;

      rows.add(MonthlyProfitRow(
        month: entry.key,
        revenue: val.revenue,
        cost: val.cost,
        grossProfit: profit,
        margin: margin,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => r.month);
    // Sort months descending by parsing back to datetime
    final parseDf = DateFormat('MMMM yyyy');
    _fullRows.sort((a, b) {
      final ad = parseDf.parse((a as MonthlyProfitRow).month);
      final bd = parseDf.parse((b as MonthlyProfitRow).month);
      return bd.compareTo(ad);
    });

    _rebuildSummaryCardsFromGroupTotals(agg);
  }

  // ── Helper to build stats cards based on aggregate totals ──
  void _rebuildSummaryCardsFromGroupTotals(Map<String, _ProfitAgg> agg) {
    double totalRev = 0.0;
    double totalCost = 0.0;

    for (final val in agg.values) {
      totalRev += val.revenue;
      totalCost += val.cost;
    }

    final gross = totalRev - totalCost;
    final margin = totalRev > 0 ? (gross / totalRev) * 100 : 0.0;

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      ProfitSummaryCardData(
        label: 'Total Revenue',
        value: currFmt.format(totalRev),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      ProfitSummaryCardData(
        label: 'Cost Value',
        value: currFmt.format(totalCost),
        icon: Icons.shopping_bag_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      ProfitSummaryCardData(
        label: 'Gross Profit',
        value: currFmt.format(gross),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      ProfitSummaryCardData(
        label: 'Profit Margin',
        value: '${margin.toStringAsFixed(1)}%',
        icon: Icons.pie_chart_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Export Stubs
  // ═════════════════════════════════════════════════════════════════════════

  void exportExcel() {
    Get.snackbar(
      'Export Excel',
      'Profit Excel export coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  void exportPdf() {
    Get.snackbar(
      'Export PDF',
      'Profit PDF export coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }
}

// ── Aggregation helper class ──
class _ProfitAgg {
  double qtySold;
  double revenue;
  double cost;
  _ProfitAgg({
    required this.qtySold,
    required this.revenue,
    required this.cost,
  });
}
