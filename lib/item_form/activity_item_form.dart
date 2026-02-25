import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../model/entity_item.dart';
import '../service/service_item.dart';
import '../service/service_object_box.dart';
import '../widget/my_text_field.dart';
import 'controller_item_form.dart';

class ActivityItemForm extends StatelessWidget {
  const ActivityItemForm({super.key});

  @override
  Widget build(BuildContext context) {
    final EntityItem? editingItem = Get.arguments as EntityItem?;
    final itemService = ItemService(
      Get.find<ServiceObjectBox>().box<EntityItem>(),
    );
    final ControllerItemForm controller = Get.put(
      ControllerItemForm.init(itemService, editingItem: editingItem),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = editingItem != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Icon(
              isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isEditing ? 'Edit Item' : 'New Item',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// ── Basic Info Section ──
                    _FormSectionHeader(
                      icon: Icons.info_outline_rounded,
                      color: Colors.blue.shade600,
                      title: 'Basic Information',
                    ),
                    const SizedBox(height: 16),
                    MyTextField(
                      controller: controller.nameController,
                      label: "Item Name",
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MyTextField(
                            controller: controller.skuController,
                            label: "SKU",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => DropdownButtonFormField<String>(
                              value: controller.rxUnit.value,
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'pcs',
                                  child: Text('Piece (pcs)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Box',
                                  child: Text('Box'),
                                ),
                                DropdownMenuItem(
                                  value: 'KG',
                                  child: Text('Kilogram (KG)'),
                                ),
                                DropdownMenuItem(
                                  value: 'g',
                                  child: Text('Gram (g)'),
                                ),
                                DropdownMenuItem(
                                  value: 'L',
                                  child: Text('Liter (L)'),
                                ),
                                DropdownMenuItem(
                                  value: 'ML',
                                  child: Text('Milliliter (ML)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Dozen',
                                  child: Text('Dozen'),
                                ),
                                DropdownMenuItem(
                                  value: 'Tray',
                                  child: Text('Tray'),
                                ),
                                DropdownMenuItem(
                                  value: 'Bottle',
                                  child: Text('Bottle'),
                                ),
                              ],
                              onChanged: (val) => controller.rxUnit.value = val,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// ── Pricing & Barcode Section ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormSectionHeader(
                                icon: Icons.attach_money_rounded,
                                color: Colors.green.shade600,
                                title: 'Pricing',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: MyTextField(
                                      controller: controller.costController,
                                      label: "Cost",
                                      isNumber: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: MyTextField(
                                      controller: controller.priceController,
                                      label: "Price",
                                      required: true,
                                      isNumber: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormSectionHeader(
                                icon: Icons.qr_code_rounded,
                                color: Colors.deepPurple.shade500,
                                title: 'Barcode',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: MyTextField(
                                      controller: controller.barcodeController,
                                      label: "Barcode",
                                      required: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _BarcodeActionButton(
                                    icon: Icons.auto_awesome_rounded,
                                    color: Colors.amber.shade700,
                                    tooltip: 'Auto-generate',
                                    onPressed: () {
                                      final random = Random();
                                      final digits = List.generate(
                                        13,
                                        (_) => random.nextInt(10),
                                      ).join();
                                      controller.barcodeController.text =
                                          digits;

                                      // Show 1D and 2D QR Code Dialog
                                      Get.dialog(
                                        Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Generated Barcode',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                // 1D Barcode – white bg for dark mode
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: BarcodeWidget(
                                                    barcode: Barcode.code128(),
                                                    data: digits,
                                                    width: 200,
                                                    height: 80,
                                                    drawText: true,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                // 2D QR Code – white bg for dark mode
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: BarcodeWidget(
                                                    barcode: Barcode.qrCode(),
                                                    data: digits,
                                                    width: 150,
                                                    height: 150,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                FilledButton(
                                                  onPressed: () => Get.back(),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  _BarcodeActionButton(
                                    icon: Icons.qr_code_scanner_rounded,
                                    color: colorScheme.primary,
                                    tooltip: 'Scan',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// ── Settings Section ──
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Obx(
                        () => SwitchListTile(
                          title: const Text(
                            "Has Expiry Date",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.event_busy_rounded,
                              size: 18,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          value: controller.hasExpiry.value,
                          onChanged: (val) => controller.hasExpiry.value = val,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// ── Action Buttons ──
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: controller.saveItem,
                          icon: Icon(
                            isEditing
                                ? Icons.check_rounded
                                : Icons.save_rounded,
                            size: 18,
                          ),
                          label: Text(isEditing ? "Update Item" : "Save Item"),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _FormSectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(height: 1, color: color.withValues(alpha: 0.2)),
        ),
      ],
    );
  }
}

class _BarcodeActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _BarcodeActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
