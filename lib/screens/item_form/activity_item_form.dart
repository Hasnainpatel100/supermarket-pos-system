import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../model/entity_item.dart';
import '../../model/entity_tax.dart';
import '../../service/service_item.dart';
import '../../service/service_object_box.dart';
import '../../widget/my_text_field.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEditing
                      ? [Colors.orange.shade400, Colors.deepOrange.shade600]
                      : [Colors.teal.shade400, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isEditing ? Colors.orange : Colors.teal).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? 'Edit Item' : 'New Item',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            margin: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Basic Information ──
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'pcs', child: Text('Piece (pcs)')),
                                DropdownMenuItem(value: 'Box', child: Text('Box')),
                                DropdownMenuItem(value: 'KG', child: Text('Kilogram (KG)')),
                                DropdownMenuItem(value: 'g', child: Text('Gram (g)')),
                                DropdownMenuItem(value: 'L', child: Text('Liter (L)')),
                                DropdownMenuItem(value: 'ML', child: Text('Milliliter (ML)')),
                                DropdownMenuItem(value: 'Dozen', child: Text('Dozen')),
                                DropdownMenuItem(value: 'Tray', child: Text('Tray')),
                                DropdownMenuItem(value: 'Bottle', child: Text('Bottle')),
                              ],
                              onChanged: (val) => controller.rxUnit.value = val,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Category ──
                    _CategoryDropdown(controller: controller, theme: theme),

                    const SizedBox(height: 24),

                    // ── Pricing & Barcode ──
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
                                      label: "Sale Price",
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
                                      final digits = List.generate(13, (_) => random.nextInt(10)).join();
                                      controller.barcodeController.text = digits;
                                      Get.dialog(
                                        Dialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Generated Barcode',
                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                                ),
                                                const SizedBox(height: 24),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                                  child: BarcodeWidget(barcode: Barcode.code128(), data: digits, width: 200, height: 80, drawText: true, color: Colors.black),
                                                ),
                                                const SizedBox(height: 24),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                                  child: BarcodeWidget(barcode: Barcode.qrCode(), data: digits, width: 150, height: 150, color: Colors.black),
                                                ),
                                                const SizedBox(height: 24),
                                                FilledButton(onPressed: () => Get.back(), child: const Text('Close')),
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

                    const SizedBox(height: 16),

                    // ── Sale Price Type Toggle ──
                    _TaxTypeSelector(controller: controller),

                    const SizedBox(height: 24),

                    // ── Tax Section ──
                    _FormSectionHeader(
                      icon: Icons.percent_rounded,
                      color: Colors.indigo.shade600,
                      title: 'Taxes',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigo.withOpacity(0.15)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _TaxSection(controller: controller, theme: theme),
                    ),

                    const SizedBox(height: 24),

                    // ── Expiry Toggle ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.25)),
                      ),
                      child: Obx(
                        () => SwitchListTile(
                          title: const Text(
                            "Has Expiry Date",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.orange),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.event_busy_rounded, size: 20, color: Colors.orange.shade700),
                          ),
                          value: controller.hasExpiry.value,
                          activeThumbColor: Colors.orange.shade700,
                          onChanged: (val) => controller.hasExpiry.value = val,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Action Buttons ──
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: theme.colorScheme.outline),
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isEditing
                                  ? [Colors.orange.shade400, Colors.deepOrange.shade600]
                                  : [Colors.teal.shade400, Colors.teal.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (isEditing ? Colors.orange : Colors.teal).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: controller.saveItem,
                            icon: Icon(
                              isEditing ? Icons.check_rounded : Icons.save_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            label: Text(
                              isEditing ? "Update Item" : "Save Item",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Category Dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final ControllerItemForm controller;
  final ThemeData theme;
  const _CategoryDropdown({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cats = [...controller.rxCategories, '+ Create New'];
      return DropdownButtonFormField<String>(
        value: controller.rxCategory.value,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.category_outlined, color: Colors.teal.shade600, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: cats.map((c) {
          if (c == '+ Create New') {
            return DropdownMenuItem(
              value: c,
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.teal.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text('Create New', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return DropdownMenuItem(value: c, child: Text(c));
        }).toList(),
        onChanged: (val) {
          if (val == '+ Create New') {
            _showCreateCategoryDialog(context);
          } else {
            controller.rxCategory.value = val;
          }
        },
      );
    });
  }

  void _showCreateCategoryDialog(BuildContext context) {
    final tc = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.category_outlined, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            const Text('New Category'),
          ],
        ),
        content: TextField(
          controller: tc,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Beverages',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) {
            controller.createCategory(tc.text);
            Get.back();
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              controller.createCategory(tc.text);
              Get.back();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tax Section
// ─────────────────────────────────────────────────────────────────────────────

class _TaxSection extends StatelessWidget {
  final ControllerItemForm controller;
  final ThemeData theme;
  const _TaxSection({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final presets = controller.rxTaxPresets;
      final selectedId = controller.rxSelectedTaxId.value;

      // Build dropdown items: None + presets + Create New
      final List<DropdownMenuItem<int?>> items = [
        const DropdownMenuItem<int?>(value: null, child: Text('None')),
        ...presets.map((t) => DropdownMenuItem<int?>(
              value: t.id,
              child: Text('${t.name} (${t.rate}%)'),
            )),
        const DropdownMenuItem<int?>(value: -1, child: _CreateNewTaxItem()),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tax Rate dropdown
          DropdownButtonFormField<int?>(
            value: presets.any((t) => t.id == selectedId) ? selectedId : null,
            decoration: InputDecoration(
              labelText: 'Tax Rate',
              prefixIcon: Icon(Icons.percent_rounded, color: Colors.indigo.shade400, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: theme.colorScheme.surface,
              filled: true,
            ),
            items: items,
            onChanged: (val) {
              if (val == -1) {
                _showCreateTaxDialog(context, controller);
              } else if (val == null) {
                controller.selectTaxPreset(null);
              } else {
                final tax = presets.firstWhereOrNull((t) => t.id == val);
                controller.selectTaxPreset(tax);
              }
            },
          ),

          // Show computed values only if tax is selected
          if (controller.rxTaxRate.value > 0) ...[
            const SizedBox(height: 12),
            // Price type reminder
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Colors.indigo.shade400),
                const SizedBox(width: 6),
                Text(
                  controller.rxSalePriceType.value == 'inclusive'
                      ? 'Price entered is inclusive of tax'
                      : 'Tax will be added on top of entered price',
                  style: TextStyle(fontSize: 12, color: Colors.indigo.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Computed breakdown chips
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _TaxInfoChip(
                  label: 'Tax Amt',
                  value: controller.rxComputedTaxAmount.value.toStringAsFixed(2),
                  color: Colors.red.shade600,
                  icon: Icons.percent_rounded,
                ),
                _TaxInfoChip(
                  label: 'Base Price',
                  value: controller.rxComputedBasePrice.value.toStringAsFixed(2),
                  color: Colors.orange.shade700,
                  icon: Icons.price_change_outlined,
                ),
                _TaxInfoChip(
                  label: 'Total Price',
                  value: controller.rxComputedTotalPrice.value.toStringAsFixed(2),
                  color: Colors.green.shade700,
                  icon: Icons.attach_money_rounded,
                ),
              ],
            ),
          ],
        ],
      );
    });
  }

  void _showCreateTaxDialog(BuildContext context, ControllerItemForm controller) {
    final nameTc = TextEditingController();
    final rateTc = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.percent_rounded, color: Colors.indigo.shade600),
            const SizedBox(width: 8),
            const Text('New Tax'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameTc,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Tax Name',
                hintText: 'e.g. SGST, CGST, VAT',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateTc,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Rate (%)',
                hintText: 'e.g. 9, 18',
                suffixText: '%',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final rate = double.tryParse(rateTc.text) ?? 0;
              final tax = await controller.createTaxPreset(nameTc.text, rate);
              Get.back();
              if (tax != null) {
                Get.snackbar('Tax Created', '${tax.name} ${tax.rate}% added', duration: const Duration(seconds: 2));
              }
            },
            child: const Text('Create & Apply'),
          ),
        ],
      ),
    );
  }
}

