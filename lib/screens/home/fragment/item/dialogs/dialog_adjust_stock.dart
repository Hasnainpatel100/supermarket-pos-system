import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../model/entity_item.dart';
import '../../../../../model/entity_item_batch.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/app_dialog_components.dart';
import '../controller_home_item.dart';

/// Professional, feature-rich Dialog for Adjusting Stock.
/// Supports:
/// 1. Increment (default) with multiple batch creation (like Add Item screen) or direct count.
/// 2. Decrement by selecting specific batches with deduction quantities, or manually by counting if no batch is available.
class DialogAdjustStock extends StatefulWidget {
  final EntityItem entityItem;

  const DialogAdjustStock({super.key, required this.entityItem});

  @override
  State<DialogAdjustStock> createState() => _DialogAdjustStockState();
}

class _DialogAdjustStockState extends State<DialogAdjustStock> {
  late final ControllerHomeItem controller;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  // Toggle mode: true = Increment, false = Decrement
  final RxBool isIncrement = true.obs;

  // ── Increment State (Multi-batch & direct count) ──
  final RxList<EntityItemBatch> rxAddedBatches = <EntityItemBatch>[].obs;
  final batchNoCtrl = TextEditingController();
  final batchQtyCtrl = TextEditingController(text: '1');
  final batchCostCtrl = TextEditingController();
  final batchSaleRateCtrl = TextEditingController();
  final batchMfgDateCtrl = TextEditingController();
  final batchExpiryDateCtrl = TextEditingController();
  final manualIncrementQtyCtrl = TextEditingController(text: '1');

  // ── Decrement State (Select batches or direct count) ──
  final RxList<EntityItemBatch> rxAvailableBatches = <EntityItemBatch>[].obs;
  // Map of batchId -> quantity to deduct
  final RxMap<int, int> rxBatchDeductions = <int, int>{}.obs;
  final manualDecrementQtyCtrl = TextEditingController(text: '1');
  final RxBool forceManualDecrement = false.obs;

  // ── Reason & Remarks ──
  final RxString selectedReason = 'Received'.obs;
  final remarksCtrl = TextEditingController();

  final List<String> incrementReasons = [
    'Received',
    'Purchase Return',
    'Count Correction',
    'Found Stock',
    'Other',
  ];

  final List<String> decrementReasons = [
    'Damaged',
    'Expired',
    'Count Correction',
    'Lost / Stolen',
    'Returned to Supplier',
    'Internal Use',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.find<ControllerHomeItem>();

    // Initial pre-fill for batch inputs
    final nextBatchNo = controller.getNextBatchNumber(widget.entityItem);
    batchNoCtrl.text = '$nextBatchNo';
    if (widget.entityItem.costPrice != null && widget.entityItem.costPrice! > 0) {
      batchCostCtrl.text = widget.entityItem.costPrice!.toStringAsFixed(2);
    }
    if (widget.entityItem.sellingPrice != null && widget.entityItem.sellingPrice! > 0) {
      batchSaleRateCtrl.text = widget.entityItem.sellingPrice!.toStringAsFixed(2);
    }

    _loadAvailableBatches();
  }

  void _loadAvailableBatches() {
    final batches = controller.getItemBatches(widget.entityItem);
    rxAvailableBatches.assignAll(batches);
    rxBatchDeductions.clear();
    for (final b in batches) {
      if (b.id != null) {
        rxBatchDeductions[b.id!] = 0;
      }
    }
  }

  @override
  void dispose() {
    batchNoCtrl.dispose();
    batchQtyCtrl.dispose();
    batchCostCtrl.dispose();
    batchSaleRateCtrl.dispose();
    batchMfgDateCtrl.dispose();
    batchExpiryDateCtrl.dispose();
    manualIncrementQtyCtrl.dispose();
    manualDecrementQtyCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }

