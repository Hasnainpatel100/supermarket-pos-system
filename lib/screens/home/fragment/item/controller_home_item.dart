import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
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
import '../../../../service/service_item_excel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sort field constants
// ─────────────────────────────────────────────────────────────────────────────

class SortField {
  static const none  = '';
  static const name  = 'name';
  static const price = 'price';
  static const stock = 'stock';
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
  List<EntityItem>         _allItems    = [];
  final RxString           searchQuery  = ''.obs;
  final searchController = TextEditingController();

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount  = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  void nextPage() {
    if (hasNext) { currentPage.value++; _applySortAndPagination(); }
  }

  void prevPage() {
    if (hasPrev) { currentPage.value--; _applySortAndPagination(); }
  }

  // ── Sorting ───────────────────────────────────────────────────────────────
  final RxString rxSortField = SortField.none.obs;
  final RxBool   rxSortAsc   = true.obs;

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
    _applySortAndPagination();
  }

  void _applySortAndPagination() {
    final list  = List<EntityItem>.from(_allItems);
    final field = rxSortField.value;
    final asc   = rxSortAsc.value;

    if (field != SortField.none) {
      list.sort((a, b) {
        int cmp;
        switch (field) {
          case SortField.name:  cmp = (a.name ?? '').compareTo(b.name ?? ''); break;
          case SortField.price: cmp = (a.sellingPrice ?? 0).compareTo(b.sellingPrice ?? 0); break;
          case SortField.stock: cmp = (a.totalQty ?? 0).compareTo(b.totalQty ?? 0); break;
          default: cmp = 0;
        }
        return asc ? cmp : -cmp;
      });
    }

    totalCount.value    = list.length;
    rxListItem.value    = list.skip(currentPage.value * _pageSize).take(_pageSize).toList();
  }

  // ── Load / Search ─────────────────────────────────────────────────────────

  void loadItems() {
    _allItems = searchQuery.value.trim().isEmpty
        ? _itemService.getAllItems()
        : _itemService.searchItems(searchQuery.value);
    _applySortAndPagination();
    debugPrint('loadItems total: ${_allItems.length}');
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

  // ── Stock methods ─────────────────────────────────────────────────────────

  bool adjustStock(EntityItem item, int delta) {
    final ok = _itemService.adjustStock(item, delta);
    if (ok) loadItems();
    return ok;
  }

  bool adjustStockDirect(EntityItem item, int delta) {
    final ok = adjustStock(item, delta);
    if (ok) {
      _logTxn(
        itemId: item.id ?? 0,
        itemName: item.name ?? '',
        type: StockTxnType.adjust,
        qty: delta,
        remarks: delta >= 0 ? 'Manual increment' : 'Manual decrement',
      );
    }
    return ok;
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

  int getNextBatchNumber(EntityItem item) {
    final q     = _boxBatch.query(EntityItemBatch_.itemId.equals(item.id ?? 0)).build();
    final count = q.count();
    q.close();
    return count + 1;
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
      _itemService.deleteItem(item.id!);
      loadItems();
    }
  }

  // ── Excel Export ──────────────────────────────────────────────────────────
  void exportExcel() async {
    if (_allItems.isEmpty) {
      Get.snackbar("Info", "No items to export");
      return;
    }
    
    final excelService = ServiceItemExcel();
    bool success = await excelService.exportItems(_allItems);
    if (!success) {
      Get.snackbar("Error", "Failed to export items", snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
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

  /// Returns the plain string content of a cell, or null if blank.
  String? _cellStr(Data? cell) {
    if (cell == null) return null;
    final raw = cell.value?.toString() ?? '';
    if (raw.isEmpty) return null;

    // excel v3 wraps values: e.g. "TextCellValue(hello)" or "DoubleCellValue(18.0)"
    // Strip the wrapper to get the actual content.
    final match = RegExp(r'^\w+CellValue\((.*)\)$', dotAll: true).firstMatch(raw);
    final value = (match != null ? match.group(1) : raw)?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  /// Returns the numeric value of a cell, or null if blank/non-numeric.
  double? _cellDouble(Data? cell) {
    final s = _cellStr(cell);
    if (s == null) return null;
    return double.tryParse(s);
  }

  Future<void> importExcel() async {
    try {
      // ── 1. Pick file ──────────────────────────────────────────────────────
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.single.path == null) return; // cancelled

      // ── 2. Read bytes ─────────────────────────────────────────────────────
      final bytes = File(result.files.single.path!).readAsBytesSync();

      // ── 3. Decode Excel ───────────────────────────────────────────────────
      final Excel workbook = Excel.decodeBytes(bytes);

      int successCount = 0;
      int errorCount   = 0;

      // ── 4. Iterate sheets and rows ────────────────────────────────────────
      for (final sheetName in workbook.tables.keys) {
        final sheet = workbook.tables[sheetName]!;

        // Row index 0 = header row → skip it; start at 1
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty) continue;

          try {
            // ── Col A (0): Name — REQUIRED ──────────────────────────────────
            final name = _cellStr(row.isNotEmpty ? row[0] : null);
            if (name == null || name.isEmpty) continue;

            // ── Col B (1): SKU ──────────────────────────────────────────────
            final sku = row.length > 1 ? _cellStr(row[1]) : null;

            // ── Col C (2): Barcode ──────────────────────────────────────────
            final barcode = row.length > 2 ? _cellStr(row[2]) : null;

            // ── Col D (3): Unit ─────────────────────────────────────────────
            final unit = row.length > 3 ? _cellStr(row[3]) : null;

            // ── Col E (4): Category ─────────────────────────────────────────
            final category = row.length > 4 ? _cellStr(row[4]) : null;

            // ── Col F (5): Cost Price ───────────────────────────────────────
            final costPrice = row.length > 5 ? _cellDouble(row[5]) : null;

            // ── Col G (6): Selling Price ────────────────────────────────────
            final sellingPrice = (row.length > 6 ? _cellDouble(row[6]) : null) ?? 0.0;

            // ── Col H (7): Tax Name ─────────────────────────────────────────
            final taxName = row.length > 7 ? _cellStr(row[7]) : null;

            // ── Col I (8): Tax Rate  (plain number, e.g. 18  not "18%") ─────
            final taxRate = row.length > 8 ? _cellDouble(row[8]) : null;

            // ── Col J (9): Tax Type  ("inclusive" or "exclusive") ───────────
            String taxType = 'exclusive';
            if (row.length > 9) {
              final t = (_cellStr(row[9]) ?? '').toLowerCase();
              if (t == 'inclusive') taxType = 'inclusive';
            }

            // ── Col K (10): Has Expiry  ("yes" / "no" / "true" / "1") ───────
            bool hasExpiry = false;
            if (row.length > 10) {
              final e = (_cellStr(row[10]) ?? '').toLowerCase();
              hasExpiry = e == 'yes' || e == 'true' || e == '1';
            }

            // ── Compute tax breakdown ────────────────────────────────────────
            double? taxAmount, priceBeforeTax, priceAfterTax;
            double  finalSellingPrice = sellingPrice;

            if (taxRate != null && taxRate > 0) {
              if (taxType == 'inclusive') {
                taxAmount      = finalSellingPrice * taxRate / (100 + taxRate);
                priceBeforeTax = finalSellingPrice - taxAmount;
                priceAfterTax  = finalSellingPrice;
              } else {
                taxAmount         = finalSellingPrice * taxRate / 100;
                priceBeforeTax    = finalSellingPrice;
                priceAfterTax     = finalSellingPrice + taxAmount;
                finalSellingPrice = priceAfterTax;
              }
            }

            // ── Save item ────────────────────────────────────────────────────
            final now = DateTime.now().toUtc().millisecondsSinceEpoch;
            _itemService.createItem(EntityItem(
              name:           name,
              sku:            sku,
              barcode:        barcode,
              unit:           unit,
              category:       category,
              costPrice:      costPrice,
              sellingPrice:   finalSellingPrice,
              taxName:        taxName,
              taxRate:        taxRate,
              taxType:        (taxRate != null && taxRate > 0) ? taxType : null,
              taxAmount:      taxAmount,
              priceBeforeTax: priceBeforeTax,
              priceAfterTax:  priceAfterTax,
              hasExpiry:      hasExpiry,
              isActive:       true,
              totalQty:       0,
              createdAtUtcMs: now,
              updatedAtUtcMs: now,
            ));
            successCount++;
          } catch (rowErr) {
            errorCount++;
            debugPrint('Row $i import error: $rowErr');
          }
        }
      }

      loadItems();

      // ── 5. Result snackbar ────────────────────────────────────────────────
      if (successCount > 0) {
        Get.snackbar(
          'Import Successful ✅',
          '$successCount item(s) imported.'
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
