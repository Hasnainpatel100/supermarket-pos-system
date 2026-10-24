import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../model/entity_item.dart';
import '../../../../../model/entity_item_batch.dart';
import '../../../../../model/entity_stock_transaction.dart';
import '../../../../../model/stock_txn_type.dart';
import '../../../../../objectbox.g.dart';
import '../../../../../service/service_object_box.dart';
import '../../../../../util/snackbar_util.dart';
import '../controller_home_item.dart';
import '../../pos/controller_home_pos.dart';

class DialogItemBatches extends StatefulWidget {
  final EntityItem entityItem;

  const DialogItemBatches({super.key, required this.entityItem});

  @override
  State<DialogItemBatches> createState() => _DialogItemBatchesState();
}

class _DialogItemBatchesState extends State<DialogItemBatches> {
  late final Box<EntityItemBatch> _boxBatch;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityStockTransaction> _boxStockTxn;

  List<EntityItemBatch> _batches = [];
  bool _showAddBatch = false;

  final TextEditingController _batchNoCtrl = TextEditingController();
  final TextEditingController _batchQtyCtrl = TextEditingController(text: '1');
  final TextEditingController _batchCostCtrl = TextEditingController();
  final TextEditingController _batchSalePriceCtrl = TextEditingController();
  final TextEditingController _batchMfgDateCtrl = TextEditingController();
  final TextEditingController _batchExpiryDateCtrl = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final ob = Get.find<ServiceObjectBox>();
    _boxBatch = ob.box<EntityItemBatch>();
    _boxItem = ob.box<EntityItem>();
    _boxStockTxn = ob.box<EntityStockTransaction>();

    if (widget.entityItem.costPrice != null && widget.entityItem.costPrice! > 0) {
      _batchCostCtrl.text = widget.entityItem.costPrice!.toStringAsFixed(2);
    }
    if (widget.entityItem.sellingPrice != null && widget.entityItem.sellingPrice! > 0) {
      _batchSalePriceCtrl.text = widget.entityItem.sellingPrice!.toStringAsFixed(2);
    }

