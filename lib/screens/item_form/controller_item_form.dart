import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_item.dart';
import '../../model/entity_item_batch.dart';
import '../../model/entity_tax.dart';
import '../../objectbox.g.dart';
import 'package:objectid/objectid.dart';
import '../../service/service_item.dart';
import '../../service/service_object_box.dart';
import '../../service/service_item_excel.dart';
import '../home/fragment/item/controller_home_item.dart';
import '../home/fragment/pos/controller_home_pos.dart';

class ControllerItemForm extends GetxController {
  final ItemService itemService;

  ControllerItemForm(this.itemService);

  ControllerItemForm.init(this.itemService, {this.editingItem});

  final formKey = GlobalKey<FormState>();

  EntityItem? editingItem;

  // ── Text Controllers ──
  final nameController = TextEditingController();
  final barcodeController = TextEditingController();
  final skuController = TextEditingController();
  final priceController = TextEditingController();
  final costController = TextEditingController();
  final unitController = TextEditingController();

  // ── Batch Fields (Matching Product Entry Opening Stock) ──
  final batchNoController = TextEditingController();
  final batchQtyController = TextEditingController();
  final batchMrpController = TextEditingController();
  final batchSalesRateController = TextEditingController();
  final batchMfgDateController = TextEditingController();
  final batchExpiryDateController = TextEditingController();
  final RxList<EntityItemBatch> rxBatches = <EntityItemBatch>[].obs;
  final rxSelectedBatchIndex = (-1).obs;

  // ── Basic Fields ──
  final rxUnit = RxnString();
  final RxList<String> rxUnits = <String>[
    'pcs', 'Box', 'KG', 'g', 'L', 'ML', 'Dozen', 'Tray', 'Bottle',
  ].obs;

  // ── Category ──
  final RxList<String> rxCategories = <String>[
    'General',
    'Beverages',
    'Snacks',
    'Dairy',
    'Fruits',
    'Vegetables',
    'Bakery',
    'Grocery',
    'Electronics',
    'Clothing',
    'Medicine',
    'Stationery',
  ].obs;
  final rxCategory = RxnString();

  // ── Tax Presets (ObjectBox) ──
  final RxList<EntityTax> rxTaxPresets = <EntityTax>[].obs;

  // ── Selected Tax ──
  final rxSelectedTaxId = RxnInt(); // null = None
  final rxTaxName = ''.obs;
  final rxTaxRate = 0.0.obs;
  final rxTaxType = 'exclusive'.obs; // "inclusive" or "exclusive"

  // ── Sale Price type (shown next to price field) ──
  final rxSalePriceType = 'exclusive'.obs; // "exclusive"=Without Tax, "inclusive"=With Tax

  // ── Computed tax values ──
  final rxComputedTaxAmount = 0.0.obs;
  final rxComputedBasePrice = 0.0.obs;
  final rxComputedTotalPrice = 0.0.obs;

  var hasExpiry = false.obs;

  // ── ObjectBox box for taxes ──
  late final _taxBox = Get.find<ServiceObjectBox>().box<EntityTax>();

  @override
  void onInit() {
    _loadTaxPresets();
    _loadCategories();
    if (editingItem != null) {
      _loadItemData();
    }
    // Reactively re-compute tax whenever price / rate / type changes
    ever(rxTaxRate, (_) => _recomputeTax());
    ever(rxSalePriceType, (_) => _recomputeTax());
    priceController.addListener(_recomputeTax);

    // Pre-fill next batch number automatically
    batchNoController.text = ControllerHomeItem.calculateNextBatchNo(
      existingBatches: rxBatches.toList(),
    );
    batchQtyController.text = '1';

    super.onInit();
  }

  void _loadTaxPresets() {
    rxTaxPresets.value = _taxBox.getAll();
  }

  void _loadCategories() {
    try {
      final itemBox = Get.find<ServiceObjectBox>().box<EntityItem>();
      final existingCategories = itemBox
          .getAll()
          .map((e) => e.category?.trim())
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet();

      for (final cat in existingCategories) {
        if (!rxCategories.any((c) => c.toLowerCase() == cat.toLowerCase())) {
          rxCategories.add(cat);
        }
      }
    } catch (_) {}
  }

