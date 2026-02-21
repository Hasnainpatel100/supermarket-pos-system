import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../model/entity_stock_transaction.dart';
import '../../../../model/stock_txn_type.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_currency.dart';
import '../../../../service/service_item.dart';
import '../../../../service/service_object_box.dart';

class ControllerHomeItem extends GetxController {
  final ServiceCurrency serviceCurrency = Get.find();
  late final ItemService _itemService;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityItemBatch> _boxBatch;
  late final Box<EntityStockTransaction> _boxStockTxn;

  final RxList<EntityItem> rxListItem = <EntityItem>[].obs;
  final RxString searchQuery = ''.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    final ob = Get.find<ServiceObjectBox>();
    _boxItem = ob.box<EntityItem>();
    _boxBatch = ob.box<EntityItemBatch>();
    _boxStockTxn = ob.box<EntityStockTransaction>();
    _itemService = ItemService(_boxItem);
    loadItems();
    super.onInit();
  }

  /// Load all items
  void loadItems() {
    if (searchQuery.value.trim().isEmpty) {
      rxListItem.value = _itemService.getAllItems();
    } else {
      rxListItem.value = _itemService.searchItems(searchQuery.value);
    }
    debugPrint("loadItems size: ${rxListItem.length}");
  }

  /// Update search and refresh list
  void updateSearch(String query) {
    searchQuery.value = query;
    loadItems();
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    loadItems();
  }

  /// Adjust stock quantity (positive = increment, negative = decrement)
  /// Kept for backward compatibility (POS uses this)
  bool adjustStock(EntityItem item, int delta) {
    final success = _itemService.adjustStock(item, delta);
    if (success) {
      loadItems();
    }
    return success;
  }

  // ──────────────────────────────────────────────────────────
  //  BATCH-AWARE STOCK ADJUSTMENT METHODS
  // ──────────────────────────────────────────────────────────

  /// Direct stock adjust (hasExpiry == false)
  bool adjustStockDirect(EntityItem item, int delta) {
    final success = adjustStock(item, delta);
    if (success) {
      _logTxn(
        itemId: item.id ?? 0,
        itemName: item.name ?? '',
        type: StockTxnType.adjust,
        qty: delta,
        remarks: delta >= 0 ? 'Manual increment' : 'Manual decrement',
      );
    }
    return success;
  }

  /// Increment with a new batch (hasExpiry == true)
  bool adjustStockWithNewBatch(
    EntityItem item,
    int qty,
    String batchNo,
    int? expiryMs,
  ) {
    if (qty <= 0) return false;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Create new batch
    final batch = EntityItemBatch(
      itemId: item.id,
      batchNo: batchNo,
      quantity: qty,
      expiryDateUtcMs: expiryMs,
      receivedAtUtcMs: now,
    );
    _boxBatch.put(batch);

    // Update item totalQty
    item.totalQty = (item.totalQty ?? 0) + qty;
    item.updatedAtUtcMs = now;
    _boxItem.put(item);

    // Log transaction
    _logTxn(
      itemId: item.id ?? 0,
      itemName: item.name ?? '',
      type: StockTxnType.add,
      qty: qty,
      remarks: 'Batch added: $batchNo',
    );

    loadItems();
    return true;
  }

  /// Decrement from oldest batch (hasExpiry == true, FIFO)
  bool adjustStockFromOldestBatch(EntityItem item, int qty) {
    if (qty <= 0) return false;
    final currentQty = item.totalQty ?? 0;
    if (qty > currentQty) return false; // Not enough stock

    // Query batches ordered by receivedAtUtcMs ASC (oldest first)
    final query = _boxBatch
        .query(EntityItemBatch_.itemId.equals(item.id ?? 0))
        .order(EntityItemBatch_.receivedAtUtcMs)
        .build();
    final batches = query.find();
    query.close();

    int remaining = qty;

    for (final batch in batches) {
      if (remaining <= 0) break;

      final batchQty = batch.quantity ?? 0;
      if (batchQty <= remaining) {
        // This batch is fully consumed → remove it
        remaining -= batchQty;
        _boxBatch.remove(batch.id!);
      } else {
        // Partially deduct from this batch
        batch.quantity = batchQty - remaining;
        _boxBatch.put(batch);
        remaining = 0;
      }
    }

    // Update item totalQty
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    item.totalQty = currentQty - qty;
    item.updatedAtUtcMs = now;
    _boxItem.put(item);

    // Log transaction
    _logTxn(
      itemId: item.id ?? 0,
      itemName: item.name ?? '',
      type: StockTxnType.deduct,
      qty: -qty,
      remarks: 'FIFO batch deduction',
    );

    loadItems();
    return true;
  }

  /// Get next batch number for an item
  int getNextBatchNumber(EntityItem item) {
    final query = _boxBatch
        .query(EntityItemBatch_.itemId.equals(item.id ?? 0))
        .build();
    final count = query.count();
    query.close();
    return count + 1;
  }

  // ── Internal: log a stock transaction ──
  void _logTxn({
    required int itemId,
    required String itemName,
    required StockTxnType type,
    required int qty,
    String? remarks,
  }) {
    _boxStockTxn.put(
      EntityStockTransaction(
        itemId: itemId,
        type: type.index,
        quantity: qty,
        referenceType: type.name,
        referenceId: itemName,
        remarks: remarks,
        createdAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  /// Auto-generate barcode for an item
  void generateBarcode(EntityItem item) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    item.barcode = 'ITM-${item.id}-$timestamp';
    _itemService.updateItem(item);
    loadItems();
  }

  /// Toggle active/inactive
  void toggleActive(EntityItem item) {
    item.isActive = !(item.isActive ?? true);
    _itemService.updateItem(item);
    loadItems();
  }

  /// Delete item
  void deleteItem(EntityItem item) {
    if (item.id != null) {
      _itemService.deleteItem(item.id!);
      loadItems();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
