import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';

import '../../../../../enums/enum_purchase_status.dart';
import '../../../../../enums/enum_stock_txn_type.dart';
import '../../../../../model/entity_item.dart';
import '../../../../../model/entity_item_batch.dart';
import '../../../../../model/entity_purchase.dart';
import '../../../../../model/entity_purchase_item.dart';
import '../../../../../model/entity_stock_transaction.dart';
import '../../../../../model/entity_supplier.dart';
import '../../../../../objectbox.g.dart';
import '../../../../../service/service_object_box.dart';

class ControllerHomePurchase extends GetxController {
  late final Box<EntityPurchase> _boxPurchase;
  late final Box<EntityPurchaseItem> _boxPurchaseItem;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityItemBatch> _boxBatch;
  late final Box<EntityStockTransaction> _boxStockTxn;
  late final Box<EntitySupplier> _boxSupplier;

  final RxList<EntityPurchase> rxListPurchase = <EntityPurchase>[].obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // ── Filter ──
  final Rx<PurchaseStatus?> filterStatus = Rx<PurchaseStatus?>(null);

  // ── Pagination ──
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxPurchase = ob.box<EntityPurchase>();
    _boxPurchaseItem = ob.box<EntityPurchaseItem>();
    _boxItem = ob.box<EntityItem>();
    _boxBatch = ob.box<EntityItemBatch>();
    _boxStockTxn = ob.box<EntityStockTransaction>();
    _boxSupplier = ob.box<EntitySupplier>();

    loadPurchases();

