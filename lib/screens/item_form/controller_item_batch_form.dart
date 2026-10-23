import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_item.dart';
import '../../model/entity_item_batch.dart';
import '../../objectbox.g.dart';
import '../../service/service_object_box.dart';

class ControllerItemBatchForm extends GetxController {
  final EntityItem item;
  late final Box<EntityItemBatch> _boxBatch;
  late final Box<EntityItem> _boxItem;

  ControllerItemBatchForm(this.item);

  final formKey = GlobalKey<FormState>();
  final batchNoController = TextEditingController();
  final expiryDateController = TextEditingController();
  final quantityController = TextEditingController();
  final mrpController = TextEditingController();
  final salePriceController = TextEditingController();
  final mfgDateController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBatch = ob.box<EntityItemBatch>();
    _boxItem = ob.box<EntityItem>();

    if (item.sellingPrice != null) {
      salePriceController.text = item.sellingPrice.toString();
    }

    // Auto-increment Batch Number
    final existingBatchesCount = _boxBatch
        .query(
          EntityItemBatch_.itemId.equals(item.id ?? 0),
        ) // Ensure itemId is queried safely
        .build()
        .count();

    batchNoController.text = (existingBatchesCount + 1).toString();
  }

  void saveBatch() {
    if (!formKey.currentState!.validate()) {
      Get.snackbar("Error", "Please fill required fields");
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Parse date from controller (assuming YYYY-MM-DD from MyDatePicker)
    int? expiryMs;
    if (expiryDateController.text.isNotEmpty) {
      try {
        expiryMs = DateTime.parse(
          expiryDateController.text,
        ).millisecondsSinceEpoch;
      } catch (_) {}
    }

    int? mfgMs;
    if (mfgDateController.text.isNotEmpty) {
      try {
        mfgMs = DateTime.parse(
          mfgDateController.text,
        ).millisecondsSinceEpoch;
      } catch (_) {}
    }

    final int qty = int.tryParse(quantityController.text) ?? 0;
    final double? mrp = double.tryParse(mrpController.text);
    final double? salePrice = double.tryParse(salePriceController.text) ?? item.sellingPrice;

    final batch = EntityItemBatch(
      itemId: item.id,
      batchNo: batchNoController.text.trim(),
      quantity: qty,
      mrp: mrp,
      salePrice: salePrice,
      costPrice: item.costPrice,
      mfgDateUtcMs: mfgMs,
      expiryDateUtcMs: expiryMs,
      receivedAtUtcMs: now,
      barcode: item.barcode,
    );

    _boxBatch.put(batch);

    // Update item total quantity
    item.totalQty = (item.totalQty ?? 0) + qty;
    item.hasExpiry = true;
    _boxItem.put(item);

    Get.back(); // Close Batch Form
  }

  @override
  void onClose() {
    batchNoController.dispose();
    quantityController.dispose();
    mrpController.dispose();
    salePriceController.dispose();
    mfgDateController.dispose();
    expiryDateController.dispose();
    super.onClose();
  }
}
