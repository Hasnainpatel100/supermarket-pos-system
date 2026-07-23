import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../model/entity_stock_transaction.dart';
import '../../../../model/stock_txn_type.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_report_pdf.dart';
import '../../../../service/service_report_excel_import.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Inventory Report Types
// ═══════════════════════════════════════════════════════════════════════════

enum InventoryReportType {
  currentStock,
  lowStock,
  outOfStock,
  stockMovement,
  stockAdjustment,
  stockValuation,
  expiry,
  nearExpiry,
}

extension InventoryReportTypeLabel on InventoryReportType {
  String get label => switch (this) {
    InventoryReportType.currentStock     => 'Current Stock',
    InventoryReportType.lowStock         => 'Low Stock',
    InventoryReportType.outOfStock       => 'Out of Stock',
    InventoryReportType.stockMovement    => 'Stock Movement',
    InventoryReportType.stockAdjustment  => 'Stock Adjustment',
    InventoryReportType.stockValuation   => 'Stock Valuation',
    InventoryReportType.expiry           => 'Expired Batches',
    InventoryReportType.nearExpiry       => 'Near Expiry',
  };

  IconData get icon => switch (this) {
    InventoryReportType.currentStock     => Icons.inventory_rounded,
    InventoryReportType.lowStock         => Icons.warning_amber_rounded,
    InventoryReportType.outOfStock       => Icons.remove_shopping_cart_rounded,
    InventoryReportType.stockMovement    => Icons.swap_horiz_rounded,
    InventoryReportType.stockAdjustment  => Icons.tune_rounded,
    InventoryReportType.stockValuation   => Icons.account_balance_rounded,
    InventoryReportType.expiry           => Icons.event_busy_rounded,
    InventoryReportType.nearExpiry       => Icons.schedule_rounded,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Row Models
// ═══════════════════════════════════════════════════════════════════════════

class CurrentStockRow {
  final String sku;
  final String name;
  final String category;
  final String unit;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final double stockValue; // selling value
  CurrentStockRow({
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockValue,
  });
}

class LowStockRow {
  final String sku;
  final String name;
  final String category;
  final int quantity;
  final int reorderLevel;
  final int shortage;
  LowStockRow({
    required this.sku,
    required this.name,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.shortage,
  });
}

class OutOfStockRow {
  final String sku;
  final String name;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final String lastPurchaseInfo;
  final String lastSaleInfo;
  OutOfStockRow({
    required this.sku,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.lastPurchaseInfo,
    required this.lastSaleInfo,
  });
}

class StockMovementRow {
  final String dateTime;
  final String itemName;
  final String txnType;
  final int quantity;
  final String performedBy;
  final String reference;
  StockMovementRow({
    required this.dateTime,
    required this.itemName,
    required this.txnType,
    required this.quantity,
    required this.performedBy,
    required this.reference,
  });
}

class StockAdjustmentRow {
  final String dateTime;
  final String itemName;
  final int previousQty;
  final int newQty;
  final int difference;
  final String reason;
  final String user;
  StockAdjustmentRow({
    required this.dateTime,
    required this.itemName,
    required this.previousQty,
    required this.newQty,
    required this.difference,
    required this.reason,
    required this.user,
  });
}

class StockValuationRow {
  final String sku;
  final String name;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final double costValue;
  final double sellingValue;
  final double expectedProfit;
  StockValuationRow({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.costValue,
    required this.sellingValue,
    required this.expectedProfit,
  });
}

class ExpiryRow {
  final String itemName;
  final String batchNo;
  final String expiryDate;
  final int quantity;
  final int daysExpired;
  ExpiryRow({
    required this.itemName,
    required this.batchNo,
    required this.expiryDate,
    required this.quantity,
    required this.daysExpired,
  });
}

class NearExpiryRow {
  final String itemName;
  final String batchNo;
  final String expiryDate;
  final int quantity;
  final int daysRemaining;
  NearExpiryRow({
    required this.itemName,
    required this.batchNo,
    required this.expiryDate,
    required this.quantity,
    required this.daysRemaining,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary Card Model (matches Sales Reports)
// ═══════════════════════════════════════════════════════════════════════════

class InventorySummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  InventorySummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════════════

class ControllerInventoryReport extends GetxController {
  late final Box<EntityItem> _boxItem;
  late final Box<EntityStockTransaction> _boxTxn;
  late final Box<EntityItemBatch> _boxBatch;

  // Report Type
  final Rx<InventoryReportType> rxReportType = InventoryReportType.currentStock.obs;

  // Search & Pagination
  final RxString rxSearchQuery = ''.obs;
  Worker? _searchWorker;

  static const int _pageSize = 25;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  // Filters
  final RxString rxBranch = 'All Warehouses'.obs;
  final RxInt rxLowStockThreshold = 10.obs;
  final RxInt rxExpiryThresholdDays = 30.obs; // configurable days for near expiry

  // Date Range Filters (primarily used for Movement, Adjustment, Expiry)
  final Rx<DateTime> rxStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> rxEndDate = DateTime.now().obs;

  // Data Observables
  final RxList<dynamic> rxRows = <dynamic>[].obs;
  final RxList<InventorySummaryCardData> rxSummaryCards = <InventorySummaryCardData>[].obs;
  final RxBool rxLoading = false.obs;

  // Internal full data lists
  List<dynamic> _fullRows = [];

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxItem = ob.box<EntityItem>();
    _boxTxn = ob.box<EntityStockTransaction>();
    _boxBatch = ob.box<EntityItemBatch>();

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
  // Setters
  // ═════════════════════════════════════════════════════════════════════════

  void setReportType(InventoryReportType type) {
    rxReportType.value = type;
    currentPage.value = 0;
    loadData();
  }

  void setSearchQuery(String q) => rxSearchQuery.value = q;

  void setLowStockThreshold(int val) {
    rxLowStockThreshold.value = val;
    loadData();
  }

  void setExpiryThresholdDays(int val) {
    rxExpiryThresholdDays.value = val;
    loadData();
  }

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
  // Load and Aggregate Data
  // ═════════════════════════════════════════════════════════════════════════

  void loadData() {
    rxLoading.value = true;
    currentPage.value = 0;

    switch (rxReportType.value) {
      case InventoryReportType.currentStock:
        _loadCurrentStock();
        break;
      case InventoryReportType.lowStock:
        _loadLowStock();
        break;
      case InventoryReportType.outOfStock:
        _loadOutOfStock();
        break;
      case InventoryReportType.stockMovement:
        _loadStockMovement();
        break;
      case InventoryReportType.stockAdjustment:
        _loadStockAdjustment();
        break;
      case InventoryReportType.stockValuation:
        _loadStockValuation();
        break;
      case InventoryReportType.expiry:
        _loadExpiry();
        break;
      case InventoryReportType.nearExpiry:
        _loadNearExpiry();
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
  // 1. Current Stock Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadCurrentStock() {
    final items = _boxItem.getAll();
    final rows = <CurrentStockRow>[];
    
    int totalItems = 0;
    int totalQty = 0;
    double totalValue = 0.0;
    double avgSellingPrice = 0.0;

    for (final item in items) {
      final qty = item.totalQty ?? 0;
      final selling = item.sellingPrice ?? 0.0;
      final val = qty * selling;

      rows.add(CurrentStockRow(
        sku: item.sku ?? item.barcode ?? '-',
        name: item.name ?? 'Unknown',
        category: item.category ?? 'Uncategorized',
        unit: item.unit ?? 'pcs',
        quantity: qty,
        costPrice: item.costPrice ?? 0.0,
        sellingPrice: selling,
        stockValue: val,
      ));

      if (qty > 0) {
        totalItems++;
        totalQty += qty;
        totalValue += val;
      }
    }

    if (totalItems > 0) {
      avgSellingPrice = totalValue / totalQty;
    }

    _fullRows = _filterSearch(rows, (r) => '${r.name} ${r.sku} ${r.category}');

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      InventorySummaryCardData(
        label: 'Active Items',
        value: totalItems.toString(),
        icon: Icons.inventory_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      InventorySummaryCardData(
        label: 'Total Qty',
        value: totalQty.toString(),
        icon: Icons.unfold_more_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      InventorySummaryCardData(
        label: 'Retail Value',
        value: currFmt.format(totalValue),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      InventorySummaryCardData(
        label: 'Avg Sell Price',
        value: currFmt.format(avgSellingPrice),
        icon: Icons.analytics_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Low Stock Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadLowStock() {
    final items = _boxItem.getAll();
    final rows = <LowStockRow>[];
    
    int lowCount = 0;
    int totalShortage = 0;
    double potentialCost = 0.0;
    String maxShortageItem = '-';
    int maxShortage = 0;

    final threshold = rxLowStockThreshold.value;

    for (final item in items) {
      final qty = item.totalQty ?? 0;
      if (qty < threshold) {
        final shortage = threshold - qty;
        rows.add(LowStockRow(
          sku: item.sku ?? item.barcode ?? '-',
          name: item.name ?? 'Unknown',
          category: item.category ?? 'Uncategorized',
          quantity: qty,
          reorderLevel: threshold,
          shortage: shortage,
        ));

        lowCount++;
        totalShortage += shortage;
        potentialCost += shortage * (item.costPrice ?? 0.0);

        if (shortage > maxShortage) {
          maxShortage = shortage;
          maxShortageItem = item.name ?? '-';
        }
      }
    }

    _fullRows = _filterSearch(rows, (r) => '${r.name} ${r.sku} ${r.category}');

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      InventorySummaryCardData(
        label: 'Low Stock Items',
        value: lowCount.toString(),
        icon: Icons.warning_amber_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      InventorySummaryCardData(
        label: 'Total Shortage',
        value: totalShortage.toString(),
        icon: Icons.trending_down_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      InventorySummaryCardData(
        label: 'Est. Refill Cost',
        value: currFmt.format(potentialCost),
        icon: Icons.shopping_basket_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      InventorySummaryCardData(
        label: 'Max Shortage',
        value: maxShortageItem.length > 12 ? '${maxShortageItem.substring(0, 12)}…' : maxShortageItem,
        icon: Icons.info_outline_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Out of Stock Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadOutOfStock() {
    final items = _boxItem.getAll();
    final rows = <OutOfStockRow>[];
    
    int outCount = 0;
    final fmt = DateFormat('dd/MM/yyyy');

    for (final item in items) {
      final qty = item.totalQty ?? 0;
      if (qty <= 0) {
        // Query last purchase/sale
        final txns = _boxTxn
            .query(EntityStockTransaction_.itemId.equals(item.id ?? 0))
            .order(EntityStockTransaction_.createdAtUtcMs, flags: Order.descending)
            .build()
            .find();

        EntityStockTransaction? lastP;
        EntityStockTransaction? lastS;

        for (final tx in txns) {
          if (tx.type == StockTxnType.purchaseIn.index && lastP == null) lastP = tx;
          if (tx.type == StockTxnType.sell.index && lastS == null) lastS = tx;
          if (lastP != null && lastS != null) break;
        }

        final lastPurchaseInfo = lastP != null
            ? '${fmt.format(DateTime.fromMillisecondsSinceEpoch(lastP.createdAtUtcMs!))} (Qty: ${lastP.quantity})'
            : 'No purchase recorded';

        final lastSaleInfo = lastS != null
            ? '${fmt.format(DateTime.fromMillisecondsSinceEpoch(lastS.createdAtUtcMs!))} (Qty: ${lastS.quantity?.abs()})'
            : 'No sales recorded';

        rows.add(OutOfStockRow(
          sku: item.sku ?? item.barcode ?? '-',
          name: item.name ?? 'Unknown',
          category: item.category ?? 'Uncategorized',
          costPrice: item.costPrice ?? 0.0,
          sellingPrice: item.sellingPrice ?? 0.0,
          lastPurchaseInfo: lastPurchaseInfo,
          lastSaleInfo: lastSaleInfo,
        ));
        outCount++;
      }
    }

    _fullRows = _filterSearch(rows, (r) => '${r.name} ${r.sku} ${r.category}');

    rxSummaryCards.assignAll([
      InventorySummaryCardData(
        label: 'Out of Stock',
        value: outCount.toString(),
        icon: Icons.remove_shopping_cart_rounded,
        gradientColors: [Colors.red.shade600, Colors.pink.shade600],
      ),
      InventorySummaryCardData(
        label: 'Refill Priority',
        value: outCount > 0 ? 'HIGH' : 'NORMAL',
        icon: Icons.priority_high_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      InventorySummaryCardData(
        label: 'Total Items Cataloged',
        value: items.length.toString(),
        icon: Icons.collections_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      InventorySummaryCardData(
        label: 'Stock Health',
        value: items.isNotEmpty 
            ? '${((items.length - outCount) / items.length * 100).toStringAsFixed(1)}%'
            : '100%',
        icon: Icons.favorite_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. Stock Movement Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadStockMovement() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    final query = _boxTxn
        .query(EntityStockTransaction_.createdAtUtcMs.between(startMs, endMs))
        .order(EntityStockTransaction_.createdAtUtcMs, flags: Order.descending)
        .build();
    final txns = query.find();
    query.close();

    final rows = <StockMovementRow>[];
    final df = DateFormat('dd/MM/yyyy HH:mm');

    int totalMovements = 0;
    int qtyIn = 0;
    int qtyOut = 0;

    for (final tx in txns) {
      final item = _boxItem.get(tx.itemId ?? 0);
      final itemName = item?.name ?? tx.referenceId ?? 'Unknown Item';
      final qty = tx.quantity ?? 0;

      rows.add(StockMovementRow(
        dateTime: tx.createdAtUtcMs != null
            ? df.format(DateTime.fromMillisecondsSinceEpoch(tx.createdAtUtcMs!))
            : '-',
        itemName: itemName,
        txnType: _getMovementLabel(tx.type),
        quantity: qty,
        performedBy: 'Staff', // default placeholder
        reference: tx.remarks ?? tx.referenceType ?? '-',
      ));

      totalMovements++;
      if (qty > 0) {
        qtyIn += qty;
      } else {
        qtyOut += qty.abs();
      }
    }

    _fullRows = _filterSearch(rows, (r) => '${r.itemName} ${r.txnType} ${r.reference}');

    rxSummaryCards.assignAll([
      InventorySummaryCardData(
        label: 'Movements Found',
        value: totalMovements.toString(),
        icon: Icons.swap_horiz_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      InventorySummaryCardData(
        label: 'Stock Checked-In',
        value: '+$qtyIn',
        icon: Icons.add_circle_outline_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      InventorySummaryCardData(
        label: 'Stock Deducted',
        value: '-$qtyOut',
        icon: Icons.remove_circle_outline_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      InventorySummaryCardData(
        label: 'Net Shift',
        value: (qtyIn - qtyOut) >= 0 ? '+${qtyIn - qtyOut}' : '${qtyIn - qtyOut}',
        icon: Icons.compare_arrows_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  String _getMovementLabel(int? typeIndex) {
    if (typeIndex == null) return 'Movement';
    if (typeIndex >= 0 && typeIndex < StockTxnType.values.length) {
      return StockTxnType.values[typeIndex].name.toUpperCase();
    }
    return 'UNKNOWN';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 5. Stock Adjustment Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadStockAdjustment() {
    // Standard run through chronological order to compute previous/new qty
    final allTxns = _boxTxn
        .query()
        .order(EntityStockTransaction_.createdAtUtcMs)
        .build()
        .find();

    final Map<int, int> runningBalances = {};
    final Map<int, Map<String, int>> calculatedAdjBalances = {}; // txnId -> {prev, new}

    for (final tx in allTxns) {
      final itemId = tx.itemId ?? 0;
      final prev = runningBalances[itemId] ?? 0;
      final diff = tx.quantity ?? 0;
      final next = prev + diff;
      runningBalances[itemId] = next;

      if (tx.type == StockTxnType.adjust.index) {
        calculatedAdjBalances[tx.id ?? 0] = {
          'prev': prev,
          'new': next,
        };
      }
    }

    // Now filter manual adjustments within date range
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    final filterQuery = _boxTxn
        .query(EntityStockTransaction_.type.equals(StockTxnType.adjust.index)
            .and(EntityStockTransaction_.createdAtUtcMs.between(startMs, endMs)))
        .order(EntityStockTransaction_.createdAtUtcMs, flags: Order.descending)
        .build();
    final adjustTxns = filterQuery.find();
    filterQuery.close();

    final rows = <StockAdjustmentRow>[];
    final df = DateFormat('dd/MM/yyyy HH:mm');

    int totalAdjCount = 0;
    int netQtyAdjusted = 0;
    double netValueAdjusted = 0.0;

    for (final tx in adjustTxns) {
      final item = _boxItem.get(tx.itemId ?? 0);
      final itemName = item?.name ?? tx.referenceId ?? 'Unknown';
      final diff = tx.quantity ?? 0;

      final calced = calculatedAdjBalances[tx.id ?? 0] ?? {'prev': 0, 'new': 0};
      final prevQty = calced['prev']!;
      final newQty = calced['new']!;

      rows.add(StockAdjustmentRow(
        dateTime: tx.createdAtUtcMs != null
            ? df.format(DateTime.fromMillisecondsSinceEpoch(tx.createdAtUtcMs!))
            : '-',
        itemName: itemName,
        previousQty: prevQty,
        newQty: newQty,
        difference: diff,
        reason: tx.remarks ?? 'Manual adjustment',
        user: 'Manager', // user name placeholder
      ));

      totalAdjCount++;
      netQtyAdjusted += diff;
      netValueAdjusted += diff * (item?.costPrice ?? 0.0);
    }

    _fullRows = _filterSearch(rows, (r) => '${r.itemName} ${r.reason}');

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      InventorySummaryCardData(
        label: 'Adjustments',
        value: totalAdjCount.toString(),
        icon: Icons.tune_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      InventorySummaryCardData(
        label: 'Net Qty Adjusted',
        value: netQtyAdjusted >= 0 ? '+$netQtyAdjusted' : '$netQtyAdjusted',
        icon: Icons.compare_arrows_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      InventorySummaryCardData(
        label: 'Net Value Impact',
        value: currFmt.format(netValueAdjusted),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      InventorySummaryCardData(
        label: 'Avg Shift',
        value: totalAdjCount > 0 ? (netQtyAdjusted / totalAdjCount).toStringAsFixed(1) : '0',
        icon: Icons.analytics_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 6. Stock Valuation Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadStockValuation() {
    final items = _boxItem.getAll();
    final rows = <StockValuationRow>[];

    double totalCostVal = 0.0;
    double totalSellingVal = 0.0;

    for (final item in items) {
      final qty = item.totalQty ?? 0;
      final cost = item.costPrice ?? 0.0;
      final sell = item.sellingPrice ?? 0.0;
      final costVal = qty * cost;
      final sellVal = qty * sell;
      final expectedProfit = sellVal - costVal;

      rows.add(StockValuationRow(
        sku: item.sku ?? item.barcode ?? '-',
        name: item.name ?? 'Unknown',
        quantity: qty,
        costPrice: cost,
        sellingPrice: sell,
        costValue: costVal,
        sellingValue: sellVal,
        expectedProfit: expectedProfit,
      ));

      totalCostVal += costVal;
      totalSellingVal += sellVal;
    }

    _fullRows = _filterSearch(rows, (r) => '${r.name} ${r.sku}');

    final expectedProfitTotal = totalSellingVal - totalCostVal;
    final profitMarginPct = totalSellingVal > 0 ? (expectedProfitTotal / totalSellingVal) * 100 : 0.0;

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      InventorySummaryCardData(
        label: 'Asset Cost Value',
        value: currFmt.format(totalCostVal),
        icon: Icons.shopping_bag_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      InventorySummaryCardData(
        label: 'Retail Value',
        value: currFmt.format(totalSellingVal),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      InventorySummaryCardData(
        label: 'Expected Profit',
        value: currFmt.format(expectedProfitTotal),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      InventorySummaryCardData(
        label: 'Est. Profit Margin',
        value: '${profitMarginPct.toStringAsFixed(1)}%',
        icon: Icons.pie_chart_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 7. Expiry Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadExpiry() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    
    // Find batches where expiryDateUtcMs is in the past
    final query = _boxBatch
        .query(EntityItemBatch_.expiryDateUtcMs.lessThan(nowMs))
        .order(EntityItemBatch_.expiryDateUtcMs)
        .build();
    final expiredBatches = query.find();
    query.close();

    final rows = <ExpiryRow>[];
    final df = DateFormat('dd/MM/yyyy');

    int totalExpiredCount = 0;
    int totalExpiredQty = 0;
    double expiredCostVal = 0.0;

    for (final batch in expiredBatches) {
      final item = _boxItem.get(batch.itemId ?? 0);
      final qty = batch.quantity ?? 0;
      final cost = item?.costPrice ?? 0.0;
      final val = qty * cost;

      final diffMs = nowMs - (batch.expiryDateUtcMs ?? 0);
      final days = diffMs ~/ (24 * 60 * 60 * 1000);

      rows.add(ExpiryRow(
        itemName: item?.name ?? 'Unknown Item',
        batchNo: batch.batchNo ?? '-',
        expiryDate: batch.expiryDateUtcMs != null
            ? df.format(DateTime.fromMillisecondsSinceEpoch(batch.expiryDateUtcMs!))
            : '-',
        quantity: qty,
        daysExpired: days,
      ));

      totalExpiredCount++;
      totalExpiredQty += qty;
      expiredCostVal += val;
    }

    _fullRows = _filterSearch(rows, (r) => '${r.itemName} ${r.batchNo}');

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      InventorySummaryCardData(
        label: 'Expired Batches',
        value: totalExpiredCount.toString(),
        icon: Icons.event_busy_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      InventorySummaryCardData(
        label: 'Total Expired Qty',
        value: totalExpiredQty.toString(),
        icon: Icons.delete_outline_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      InventorySummaryCardData(
        label: 'Expired Cost Value',
        value: currFmt.format(expiredCostVal),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      InventorySummaryCardData(
        label: 'Loss Index',
        value: expiredCostVal > 5000 ? 'HIGH' : 'LOW',
        icon: Icons.analytics_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 8. Near Expiry Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadNearExpiry() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final thresholdDays = rxExpiryThresholdDays.value;
    final limitMs = nowMs + (thresholdDays * 24 * 60 * 60 * 1000);

    // Find batches where expiryDateUtcMs is between now and the limit
    final query = _boxBatch
        .query(EntityItemBatch_.expiryDateUtcMs.between(nowMs, limitMs))
        .order(EntityItemBatch_.expiryDateUtcMs)
        .build();
    final nearExpiredBatches = query.find();
    query.close();

    final rows = <NearExpiryRow>[];
    final df = DateFormat('dd/MM/yyyy');

    int totalNearCount = 0;
    int totalNearQty = 0;
    double nearCostVal = 0.0;
    int minDaysRemaining = thresholdDays;

    for (final batch in nearExpiredBatches) {
      final item = _boxItem.get(batch.itemId ?? 0);
      final qty = batch.quantity ?? 0;
      final cost = item?.costPrice ?? 0.0;
      final val = qty * cost;

      final diffMs = (batch.expiryDateUtcMs ?? 0) - nowMs;
      final days = (diffMs / (24 * 60 * 60 * 1000)).ceil();

      rows.add(NearExpiryRow(
        itemName: item?.name ?? 'Unknown Item',
        batchNo: batch.batchNo ?? '-',
        expiryDate: batch.expiryDateUtcMs != null
            ? df.format(DateTime.fromMillisecondsSinceEpoch(batch.expiryDateUtcMs!))
            : '-',
        quantity: qty,
        daysRemaining: days,
      ));

      totalNearCount++;
      totalNearQty += qty;
      nearCostVal += val;
      if (days < minDaysRemaining) {
        minDaysRemaining = days;
      }
    }

    _fullRows = _filterSearch(rows, (r) => '${r.itemName} ${r.batchNo}');

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      InventorySummaryCardData(
        label: 'Near Expiry Batches',
        value: totalNearCount.toString(),
        icon: Icons.schedule_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      InventorySummaryCardData(
        label: 'Near Expiry Qty',
        value: totalNearQty.toString(),
        icon: Icons.hourglass_empty_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      InventorySummaryCardData(
        label: 'Potential Waste Value',
        value: currFmt.format(nearCostVal),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      InventorySummaryCardData(
        label: 'Busiest Expiry Day',
        value: minDaysRemaining == thresholdDays ? 'N/A' : '$minDaysRemaining days',
        icon: Icons.date_range_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Export Stubs
  // ═════════════════════════════════════════════════════════════════════════

  void exportExcel() async {
    final type = rxReportType.value;
    final reportTitle = 'Inventory Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final filters = <String, String>{
      'Report Type': type.label,
      'Warehouse/Branch': rxBranch.value,
    };
    if (type == InventoryReportType.stockMovement ||
        type == InventoryReportType.stockAdjustment ||
        type == InventoryReportType.expiry ||
        type == InventoryReportType.nearExpiry) {
      final fmt = DateFormat('dd MMM yyyy');
      filters['Date Range'] = '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}';
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
      case InventoryReportType.currentStock:
        headers = ['SKU/Barcode', 'Name', 'Category', 'Unit', 'Quantity', 'Cost Price', 'Selling Price', 'Stock Value'];
        for (final r in allRows) {
          if (r is CurrentStockRow) {
            exportRows.add([r.sku, r.name, r.category, r.unit, r.quantity, r.costPrice, r.sellingPrice, r.stockValue]);
          }
        }
        break;
      case InventoryReportType.lowStock:
        headers = ['SKU/Barcode', 'Name', 'Category', 'Current Qty', 'Reorder Level', 'Shortage'];
        for (final r in allRows) {
          if (r is LowStockRow) {
            exportRows.add([r.sku, r.name, r.category, r.quantity, r.reorderLevel, r.shortage]);
          }
        }
        break;
      case InventoryReportType.outOfStock:
        headers = ['SKU/Barcode', 'Name', 'Category', 'Cost Price', 'Last Purchase', 'Last Sale'];
        for (final r in allRows) {
          if (r is OutOfStockRow) {
            exportRows.add([r.sku, r.name, r.category, r.costPrice, r.lastPurchaseInfo, r.lastSaleInfo]);
          }
        }
        break;
      case InventoryReportType.stockMovement:
        headers = ['Date & Time', 'Item Name', 'Type', 'Quantity', 'Performed By', 'Reference/Remarks'];
        for (final r in allRows) {
          if (r is StockMovementRow) {
            exportRows.add([r.dateTime, r.itemName, r.txnType, r.quantity, r.performedBy, r.reference]);
          }
        }
        break;
      case InventoryReportType.stockAdjustment:
        headers = ['Date & Time', 'Item Name', 'Prev Qty', 'New Qty', 'Difference', 'Reason', 'User'];
        for (final r in allRows) {
          if (r is StockAdjustmentRow) {
            exportRows.add([r.dateTime, r.itemName, r.previousQty, r.newQty, r.difference, r.reason, r.user]);
          }
        }
        break;
      case InventoryReportType.stockValuation:
        headers = ['SKU/Barcode', 'Name', 'Quantity', 'Cost Price', 'Selling Price', 'Cost Value', 'Selling Value', 'Expected Profit'];
        for (final r in allRows) {
          if (r is StockValuationRow) {
            exportRows.add([r.sku, r.name, r.quantity, r.costPrice, r.sellingPrice, r.costValue, r.sellingValue, r.expectedProfit]);
          }
        }
        break;
      case InventoryReportType.expiry:
        headers = ['Item Name', 'Batch No', 'Expiry Date', 'Quantity', 'Days Expired'];
        for (final r in allRows) {
          if (r is ExpiryRow) {
            exportRows.add([r.itemName, r.batchNo, r.expiryDate, r.quantity, r.daysExpired]);
          }
        }
        break;
      case InventoryReportType.nearExpiry:
        headers = ['Item Name', 'Batch No', 'Expiry Date', 'Quantity', 'Days Remaining'];
        for (final r in allRows) {
          if (r is NearExpiryRow) {
            exportRows.add([r.itemName, r.batchNo, r.expiryDate, r.quantity, r.daysRemaining]);
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
      case InventoryReportType.currentStock:
        return ['SKU/Barcode', 'Name', 'Category', 'Unit', 'Quantity', 'Cost Price', 'Selling Price', 'Stock Value'];
      case InventoryReportType.lowStock:
        return ['SKU/Barcode', 'Name', 'Category', 'Current Qty', 'Reorder Level', 'Shortage'];
      case InventoryReportType.outOfStock:
        return ['SKU/Barcode', 'Name', 'Category', 'Cost Price', 'Last Purchase', 'Last Sale'];
      case InventoryReportType.stockMovement:
        return ['Date & Time', 'Item Name', 'Type', 'Quantity', 'Performed By', 'Reference/Remarks'];
      case InventoryReportType.stockAdjustment:
        return ['Date & Time', 'Item Name', 'Prev Qty', 'New Qty', 'Difference', 'Reason', 'User'];
      case InventoryReportType.stockValuation:
        return ['SKU/Barcode', 'Name', 'Quantity', 'Cost Price', 'Selling Price', 'Cost Value', 'Selling Value', 'Expected Profit'];
      case InventoryReportType.expiry:
        return ['Item Name', 'Batch No', 'Expiry Date', 'Quantity', 'Days Expired'];
      case InventoryReportType.nearExpiry:
        return ['Item Name', 'Batch No', 'Expiry Date', 'Quantity', 'Days Remaining'];
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
      case InventoryReportType.currentStock:
        for (final raw in rawRows) {
          testRows.add(CurrentStockRow(
            sku: raw['SKU/Barcode']?.toString() ?? '-',
            name: raw['Name']?.toString() ?? '-',
            category: raw['Category']?.toString() ?? '-',
            unit: raw['Unit']?.toString() ?? '-',
            quantity: int.tryParse(raw['Quantity']?.toString() ?? '0') ?? 0,
            costPrice: double.tryParse(raw['Cost Price']?.toString() ?? '0') ?? 0.0,
            sellingPrice: double.tryParse(raw['Selling Price']?.toString() ?? '0') ?? 0.0,
            stockValue: double.tryParse(raw['Stock Value']?.toString() ?? '0') ?? 0.0,
          ));
        }
        break;
      case InventoryReportType.lowStock:
        for (final raw in rawRows) {
          testRows.add(LowStockRow(
            sku: raw['SKU/Barcode']?.toString() ?? '-',
            name: raw['Name']?.toString() ?? '-',
            category: raw['Category']?.toString() ?? '-',
            quantity: int.tryParse(raw['Current Qty']?.toString() ?? '0') ?? 0,
            reorderLevel: int.tryParse(raw['Reorder Level']?.toString() ?? '0') ?? 0,
            shortage: int.tryParse(raw['Shortage']?.toString() ?? '0') ?? 0,
          ));
        }
        break;
      case InventoryReportType.outOfStock:
        for (final raw in rawRows) {
          testRows.add(OutOfStockRow(
            sku: raw['SKU/Barcode']?.toString() ?? '-',
            name: raw['Name']?.toString() ?? '-',
            category: raw['Category']?.toString() ?? '-',
            costPrice: double.tryParse(raw['Cost Price']?.toString() ?? '0') ?? 0.0,
            sellingPrice: double.tryParse(raw['Selling Price']?.toString() ?? '0') ?? 0.0,
            lastPurchaseInfo: raw['Last Purchase']?.toString() ?? '-',
            lastSaleInfo: raw['Last Sale']?.toString() ?? '-',
          ));
        }
        break;
      case InventoryReportType.stockMovement:
        for (final raw in rawRows) {
          testRows.add(StockMovementRow(
            dateTime: raw['Date & Time']?.toString() ?? '-',
            itemName: raw['Item Name']?.toString() ?? '-',
            txnType: raw['Type']?.toString() ?? '-',
            quantity: int.tryParse(raw['Quantity']?.toString() ?? '0') ?? 0,
            performedBy: raw['Performed By']?.toString() ?? '-',
            reference: raw['Reference/Remarks']?.toString() ?? '-',
          ));
        }
        break;
      case InventoryReportType.stockAdjustment:
        for (final raw in rawRows) {
          testRows.add(StockAdjustmentRow(
            dateTime: raw['Date & Time']?.toString() ?? '-',
            itemName: raw['Item Name']?.toString() ?? '-',
            previousQty: int.tryParse(raw['Prev Qty']?.toString() ?? '0') ?? 0,
            newQty: int.tryParse(raw['New Qty']?.toString() ?? '0') ?? 0,
            difference: int.tryParse(raw['Difference']?.toString() ?? '0') ?? 0,
            reason: raw['Reason']?.toString() ?? '-',
            user: raw['User']?.toString() ?? '-',
          ));
        }
        break;
      case InventoryReportType.stockValuation:
        for (final raw in rawRows) {
          testRows.add(StockValuationRow(
            sku: raw['SKU/Barcode']?.toString() ?? '-',
            name: raw['Name']?.toString() ?? '-',
            quantity: int.tryParse(raw['Quantity']?.toString() ?? '0') ?? 0,
            costPrice: double.tryParse(raw['Cost Price']?.toString() ?? '0') ?? 0.0,
            sellingPrice: double.tryParse(raw['Selling Price']?.toString() ?? '0') ?? 0.0,
            costValue: double.tryParse(raw['Cost Value']?.toString() ?? '0') ?? 0.0,
            sellingValue: double.tryParse(raw['Selling Value']?.toString() ?? '0') ?? 0.0,
            expectedProfit: double.tryParse(raw['Expected Profit']?.toString() ?? '0') ?? 0.0,
          ));
        }
        break;
      case InventoryReportType.expiry:
        for (final raw in rawRows) {
          testRows.add(ExpiryRow(
            itemName: raw['Item Name']?.toString() ?? '-',
            batchNo: raw['Batch No']?.toString() ?? '-',
            expiryDate: raw['Expiry Date']?.toString() ?? '-',
            quantity: int.tryParse(raw['Quantity']?.toString() ?? '0') ?? 0,
            daysExpired: int.tryParse(raw['Days Expired']?.toString() ?? '0') ?? 0,
          ));
        }
        break;
      case InventoryReportType.nearExpiry:
        for (final raw in rawRows) {
          testRows.add(NearExpiryRow(
            itemName: raw['Item Name']?.toString() ?? '-',
            batchNo: raw['Batch No']?.toString() ?? '-',
            expiryDate: raw['Expiry Date']?.toString() ?? '-',
            quantity: int.tryParse(raw['Quantity']?.toString() ?? '0') ?? 0,
            daysRemaining: int.tryParse(raw['Days Remaining']?.toString() ?? '0') ?? 0,
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
      case InventoryReportType.currentStock:
        int totalItems = _fullRows.length;
        int totalQty = 0;
        double totalVal = 0;
        for (final r in _fullRows.cast<CurrentStockRow>()) {
          totalQty += r.quantity;
          totalVal += r.stockValue;
        }
        rxSummaryCards.assignAll([
          InventorySummaryCardData(
            label: 'Total Unique Items',
            value: totalItems.toString(),
            icon: Icons.inventory_2_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
          InventorySummaryCardData(
            label: 'Total Quantity',
            value: totalQty.toString(),
            icon: Icons.format_list_numbered_rounded,
            gradientColors: [Colors.teal.shade500, Colors.green.shade500],
          ),
          InventorySummaryCardData(
            label: 'Total Stock Value',
            value: _currFmt.format(totalVal),
            icon: Icons.account_balance_wallet_rounded,
            gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
          ),
        ]);
        break;
      case InventoryReportType.lowStock:
        int totalShortage = 0;
        for (final r in _fullRows.cast<LowStockRow>()) {
          totalShortage += r.shortage;
        }
        rxSummaryCards.assignAll([
          InventorySummaryCardData(
            label: 'Low Stock Items',
            value: _fullRows.length.toString(),
            icon: Icons.warning_amber_rounded,
            gradientColors: [Colors.orange.shade600, Colors.red.shade400],
          ),
          InventorySummaryCardData(
            label: 'Total Shortage Qty',
            value: totalShortage.toString(),
            icon: Icons.trending_down_rounded,
            gradientColors: [Colors.red.shade500, Colors.pink.shade500],
          ),
        ]);
        break;
      case InventoryReportType.outOfStock:
        rxSummaryCards.assignAll([
          InventorySummaryCardData(
            label: 'Out of Stock Items',
            value: _fullRows.length.toString(),
            icon: Icons.production_quantity_limits_rounded,
            gradientColors: [Colors.red.shade600, Colors.pink.shade600],
          ),
        ]);
        break;
      case InventoryReportType.stockMovement:
        int totalMovement = 0;
        for (final r in _fullRows.cast<StockMovementRow>()) {
          totalMovement += r.quantity.abs();
        }
        rxSummaryCards.assignAll([
          InventorySummaryCardData(
            label: 'Total Txns',
            value: _fullRows.length.toString(),
            icon: Icons.swap_vert_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
          InventorySummaryCardData(
            label: 'Total Qty Moved',
            value: totalMovement.toString(),
            icon: Icons.move_to_inbox_rounded,
            gradientColors: [Colors.teal.shade500, Colors.green.shade500],
          ),
        ]);
        break;
      case InventoryReportType.stockAdjustment:
        int totalDiff = 0;
        for (final r in _fullRows.cast<StockAdjustmentRow>()) {
          totalDiff += r.difference;
        }
        rxSummaryCards.assignAll([
          InventorySummaryCardData(
            label: 'Total Adjustments',
            value: _fullRows.length.toString(),
            icon: Icons.edit_note_rounded,
            gradientColors: [Colors.purple.shade500, Colors.indigo.shade500],
          ),
          InventorySummaryCardData(
            label: 'Net Qty Diff',
            value: totalDiff.toString(),
            icon: Icons.tune_rounded,
            gradientColors: [Colors.teal.shade500, Colors.blue.shade500],
          ),
        ]);
        break;
      case InventoryReportType.stockValuation:
        double totalCost = 0, totalRetail = 0, totalProfit = 0;
        for (final r in _fullRows.cast<StockValuationRow>()) {
          totalCost += r.costValue;
          totalRetail += r.sellingValue;
          totalProfit += r.expectedProfit;
        }
        rxSummaryCards.assignAll([
          InventorySummaryCardData(
            label: 'Total Cost Value',
            value: _currFmt.format(totalCost),
            icon: Icons.payments_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
          InventorySummaryCardData(
            label: 'Total Retail Value',
            value: _currFmt.format(totalRetail),
            icon: Icons.storefront_rounded,
            gradientColors: [Colors.teal.shade500, Colors.green.shade500],
          ),
          InventorySummaryCardData(
            label: 'Expected Profit',
            value: _currFmt.format(totalProfit),
            icon: Icons.trending_up_rounded,
            gradientColors: [Colors.green.shade600, Colors.teal.shade400],
          ),
        ]);
        break;
      case InventoryReportType.expiry:
        int totalExpired = 0;
        for (final r in _fullRows.cast<ExpiryRow>()) {
          totalExpired += r.quantity;
        }
        rxSummaryCards.assignAll([
          InventorySummaryCardData(
            label: 'Expired Batches',
            value: _fullRows.length.toString(),
            icon: Icons.event_busy_rounded,
            gradientColors: [Colors.red.shade600, Colors.orange.shade600],
          ),
          InventorySummaryCardData(
            label: 'Total Expired Qty',
            value: totalExpired.toString(),
            icon: Icons.delete_sweep_rounded,
            gradientColors: [Colors.red.shade500, Colors.pink.shade500],
          ),
        ]);
        break;
      case InventoryReportType.nearExpiry:
        int totalNearExpiry = 0;
        for (final r in _fullRows.cast<NearExpiryRow>()) {
          totalNearExpiry += r.quantity;
        }
        rxSummaryCards.assignAll([
          InventorySummaryCardData(
            label: 'Near Expiry Batches',
            value: _fullRows.length.toString(),
            icon: Icons.notification_important_rounded,
            gradientColors: [Colors.amber.shade600, Colors.orange.shade500],
          ),
          InventorySummaryCardData(
            label: 'Near Expiry Qty',
            value: totalNearExpiry.toString(),
            icon: Icons.inventory_rounded,
            gradientColors: [Colors.orange.shade500, Colors.red.shade400],
          ),
        ]);
        break;
    }
  }

  void exportPdf() async {
    final type = rxReportType.value;
    final reportTitle = 'Inventory Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final filters = <String, String>{
      'Report Type': type.label,
      'Warehouse/Branch': rxBranch.value,
    };
    if (type == InventoryReportType.stockMovement ||
        type == InventoryReportType.stockAdjustment ||
        type == InventoryReportType.expiry ||
        type == InventoryReportType.nearExpiry) {
      final fmt = DateFormat('dd MMM yyyy');
      filters['Date Range'] = '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}';
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
      case InventoryReportType.currentStock:
        headers = ['SKU/Barcode', 'Name', 'Category', 'Unit', 'Quantity', 'Cost Price', 'Selling Price', 'Stock Value'];
        for (final r in allRows) {
          if (r is CurrentStockRow) {
            exportRows.add([r.sku, r.name, r.category, r.unit, r.quantity, r.costPrice, r.sellingPrice, r.stockValue]);
          }
        }
        break;
      case InventoryReportType.lowStock:
        headers = ['SKU/Barcode', 'Name', 'Category', 'Current Qty', 'Reorder Level', 'Shortage'];
        for (final r in allRows) {
          if (r is LowStockRow) {
            exportRows.add([r.sku, r.name, r.category, r.quantity, r.reorderLevel, r.shortage]);
          }
        }
        break;
      case InventoryReportType.outOfStock:
        headers = ['SKU/Barcode', 'Name', 'Category', 'Cost Price', 'Last Purchase', 'Last Sale'];
        for (final r in allRows) {
          if (r is OutOfStockRow) {
            exportRows.add([r.sku, r.name, r.category, r.costPrice, r.lastPurchaseInfo, r.lastSaleInfo]);
          }
        }
        break;
      case InventoryReportType.stockMovement:
        headers = ['Date & Time', 'Item Name', 'Type', 'Quantity', 'Performed By', 'Reference/Remarks'];
        for (final r in allRows) {
          if (r is StockMovementRow) {
            exportRows.add([r.dateTime, r.itemName, r.txnType, r.quantity, r.performedBy, r.reference]);
          }
        }
        break;
      case InventoryReportType.stockAdjustment:
        headers = ['Date & Time', 'Item Name', 'Prev Qty', 'New Qty', 'Difference', 'Reason', 'User'];
        for (final r in allRows) {
          if (r is StockAdjustmentRow) {
            exportRows.add([r.dateTime, r.itemName, r.previousQty, r.newQty, r.difference, r.reason, r.user]);
          }
        }
        break;
      case InventoryReportType.stockValuation:
        headers = ['SKU/Barcode', 'Name', 'Quantity', 'Cost Price', 'Selling Price', 'Cost Value', 'Selling Value', 'Expected Profit'];
        for (final r in allRows) {
          if (r is StockValuationRow) {
            exportRows.add([r.sku, r.name, r.quantity, r.costPrice, r.sellingPrice, r.costValue, r.sellingValue, r.expectedProfit]);
          }
        }
        break;
      case InventoryReportType.expiry:
        headers = ['Item Name', 'Batch No', 'Expiry Date', 'Quantity', 'Days Expired'];
        for (final r in allRows) {
          if (r is ExpiryRow) {
            exportRows.add([r.itemName, r.batchNo, r.expiryDate, r.quantity, r.daysExpired]);
          }
        }
        break;
      case InventoryReportType.nearExpiry:
        headers = ['Item Name', 'Batch No', 'Expiry Date', 'Quantity', 'Days Remaining'];
        for (final r in allRows) {
          if (r is NearExpiryRow) {
            exportRows.add([r.itemName, r.batchNo, r.expiryDate, r.quantity, r.daysRemaining]);
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