class _CreateNewTaxItem extends StatelessWidget {
  const _CreateNewTaxItem();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.add_circle_outline_rounded, color: Colors.indigo.shade600, size: 18),
        const SizedBox(width: 8),
        Text('Create New Tax', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TaxInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _TaxInfoChip({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TaxTypeSelector extends StatelessWidget {
  final ControllerItemForm controller;
  
  const _TaxTypeSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Obx(() {
      final currentType = controller.rxSalePriceType.value;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.sell_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Sale Price Type',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'exclusive',
                  label: Text('Excl. Tax'),
                  icon: Icon(Icons.remove_circle_outline, size: 16),
                ),
                ButtonSegment<String>(
                  value: 'inclusive',
                  label: Text('Incl. Tax'),
                  icon: Icon(Icons.add_circle_outline, size: 16),
                ),
              ],
              selected: {currentType},
              onSelectionChanged: (selected) {
                controller.rxSalePriceType.value = selected.first;
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                padding: WidgetStatePropertyAll(
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FormSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _FormSectionHeader({required this.icon, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(height: 1, color: color.withValues(alpha: 0.2))),
      ],
    );
  }
}

class _BarcodeActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _BarcodeActionButton({required this.icon, required this.color, required this.tooltip, required this.onPressed});

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