  void _addBatchToList() {
    final batchNo = batchNoCtrl.text.trim();
    if (batchNo.isEmpty) {
      SnackbarUtil.showError('Please enter a batch number');
      return;
    }

    final qty = int.tryParse(batchQtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      SnackbarUtil.showError('Quantity must be greater than 0');
      return;
    }

    // Check duplicate batch number in current list
    if (rxAddedBatches.any((b) => b.batchNo?.toLowerCase() == batchNo.toLowerCase())) {
      SnackbarUtil.showError('Batch number "$batchNo" is already added');
      return;
    }

    int? mfgMs;
    if (batchMfgDateCtrl.text.isNotEmpty) {
      try {
        mfgMs = dateFormat.parse(batchMfgDateCtrl.text).toUtc().millisecondsSinceEpoch;
      } catch (_) {}
    }

    int? expMs;
    if (batchExpiryDateCtrl.text.isNotEmpty) {
      try {
        expMs = dateFormat.parse(batchExpiryDateCtrl.text).toUtc().millisecondsSinceEpoch;
      } catch (_) {}
    }

    final newBatch = EntityItemBatch(
      batchNo: batchNo,
      quantity: qty,
      costPrice: double.tryParse(batchCostCtrl.text.trim()) ?? widget.entityItem.costPrice,
      mrp: double.tryParse(batchCostCtrl.text.trim()) ?? widget.entityItem.costPrice,
      salePrice: double.tryParse(batchSaleRateCtrl.text.trim()) ?? widget.entityItem.sellingPrice,
      mfgDateUtcMs: mfgMs,
      expiryDateUtcMs: expMs,
    );

    rxAddedBatches.add(newBatch);

    // Prepare next batch number automatically
    final currentNum = int.tryParse(batchNo);
    if (currentNum != null) {
      batchNoCtrl.text = '${currentNum + 1}';
    } else {
      batchNoCtrl.text = '${batchNo}_1';
    }
    batchQtyCtrl.text = '1';
    batchMfgDateCtrl.clear();
    batchExpiryDateCtrl.clear();

    SnackbarUtil.showSuccess('Batch $batchNo added');
  }

