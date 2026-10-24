import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../model/entity_item.dart';
import '../../service/service_item.dart';
import '../../service/service_object_box.dart';
import '../../widget/app_dialog_components.dart';
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

    return AppDialog(
      maxWidth: 980,
      maxHeight: 850,
      header: DialogHeader(
        title: isEditing ? 'edit_item'.tr : 'new_item'.tr,
        icon: isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
        iconColor: isEditing ? Colors.orange.shade700 : Colors.teal.shade700,
      ),
      body: DialogBody(
        child: Form(
          key: controller.formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Basic Information ──
                  FormSection(
                    icon: Icons.info_outline_rounded,
                    color: Colors.blue.shade600,
                    title: 'basic_information'.tr,
                  ),
                  const SizedBox(height: 16),

                  if (isWide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            controller: controller.nameController,
                            label: 'item_name'.tr,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: controller.skuController,
                            label: 'sku'.tr,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CategoryDropdown(controller: controller, theme: theme),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => AppDropdown<String>(
                              label: 'unit'.tr,
                              value: controller.rxUnit.value,
                              prefixIcon: Icons.unfold_more_rounded,
                              items: [
                                ...controller.rxUnits.map((String u) {
                                  final unitLabels = {
                                    'pcs': 'unit_pcs'.tr,
                                    'KG': 'unit_kg'.tr,
                                    'g': 'unit_g'.tr,
                                    'L': 'unit_l'.tr,
                                    'ML': 'unit_ml'.tr,
                                  };
                                  final label = unitLabels[u] ?? u;
                                  return DropdownMenuItem(value: u, child: Text(label));
                                }),
                                DropdownMenuItem(
                                  value: '+ Create New',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded, color: Colors.teal.shade600, size: 18),
                                      const SizedBox(width: 8),
                                      Text('create_new'.tr, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == '+ Create New') {
                                  _showCreateUnitDialog(context, controller);
                                } else {
                                  controller.rxUnit.value = val;
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    AppTextField(
                      controller: controller.nameController,
                      label: 'item_name'.tr,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: controller.skuController,
                      label: 'sku'.tr,
                    ),
                    const SizedBox(height: 16),
                    _CategoryDropdown(controller: controller, theme: theme),
                    const SizedBox(height: 16),
                    Obx(
                      () => AppDropdown<String>(
                        label: 'unit'.tr,
                        value: controller.rxUnit.value,
                        prefixIcon: Icons.unfold_more_rounded,
                        items: [
                          ...controller.rxUnits.map((String u) {
                            final unitLabels2 = {
                              'pcs': 'unit_pcs'.tr,
                              'KG': 'unit_kg'.tr,
                              'g': 'unit_g'.tr,
                              'L': 'unit_l'.tr,
                              'ML': 'unit_ml'.tr,
                            };
                            final label = unitLabels2[u] ?? u;
                            return DropdownMenuItem(value: u, child: Text(label));
                          }),
                          DropdownMenuItem(
                            value: '+ Create New',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: Colors.teal.shade600, size: 18),
                                const SizedBox(width: 8),
                                Text('create_new'.tr, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == '+ Create New') {
                            _showCreateUnitDialog(context, controller);
                          } else {
                            controller.rxUnit.value = val;
                          }
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Pricing & Barcode ──
                  if (isWide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FormSection(
                                icon: Icons.attach_money_rounded,
                                color: Colors.green.shade600,
                                title: 'pricing_section'.tr,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppNumberField(
                                      controller: controller.costController,
                                      label: 'cost'.tr,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppNumberField(
                                      controller: controller.priceController,
                                      label: 'sale_price'.tr,
                                      required: true,
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
                              FormSection(
                                icon: Icons.qr_code_rounded,
                                color: Colors.deepPurple.shade500,
                                title: 'barcode_section'.tr,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: controller.barcodeController,
                                      label: 'barcode'.tr,
                                      required: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _BarcodeActionButton(
                                    icon: Icons.auto_awesome_rounded,
                                    color: Colors.amber.shade700,
                                    tooltip: 'auto_generate'.tr,
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
                                                  'generated_barcode'.tr,
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
                                                FilledButton(onPressed: () => Get.back(), child: Text('close'.tr)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        barrierDismissible: false,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  _BarcodeActionButton(
                                    icon: Icons.qr_code_scanner_rounded,
                                    color: colorScheme.primary,
                                    tooltip: 'scan'.tr,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    FormSection(
                      icon: Icons.attach_money_rounded,
                      color: Colors.green.shade600,
                      title: 'pricing_section'.tr,
                    ),
                    const SizedBox(height: 16),
                    AppNumberField(
                      controller: controller.costController,
                      label: 'cost'.tr,
                    ),
                    const SizedBox(height: 16),
                    AppNumberField(
                      controller: controller.priceController,
                      label: 'sale_price'.tr,
                      required: true,
                    ),
                    const SizedBox(height: 24),
                    FormSection(
                      icon: Icons.qr_code_rounded,
                      color: Colors.deepPurple.shade500,
                      title: 'barcode_section'.tr,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: controller.barcodeController,
                            label: 'barcode'.tr,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BarcodeActionButton(
                          icon: Icons.auto_awesome_rounded,
                          color: Colors.amber.shade700,
                          tooltip: 'auto_generate'.tr,
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
                                        'generated_barcode'.tr,
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
                                      FilledButton(onPressed: () => Get.back(), child: Text('close'.tr)),
                                    ],
                                  ),
                                ),
                              ),
                              barrierDismissible: false,
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        _BarcodeActionButton(
                          icon: Icons.qr_code_scanner_rounded,
                          color: colorScheme.primary,
                          tooltip: 'scan'.tr,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Sale Price Type Toggle ──
                  _TaxTypeSelector(controller: controller),

                  const SizedBox(height: 24),

                  // ── Tax Section ──
                  FormSection(
                    icon: Icons.percent_rounded,
                    color: Colors.indigo.shade600,
                    title: 'taxes_section'.tr,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _TaxSection(controller: controller, theme: theme),
                  ),

                  const SizedBox(height: 24),

                  // ── Expiry Toggle ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                    ),
                    child: Obx(
                      () => SwitchListTile(
                        title: Text(
                          'has_expiry_date'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.orange),
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
                  // ── Opening Stock & Batches Section (Visible ONLY when has_expiry_date is true) ──
                  Obx(() {
                    if (!controller.hasExpiry.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _BatchesSection(controller: controller, theme: theme, isWide: isWide),
                      ],
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Get.back(),
        onSave: controller.saveItem,
        saveLabel: isEditing ? 'update_item'.tr : 'save_item'.tr,
        saveButtonColor: isEditing ? Colors.orange.shade700 : Colors.teal.shade700,
      ),
    );
  }

  void _showCreateUnitDialog(BuildContext context, ControllerItemForm controller) {
    final tc = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('new_unit'.tr),
        content: TextField(
          controller: tc,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'unit_name'.tr,
            hintText: 'unit_name_hint'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) {
            final newUnit = tc.text.trim();
            if (newUnit.isNotEmpty) {
              if (!controller.rxUnits.contains(newUnit)) {
                controller.rxUnits.add(newUnit);
              }
              controller.rxUnit.value = newUnit;
            }
            Get.back();
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () {
              final newUnit = tc.text.trim();
              if (newUnit.isNotEmpty) {
                if (!controller.rxUnits.contains(newUnit)) {
                  controller.rxUnits.add(newUnit);
                }
                controller.rxUnit.value = newUnit;
              }
              Get.back();
            },
            child: Text('create'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
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
      final currentCategory = controller.rxCategory.value?.trim();
      final uniqueCategories = <String>[];
      for (final cat in controller.rxCategories) {
        final trimmed = cat.trim();
        if (trimmed.isNotEmpty && !uniqueCategories.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
          uniqueCategories.add(trimmed);
        }
      }
      if (currentCategory != null &&
          currentCategory.isNotEmpty &&
          !uniqueCategories.any((c) => c.toLowerCase() == currentCategory.toLowerCase())) {
        uniqueCategories.add(currentCategory);
      }

      final cats = [...uniqueCategories, '+ Create New'];
      final selectedCategory = currentCategory != null
          ? uniqueCategories.firstWhereOrNull((c) => c.toLowerCase() == currentCategory.toLowerCase())
          : null;

      return AppDropdown<String>(
        value: selectedCategory,
        label: 'category'.tr,
        prefixIcon: Icons.category_outlined,
        items: cats.map((c) {
          if (c == '+ Create New') {
            return DropdownMenuItem(
              value: c,
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.teal.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text('create_new'.tr, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
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
            Text('new_category'.tr),
          ],
        ),
        content: TextField(
          controller: tc,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'category_name'.tr,
            hintText: 'category_name_hint'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) {
            controller.createCategory(tc.text);
            Get.back();
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () {
              controller.createCategory(tc.text);
              Get.back();
            },
            child: Text('create'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
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

      final List<DropdownMenuItem<int?>> items = [
        DropdownMenuItem<int?>(value: null, child: Text('none'.tr)),
        ...presets.map((t) => DropdownMenuItem<int?>(
          value: t.id,
          child: Text('${t.name} (${t.rate}%)'),
        )),
        const DropdownMenuItem<int?>(value: -1, child: _CreateNewTaxItem()),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int?>(
            initialValue: presets.any((t) => t.id == selectedId) ? selectedId : null,
            decoration: InputDecoration(
              labelText: 'tax_rate'.tr,
              prefixIcon: Icon(Icons.percent_rounded, color: Colors.indigo.shade400, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: theme.colorScheme.surface,
              filled: true,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
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

          if (controller.rxTaxRate.value > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Colors.indigo.shade400),
                const SizedBox(width: 6),
                Text(
                  controller.rxSalePriceType.value == 'inclusive'
                      ? 'price_inclusive_of_tax'.tr
                      : 'tax_added_on_top'.tr,
                  style: TextStyle(fontSize: 12, color: Colors.indigo.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _TaxInfoChip(
                  label: 'tax_amt'.tr,
                  value: controller.rxComputedTaxAmount.value.toStringAsFixed(2),
                  color: Colors.red.shade600,
                  icon: Icons.percent_rounded,
                ),
                _TaxInfoChip(
                  label: 'base_price'.tr,
                  value: controller.rxComputedBasePrice.value.toStringAsFixed(2),
                  color: Colors.orange.shade700,
                  icon: Icons.price_change_outlined,
                ),
                _TaxInfoChip(
                  label: 'total_price'.tr,
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
            Text('new_tax'.tr),
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
                labelText: 'tax_name'.tr,
                hintText: 'tax_name_hint'.tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateTc,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${'rate'.tr} (%)',
                hintText: 'rate_hint'.tr,
                suffixText: '%',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () async {
              final rate = double.tryParse(rateTc.text) ?? 0;
              final tax = await controller.createTaxPreset(nameTc.text, rate);
              Get.back();
              if (tax != null) {
                Get.snackbar('tax_created'.tr, '${tax.name} ${tax.rate}% ${'add'.tr}', duration: const Duration(seconds: 2));
              }
            },
            child: Text('create_and_apply'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
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
        Text('create_new_tax'.tr, style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.w600)),
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
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha:0.2)),
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
          color: theme.colorScheme.secondaryContainer.withValues(alpha:0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha:0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.sell_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'sale_price_type'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            SegmentedButton<String>(
              segments: [
                ButtonSegment<String>(
                  value: 'exclusive',
                  label: Text('excl_tax'.tr),
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                ),
                ButtonSegment<String>(
                  value: 'inclusive',
                  label: Text('incl_tax'.tr),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                ),
              ],
              selected: {currentType},
              onSelectionChanged: (selected) {
                controller.rxSalePriceType.value = selected.first;
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _BatchesSection extends StatelessWidget {
  final ControllerItemForm controller;
  final ThemeData theme;
  final bool isWide;

  const _BatchesSection({
    required this.controller,
    required this.theme,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FormSection(
                icon: Icons.inventory_2_rounded,
                color: Colors.purple.shade700,
                title: 'Opening Stock & Batches',
              ),
              Obx(() {
                final totalQty = controller.rxBatches.fold<int>(
                  0,
                  (sum, b) => sum + (b.quantity ?? 0),
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Batches: ${controller.rxBatches.length}  |  Total Stock: $totalQty',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Inputs Card matching Photo 2
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: controller.batchNoController,
                          label: 'Batch No.',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppNumberField(
                          controller: controller.batchQtyController,
                          label: 'Qty',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppNumberField(
                          controller: controller.batchMrpController,
                          label: 'Cost',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppNumberField(
                          controller: controller.batchSalesRateController,
                          label: 'Sales Rate',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppDatePicker(
                          controller: controller.batchMfgDateController,
                          label: 'Mfg. Date',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (picked != null) {
                              controller.batchMfgDateController.text = dateFormat.format(picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppDatePicker(
                          controller: controller.batchExpiryDateController,
                          label: 'Expiry Date',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 180)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (picked != null) {
                              controller.batchExpiryDateController.text = dateFormat.format(picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: controller.addBatch,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Batch'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: controller.batchNoController,
                          label: 'Batch No.',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppNumberField(
                          controller: controller.batchQtyController,
                          label: 'Qty',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppNumberField(
                          controller: controller.batchMrpController,
                          label: 'Cost',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppNumberField(
                          controller: controller.batchSalesRateController,
                          label: 'Sales Rate',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppDatePicker(
                          controller: controller.batchMfgDateController,
                          label: 'Mfg. Date',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (picked != null) {
                              controller.batchMfgDateController.text = dateFormat.format(picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppDatePicker(
                          controller: controller.batchExpiryDateController,
                          label: 'Expiry Date',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 180)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (picked != null) {
                              controller.batchExpiryDateController.text = dateFormat.format(picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: controller.addBatch,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Batch'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Batches Data Table matching Photo 2
          Obx(() {
            final batches = controller.rxBatches;
            if (batches.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
                ),
                child: Text(
                  'No batches added yet. Fill in batch details above and click "Add Batch".',
                  style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 13),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      theme.brightness == Brightness.dark
                          ? const Color(0xFF263238)
                          : const Color(0xFFE0F2F1),
                    ),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: cs.onSurface,
                    ),
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 44,
                    columns: const [
                      DataColumn(label: Text('Batch No.')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Cost')),
                      DataColumn(label: Text('Sales Rate')),
                      DataColumn(label: Text('Mfg. Date')),
                      DataColumn(label: Text('Expiry Date')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: List.generate(batches.length, (index) {
                      final b = batches[index];
                      final mfgStr = b.mfgDateUtcMs != null
                          ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(b.mfgDateUtcMs!, isUtc: true).toLocal())
                          : '-';
                      final expStr = b.expiryDateUtcMs != null
                          ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(b.expiryDateUtcMs!, isUtc: true).toLocal())
                          : '-';

                      return DataRow(
                        color: WidgetStateProperty.resolveWith((states) {
                          if (index.isOdd) {
                            return cs.surfaceContainerHighest.withValues(alpha: 0.25);
                          }
                          return Colors.transparent;
                        }),
                        cells: [
                          DataCell(
                            Text(
                              b.batchNo ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text('${b.quantity ?? 0}')),
                          DataCell(Text(b.mrp != null ? '₹${b.mrp!.toStringAsFixed(2)}' : '-')),
                          DataCell(
                            Text(
                              b.salePrice != null ? '₹${b.salePrice!.toStringAsFixed(2)}' : '-',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade700),
                            ),
                          ),
                          DataCell(Text(mfgStr)),
                          DataCell(
                            Text(
                              expStr,
                              style: TextStyle(
                                color: b.expiryDateUtcMs != null &&
                                        b.expiryDateUtcMs! < DateTime.now().millisecondsSinceEpoch
                                    ? Colors.red
                                    : cs.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              tooltip: 'Remove Batch',
                              onPressed: () => controller.removeBatch(index),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
