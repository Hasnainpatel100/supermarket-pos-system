import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/entity_item.dart';
import '../model/entity_item_batch.dart';
import '../service/service_object_box.dart';
import '../objectbox.g.dart';

class ControllerItemBatchForm extends GetxController {
  final EntityItem item;
  late final Box<EntityItemBatch> _boxBatch;
  late final Box<EntityItem> _boxItem;

  ControllerItemBatchForm(this.item);

  final formKey = GlobalKey<FormState>();
  final batchNoController = TextEditingController();
  final expiryDateController = TextEditingController();
  final quantityController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBatch = ob.box<EntityItemBatch>();
    _boxItem = ob.box<EntityItem>();

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
      } catch (_) {
        // Handle parse error or leave null
      }
    }

    final int qty = int.tryParse(quantityController.text) ?? 0;

    final batch = EntityItemBatch(
      itemId: item.id,
      batchNo: batchNoController.text.trim(),
      quantity: qty,
      expiryDateUtcMs: expiryMs,
      receivedAtUtcMs: now,
    );

    _boxBatch.put(batch);

    // Update item total quantity
    item.totalQty = (item.totalQty ?? 0) + qty;
    _boxItem.put(item);

    Get.back(); // Close Batch Form, returning to where we came from (likely Home or Item List)
  }
}
