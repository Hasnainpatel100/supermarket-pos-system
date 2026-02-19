import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/entity_item.dart';
import '../service/service_item.dart';
import 'activity_item_batch_form.dart';

class ControllerItemForm extends GetxController {
  final ItemService itemService;

  ControllerItemForm(this.itemService);

  final formKey = GlobalKey<FormState>();

  /// ⭐ IMPORTANT

  EntityItem? editingItem;

  final nameController = TextEditingController();
  final barcodeController = TextEditingController();
  final skuController = TextEditingController();
  final priceController = TextEditingController();
  final costController = TextEditingController();
  final unitController = TextEditingController();

  var hasExpiry = false.obs;

  ControllerItemForm.init(this.itemService, {this.editingItem});

  @override
  void onInit() {
    if (editingItem != null) {
      _loadItemData();
    }
    super.onInit();
  }

  void _loadItemData() {
    nameController.text = editingItem?.name ?? '';
    barcodeController.text = editingItem?.barcode ?? '';
    skuController.text = editingItem?.sku ?? '';

    priceController.text = editingItem?.sellingPrice?.toString() ?? '';
    costController.text = editingItem?.costPrice?.toString() ?? '';

    unitController.text = editingItem?.unit ?? '';
    hasExpiry.value = editingItem?.hasExpiry ?? false;
  }

  void saveItem() {
    if (!formKey.currentState!.validate()) {
      Get.snackbar("Error", "Please fill required fields");
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    try {
      EntityItem savedItem;
      if (editingItem == null) {
        savedItem = EntityItem(
          name: nameController.text,
          barcode: barcodeController.text,
          sku: skuController.text,
          sellingPrice: double.tryParse(priceController.text),
          costPrice: double.tryParse(costController.text),
          unit: unitController.text,
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
        editingItem?.sellingPrice = double.tryParse(priceController.text);
        editingItem?.costPrice = double.tryParse(costController.text);
        editingItem?.unit = unitController.text;
        editingItem?.hasExpiry = hasExpiry.value;
        editingItem?.updatedAtUtcMs = now;

        itemService.updateItem(editingItem!);
        savedItem = editingItem!;
      }

      if (hasExpiry.value) {
        // If item has expiry, go to batch creation
        Get.off(() => const ActivityItemBatchForm(), arguments: savedItem);
      } else {
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Duplicate SKU / Barcode");
    }
  }
}