    debounce(
      searchQuery,
          (_) {
        currentPage.value = 0;
        loadPurchases();
      },
      time: const Duration(milliseconds: 300),
    );
  }

  // ─────────────────────────────────────────────
  //  LOAD
  // ─────────────────────────────────────────────

  void loadPurchases() {
    final q = searchQuery.value.trim();
    Condition<EntityPurchase>? condition;

    if (q.isNotEmpty) {
      condition = EntityPurchase_.purchaseNo
          .contains(q, caseSensitive: false)
          .or(EntityPurchase_.supplierName.contains(q, caseSensitive: false));
    }

    if (filterStatus.value != null) {
      final statusCondition =
      EntityPurchase_.status.equals(filterStatus.value!.index);
      condition =
      condition != null ? condition.and(statusCondition) : statusCondition;
    }

    final builder = condition != null
        ? _boxPurchase.query(condition)
        : _boxPurchase.query();

    builder.order(EntityPurchase_.createdAtUtcMs, flags: Order.descending);

    final query = builder.build();
    totalCount.value = query.count();
    query
      ..offset = currentPage.value * _pageSize
      ..limit = _pageSize;

    rxListPurchase.assignAll(query.find());
    query.close();
  }

  void updateSearch(String val) => searchQuery.value = val;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 0;
    loadPurchases();
  }

  void setStatusFilter(PurchaseStatus? status) {
    filterStatus.value = status;
    currentPage.value = 0;
    loadPurchases();
  }

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      loadPurchases();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      loadPurchases();
    }
  }

  // ─────────────────────────────────────────────
  //  GET ITEMS FOR A PURCHASE
  // ─────────────────────────────────────────────

  List<EntityPurchaseItem> getItemsForPurchase(int purchaseId) {
    return _boxPurchaseItem
        .query(EntityPurchaseItem_.purchaseId.equals(purchaseId))
        .build()
        .find();
  }

  // ─────────────────────────────────────────────
  //  CREATE PURCHASE
  // ─────────────────────────────────────────────

  /// Creates a full purchase with its items atomically.
  /// Returns error string or null on success.
  String? createPurchase({
    required int supplierId,
    required String supplierName,
    required DateTime purchaseDate,
    DateTime? expectedDate,
    required List<_PurchaseItemInput> items,
    int? createdByUserId,
  }) {
    if (items.isEmpty) return 'At least one item is required';
    for (final item in items) {
      if (item.orderedQty <= 0) return 'Quantity must be greater than 0';
      if (item.unitCost <= 0) return 'Unit cost must be greater than 0';
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final purchaseNo = _generatePurchaseNo();
    final totalAmount =
    items.fold(0.0, (sum, i) => sum + i.orderedQty * i.unitCost);

    final purchase = EntityPurchase(
      purchaseNo: purchaseNo,
      supplierId: supplierId,
      supplierName: supplierName,
      purchaseDateUtcMs: purchaseDate.toUtc().millisecondsSinceEpoch,
      expectedDateUtcMs: expectedDate?.toUtc().millisecondsSinceEpoch,
      status: PurchaseStatus.ordered.index,
      totalAmount: totalAmount,
      createdByUserId: createdByUserId,
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );

    final purchaseId = _boxPurchase.put(purchase);

    for (final input in items) {
      final pi = EntityPurchaseItem(
        purchaseId: purchaseId,
        itemId: input.itemId,
        itemName: input.itemName,
        itemUnit: input.itemUnit,
        orderedQty: input.orderedQty,
        unitCost: input.unitCost,
        receivedQty: 0,
      );
      _boxPurchaseItem.put(pi);
    }

    loadPurchases();
    return null;
  }

  // ─────────────────────────────────────────────
  //  RECEIVE GOODS  ← CORE OPERATION
  // ─────────────────────────────────────────────

  /// Called when goods physically arrive at the store.
  /// For each received item this method:
  ///   1. Creates StockTransaction (purchaseIn) — source of truth
  ///   2. Creates ItemBatch if item.hasExpiry == true
  ///   3. Updates EntityItem.totalQty (cache)
  ///   4. Updates PurchaseItem.receivedQty
  ///   5. Updates Purchase.status (PARTIAL / RECEIVED)
  ///
  /// Returns error string or null on success.
  String? receiveGoods({
    required EntityPurchase purchase,
    required List<_ReceiveItemInput> receivedItems,
    int? performedByUserId,
  }) {
    if (receivedItems.isEmpty) return 'No items provided';
    for (final r in receivedItems) {
      if (r.receivedQty <= 0) return 'Received qty must be > 0';
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final allPurchaseItems = getItemsForPurchase(purchase.id);

    for (final r in receivedItems) {
      // ── 1. StockTransaction ──
      _boxStockTxn.put(EntityStockTransaction(
        itemId: r.itemId,
        type: StockTxnType.purchaseIn.index,
        quantity: r.receivedQty,
        referenceType: 'purchase',
        referenceId: purchase.id.toString(),
        remarks: 'Received via ${purchase.purchaseNo}',
        performedByUserId: performedByUserId,
        createdAtUtcMs: now,
      ));

      // ── 2. ItemBatch (only if hasExpiry) ──
      final item = _boxItem.get(r.itemId);
      if (item != null && (item.hasExpiry ?? false)) {
        _boxBatch.put(EntityItemBatch(
          itemId: r.itemId,
          batchNo: r.batchNo,
          expiryDateUtcMs: r.expiryDateUtcMs,
          quantity: r.receivedQty,
          receivedAtUtcMs: now,
        ));
      }

      // ── 3. Update item totalQty cache ──
      if (item != null) {
        item.totalQty = (item.totalQty ?? 0) + r.receivedQty;
        item.updatedAtUtcMs = now;
        _boxItem.put(item);
      }

      // ── 4. Update PurchaseItem.receivedQty ──
      final purchaseItem = allPurchaseItems
          .where((pi) => pi.itemId == r.itemId)
          .firstOrNull;
      if (purchaseItem != null) {
        purchaseItem.receivedQty =
            (purchaseItem.receivedQty ?? 0) + r.receivedQty;
        _boxPurchaseItem.put(purchaseItem);
      }
    }

    // ── 5. Auto-update purchase status ──
    _updatePurchaseStatus(purchase);
    loadPurchases();
    return null;
  }

  // ─────────────────────────────────────────────
  //  CANCEL PURCHASE
  // ─────────────────────────────────────────────

  void cancelPurchase(EntityPurchase purchase) {
    purchase.status = PurchaseStatus.cancelled.index;
    purchase.updatedAtUtcMs =
        DateTime.now().toUtc().millisecondsSinceEpoch;
    _boxPurchase.put(purchase);
    loadPurchases();
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  void _updatePurchaseStatus(EntityPurchase purchase) {
    final items = getItemsForPurchase(purchase.id);
    if (items.isEmpty) return;

    final allReceived = items.every((i) => i.isFullyReceived);
    final anyReceived = items.any((i) => (i.receivedQty ?? 0) > 0);

    purchase.status = allReceived
        ? PurchaseStatus.received.index
        : anyReceived
        ? PurchaseStatus.partial.index
        : purchase.status;

    purchase.updatedAtUtcMs =
        DateTime.now().toUtc().millisecondsSinceEpoch;
    _boxPurchase.put(purchase);
  }

  String _generatePurchaseNo() {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final prefix = 'PO-$date-';

    // Count purchases created today
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).toUtc().millisecondsSinceEpoch;

    final count = _boxPurchase
        .query(EntityPurchase_.createdAtUtcMs.greaterOrEqual(todayStart))
        .build()
        .count();

    final seq = (count + 1).toString().padLeft(3, '0');
    return '$prefix$seq';
  }

  List<EntitySupplier> getAllActiveSuppliers() {
    return _boxSupplier
        .query(EntitySupplier_.isActive.equals(true))
        .order(EntitySupplier_.name)
        .build()
        .find();
  }

  List<EntityItem> getAllActiveItems() {
    return _boxItem
        .query(EntityItem_.isActive.equals(true))
        .order(EntityItem_.name)
        .build()
        .find();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

// ─────────────────────────────────────────────
//  INPUT DATA CLASSES
// ─────────────────────────────────────────────

class _PurchaseItemInput {
  final int itemId;
  final String itemName;
  final String? itemUnit;
  final double orderedQty;
  final double unitCost;

  _PurchaseItemInput({
    required this.itemId,
    required this.itemName,
    this.itemUnit,
    required this.orderedQty,
    required this.unitCost,
  });
}

class _ReceiveItemInput {
  final int itemId;
  final int receivedQty;
  final String? batchNo;
  final int? expiryDateUtcMs;

  _ReceiveItemInput({
    required this.itemId,
    required this.receivedQty,
    this.batchNo,
    this.expiryDateUtcMs,
  });
}

// Public aliases so screens can use them directly
typedef PurchaseItemInput = _PurchaseItemInput;
typedef ReceiveItemInput = _ReceiveItemInput;