    _loadBatches();
  }

  @override
  void dispose() {
    _batchNoCtrl.dispose();
    _batchQtyCtrl.dispose();
    _batchCostCtrl.dispose();
    _batchSalePriceCtrl.dispose();
    _batchMfgDateCtrl.dispose();
    _batchExpiryDateCtrl.dispose();
    super.dispose();
  }

  void _loadBatches() {
    final allBatches = _boxBatch
        .query(EntityItemBatch_.itemId.equals(widget.entityItem.id ?? 0))
        .order(EntityItemBatch_.expiryDateUtcMs)
        .build()
        .find();

    final activeBatches = <EntityItemBatch>[];
    for (final b in allBatches) {
      if ((b.quantity ?? 0) <= 0) {
        if (b.id != null && b.id! > 0) {
          _boxBatch.remove(b.id!);
        }
      } else {
        activeBatches.add(b);
      }
    }

    setState(() {
      _batches = activeBatches;
      _batchNoCtrl.text = ControllerHomeItem.calculateNextBatchNo(
        existingBatches: _batches,
      );
    });
  }

  void _saveNewBatch() {
    final batchNo = _batchNoCtrl.text.trim();
    if (batchNo.isEmpty) {
      SnackbarUtil.showError('Please enter a batch number');
      return;
    }

    final qty = int.tryParse(_batchQtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      SnackbarUtil.showError('Quantity must be greater than 0');
      return;
    }

    // Check duplicate batch number in current batches
    if (_batches.any((b) => (b.batchNo ?? '').toLowerCase() == batchNo.toLowerCase())) {
      SnackbarUtil.showError('Batch "$batchNo" already exists for this item');
      return;
    }

    final cost = double.tryParse(_batchCostCtrl.text.trim()) ?? widget.entityItem.costPrice;
    final salePrice = double.tryParse(_batchSalePriceCtrl.text.trim()) ?? widget.entityItem.sellingPrice;

    int? mfgMs;
    if (_batchMfgDateCtrl.text.trim().isNotEmpty) {
      try {
        mfgMs = _dateFormat.parse(_batchMfgDateCtrl.text.trim()).toUtc().millisecondsSinceEpoch;
      } catch (_) {}
    }

    int? expMs;
    if (_batchExpiryDateCtrl.text.trim().isNotEmpty) {
      try {
        expMs = _dateFormat.parse(_batchExpiryDateCtrl.text.trim()).toUtc().millisecondsSinceEpoch;
      } catch (_) {}
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final newBatch = EntityItemBatch(
      itemId: widget.entityItem.id,
      batchNo: batchNo,
      quantity: qty,
      costPrice: cost,
      mrp: cost,
      salePrice: salePrice,
      mfgDateUtcMs: mfgMs,
      expiryDateUtcMs: expMs,
      receivedAtUtcMs: now,
      barcode: widget.entityItem.barcode,
    );

    _boxBatch.put(newBatch);

    // Update item total quantity and expiry status
    widget.entityItem.totalQty = (widget.entityItem.totalQty ?? 0) + qty;
    widget.entityItem.hasExpiry = true;
    widget.entityItem.updatedAtUtcMs = now;
    _boxItem.put(widget.entityItem);

    // Log stock transaction
    _boxStockTxn.put(EntityStockTransaction(
      itemId: widget.entityItem.id ?? 0,
      type: StockTxnType.add.index,
      quantity: qty,
      referenceType: 'batch_add',
      referenceId: batchNo,
      remarks: 'Added batch: $batchNo (Qty: $qty)',
      createdAtUtcMs: now,
    ));

    // Reload active batches immediately so user sees it right away
    _loadBatches();

    // Reset input fields and advance batch number
    _batchQtyCtrl.text = '1';
    _batchMfgDateCtrl.clear();
    _batchExpiryDateCtrl.clear();
    setState(() {
      _showAddBatch = false;
    });

    // Notify item and pos controllers everywhere
    if (Get.isRegistered<ControllerHomeItem>()) {
      Get.find<ControllerHomeItem>().loadItems();
    }
    if (Get.isRegistered<ControllerHomePos>()) {
      Get.find<ControllerHomePos>().loadItems();
    }

    SnackbarUtil.showSuccess('Batch $batchNo added successfully!');
  }

  void _deleteBatch(EntityItemBatch batch) {
    Get.defaultDialog(
      title: 'Delete Batch',
      middleText: 'Are you sure you want to remove Batch ${batch.batchNo} (${batch.quantity ?? 0} units)?',
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        onPressed: () {
          final qty = batch.quantity ?? 0;
          if (batch.id != null) {
            _boxBatch.remove(batch.id!);
          }
          final current = widget.entityItem.totalQty ?? 0;
          widget.entityItem.totalQty = (current - qty).clamp(0, 999999999);
          final remaining = _boxBatch.query(EntityItemBatch_.itemId.equals(widget.entityItem.id ?? 0)).build().count();
          widget.entityItem.hasExpiry = remaining > 0;
          widget.entityItem.updatedAtUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;
          _boxItem.put(widget.entityItem);

          Get.back();
          _loadBatches();

          if (Get.isRegistered<ControllerHomeItem>()) {
            Get.find<ControllerHomeItem>().loadItems();
          }
          if (Get.isRegistered<ControllerHomePos>()) {
            Get.find<ControllerHomePos>().loadItems();
          }
          SnackbarUtil.showSuccess('Batch ${batch.batchNo} removed');
        },
        child: const Text('Delete'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalQty = _batches.fold<int>(0, (sum, b) => sum + (b.quantity ?? 0));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Header
            Row(
              children: [
                Icon(Icons.history_edu_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batches for ${widget.entityItem.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_batches.length} Batch(es)  •  Total Stock: $totalQty units',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAddBatch = !_showAddBatch;
                    });
                  },
                  icon: Icon(_showAddBatch ? Icons.close_rounded : Icons.add_rounded, size: 18),
                  label: Text(_showAddBatch ? 'Cancel' : '+ Add Batch'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _showAddBatch ? Colors.grey.shade700 : colorScheme.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            /// Inline Add Batch Card
            if (_showAddBatch) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'New Batch Entry (Auto-incremented)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _batchNoCtrl,
                            decoration: InputDecoration(
                              labelText: 'Batch No. *',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _batchQtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Qty *',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _batchCostCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cost Rate',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _batchSalePriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Sale Rate',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _batchMfgDateCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                              );
                              if (picked != null) {
                                _batchMfgDateCtrl.text = _dateFormat.format(picked);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Mfg. Date',
                              isDense: true,
                              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _batchExpiryDateCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 180)),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                              );
                              if (picked != null) {
                                _batchExpiryDateCtrl.text = _dateFormat.format(picked);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Expiry Date',
                              isDense: true,
                              suffixIcon: const Icon(Icons.event_busy_rounded, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _saveNewBatch,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Save Batch'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            /// List of Batches
            Expanded(
              child: _batches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            "No active batches found for this item.",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAddBatch = true;
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add First Batch Now'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _batches.length,
                      itemBuilder: (context, index) {
                        final batch = _batches[index];
                        final expiry = batch.expiryDateUtcMs != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                batch.expiryDateUtcMs!,
                                isUtc: true,
                              ).toLocal()
                            : null;

                        final received = batch.receivedAtUtcMs != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                batch.receivedAtUtcMs!,
                                isUtc: true,
                              ).toLocal()
                            : null;

                        return Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                /// Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                /// Batch Info
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Batch: ${batch.batchNo ?? "N/A"}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (received != null)
                                        Text(
                                          'Rcvd: ${_dateFormat.format(received)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      if (batch.salePrice != null || batch.costPrice != null)
                                        Text(
                                          'Sale: ₹${(batch.salePrice ?? 0).toStringAsFixed(2)}${batch.costPrice != null ? ' • Cost: ₹${batch.costPrice!.toStringAsFixed(2)}' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                /// Expiry & Qty
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Qty: ${batch.quantity ?? 0}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: (batch.quantity ?? 0) <= 0 ? Colors.red : colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (expiry != null)
                                        Text(
                                          'Exp: ${_dateFormat.format(expiry)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                /// Delete Action
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                  tooltip: 'Delete Batch',
                                  onPressed: () => _deleteBatch(batch),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
