import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_item.dart';
import '../../model/entity_tax.dart';
import '../../service/service_item.dart';
import '../../service/service_object_box.dart';
import 'activity_item_batch_form.dart';

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

  // ── Basic Fields ──
  final rxUnit = RxnString();

  // ── Category ──
  final RxList<String> rxCategories = <String>[
    'General',
    'Beverages',
    'Snacks',
    'Dairy',
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
    if (editingItem != null) {
      _loadItemData();
    }
    // Reactively re-compute tax whenever price / rate / type changes
    ever(rxTaxRate, (_) => _recomputeTax());
    ever(rxSalePriceType, (_) => _recomputeTax());
    priceController.addListener(_recomputeTax);
    super.onInit();
  }

  void _loadTaxPresets() {
    rxTaxPresets.value = _taxBox.getAll();
  }

  void _loadItemData() {
    nameController.text = editingItem?.name ?? '';
    barcodeController.text = editingItem?.barcode ?? '';
    skuController.text = editingItem?.sku ?? '';
    priceController.text = editingItem?.sellingPrice?.toString() ?? '';
    costController.text = editingItem?.costPrice?.toString() ?? '';
    unitController.text = editingItem?.unit ?? '';
    rxUnit.value = editingItem?.unit;
    hasExpiry.value = editingItem?.hasExpiry ?? false;
    rxCategory.value = editingItem?.category;
    rxTaxType.value = editingItem?.taxType ?? 'exclusive';
    rxSalePriceType.value = editingItem?.taxType ?? 'exclusive';
    rxTaxRate.value = editingItem?.taxRate ?? 0.0;
    rxTaxName.value = editingItem?.taxName ?? '';

    // Re-select preset if matching
    if (editingItem?.taxName != null && editingItem!.taxName!.isNotEmpty) {
      final match = rxTaxPresets.firstWhereOrNull(
        (t) => t.name == editingItem!.taxName && t.rate == editingItem!.taxRate,
      );
      rxSelectedTaxId.value = match?.id;
    }
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
    if (!rxCategories.contains(trimmed)) {
      rxCategories.add(trimmed);
    }
    rxCategory.value = trimmed;
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
          name: nameController.text,
          barcode: barcodeController.text,
          sku: skuController.text,
          sellingPrice: finalPrice,
          costPrice: double.tryParse(costController.text),
          unit: rxUnit.value ?? unitController.text,
          category: rxCategory.value,
          taxName: rxTaxName.value.isEmpty ? null : rxTaxName.value,
          taxRate: rxTaxRate.value > 0 ? rxTaxRate.value : null,
          taxType: rxTaxRate.value > 0 ? type : null,
          taxAmount: rxTaxRate.value > 0 ? rxComputedTaxAmount.value : null,
          priceBeforeTax: rxTaxRate.value > 0 ? rxComputedBasePrice.value : null,
          priceAfterTax: rxTaxRate.value > 0 ? finalPrice : null,
          hasExpiry: hasExpiry.value,
          isActive: true,
          totalQty: 0,
          createdAtUtcMs: now,
          updatedAtUtcMs: now,
        );
        itemService.createItem(savedItem);
      } else {
        editingItem?.name = nameController.text;
        editingItem?.barcode = barcodeController.text;
        editingItem?.sku = skuController.text;
        editingItem?.sellingPrice = finalPrice;
        editingItem?.costPrice = double.tryParse(costController.text);
        editingItem?.unit = rxUnit.value ?? unitController.text;
        editingItem?.category = rxCategory.value;
        editingItem?.taxName = rxTaxName.value.isEmpty ? null : rxTaxName.value;
        editingItem?.taxRate = rxTaxRate.value > 0 ? rxTaxRate.value : null;
        editingItem?.taxType = rxTaxRate.value > 0 ? type : null;
        editingItem?.taxAmount = rxTaxRate.value > 0 ? rxComputedTaxAmount.value : null;
        editingItem?.priceBeforeTax = rxTaxRate.value > 0 ? rxComputedBasePrice.value : null;
        editingItem?.priceAfterTax = rxTaxRate.value > 0 ? finalPrice : null;
        editingItem?.hasExpiry = hasExpiry.value;
        editingItem?.updatedAtUtcMs = now;
        itemService.updateItem(editingItem!);
        savedItem = editingItem!;
      }

      if (hasExpiry.value) {
        await Get.to(() => const ActivityItemBatchForm(), arguments: savedItem);
        Get.back();
      } else {
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Duplicate SKU / Barcode");
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    barcodeController.dispose();
    skuController.dispose();
    priceController.dispose();
    costController.dispose();
    unitController.dispose();
    super.onClose();
  }
}