  void _loadItemData() {
    nameController.text = editingItem?.name ?? '';
    barcodeController.text = editingItem?.barcode ?? '';
    skuController.text = editingItem?.sku ?? '';
    priceController.text = editingItem?.sellingPrice?.toString() ?? '';
    costController.text = editingItem?.costPrice?.toString() ?? '';
    unitController.text = editingItem?.unit ?? '';
    final u = editingItem?.unit?.trim();
    if (u != null && u.isNotEmpty) {
      if (!rxUnits.any((x) => x.toLowerCase() == u.toLowerCase())) {
        rxUnits.add(u);
      }
      final match = rxUnits.firstWhereOrNull((x) => x.toLowerCase() == u.toLowerCase());
      rxUnit.value = match ?? u;
    } else {
      rxUnit.value = null;
    }
    hasExpiry.value = editingItem?.hasExpiry ?? false;

    final cat = editingItem?.category?.trim();
    if (cat != null && cat.isNotEmpty) {
      if (!rxCategories.any((c) => c.toLowerCase() == cat.toLowerCase())) {
        rxCategories.add(cat);
      }
      final match = rxCategories.firstWhereOrNull((c) => c.toLowerCase() == cat.toLowerCase());
      rxCategory.value = match ?? cat;
    } else {
      rxCategory.value = null;
    }

    rxTaxName.value = editingItem?.taxName ?? '';
    rxTaxRate.value = editingItem?.taxRate ?? 0.0;
    rxTaxType.value = editingItem?.taxType ?? 'exclusive';
    rxSalePriceType.value = editingItem?.taxType ?? 'exclusive';

    // Match tax preset by id, name, or rate so dropdown shows the current tax
    final matchedPreset = rxTaxPresets.firstWhereOrNull(
      (t) =>
          (editingItem?.taxName != null &&
              t.name?.trim().toLowerCase() == editingItem!.taxName!.trim().toLowerCase()) ||
          (editingItem?.taxRate != null && t.rate == editingItem!.taxRate),
    );
    if (matchedPreset != null) {
      rxSelectedTaxId.value = matchedPreset.id;
      rxTaxName.value = matchedPreset.name ?? '';
      if (rxTaxRate.value == 0 && (matchedPreset.rate ?? 0) > 0) {
        rxTaxRate.value = matchedPreset.rate ?? 0.0;
      }
    }

    // Load existing batches for this item
    try {
      if (editingItem?.id != null) {
        final boxBatch = Get.find<ServiceObjectBox>().box<EntityItemBatch>();
        final existingBatches = boxBatch
            .query(EntityItemBatch_.itemId
                .equals(editingItem!.id!)
                .and(EntityItemBatch_.quantity.greaterThan(0)))
            .order(EntityItemBatch_.id)
            .build()
            .find();
        rxBatches.assignAll(existingBatches);
        if (existingBatches.isNotEmpty) {
          hasExpiry.value = true;
        }
      }
    } catch (_) {}

    _recomputeTax();
  }

  // ── Tax calculation ──
  void _recomputeTax() {
    final price = double.tryParse(priceController.text) ?? 0.0;
    final rate = rxTaxRate.value;
    final type = rxSalePriceType.value;

    if (rate <= 0 || price <= 0) {
      rxComputedTaxAmount.value = 0;
      rxComputedBasePrice.value = price;
      rxComputedTotalPrice.value = price;
      return;
    }

    if (type == 'inclusive') {
      // Price already includes tax
      final taxAmount = price * rate / (100 + rate);
      rxComputedTaxAmount.value = taxAmount;
      rxComputedBasePrice.value = price - taxAmount;
      rxComputedTotalPrice.value = price;
    } else {
      // Exclusive: tax added on top
      final taxAmount = price * rate / 100;
      rxComputedTaxAmount.value = taxAmount;
      rxComputedBasePrice.value = price;
      rxComputedTotalPrice.value = price + taxAmount;
    }
  }

  /// Called when user picks a preset from the tax dropdown
  void selectTaxPreset(EntityTax? tax) {
    if (tax == null) {
      rxSelectedTaxId.value = null;
      rxTaxName.value = '';
      rxTaxRate.value = 0;
    } else {
      rxSelectedTaxId.value = tax.id;
      rxTaxName.value = tax.name ?? '';
      rxTaxRate.value = tax.rate ?? 0;
    }
    _recomputeTax();
  }