  void _submitAdjustment() {
    final reason = selectedReason.value;
    final remarks = remarksCtrl.text.trim();
    final currentStock = widget.entityItem.totalQty ?? 0;

    if (isIncrement.value) {
      // ── INCREMENT ──
      if (rxAddedBatches.isNotEmpty) {
        // Save multiple batches
        final success = controller.adjustStockWithMultipleBatches(
          widget.entityItem,
          rxAddedBatches.toList(),
          reason,
          remarks: remarks.isNotEmpty ? remarks : null,
        );

        if (success) {
          final totalAdded = rxAddedBatches.fold<int>(0, (sum, b) => sum + (b.quantity ?? 0));
          SnackbarUtil.showSuccess('Added $totalAdded units across ${rxAddedBatches.length} batch(es)');
          Get.back();
        } else {
          SnackbarUtil.showError('Failed to save batches');
        }
      } else {
        // Direct manual increment count
        final qty = int.tryParse(manualIncrementQtyCtrl.text.trim()) ?? 0;
        if (qty <= 0) {
          SnackbarUtil.showError('Enter a valid quantity to increment or add batches above');
          return;
        }

        final success = controller.adjustStockDirect(
          widget.entityItem,
          qty,
          reason: reason,
          remarks: remarks.isNotEmpty ? remarks : null,
        );

        if (success) {
          SnackbarUtil.showSuccess('Added $qty unit(s) — $reason');
          Get.back();
        } else {
          SnackbarUtil.showError('Failed to update stock');
        }
      }
    } else {
      // ── DECREMENT ──
      final bool hasBatches = rxAvailableBatches.isNotEmpty && !forceManualDecrement.value;

      if (hasBatches) {
        // Decrement by selected batches
        final deductions = <int, int>{};
        int totalDeduct = 0;

        for (final entry in rxBatchDeductions.entries) {
          if (entry.value > 0) {
            deductions[entry.key] = entry.value;
            totalDeduct += entry.value;
          }
        }

        if (totalDeduct <= 0) {
          SnackbarUtil.showError('Please specify deduction quantity for at least one batch');
          return;
        }

        if (totalDeduct > currentStock) {
          SnackbarUtil.showError('Total deduction cannot exceed current stock ($currentStock)');
          return;
        }

        final success = controller.adjustStockDecrementByBatches(
          widget.entityItem,
          deductions,
          reason,
          remarks: remarks.isNotEmpty ? remarks : null,
        );

        if (success) {
          SnackbarUtil.showSuccess('Deducted $totalDeduct unit(s) from ${deductions.length} batch(es)');
          Get.back();
        } else {
          SnackbarUtil.showError('Failed to deduct from batches');
        }
      } else {
        // Decrement manually by counting
        final qty = int.tryParse(manualDecrementQtyCtrl.text.trim()) ?? 0;
        if (qty <= 0) {
          SnackbarUtil.showError('Enter a valid quantity to deduct');
          return;
        }

        if (qty > currentStock) {
          SnackbarUtil.showError('Cannot deduct $qty units. Current stock is only $currentStock');
          return;
        }

        final success = controller.adjustStockDirect(
          widget.entityItem,
          -qty,
          reason: reason,
          remarks: remarks.isNotEmpty ? remarks : null,
        );

        if (success) {
          SnackbarUtil.showSuccess('Deducted $qty unit(s) — $reason');
          Get.back();
        } else {
          SnackbarUtil.showError('Stock cannot go below 0');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppDialog(
      maxWidth: 760,
      maxHeight: 700,
      header: DialogHeader(
        title: 'Adjust Stock',
        icon: Icons.tune_rounded,
        iconColor: cs.primary,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Current Stock: ${widget.entityItem.totalQty ?? 0} ${widget.entityItem.unit ?? "Pcs"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: DialogBody(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Item Information Card ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.35)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.shopping_bag_outlined, color: cs.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.entityItem.name ?? 'Unnamed Item',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${widget.entityItem.sku ?? "-"}  •  Barcode: ${widget.entityItem.barcode ?? "-"}',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Primary 2 Options: Increment or Decrement Toggle ──
              Obx(() {
                final isInc = isIncrement.value;
                return Row(
                  children: [
                    Expanded(
                      child: _buildModeToggle(
                        title: 'Increment Stock',
                        subtitle: 'Add batches or direct count',
                        icon: Icons.add_circle_outline_rounded,
                        isSelected: isInc,
                        activeColor: Colors.green.shade600,
                        onTap: () {
                          isIncrement.value = true;
                          selectedReason.value = incrementReasons.first;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildModeToggle(
                        title: 'Decrement Stock',
                        subtitle: 'Select batches or manual count',
                        icon: Icons.remove_circle_outline_rounded,
                        isSelected: !isInc,
                        activeColor: Colors.red.shade600,
                        onTap: () {
                          isIncrement.value = false;
                          selectedReason.value = decrementReasons.first;
                          _loadAvailableBatches();
                        },
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // ── Dynamic Body: Increment View or Decrement View ──
              Obx(() {
                return isIncrement.value ? _buildIncrementView(cs, isDark) : _buildDecrementView(cs, isDark);
              }),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ── Reason & Remarks ──
              Obx(() {
                final reasons = isIncrement.value ? incrementReasons : decrementReasons;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(isIncrement.value),
                        initialValue: reasons.contains(selectedReason.value) ? selectedReason.value : reasons.first,
                        decoration: InputDecoration(
                          labelText: 'Reason for Adjustment',
                          prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: reasons
                            .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) selectedReason.value = val;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: remarksCtrl,
                        decoration: InputDecoration(
                          labelText: 'Remarks / Notes (Optional)',
                          hintText: 'Add audit note...',
                          prefixIcon: const Icon(Icons.comment_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      footer: Obx(() {
        final isInc = isIncrement.value;
        String buttonLabel = 'Save Adjustment';
        Color btnColor = Colors.teal.shade700;

        if (isInc) {
          if (rxAddedBatches.isNotEmpty) {
            final total = rxAddedBatches.fold<int>(0, (sum, b) => sum + (b.quantity ?? 0));
            buttonLabel = 'Add $total Units (${rxAddedBatches.length} Batches)';
          } else {
            final qty = int.tryParse(manualIncrementQtyCtrl.text) ?? 0;
            buttonLabel = qty > 0 ? 'Add $qty Units' : 'Save Increment';
          }
          btnColor = Colors.green.shade700;
        } else {
          final hasBatches = rxAvailableBatches.isNotEmpty && !forceManualDecrement.value;
          if (hasBatches) {
            int total = 0;
            for (final v in rxBatchDeductions.values) {
              total += v;
            }
            buttonLabel = total > 0 ? 'Deduct $total Units' : 'Deduct from Batches';
          } else {
            final qty = int.tryParse(manualDecrementQtyCtrl.text) ?? 0;
            buttonLabel = qty > 0 ? 'Deduct $qty Units' : 'Save Decrement';
          }
          btnColor = Colors.red.shade700;
        }

        return DialogFooter(
          onCancel: () => Get.back(),
          onSave: _submitAdjustment,
          saveLabel: buttonLabel,
          saveButtonColor: btnColor,
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Increment View (Multi-Batch Builder & Direct Count)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildIncrementView(ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FormSection(
              icon: Icons.inventory_2_rounded,
              color: Colors.purple.shade700,
              title: 'Add Multiple Batches',
            ),
            Obx(() {
              final total = rxAddedBatches.fold<int>(0, (sum, b) => sum + (b.quantity ?? 0));
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Batches Added: ${rxAddedBatches.length}  |  Total Units: +$total',
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
        const SizedBox(height: 12),

        // Batch Input Form (matching Add Item screen)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: batchNoCtrl,
                      label: 'Batch No.',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppNumberField(
                      controller: batchQtyCtrl,
                      label: 'Quantity',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppNumberField(
                      controller: batchCostCtrl,
                      label: 'Cost Price',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppNumberField(
                      controller: batchSaleRateCtrl,
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
                      controller: batchMfgDateCtrl,
                      label: 'Mfg. Date',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          batchMfgDateCtrl.text = dateFormat.format(picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDatePicker(
                      controller: batchExpiryDateCtrl,
                      label: 'Expiry Date',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          batchExpiryDateCtrl.text = dateFormat.format(picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _addBatchToList,
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
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Added Batches Table or Empty Manual Option
        Obx(() {
          if (rxAddedBatches.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'No batches added yet. Add batches above, or increment directly by count below:',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Direct Increment Qty: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          final current = int.tryParse(manualIncrementQtyCtrl.text) ?? 1;
                          if (current > 1) {
                            manualIncrementQtyCtrl.text = (current - 1).toString();
                          }
                        },
                        icon: const Icon(Icons.remove, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: manualIncrementQtyCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final current = int.tryParse(manualIncrementQtyCtrl.text) ?? 1;
                          manualIncrementQtyCtrl.text = (current + 1).toString();
                        },
                        icon: const Icon(Icons.add, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Table of Batches
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
                    isDark ? const Color(0xFF263238) : const Color(0xFFE0F2F1),
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: cs.onSurface,
                  ),
                  dataRowMinHeight: 38,
                  dataRowMaxHeight: 42,
                  columns: const [
                    DataColumn(label: Text('Batch No.')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Cost')),
                    DataColumn(label: Text('Sales Rate')),
                    DataColumn(label: Text('Mfg. Date')),
                    DataColumn(label: Text('Expiry Date')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: List.generate(rxAddedBatches.length, (index) {
                    final b = rxAddedBatches[index];
                    final mfgStr = b.mfgDateUtcMs != null
                        ? dateFormat.format(
                            DateTime.fromMillisecondsSinceEpoch(b.mfgDateUtcMs!, isUtc: true).toLocal(),
                          )
                        : '-';
                    final expStr = b.expiryDateUtcMs != null
                        ? dateFormat.format(
                            DateTime.fromMillisecondsSinceEpoch(b.expiryDateUtcMs!, isUtc: true).toLocal(),
                          )
                        : '-';

                    return DataRow(
                      cells: [
                        DataCell(Text(b.batchNo ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text('${b.quantity ?? 0}', style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(b.costPrice != null ? '₹${b.costPrice!.toStringAsFixed(2)}' : '-')),
                        DataCell(Text(b.salePrice != null ? '₹${b.salePrice!.toStringAsFixed(2)}' : '-')),
                        DataCell(Text(mfgStr)),
                        DataCell(Text(expStr)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => rxAddedBatches.removeAt(index),
                            tooltip: 'Remove',
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Decrement View (Select Batches or Manual Counting)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDecrementView(ColorScheme cs, bool isDark) {
    final availableBatches = rxAvailableBatches;
    final bool hasBatches = availableBatches.isNotEmpty;

    if (!hasBatches || forceManualDecrement.value) {
      // ── Manual Count Decrement (Used when no batch is available or explicitly toggled) ──
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasBatches
                          ? 'Manual counting mode selected. Stock will be reduced directly.'
                          : 'No active batches available for this item. Decrement stock manually by counting.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                  if (hasBatches) ...[
                    TextButton(
                      onPressed: () => forceManualDecrement.value = false,
                      child: const Text('Switch to Batches', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Enter Quantity to Decrement',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(manualDecrementQtyCtrl.text) ?? 1;
                    if (current > 1) {
                      manualDecrementQtyCtrl.text = (current - 1).toString();
                    }
                  },
                  icon: const Icon(Icons.remove, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: manualDecrementQtyCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(manualDecrementQtyCtrl.text) ?? 1;
                    final maxStock = widget.entityItem.totalQty ?? 0;
                    if (current < maxStock) {
                      manualDecrementQtyCtrl.text = (current + 1).toString();
                    }
                  },
                  icon: const Icon(Icons.add, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Selection Chips
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('-1'),
                  onPressed: () => manualDecrementQtyCtrl.text = '1',
                ),
                ActionChip(
                  label: const Text('-5'),
                  onPressed: () {
                    final max = widget.entityItem.totalQty ?? 0;
                    manualDecrementQtyCtrl.text = (5 > max ? max : 5).toString();
                  },
                ),
                ActionChip(
                  label: const Text('-10'),
                  onPressed: () {
                    final max = widget.entityItem.totalQty ?? 0;
                    manualDecrementQtyCtrl.text = (10 > max ? max : 10).toString();
                  },
                ),
                ActionChip(
                  label: Text('All (${widget.entityItem.totalQty ?? 0})'),
                  onPressed: () => manualDecrementQtyCtrl.text = '${widget.entityItem.totalQty ?? 0}',
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── Decrement by Selecting Available Batches ──
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FormSection(
              icon: Icons.checklist_rounded,
              color: Colors.red.shade700,
              title: 'Select Batches to Decrement',
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => forceManualDecrement.value = true,
                  icon: const Icon(Icons.calculate_outlined, size: 16),
                  label: const Text('Decrement Manually', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  int total = 0;
                  for (final v in rxBatchDeductions.values) {
                    total += v;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Total Deducting: -$total Units',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
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
                  isDark ? const Color(0xFF263238) : const Color(0xFFFFEBEE),
                ),
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: cs.onSurface,
                ),
                dataRowMinHeight: 46,
                dataRowMaxHeight: 52,
                columns: const [
                  DataColumn(label: Text('Batch No.')),
                  DataColumn(label: Text('In Stock')),
                  DataColumn(label: Text('Sales Rate')),
                  DataColumn(label: Text('Expiry Date')),
                  DataColumn(label: Text('Deduct Quantity')),
                ],
                rows: List.generate(availableBatches.length, (index) {
                  final b = availableBatches[index];
                  final maxQty = b.quantity ?? 0;
                  final expStr = b.expiryDateUtcMs != null
                      ? dateFormat.format(
                          DateTime.fromMillisecondsSinceEpoch(b.expiryDateUtcMs!, isUtc: true).toLocal(),
                        )
                      : 'No Expiry';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          b.batchNo ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$maxQty units',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                        ),
                      ),
                      DataCell(Text(b.salePrice != null ? '₹${b.salePrice!.toStringAsFixed(2)}' : '-')),
                      DataCell(Text(expStr)),
                      DataCell(
                        Obx(() {
                          final currentDeduct = rxBatchDeductions[b.id] ?? 0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: currentDeduct > 0
                                    ? () => rxBatchDeductions[b.id!] = currentDeduct - 1
                                    : null,
                              ),
                              Container(
                                width: 44,
                                alignment: Alignment.center,
                                child: Text(
                                  '$currentDeduct',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: currentDeduct > 0 ? Colors.red.shade700 : cs.onSurface,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: currentDeduct < maxQty
                                    ? () => rxBatchDeductions[b.id!] = currentDeduct + 1
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () {
                                  rxBatchDeductions[b.id!] = currentDeduct == maxQty ? 0 : maxQty;
                                },
                                child: Text(currentDeduct == maxQty ? 'Clear' : 'Max'),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mode Toggle Button Component
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildModeToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? activeColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? activeColor.withValues(alpha: 0.8) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: activeColor, size: 20),
          ],
        ),
      ),
    );
  }
}
