import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/performance/debouncer.dart';
import '../../../../core/performance/performance_config.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../model/entity_stock_transaction.dart';
import '../../../../model/stock_txn_type.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_currency.dart';
import '../../../../service/service_item.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../util/snackbar_util.dart';
import '../pos/controller_home_pos.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sort field constants
// ─────────────────────────────────────────────────────────────────────────────

class SortField {
  static const none  = '';
  static const name  = 'name';
  static const price = 'price';
  static const stock = 'stock';
}

/// Expiry filter tab values
class ExpiryFilter {
  static const all       = 'all';
  static const expiring  = 'expiring';   // 1-30 days
  static const expired   = 'expired';    // past today
  static const safe      = 'safe';       // > 30 days
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class ControllerHomeItem extends GetxController {
  final ServiceCurrency serviceCurrency = Get.find();
  late final ItemService              _itemService;
  late final Box<EntityItem>          _boxItem;
  late final Box<EntityItemBatch>     _boxBatch;
  late final Box<EntityStockTransaction> _boxStockTxn;

  final RxList<EntityItem> rxListItem   = <EntityItem>[].obs;
  final RxString           searchQuery  = ''.obs;
  final searchController = TextEditingController();
  final RxString rxExpiryFilter = ExpiryFilter.all.obs;

  // ── Filter counts for UI chips ──
  final RxInt countAll = 0.obs;
  final RxInt countExpiring = 0.obs;
  final RxInt countExpired = 0.obs;
  final RxInt countSafe = 0.obs;

  // ── Multi-Select State ──
  final RxSet<int> rxSelectedIds = <int>{}.obs;

  bool isSelected(int? id) => id != null && id > 0 && rxSelectedIds.contains(id);
  bool get hasSelection => rxSelectedIds.isNotEmpty;
  int get selectedCount => rxSelectedIds.length;
  bool get isAllVisibleSelected =>
      rxListItem.isNotEmpty &&
      rxListItem.every((item) => item.id != null && item.id! > 0 && rxSelectedIds.contains(item.id));

  void toggleSelection(int id) {
    if (id <= 0) return;
    if (rxSelectedIds.contains(id)) {
      rxSelectedIds.remove(id);
    } else {
      rxSelectedIds.add(id);
    }
    rxSelectedIds.refresh();
  }

  void selectAllVisible() {
    for (final item in rxListItem) {
      if (item.id != null && item.id! > 0) rxSelectedIds.add(item.id!);
    }
    rxSelectedIds.refresh();
  }

  void deselectAllVisible() {
    for (final item in rxListItem) {
      if (item.id != null) rxSelectedIds.remove(item.id!);
    }
    rxSelectedIds.refresh();
  }

  void clearSelection() {
    rxSelectedIds.clear();
    rxSelectedIds.refresh();
  }

  /// Debounce search input to avoid querying ObjectBox on every keystroke.
  final _searchDebouncer = Debouncer(milliseconds: PerfConfig.searchDebounceMs);

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount  = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      _fetchPagedItems();
      _resetHorizontalScroll();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      _fetchPagedItems();
      _resetHorizontalScroll();
    }
  }

  void _resetHorizontalScroll() {
    if (horizontalScrollController.hasClients && horizontalScrollController.offset > 0) {
      horizontalScrollController.jumpTo(0.0);
    }
  }

  void resetSearch() {
    if (searchQuery.value.isNotEmpty || searchController.text.isNotEmpty) {
      searchQuery.value = '';
      searchController.clear();
      currentPage.value = 0;
      loadItems();
    }
  }

  // ── Sorting ───────────────────────────────────────────────────────────────
  final RxString rxSortField = SortField.none.obs;
  final RxBool   rxSortAsc   = true.obs;

  // ── Horizontal Table Scrolling ──
  final horizontalScrollController = ScrollController();

  void scrollLeft() {
    if (horizontalScrollController.hasClients) {
      final target = (horizontalScrollController.offset - 250).clamp(
        0.0,
        horizontalScrollController.position.maxScrollExtent,
      );
      horizontalScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void scrollRight() {
    if (horizontalScrollController.hasClients) {
      final target = (horizontalScrollController.offset + 250).clamp(
        0.0,
        horizontalScrollController.position.maxScrollExtent,
      );
      horizontalScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }


  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    final ob = Get.find<ServiceObjectBox>();
    _boxItem      = ob.box<EntityItem>();
    _boxBatch     = ob.box<EntityItemBatch>();
    _boxStockTxn  = ob.box<EntityStockTransaction>();
    _itemService  = ItemService(_boxItem);
    loadItems();
    super.onInit();
  }

  // ── Sort toggle ───────────────────────────────────────────────────────────

  void toggleSort(String field) {
    if (rxSortField.value == field) {
      if (rxSortAsc.value) {
        rxSortAsc.value = false;
      } else {
        rxSortField.value = SortField.none;
        rxSortAsc.value   = true;
      }
    } else {
      rxSortField.value = field;
      rxSortAsc.value   = true;
    }
    currentPage.value = 0;
    _fetchPagedItems();
  }

  void setExpiryFilter(String filter) {
    rxExpiryFilter.value = filter;
    currentPage.value = 0;
    _fetchPagedItems();
  }

  void _fetchPagedItems() {
    // 1. Get paged items with search + sort from service
    final result = _itemService.getItemsPaged(
      query: searchQuery.value,
      sortField: rxSortField.value,
      sortAsc: rxSortAsc.value,
      offset: 0,   // fetch ALL for expiry filter; we'll paginate below
      limit: 99999,
    );

    final allForFilter = result.items;
    countAll.value = allForFilter.length;

    // 2. Compute counts across all items for each filter chip
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final in30Ms = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;

    int expCount = 0;
    int expSoonCount = 0;
    int safeCount = 0;

    for (final item in allForFilter) {
      if (item.hasExpiry == true) {
        final expMs = getNearestExpiryMsForItem(item.id ?? 0);
        if (expMs != null) {
          if (expMs <= nowMs) {
            expCount++;
          } else if (expMs <= in30Ms) {
            expSoonCount++;
          } else {
            safeCount++;
          }
        }
      }
    }

    countExpired.value = expCount;
    countExpiring.value = expSoonCount;
    countSafe.value = safeCount;

    // 3. Apply active filter
    List<EntityItem> filtered = allForFilter;
    if (rxExpiryFilter.value != ExpiryFilter.all) {
      filtered = filtered.where((item) {
        if (item.hasExpiry != true) {
          // Items without expiry tracking only appear in 'all'
          return false;
        }
        final expMs = getNearestExpiryMsForItem(item.id ?? 0);
        if (expMs == null) return false;
        if (rxExpiryFilter.value == ExpiryFilter.expired) return expMs <= nowMs;
        if (rxExpiryFilter.value == ExpiryFilter.expiring) return expMs > nowMs && expMs <= in30Ms;
        if (rxExpiryFilter.value == ExpiryFilter.safe) return expMs > in30Ms;
        return true;
      }).toList();
    }

    // 4. Paginate client-side
    totalCount.value = filtered.length;
    final start = currentPage.value * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    rxListItem.assignAll(start < filtered.length ? filtered.sublist(start, end) : []);
  }

  /// Gets the nearest future batch expiry ms for an item (nil if none)
  int? getNearestExpiryMsForItem(int itemId) {
    final q = _boxBatch
        .query(EntityItemBatch_.itemId.equals(itemId))
        .order(EntityItemBatch_.expiryDateUtcMs)
        .build();
    final batches = q.find();
    q.close();
    // 1. Prefer batches with quantity > 0
    for (final b in batches) {
      if ((b.quantity ?? 0) > 0 && b.expiryDateUtcMs != null) {
        return b.expiryDateUtcMs;
      }
    }
    // 2. Fallback to any batch with an expiry date
    for (final b in batches) {
      if (b.expiryDateUtcMs != null) {
        return b.expiryDateUtcMs;
      }
    }
    return null;
  }

  // ── Load / Search ─────────────────────────────────────────────────────────

  void loadItems() {
    _fetchPagedItems();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    currentPage.value = 0;
    // Debounce: only query ObjectBox after 300ms of inactivity.
    // This prevents firing a DB query on every single keystroke.
    _searchDebouncer.run(() => loadItems());
  }

  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    currentPage.value = 0;
    loadItems();
  }

  // ── Stock methods ─────────────────────────────────────────────────────────

  bool adjustStock(EntityItem item, int delta) {
    final ok = _itemService.adjustStock(item, delta);
    if (ok) {
      loadItems();
      if (Get.isRegistered<ControllerHomePos>()) {
        Get.find<ControllerHomePos>().loadItems();
      }
    }
    return ok;
  }

  bool adjustStockDirect(EntityItem item, int delta, {String? reason, String? remarks}) {
    final ok = adjustStock(item, delta);
    if (ok) {
      _logTxn(
        itemId: item.id ?? 0,
        itemName: item.name ?? '',
        type: StockTxnType.adjust,
        qty: delta,
        remarks: remarks ??
            (reason != null
                ? '$reason (${delta >= 0 ? "Increment" : "Decrement"})'
                : (delta >= 0 ? 'Manual increment' : 'Manual decrement')),
      );
    }
    return ok;
  }

  List<EntityItemBatch> getItemBatches(EntityItem item) {
    if (item.id == null) return [];
    final q = _boxBatch
        .query(EntityItemBatch_.itemId.equals(item.id!))
        .order(EntityItemBatch_.expiryDateUtcMs)
        .build();
    final batches = q.find();
    q.close();
    return batches.where((b) => (b.quantity ?? 0) > 0).toList();
  }

  bool adjustStockWithMultipleBatches(
    EntityItem item,
    List<EntityItemBatch> batches,
    String reason, {
    String? remarks,
  }) {
    if (batches.isEmpty) return false;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    int totalAdded = 0;

    for (final b in batches) {
      final qty = b.quantity ?? 0;
      if (qty <= 0) continue;
      b.itemId = item.id;
      b.barcode = item.barcode;
      b.costPrice ??= item.costPrice;
      b.salePrice ??= item.sellingPrice;
      b.receivedAtUtcMs ??= now;
      _boxBatch.put(b);
      totalAdded += qty;

      _logTxn(
        itemId: item.id ?? 0,
        itemName: item.name ?? '',
        type: StockTxnType.add,
        qty: qty,
        remarks:
            'Batch: ${b.batchNo ?? "-"} ($reason)${remarks != null && remarks.isNotEmpty ? " - $remarks" : ""}',
      );
    }

    if (totalAdded == 0) return false;

    item.totalQty = (item.totalQty ?? 0) + totalAdded;
    item.hasExpiry = true;
    item.updatedAtUtcMs = now;
    _boxItem.put(item);
    loadItems();
    if (Get.isRegistered<ControllerHomePos>()) {
      Get.find<ControllerHomePos>().loadItems();
    }
    return true;
  }

  bool adjustStockDecrementByBatches(
    EntityItem item,
    Map<int, int> batchDeductions,
    String reason, {
    String? remarks,
  }) {
    if (batchDeductions.isEmpty) return false;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    int totalDeducted = 0;

    for (final entry in batchDeductions.entries) {
      final batchId = entry.key;
      final deductQty = entry.value;
      if (deductQty <= 0) continue;

      final batch = _boxBatch.get(batchId);
      if (batch == null) continue;

      final current = batch.quantity ?? 0;
      final newQty = current - deductQty;
      if (newQty <= 0) {
        _boxBatch.remove(batchId);
      } else {
        batch.quantity = newQty;
        _boxBatch.put(batch);
      }
      totalDeducted += deductQty;

      _logTxn(
        itemId: item.id ?? 0,
        itemName: item.name ?? '',
        type: StockTxnType.deduct,
        qty: -deductQty,
        remarks:
            'Batch: ${batch.batchNo ?? "-"} ($reason)${remarks != null && remarks.isNotEmpty ? " - $remarks" : ""}',
      );
    }

    if (totalDeducted == 0) return false;

    final currentTotal = item.totalQty ?? 0;
    item.totalQty = (currentTotal - totalDeducted).clamp(0, 999999999);
    item.updatedAtUtcMs = now;
    _boxItem.put(item);
    loadItems();
    if (Get.isRegistered<ControllerHomePos>()) {
      Get.find<ControllerHomePos>().loadItems();
    }
    return true;
  }

  bool adjustStockWithNewBatch(EntityItem item, int qty, String batchNo, int? expiryMs) {
    if (qty <= 0) return false;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    _boxBatch.put(EntityItemBatch(
      itemId: item.id,
      batchNo: batchNo,
      quantity: qty,
      expiryDateUtcMs: expiryMs,
      receivedAtUtcMs: now,
    ));
    item.totalQty      = (item.totalQty ?? 0) + qty;
    item.updatedAtUtcMs = now;
    _boxItem.put(item);
    _logTxn(itemId: item.id ?? 0, itemName: item.name ?? '', type: StockTxnType.add, qty: qty, remarks: 'Batch: $batchNo');
    loadItems();
    if (Get.isRegistered<ControllerHomePos>()) {
      Get.find<ControllerHomePos>().loadItems();
    }
    return true;
  }

  bool adjustStockFromOldestBatch(EntityItem item, int qty) {
    if (qty <= 0) return false;
    final currentQty = item.totalQty ?? 0;
    if (qty > currentQty) return false;

    final q = _boxBatch
        .query(EntityItemBatch_.itemId.equals(item.id ?? 0))
        .order(EntityItemBatch_.receivedAtUtcMs)
        .build();
    final batches = q.find();
    q.close();

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
    item.totalQty       = currentQty - qty;
    item.updatedAtUtcMs = now;
    _boxItem.put(item);
    _logTxn(itemId: item.id ?? 0, itemName: item.name ?? '', type: StockTxnType.deduct, qty: -qty, remarks: 'FIFO deduction');
    loadItems();
    return true;
  }

  /// ⚡ Calculates the next auto-incremented batch number.
  /// If previous batch is "1", next is "2". If "B-1", next is "B-2".
  static String calculateNextBatchNo({
    required List<EntityItemBatch> existingBatches,
    List<EntityItemBatch>? pendingBatches,
  }) {
    final all = <EntityItemBatch>[
      ...existingBatches,
      if (pendingBatches != null) ...pendingBatches,
    ];

    if (all.isEmpty) return '1';

    int maxNum = 0;
    String? commonPrefix;

    for (final b in all) {
      final str = (b.batchNo ?? '').trim();
      if (str.isEmpty) continue;

      // Pure integer (e.g. "1", "2")
      final pureInt = int.tryParse(str);
      if (pureInt != null) {
        if (pureInt > maxNum) maxNum = pureInt;
        continue;
      }

      // Prefix + number (e.g. "B-1", "BATCH-02")
      final match = RegExp(r'^(.*?)(\d+)$').firstMatch(str);
      if (match != null) {
        final prefix = match.group(1) ?? '';
        final numPart = int.tryParse(match.group(2) ?? '') ?? 0;
        if (numPart > maxNum) {
          maxNum = numPart;
          commonPrefix = prefix;
        }
      }
    }

    if (maxNum > 0) {
      if (commonPrefix != null && commonPrefix.isNotEmpty) {
        return '$commonPrefix${maxNum + 1}';
      }
      return '${maxNum + 1}';
    }

    return '${all.length + 1}';
  }

  String getNextBatchNo(EntityItem item, [List<EntityItemBatch>? pendingBatches]) {
    final existing = getItemBatches(item);
    return calculateNextBatchNo(existingBatches: existing, pendingBatches: pendingBatches);
  }

  int getNextBatchNumber(EntityItem item) {
    final nextStr = getNextBatchNo(item);
    return int.tryParse(nextStr) ?? 1;
  }

  void _logTxn({
    required int          itemId,
    required String       itemName,
    required StockTxnType type,
    required int          qty,
    String?               remarks,
  }) {
    _boxStockTxn.put(EntityStockTransaction(
      itemId:        itemId,
      type:          type.index,
      quantity:      qty,
      referenceType: type.name,
      referenceId:   itemName,
      remarks:       remarks,
      createdAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
  }

  void generateBarcode(EntityItem item) {
    item.barcode = 'ITM-${item.id}-${DateTime.now().millisecondsSinceEpoch}';
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
      rxSelectedIds.remove(item.id!);
      _itemService.deleteItem(item.id!);
      loadItems();
    }
  }

  Future<void> bulkToggleActive(bool targetActive) async {
    if (rxSelectedIds.isEmpty) return;
    final ids = rxSelectedIds.toList();
    final items = _boxItem.getMany(ids).whereType<EntityItem>().toList();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final item in items) {
      item.isActive = targetActive;
      item.updatedAtUtcMs = now;
    }
    _boxItem.putMany(items);
    final count = items.length;
    clearSelection();
    loadItems();
    SnackbarUtil.showSuccess(
      targetActive
          ? '$count item(s) activated successfully'
          : '$count item(s) deactivated successfully',
    );
  }

  Future<void> bulkDeleteSelected() async {
    if (rxSelectedIds.isEmpty) return;
    final ids = rxSelectedIds.toList();
    final count = ids.length;
    _boxItem.removeMany(ids);
    clearSelection();
    loadItems();
    SnackbarUtil.showSuccess('$count item(s) deleted successfully');
  }

  void confirmBulkDelete(BuildContext context) {
    if (rxSelectedIds.isEmpty) return;
    final count = rxSelectedIds.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Selected Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete $count selected item(s)? This will remove them from the catalog and inventory.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Get.back();
              bulkDeleteSelected();
            },
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text('Delete $count Items'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void confirmSingleDelete(BuildContext context, EntityItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.name ?? 'this item'}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Get.back();
              deleteItem(item);
              SnackbarUtil.showSuccess('Item "${item.name ?? ''}" deleted');
            },
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Excel Export ──────────────────────────────────────────────────────────
  void exportExcel() async {
    final allItems = _itemService.getAllItems();
    if (allItems.isEmpty) {
      Get.snackbar("Info", "No items to export");
      return;
    }
    
    final excelService = ServiceItemExcel();
    bool success = await excelService.exportItems(allItems);
    if (!success) {
      Get.snackbar("Error", "Failed to export items", snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    horizontalScrollController.dispose();
    _searchDebouncer.dispose();
    searchController.dispose();
    super.onClose();
  }

  // ── Excel Import ──────────────────────────────────────────────────────────
  //
  // Compatible with   excel ^3.0.0
  //
  // In excel v3 every cell value is wrapped in a typed object such as
  //   TextCellValue("hello")  DoubleCellValue(18.0)  IntCellValue(5)
  // Calling .toString() on such an object produces the raw wrapper string
  //   "TextCellValue(hello)"
  // so we strip the prefix with a regex to get the actual value.
  // ─────────────────────────────────────────────────────────────────────────

  /// ⚡ HIGH-PERFORMANCE: Decodes and parses Excel rows in a separate Dart Isolate
  /// so the UI thread stays at 60 FPS without dropping a single frame.
  static ({List<EntityItem> items, int errorCount}) _parseExcelBytesInIsolate(Uint8List bytes) {
    final Excel workbook = Excel.decodeBytes(bytes);
    final List<EntityItem> items = [];
    int errorCount = 0;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    String? cellStr(Data? cell) {
      if (cell == null) return null;
      final raw = cell.value?.toString() ?? '';
      if (raw.isEmpty) return null;
      final match = RegExp(r'^\w+CellValue\((.*)\)$', dotAll: true).firstMatch(raw);
      final value = (match != null ? match.group(1) : raw)?.trim() ?? '';
      return value.isEmpty ? null : value;
    }

    double? cellDouble(Data? cell) {
      final s = cellStr(cell);
      if (s == null) return null;
      return double.tryParse(s);
    }

    for (final sheetName in workbook.tables.keys) {
      final sheet = workbook.tables[sheetName]!;

      // Row index 0 = header row → skip it; start at 1
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        try {
          final name = cellStr(row.isNotEmpty ? row[0] : null);
          if (name == null || name.isEmpty) continue;

          final sku = row.length > 1 ? cellStr(row[1]) : null;
          final barcode = row.length > 2 ? cellStr(row[2]) : null;
          final unit = row.length > 3 ? cellStr(row[3]) : null;
          final category = row.length > 4 ? cellStr(row[4]) : null;
          final costPrice = row.length > 5 ? cellDouble(row[5]) : null;
          final sellingPrice = (row.length > 6 ? cellDouble(row[6]) : null) ?? 0.0;
          final taxName = row.length > 7 ? cellStr(row[7]) : null;
          final taxRate = row.length > 8 ? cellDouble(row[8]) : null;

          String taxType = 'exclusive';
          if (row.length > 9) {
            final t = (cellStr(row[9]) ?? '').toLowerCase();
            if (t == 'inclusive') taxType = 'inclusive';
          }

          bool hasExpiry = false;
          if (row.length > 10) {
            final e = (cellStr(row[10]) ?? '').toLowerCase();
            hasExpiry = e == 'yes' || e == 'true' || e == '1';
          }

          double? taxAmount, priceBeforeTax, priceAfterTax;
          double finalSellingPrice = sellingPrice;

          if (taxRate != null && taxRate > 0) {
            if (taxType == 'inclusive') {
              taxAmount = finalSellingPrice * taxRate / (100 + taxRate);
              priceBeforeTax = finalSellingPrice - taxAmount;
              priceAfterTax = finalSellingPrice;
            } else {
              taxAmount = finalSellingPrice * taxRate / 100;
              priceBeforeTax = finalSellingPrice;
              priceAfterTax = finalSellingPrice + taxAmount;
              finalSellingPrice = priceAfterTax;
            }
          }

          items.add(EntityItem(
            name: name,
            sku: sku,
            barcode: barcode,
            unit: unit,
            category: category,
            costPrice: costPrice,
            sellingPrice: finalSellingPrice,
            taxName: taxName,
            taxRate: taxRate,
            taxType: (taxRate != null && taxRate > 0) ? taxType : null,
            taxAmount: taxAmount,
            priceBeforeTax: priceBeforeTax,
            priceAfterTax: priceAfterTax,
            hasExpiry: hasExpiry,
            isActive: true,
            totalQty: 0,
            createdAtUtcMs: now,
            updatedAtUtcMs: now,
          ));
        } catch (_) {
          errorCount++;
        }
      }
    }
    return (items: items, errorCount: errorCount);
  }

  Future<void> importExcel() async {
    try {
      // ── 1. Pick file ──────────────────────────────────────────────────────
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.single.path == null) return; // cancelled

      // ── 2. Read bytes asynchronously (non-blocking) ───────────────────────
      final bytes = await File(result.files.single.path!).readAsBytes();

      // Show non-blocking loading indicator
      Get.dialog(
        const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text(
                      'Importing items in background...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // ── 3. Parse in background Isolate ────────────────────────────────────
      final parsed = await Isolate.run(() => _parseExcelBytesInIsolate(bytes));

      // ── 4. Atomic Bulk Write in single ACID transaction ───────────────────
      if (parsed.items.isNotEmpty) {
        _boxItem.putMany(parsed.items);
      }

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      loadItems();

      final successCount = parsed.items.length;
      final errorCount = parsed.errorCount;

      // ── 5. Result snackbar ────────────────────────────────────────────────
      if (successCount > 0) {
        Get.snackbar(
          'Import Successful ✅',
          '$successCount item(s) imported in bulk.'
          '${errorCount > 0 ? ' ($errorCount row(s) skipped)' : ''}',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else if (errorCount > 0) {
        Get.snackbar(
          'Import Failed',
          'No items were imported. Ensure Name column is filled and '
          'SKU / Barcode values are unique.',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Nothing Imported',
          'No data rows found. Make sure row 1 is the header and '
          'data starts from row 2.',
          duration: const Duration(seconds: 4),
        );
      }

    } on FileSystemException {
      Get.snackbar(
        'File Locked',
        'The file is open in another program. '
        'Close Microsoft Excel and try again.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e, st) {
      debugPrint('importExcel error: $e\n$st');
      Get.snackbar(
        'Import Error',
        'Failed to read the file.\n$e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        isDismissible: true,
      );
    }
  }
}
