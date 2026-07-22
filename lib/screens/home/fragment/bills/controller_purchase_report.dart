import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../model/entity_purchase_item.dart';
import '../../../../model/entity_supplier.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Purchase Report Types
// ═══════════════════════════════════════════════════════════════════════════

enum PurchaseReportType {
  purchaseSummary,
  purchaseDetail,
  supplierPurchase,
  pendingPurchaseOrders,
  purchaseReturn,
}

extension PurchaseReportTypeLabel on PurchaseReportType {
  String get label => switch (this) {
    PurchaseReportType.purchaseSummary         => 'Purchase Summary',
    PurchaseReportType.purchaseDetail          => 'Purchase Detail',
    PurchaseReportType.supplierPurchase        => 'Supplier Purchase',
    PurchaseReportType.pendingPurchaseOrders   => 'Pending Purchase Orders',
    PurchaseReportType.purchaseReturn           => 'Purchase Return',
  };

  IconData get icon => switch (this) {
    PurchaseReportType.purchaseSummary         => Icons.summarize_rounded,
    PurchaseReportType.purchaseDetail          => Icons.receipt_long_rounded,
    PurchaseReportType.supplierPurchase        => Icons.local_shipping_rounded,
    PurchaseReportType.pendingPurchaseOrders   => Icons.pending_actions_rounded,
    PurchaseReportType.purchaseReturn           => Icons.assignment_return_rounded,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Row Models
// ═══════════════════════════════════════════════════════════════════════════

class PurchaseSummaryRow {
  final String date;
  final String purchaseNo;
  final String supplierName;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String status;
  PurchaseSummaryRow({
    required this.date,
    required this.purchaseNo,
    required this.supplierName,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.status,
  });
}

class PurchaseDetailRow {
  final String date;
  final String purchaseNo;
  final String supplierName;
  final String itemName;
  final double quantity;
  final double costPrice;
  final double totalValue;
  PurchaseDetailRow({
    required this.date,
    required this.purchaseNo,
    required this.supplierName,
    required this.itemName,
    required this.quantity,
    required this.costPrice,
    required this.totalValue,
  });
}

class SupplierPurchaseRow {
  final String supplierName;
  final int numBills;
  final double qtyPurchased;
  final double totalPurchaseAmount;
  final double paidAmount;
  final double outstandingBalance;
  SupplierPurchaseRow({
    required this.supplierName,
    required this.numBills,
    required this.qtyPurchased,
    required this.totalPurchaseAmount,
    required this.paidAmount,
    required this.outstandingBalance,
  });
}

class PendingPurchaseOrderRow {
  final String date;
  final String purchaseNo;
  final String supplierName;
  final String expectedDate;
  final double orderedQty;
  final double receivedQty;
  final double pendingQty;
  final String status;
  PendingPurchaseOrderRow({
    required this.date,
    required this.purchaseNo,
    required this.supplierName,
    required this.expectedDate,
    required this.orderedQty,
    required this.receivedQty,
    required this.pendingQty,
    required this.status,
  });
}

class PurchaseReturnRow {
  final String returnNo;
  final String date;
  final String supplierName;
  final String itemName;
  final double quantityReturned;
  final double returnAmount;
  final String returnReason;
  PurchaseReturnRow({
    required this.returnNo,
    required this.date,
    required this.supplierName,
    required this.itemName,
    required this.quantityReturned,
    required this.returnAmount,
    required this.returnReason,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary Card Model
// ═══════════════════════════════════════════════════════════════════════════

class PurchaseSummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  PurchaseSummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════════════

class ControllerPurchaseReport extends GetxController {
  late final Box<EntityPurchase> _boxPurchase;
  late final Box<EntityPurchaseItem> _boxPurchaseItem;
  late final Box<EntitySupplier> _boxSupplier;

  // Report Type
  final Rx<PurchaseReportType> rxReportType = PurchaseReportType.purchaseSummary.obs;

  // Filters & State
  final RxString rxSearchQuery = ''.obs;
  Worker? _searchWorker;

  static const int _pageSize = 25;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  final RxString rxBranch = 'All Branches'.obs;
  final Rxn<int> rxSelectedSupplierId = Rxn<int>(); // Supplier filter

  // Date Range Filters
  final Rx<DateTime> rxStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> rxEndDate = DateTime.now().obs;

  // Loaded Lists for Dropdowns
  final RxList<EntitySupplier> rxSuppliersList = <EntitySupplier>[].obs;

  // Data Observables
  final RxList<dynamic> rxRows = <dynamic>[].obs;
  final RxList<PurchaseSummaryCardData> rxSummaryCards = <PurchaseSummaryCardData>[].obs;
  final RxBool rxLoading = false.obs;

  // Internal full data lists
  List<dynamic> _fullRows = [];

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxPurchase = ob.box<EntityPurchase>();
    _boxPurchaseItem = ob.box<EntityPurchaseItem>();
    _boxSupplier = ob.box<EntitySupplier>();

    _loadSuppliersDropdown();
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

  void setReportType(PurchaseReportType type) {
    rxReportType.value = type;
    currentPage.value = 0;
    loadData();
  }

  void setSearchQuery(String q) => rxSearchQuery.value = q;

  void setSelectedSupplier(int? supplierId) {
    rxSelectedSupplierId.value = supplierId;
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
  // Load Dropdowns
  // ═════════════════════════════════════════════════════════════════════════

  void _loadSuppliersDropdown() {
    final list = _boxSupplier.getAll();
    rxSuppliersList.assignAll(list);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Data Load
  // ═════════════════════════════════════════════════════════════════════════

  void loadData() {
    rxLoading.value = true;
    currentPage.value = 0;

    switch (rxReportType.value) {
      case PurchaseReportType.purchaseSummary:
        _loadPurchaseSummary();
        break;
      case PurchaseReportType.purchaseDetail:
        _loadPurchaseDetail();
        break;
      case PurchaseReportType.supplierPurchase:
        _loadSupplierPurchase();
        break;
      case PurchaseReportType.pendingPurchaseOrders:
        _loadPendingPurchaseOrders();
        break;
      case PurchaseReportType.purchaseReturn:
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

  // ── Helper to convert Status Index to String ──
  String _getStatusLabel(int? statusIndex) {
    return switch (statusIndex) {
      0 => 'DRAFT',
      1 => 'ORDERED',
      2 => 'PARTIAL',
      3 => 'RECEIVED',
      4 => 'CANCELLED',
      _ => 'UNKNOWN',
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. Purchase Summary Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadPurchaseSummary() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // Query purchases
    Condition<EntityPurchase> cond = EntityPurchase_.purchaseDateUtcMs.between(startMs, endMs);
    if (rxSelectedSupplierId.value != null) {
      cond = cond.and(EntityPurchase_.supplierId.equals(rxSelectedSupplierId.value!));
    }

    final queryBuilder = _boxPurchase.query(cond);
    queryBuilder.order(EntityPurchase_.purchaseDateUtcMs, flags: Order.descending);
    final query = queryBuilder.build();
    final purchases = query.find();
    query.close();

    final rows = <PurchaseSummaryRow>[];
    final df = DateFormat('dd/MM/yyyy');

    double totalPurchases = 0.0;
    double totalPaid = 0.0;
    double totalOutstanding = 0.0;

    for (final p in purchases) {
      final amt = p.totalAmount ?? 0.0;
      final paid = p.amountPaid ?? 0.0;
      final outstanding = p.outstandingAmount;
      final dateStr = p.purchaseDateUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(p.purchaseDateUtcMs!))
          : '-';

      rows.add(PurchaseSummaryRow(
        date: dateStr,
        purchaseNo: p.purchaseNo ?? '-',
        supplierName: p.supplierName ?? 'Unknown Supplier',
        totalAmount: amt,
        paidAmount: paid,
        outstandingAmount: outstanding,
        status: _getStatusLabel(p.status),
      ));

      if (p.status != 4) { // Exclude cancelled from totals
        totalPurchases += amt;
        totalPaid += paid;
        totalOutstanding += outstanding;
      }
    }

    _fullRows = _filterSearch(rows, (r) => '${r.purchaseNo} ${r.supplierName}');

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      PurchaseSummaryCardData(
        label: 'Total Orders',
        value: totalPurchases > 0 ? purchases.length.toString() : '0',
        icon: Icons.shopping_bag_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Total Purchased',
        value: currFmt.format(totalPurchases),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Paid Amount',
        value: currFmt.format(totalPaid),
        icon: Icons.check_circle_outline_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Outstanding Due',
        value: currFmt.format(totalOutstanding),
        icon: Icons.pending_actions_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Purchase Detail Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadPurchaseDetail() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // Query purchases
    Condition<EntityPurchase> cond = EntityPurchase_.purchaseDateUtcMs.between(startMs, endMs);
    if (rxSelectedSupplierId.value != null) {
      cond = cond.and(EntityPurchase_.supplierId.equals(rxSelectedSupplierId.value!));
    }

    final queryBuilder = _boxPurchase.query(cond);
    final query = queryBuilder.build();
    final purchases = query.find();
    query.close();

    final rows = <PurchaseDetailRow>[];
    final df = DateFormat('dd/MM/yyyy');

    double totalVolume = 0.0;
    double totalDetailValue = 0.0;
    double maxLineValue = 0.0;
    String maxLineItem = '-';

    for (final p in purchases) {
      // Find items in purchase order
      final itemsQuery = _boxPurchaseItem.query(EntityPurchaseItem_.purchaseId.equals(p.id)).build();
      final items = itemsQuery.find();
      itemsQuery.close();

      final dateStr = p.purchaseDateUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(p.purchaseDateUtcMs!))
          : '-';

      for (final item in items) {
        final qty = item.orderedQty ?? 0.0;
        final cost = item.unitCost ?? 0.0;
        final total = item.lineTotal;

        rows.add(PurchaseDetailRow(
          date: dateStr,
          purchaseNo: p.purchaseNo ?? '-',
          supplierName: p.supplierName ?? 'Unknown Supplier',
          itemName: item.itemName ?? 'Unknown Item',
          quantity: qty,
          costPrice: cost,
          totalValue: total,
        ));

        totalVolume += qty;
        totalDetailValue += total;

        if (total > maxLineValue) {
          maxLineValue = total;
          maxLineItem = item.itemName ?? '-';
        }
      }
    }

    _fullRows = _filterSearch(rows, (r) => '${r.purchaseNo} ${r.supplierName} ${r.itemName}');

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      PurchaseSummaryCardData(
        label: 'Total Items Qty',
        value: totalVolume.toString(),
        icon: Icons.inventory_2_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Total Cost Value',
        value: currFmt.format(totalDetailValue),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Highest Line Value',
        value: currFmt.format(maxLineValue),
        icon: Icons.trending_up_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Top Cost Item',
        value: maxLineItem.length > 12 ? '${maxLineItem.substring(0, 12)}…' : maxLineItem,
        icon: Icons.info_outline_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Supplier Purchase Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadSupplierPurchase() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // Query purchases
    Condition<EntityPurchase> cond = EntityPurchase_.purchaseDateUtcMs.between(startMs, endMs);
    if (rxSelectedSupplierId.value != null) {
      cond = cond.and(EntityPurchase_.supplierId.equals(rxSelectedSupplierId.value!));
    }

    final queryBuilder = _boxPurchase.query(cond);
    final query = queryBuilder.build();
    final purchases = query.find();
    query.close();

    final Map<String, _SupplierAgg> agg = {};

    for (final p in purchases) {
      final name = p.supplierName ?? 'Unknown Supplier';
      
      // Load PO items to count quantities
      final itemsQuery = _boxPurchaseItem.query(EntityPurchaseItem_.purchaseId.equals(p.id)).build();
      final items = itemsQuery.find();
      itemsQuery.close();

      double sumQty = 0.0;
      for (final item in items) {
        sumQty += (item.orderedQty ?? 0.0);
      }

      final existing = agg[name];
      if (existing != null) {
        existing.numBills++;
        existing.qtyPurchased += sumQty;
        existing.totalPurchaseAmount += (p.totalAmount ?? 0.0);
        existing.paidAmount += (p.amountPaid ?? 0.0);
        existing.outstandingBalance += p.outstandingAmount;
      } else {
        agg[name] = _SupplierAgg(
          numBills: 1,
          qtyPurchased: sumQty,
          totalPurchaseAmount: (p.totalAmount ?? 0.0),
          paidAmount: (p.amountPaid ?? 0.0),
          outstandingBalance: p.outstandingAmount,
        );
      }
    }

    final rows = <SupplierPurchaseRow>[];
    double totalSpend = 0.0;
    double totalOutstanding = 0.0;
    String topSupplier = '-';
    double maxSpend = 0.0;

    for (final entry in agg.entries) {
      final val = entry.value;
      rows.add(SupplierPurchaseRow(
        supplierName: entry.key,
        numBills: val.numBills,
        qtyPurchased: val.qtyPurchased,
        totalPurchaseAmount: val.totalPurchaseAmount,
        paidAmount: val.paidAmount,
        outstandingBalance: val.outstandingBalance,
      ));

      totalSpend += val.totalPurchaseAmount;
      totalOutstanding += val.outstandingBalance;

      if (val.totalPurchaseAmount > maxSpend) {
        maxSpend = val.totalPurchaseAmount;
        topSupplier = entry.key;
      }
    }

    _fullRows = _filterSearch(rows, (r) => r.supplierName);

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      PurchaseSummaryCardData(
        label: 'Active Suppliers',
        value: agg.length.toString(),
        icon: Icons.local_shipping_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Total Cost Spent',
        value: currFmt.format(totalSpend),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Total Outstanding',
        value: currFmt.format(totalOutstanding),
        icon: Icons.pending_actions_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Top Supplier',
        value: topSupplier.length > 12 ? '${topSupplier.substring(0, 12)}…' : topSupplier,
        icon: Icons.emoji_events_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. Pending Purchase Orders Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadPendingPurchaseOrders() {
    // Pending: status == 1 (ordered) or status == 2 (partial)
    Condition<EntityPurchase> cond = EntityPurchase_.status.oneOf([1, 2]);
    if (rxSelectedSupplierId.value != null) {
      cond = cond.and(EntityPurchase_.supplierId.equals(rxSelectedSupplierId.value!));
    }

    final queryBuilder = _boxPurchase.query(cond);
    final query = queryBuilder.build();
    final pendingPOs = query.find();
    query.close();

    final rows = <PendingPurchaseOrderRow>[];
    final df = DateFormat('dd/MM/yyyy');

    int pendingCount = 0;
    double totalPendingQty = 0.0;
    double expectedPendingValue = 0.0;

    for (final p in pendingPOs) {
      // Find items in purchase order to sum ordered / received / pending
      final itemsQuery = _boxPurchaseItem.query(EntityPurchaseItem_.purchaseId.equals(p.id)).build();
      final items = itemsQuery.find();
      itemsQuery.close();

      double sumOrdered = 0.0;
      double sumReceived = 0.0;
      double sumPending = 0.0;

      for (final item in items) {
        final ord = item.orderedQty ?? 0.0;
        final rec = item.receivedQty ?? 0.0;
        final pend = item.pendingQty;

        sumOrdered += ord;
        sumReceived += rec;
        sumPending += pend;

        // Pending valuation cost
        expectedPendingValue += pend * (item.unitCost ?? 0.0);
      }

      final dateStr = p.purchaseDateUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(p.purchaseDateUtcMs!))
          : '-';

      final expDateStr = p.expectedDateUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(p.expectedDateUtcMs!))
          : 'Not specified';

      rows.add(PendingPurchaseOrderRow(
        date: dateStr,
        purchaseNo: p.purchaseNo ?? '-',
        supplierName: p.supplierName ?? 'Unknown Supplier',
        expectedDate: expDateStr,
        orderedQty: sumOrdered,
        receivedQty: sumReceived,
        pendingQty: sumPending,
        status: _getStatusLabel(p.status),
      ));

      pendingCount++;
      totalPendingQty += sumPending;
    }

    _fullRows = _filterSearch(rows, (r) => '${r.purchaseNo} ${r.supplierName}');

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      PurchaseSummaryCardData(
        label: 'Pending POs',
        value: pendingCount.toString(),
        icon: Icons.pending_actions_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Pending Items Qty',
        value: totalPendingQty.toString(),
        icon: Icons.inventory_2_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Expected Cost Value',
        value: currFmt.format(expectedPendingValue),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Fulfillment Rate',
        value: pendingCount > 0 ? 'PARTIAL' : 'COMPLETE',
        icon: Icons.playlist_add_check_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 5. Purchase Return Builder (Removed Mock data, empty state shown if none)
  // ═════════════════════════════════════════════════════════════════════════

  void _loadPurchaseReturn() {
    // In our ObjectBox database, there is no separate EntityPurchaseReturn.
    // Querying empty list as requested.
    final rows = <PurchaseReturnRow>[];
    _fullRows = rows;

    rxSummaryCards.assignAll([
      PurchaseSummaryCardData(
        label: 'Returned Bills',
        value: '0',
        icon: Icons.assignment_return_rounded,
        gradientColors: [Colors.red.shade500, Colors.orange.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Returned Qty',
        value: '0',
        icon: Icons.remove_circle_outline_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Credit Amount',
        value: '₹0.00',
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      PurchaseSummaryCardData(
        label: 'Return Rate',
        value: '0.0%',
        icon: Icons.pie_chart_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ── Export stubs ──
  void exportExcel() {
    Get.snackbar(
      'Export Excel',
      'Purchase Excel export coming soon',
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
      'Purchase PDF export coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }
}

// ── Aggregation structure ──
class _SupplierAgg {
  int numBills;
  double qtyPurchased;
  double totalPurchaseAmount;
  double paidAmount;
  double outstandingBalance;
  _SupplierAgg({
    required this.numBills,
    required this.qtyPurchased,
    required this.totalPurchaseAmount,
    required this.paidAmount,
    required this.outstandingBalance,
  });
}