  /// Create and persist a new tax preset
  Future<EntityTax?> createTaxPreset(String name, double rate) async {
    if (name.trim().isEmpty || rate <= 0) return null;
    final newTax = EntityTax(name: name.trim(), rate: rate);
    final id = _taxBox.put(newTax);
    newTax.id = id;
    _loadTaxPresets();
    selectTaxPreset(newTax);
    return newTax;
  }

  /// Create a new category
  void createCategory(String name) {
    if (name.trim().isEmpty) return;
    final trimmed = name.trim();
    final match = rxCategories.firstWhereOrNull((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (match == null) {
      rxCategories.add(trimmed);
      rxCategory.value = trimmed;
    } else {
      rxCategory.value = match;
    }
  }

  void addBatch() {
    final batchNo = batchNoController.text.trim();
    final qty = int.tryParse(batchQtyController.text.trim()) ?? 0;
    final mrp = double.tryParse(batchMrpController.text.trim());
    final saleRate = double.tryParse(batchSalesRateController.text.trim()) ?? double.tryParse(priceController.text);

    if (batchNo.isEmpty) {
      Get.snackbar("Error", "Please enter a batch number", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (qty <= 0) {
      Get.snackbar("Error", "Please enter a valid quantity", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    int? mfgMs;
    if (batchMfgDateController.text.trim().isNotEmpty) {
      try {
        mfgMs = DateTime.parse(batchMfgDateController.text.trim()).millisecondsSinceEpoch;
      } catch (_) {}
    }

    int? expMs;
    if (batchExpiryDateController.text.trim().isNotEmpty) {
      try {
        expMs = DateTime.parse(batchExpiryDateController.text.trim()).millisecondsSinceEpoch;
      } catch (_) {}
    }

    final newBatch = EntityItemBatch(
      batchNo: batchNo,
      quantity: qty,
      mrp: mrp,
      salePrice: saleRate,
      costPrice: double.tryParse(costController.text.trim()),
      mfgDateUtcMs: mfgMs,
      expiryDateUtcMs: expMs,
      receivedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    );

    rxBatches.add(newBatch);
    hasExpiry.value = true;

    if (priceController.text.isEmpty && saleRate != null) {
      priceController.text = saleRate.toString();
    }

    // Auto-increment to the next sequential batch number (e.g. 1 -> 2 -> 3)
    final nextNo = ControllerHomeItem.calculateNextBatchNo(
      existingBatches: rxBatches.toList(),
    );
    batchNoController.text = nextNo;
    batchQtyController.text = '1';
    batchMrpController.clear();
    batchSalesRateController.clear();
    batchMfgDateController.clear();
    batchExpiryDateController.clear();
  }

  void removeBatch(int index) {
    if (index >= 0 && index < rxBatches.length) {
      rxBatches.removeAt(index);
    }
  }

  void saveItem() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar("Error", "Please fill required fields");
      return;
    }

    _recomputeTax();

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final type = rxSalePriceType.value;
    final enteredPrice = double.tryParse(priceController.text) ?? 0.0;

    // Determine the sellingPrice (what POS charges) = priceAfterTax
    final double finalPrice = type == 'inclusive'
        ? enteredPrice // inclusive: entered price IS the final price
        : rxComputedTotalPrice.value; // exclusive: base + tax

    try {
      EntityItem savedItem;
      if (editingItem == null) {
        savedItem = EntityItem(
          name: nameController.text.trim(),
          barcode: barcodeController.text.trim(),
          sku: skuController.text.trim(),
          sellingPrice: enteredPrice,
          costPrice: double.tryParse(costController.text.trim()),
          unit: rxUnit.value ?? unitController.text.trim(),
          category: rxCategory.value,
          taxName: rxTaxName.value.isEmpty ? null : rxTaxName.value,
          taxRate: rxTaxRate.value > 0 ? rxTaxRate.value : null,
          taxType: rxTaxRate.value > 0 ? type : null,
          taxAmount: rxTaxRate.value > 0 ? rxComputedTaxAmount.value : null,
          priceBeforeTax: rxTaxRate.value > 0 ? rxComputedBasePrice.value : null,
          priceAfterTax: rxTaxRate.value > 0 ? finalPrice : enteredPrice,
          hasExpiry: hasExpiry.value || rxBatches.isNotEmpty,
          isActive: true,
          totalQty: 0,
          createdAtUtcMs: now,
          updatedAtUtcMs: now,
        );
        itemService.createItem(savedItem);
      } else {
        editingItem?.name = nameController.text.trim();
        editingItem?.barcode = barcodeController.text.trim();
        editingItem?.sku = skuController.text.trim();
        editingItem?.sellingPrice = enteredPrice;
        editingItem?.costPrice = double.tryParse(costController.text.trim());
        editingItem?.unit = rxUnit.value ?? unitController.text.trim();
        editingItem?.category = rxCategory.value;
        editingItem?.taxName = rxTaxName.value.isEmpty ? null : rxTaxName.value;
        editingItem?.taxRate = rxTaxRate.value > 0 ? rxTaxRate.value : null;
        editingItem?.taxType = rxTaxRate.value > 0 ? type : null;
        editingItem?.taxAmount = rxTaxRate.value > 0 ? rxComputedTaxAmount.value : null;
        editingItem?.priceBeforeTax = rxTaxRate.value > 0 ? rxComputedBasePrice.value : null;
        editingItem?.priceAfterTax = rxTaxRate.value > 0 ? finalPrice : enteredPrice;
        editingItem?.hasExpiry = hasExpiry.value || rxBatches.isNotEmpty;
        editingItem?.updatedAtUtcMs = now;
        itemService.updateItem(editingItem!);
        savedItem = editingItem!;
      }

      // Persist batches if added
      if (rxBatches.isNotEmpty) {
        final boxBatch = Get.find<ServiceObjectBox>().box<EntityItemBatch>();
        if (editingItem != null && editingItem!.id != null) {
          final old = boxBatch.query(EntityItemBatch_.itemId.equals(editingItem!.id!)).build().find();
          for (final ob in old) {
            if (ob.id != null) boxBatch.remove(ob.id!);
          }
        }
        int totalBatchQty = 0;
        for (final b in rxBatches) {
          b.id = 0;
          b.objectId = ObjectId().hexString;
          b.itemId = savedItem.id;
          b.barcode = savedItem.barcode;
          b.costPrice ??= savedItem.costPrice;
          boxBatch.put(b);
          totalBatchQty += (b.quantity ?? 0);
        }
        savedItem.totalQty = totalBatchQty;
        savedItem.hasExpiry = true;
        itemService.updateItem(savedItem);
      }

      // ⚡ Always notify both Item and POS controllers so changes reflect everywhere!
      if (Get.isRegistered<ControllerHomeItem>()) {
        Get.find<ControllerHomeItem>().loadItems();
      }
      if (Get.isRegistered<ControllerHomePos>()) {
        final posCtrl = Get.find<ControllerHomePos>();
        posCtrl.loadItems();
        posCtrl.calculateTotals();
      }

      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Duplicate SKU / Barcode");
    }
  }

  // ── Import/Export ──
  void exportToExcel() async {
    final items = itemService.getAllItems();
    if (items.isEmpty) {
      Get.snackbar("Info", "No items to export");
      return;
    }
    
    final excelService = ServiceItemExcel();
    bool success = await excelService.exportItems(items);
    if (!success) {
      Get.snackbar("Error", "Failed to export items", snackPosition: SnackPosition.BOTTOM);
    }
  }

  void importFromExcel() async {
    final excelService = ServiceItemExcel();
    final importedItems = await excelService.importItems();
    
    if (importedItems == null) {
      return; // cancelled or failed to read
    }
    
    if (importedItems.isEmpty) {
      Get.snackbar("Error", "No valid items found in excel", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    int successCount = 0;
    int failCount = 0;
    
    for (var item in importedItems) {
      try {
        if (item.barcode != null && item.barcode!.isNotEmpty) {
           final existing = itemService.findByBarcode(item.barcode!);
           if (existing != null) {
             failCount++;
             continue; // ignore duplicates
           }
        }
        itemService.createItem(item);
        successCount++;
      } catch (e) {
        failCount++;
      }
    }
    
    Get.snackbar(
       "Import Complete", 
       "Successfully imported $successCount items. Failed/Skipped: $failCount.",
       snackPosition: SnackPosition.BOTTOM,
       duration: const Duration(seconds: 4)
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    barcodeController.dispose();
    skuController.dispose();
    priceController.dispose();
    costController.dispose();
    unitController.dispose();
    batchNoController.dispose();
    batchQtyController.dispose();
    batchMrpController.dispose();
    batchSalesRateController.dispose();
    batchMfgDateController.dispose();
    batchExpiryDateController.dispose();
    super.onClose();
  }
}
