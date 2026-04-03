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
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

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

  // ──────────────────────────────────────────────────────────
  //  IMPORT EXCEL
  // ──────────────────────────────────────────────────────────

  Future<void> importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled the picker
      }

      String filePath = result.files.single.path!;
      var bytes = File(filePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      int successCount = 0;
      int errorCount = 0;

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        for (int i = 1; i < sheet.rows.length; i++) { // Skip header row
          var row = sheet.rows[i];
          if (row.isEmpty || row[0]?.value == null) continue; // Name is required

          try {
            String name = (row[0]?.value?.toString() ?? '').trim();
            if (name.isEmpty) continue; // Name is required

            String? sku = row.length > 1 ? row[1]?.value?.toString().trim() : null;
            if (sku != null && sku.isEmpty) sku = null;

            String? barcode = row.length > 2 ? row[2]?.value?.toString().trim() : null;
            if (barcode != null && barcode.isEmpty) barcode = null;

            String? unit = row.length > 3 ? row[3]?.value?.toString().trim() : null;
            if (unit != null && unit.isEmpty) unit = null;

            String? category = row.length > 4 ? row[4]?.value?.toString().trim() : null;
            if (category != null && category.isEmpty) category = null;

            double? costPrice;
            if (row.length > 5 && row[5]?.value != null) {
              costPrice = double.tryParse(row[5]!.value.toString());
            }

            double sellingPrice = 0.0;
            if (row.length > 6 && row[6]?.value != null) {
              sellingPrice = double.tryParse(row[6]!.value.toString()) ?? 0.0;
            }

            String? taxName = row.length > 7 ? row[7]?.value?.toString().trim() : null;
            if (taxName != null && taxName.isEmpty) taxName = null;

            double? taxRate;
            if (row.length > 8 && row[8]?.value != null) {
              taxRate = double.tryParse(row[8]!.value.toString());
            }

            String? taxType = row.length > 9 ? row[9]?.value?.toString().trim().toLowerCase() : null;
            if (taxType != 'inclusive' && taxType != 'exclusive') {
                taxType = 'exclusive'; // default
            }

            bool hasExpiry = false;
            if (row.length > 10 && row[10]?.value != null) {
              String exprStr = row[10]!.value.toString().trim().toLowerCase();
              if (exprStr == 'yes' || exprStr == 'true' || exprStr == '1') {
                hasExpiry = true;
              }
            }

            // Compute taxes like in ControllerItemForm
            double? taxAmount;
            double? priceBeforeTax;
            double? priceAfterTax;
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

            final now = DateTime.now().toUtc().millisecondsSinceEpoch;

            EntityItem newItem = EntityItem(
              name: name,
              sku: sku,
              barcode: barcode,
              unit: unit,
              category: category,
              costPrice: costPrice,
              sellingPrice: finalSellingPrice,
              taxName: taxName,
              taxRate: taxRate,
              taxType: taxRate != null && taxRate > 0 ? taxType : null,
              taxAmount: taxAmount,
              priceBeforeTax: priceBeforeTax,
              priceAfterTax: priceAfterTax,
              hasExpiry: hasExpiry,
              isActive: true,
              totalQty: 0,
              createdAtUtcMs: now,
              updatedAtUtcMs: now,
            );

            _itemService.createItem(newItem);
            successCount++;
          } catch (e) {
            errorCount++;
            debugPrint("Error importing row $i: $e");
          }
        }
      }

      loadItems();

      if (successCount > 0) {
        Get.snackbar(
          "Import Successful",
          "$successCount items imported successfully." + (errorCount > 0 ? " ($errorCount failed due to duplicates/errors)" : ""),
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else if (errorCount > 0) {
        Get.snackbar(
          "Import Failed",
          "Failed to import items. Make sure SKUs and Barcodes are unique.",
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar("Import Finished", "No valid items found in the Excel file.");
      }

    } catch (e) {
      debugPrint("Excel import error: $e");
      Get.snackbar(
        "Import Error",
        "Could not read the Excel file. Please check the format.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }
}
