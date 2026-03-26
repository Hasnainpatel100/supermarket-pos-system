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

/// Sort field enum expressed as string constants
class SortField {
  static const none = '';
  static const name = 'name';
  static const price = 'price';
  static const stock = 'stock';
}

class ControllerHomeItem extends GetxController {
  final ServiceCurrency serviceCurrency = Get.find();
  late final ItemService _itemService;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityItemBatch> _boxBatch;
  late final Box<EntityStockTransaction> _boxStockTxn;

  final RxList<EntityItem> rxListItem = <EntityItem>[].obs;
  List<EntityItem> _allItems = [];
  final RxString searchQuery = ''.obs;
  final searchController = TextEditingController();

  // ── Pagination ──
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      _applySortAndPagination();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      _applySortAndPagination();
    }
  }

  // ── Sorting ──
  final RxString rxSortField = SortField.none.obs;
  final RxBool rxSortAsc = true.obs;

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

  // ──────────────────────────────────────────────────────────
  //  SORT TOGGLE
  // ──────────────────────────────────────────────────────────

  /// Toggle sort for [field]: same field → flip asc/desc → then neutral.
  /// Different field → switch to asc on that field.
  void toggleSort(String field) {
    if (rxSortField.value == field) {
      if (rxSortAsc.value) {
        // asc → desc
        rxSortAsc.value = false;
      } else {
        // desc → neutral
        rxSortField.value = SortField.none;
        rxSortAsc.value = true;
      }
    } else {
      rxSortField.value = field;
      rxSortAsc.value = true;
    }
    currentPage.value = 0;
    _applySortAndPagination();
  }

  void _applySortAndPagination() {
    List<EntityItem> list = List.from(_allItems);
    final field = rxSortField.value;
    final asc = rxSortAsc.value;
    
    if (field != SortField.none) {
      list.sort((a, b) {
        int cmp;
        switch (field) {
          case SortField.name:
            cmp = (a.name ?? '').compareTo(b.name ?? '');
            break;
          case SortField.price:
            cmp = (a.sellingPrice ?? 0).compareTo(b.sellingPrice ?? 0);
            break;
          case SortField.stock:
            cmp = (a.totalQty ?? 0).compareTo(b.totalQty ?? 0);
            break;
          default:
            cmp = 0;
        }
        return asc ? cmp : -cmp;
      });
    }

    totalCount.value = list.length;
    final paged = list.skip(currentPage.value * _pageSize).take(_pageSize).toList();
    rxListItem.value = paged;
  }

  // ──────────────────────────────────────────────────────────
  //  LOAD / SEARCH
  // ──────────────────────────────────────────────────────────

  void loadItems() {
    if (searchQuery.value.trim().isEmpty) {
      _allItems = _itemService.getAllItems();
    } else {
      _allItems = _itemService.searchItems(searchQuery.value);
    }
    // Re-apply current sort & pagination after loading
    _applySortAndPagination();
    debugPrint("loadItems total size: ${_allItems.length}");
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    currentPage.value = 0;
    loadItems();
  }

  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    currentPage.value = 0;
    loadItems();
  }

  // ──────────────────────────────────────────────────────────
  //  STOCK METHODS
  // ──────────────────────────────────────────────────────────

  bool adjustStock(EntityItem item, int delta) {
    final success = _itemService.adjustStock(item, delta);
    if (success) loadItems();
    return success;
  }

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

  bool adjustStockWithNewBatch(EntityItem item, int qty, String batchNo, int? expiryMs) {
    if (qty <= 0) return false;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final batch = EntityItemBatch(
      itemId: item.id,
      batchNo: batchNo,
      quantity: qty,
      expiryDateUtcMs: expiryMs,
      receivedAtUtcMs: now,
    );
    _boxBatch.put(batch);
    item.totalQty = (item.totalQty ?? 0) + qty;
    item.updatedAtUtcMs = now;
    _boxItem.put(item);
    _logTxn(itemId: item.id ?? 0, itemName: item.name ?? '', type: StockTxnType.add, qty: qty, remarks: 'Batch added: $batchNo');
    loadItems();
    return true;
  }

  bool adjustStockFromOldestBatch(EntityItem item, int qty) {
    if (qty <= 0) return false;
    final currentQty = item.totalQty ?? 0;
    if (qty > currentQty) return false;
    final query = _boxBatch.query(EntityItemBatch_.itemId.equals(item.id ?? 0)).order(EntityItemBatch_.receivedAtUtcMs).build();
    final batches = query.find();
    query.close();
    int remaining = qty;
    for (final batch in batches) {
      if (remaining <= 0) break;
      final batchQty = batch.quantity ?? 0;
      if (batchQty <= remaining) {
        remaining -= batchQty;
        _boxBatch.remove(batch.id!);
      } else {
        batch.quantity = batchQty - remaining;
        _boxBatch.put(batch);
        remaining = 0;
      }
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    item.totalQty = currentQty - qty;
    item.updatedAtUtcMs = now;
    _boxItem.put(item);
    _logTxn(itemId: item.id ?? 0, itemName: item.name ?? '', type: StockTxnType.deduct, qty: -qty, remarks: 'FIFO batch deduction');
    loadItems();
    return true;
  }

  int getNextBatchNumber(EntityItem item) {
    final query = _boxBatch.query(EntityItemBatch_.itemId.equals(item.id ?? 0)).build();
    final count = query.count();
    query.close();
    return count + 1;
  }

  void _logTxn({required int itemId, required String itemName, required StockTxnType type, required int qty, String? remarks}) {
    _boxStockTxn.put(EntityStockTransaction(
      itemId: itemId,
      type: type.index,
      quantity: qty,
      referenceType: type.name,
      referenceId: itemName,
      remarks: remarks,
      createdAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
  }

  void generateBarcode(EntityItem item) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    item.barcode = 'ITM-${item.id}-$timestamp';
    _itemService.updateItem(item);
    loadItems();
  }

  void toggleActive(EntityItem item) {
    item.isActive = !(item.isActive ?? true);
    _itemService.updateItem(item);
    loadItems();
  }

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
