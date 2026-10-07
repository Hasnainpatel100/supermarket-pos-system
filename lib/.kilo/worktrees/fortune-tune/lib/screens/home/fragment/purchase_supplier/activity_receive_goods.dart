import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:super_market/screens/home/fragment/purchase_supplier/purchase/controller_home_purchase.dart';

import '../../../../enums/enum_purchase_status.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../model/entity_purchase_item.dart';
import '../../../../util/snackbar_util.dart';
import '../../../../widget/my_card.dart';

/// Receive Goods Screen.
///
/// Supports MULTI-BATCH per item:
///   Milk 100 units → BATCH001 (60 units, exp 01 Apr) + BATCH002 (40 units, exp 15 Apr)
///
/// For each item row, user can add N batch sub-rows.
/// Each batch sub-row has: qty + batchNo + expiryDate (if hasExpiry).
///
/// On confirm → for each batch sub-row:
///   StockTransaction (purchaseIn)   ← one per batch
///   ItemBatch (if hasExpiry)        ← one per batch
///   EntityItem.totalQty += qty      ← cumulative
///   PurchaseItem.receivedQty += qty ← cumulative
class ActivityReceiveGoods extends StatefulWidget {
  const ActivityReceiveGoods({super.key});

  @override
  State<ActivityReceiveGoods> createState() => _ActivityReceiveGoodsState();
}

class _ActivityReceiveGoodsState extends State<ActivityReceiveGoods> {
  late final ControllerHomePurchase _controller;
  late final EntityPurchase _purchase;
  late List<_ReceiveItemRow> _rows;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ControllerHomePurchase>()
        ? Get.find<ControllerHomePurchase>()
        : Get.put(ControllerHomePurchase());

    _purchase = Get.arguments as EntityPurchase;
    final purchaseItems = _controller.getItemsForPurchase(_purchase.id);
    final pendingItems =
    purchaseItems.where((pi) => !pi.isFullyReceived).toList();

    // Load item details to get hasExpiry flag
    final allItems = _controller.getAllActiveItems();

    _rows = pendingItems.map((pi) {
      final item = allItems.where((i) => i.id == pi.itemId).firstOrNull;
      final needsExpiry = item?.hasExpiry ?? false;
      return _ReceiveItemRow(pi, needsExpiry: needsExpiry);
    }).toList();
  }

  // ─────────────────────────────────────────────
  //  VALIDATE & CONFIRM
  // ─────────────────────────────────────────────

  void _confirm() {
    for (final row in _rows) {
      if (!row.willReceive) continue;

      if (row.batches.isEmpty) {
        SnackbarUtil.showError(
            'Add at least one batch for ${row.purchaseItem.itemName}');
        return;
      }

      double totalEntered = 0;
      for (final b in row.batches) {
        final qty = double.tryParse(b.qtyCtrl.text) ?? 0;
        if (qty <= 0) {
          SnackbarUtil.showError(
              'Batch qty must be > 0 for ${row.purchaseItem.itemName}');
          return;
        }
        if (row.needsExpiry && b.expiryDateMs == null) {
          SnackbarUtil.showError(
              'Set expiry date for all batches of ${row.purchaseItem.itemName}');
          return;
        }
        totalEntered += qty;
      }

      final pending = row.purchaseItem.pendingQty;
      if (totalEntered > pending) {
        SnackbarUtil.showError(
            '${row.purchaseItem.itemName}: total entered '
                '(${totalEntered.toStringAsFixed(0)}) exceeds pending '
                '(${pending.toStringAsFixed(0)})');
        return;
      }
    }

    final activeRows = _rows.where((r) => r.willReceive).toList();
    if (activeRows.isEmpty) {
      SnackbarUtil.showError('Select at least one item to receive');
      return;
    }

    // Build flat list of ReceiveItemInput — one entry per batch sub-row
    final inputs = <ReceiveItemInput>[];
    for (final row in activeRows) {
      for (final b in row.batches) {
        final qty = (double.tryParse(b.qtyCtrl.text) ?? 0).toInt();
        if (qty <= 0) continue;
        inputs.add(ReceiveItemInput(
          itemId: row.purchaseItem.itemId!,
          receivedQty: qty,
          batchNo: b.batchCtrl.text.trim().isNotEmpty
              ? b.batchCtrl.text.trim()
              : null,
          expiryDateUtcMs: b.expiryDateMs,
        ));
      }
    }

    setState(() => _isSaving = true);

    final error = _controller.receiveGoods(
      purchase: _purchase,
      receivedItems: inputs,
    );

    setState(() => _isSaving = false);

    if (error != null) {
      SnackbarUtil.showError(error);
      return;
    }

    SnackbarUtil.showSuccess('Goods received successfully!');
    Get.back();
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = PurchaseStatus.values[_purchase.status ?? 0];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade800]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.move_to_inbox_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Receive Goods',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  '${_purchase.purchaseNo} · ${_purchase.supplierName}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _rows.isEmpty
          ? _buildAlreadyReceived()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Purchase summary ──
            MyCard(
              child: Row(children: [
                _summaryChip('PO Number',
                    _purchase.purchaseNo ?? '-', Colors.deepPurple),
                const SizedBox(width: 24),
                _summaryChip('Supplier',
                    _purchase.supplierName ?? '-', Colors.indigo),
                const SizedBox(width: 24),
                _summaryChip('Status', status.label,
                    Color(status.colorValue)),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Warning note ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Receiving goods will create StockTransactions and update inventory immediately. This cannot be undone.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.amber.shade800),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── One card per item ──
            ...List.generate(
                _rows.length, (i) => _buildItemCard(_rows[i])),

            const SizedBox(height: 24),

            // ── Action buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.green.shade500,
                      Colors.green.shade800
                    ]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _confirm,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        child: Row(children: [
                          _isSaving
                              ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                              : const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20),
                          const SizedBox(width: 8),
                          const Text('Confirm Goods Received',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ITEM CARD — one card per PurchaseItem,
  //  contains expandable batch sub-rows
  // ─────────────────────────────────────────────

  Widget _buildItemCard(_ReceiveItemRow row) {
    final pi = row.purchaseItem;

    return MyCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Item header ──
          Row(children: [
            Checkbox(
              value: row.willReceive,
              onChanged: (val) =>
                  setState(() => row.willReceive = val ?? false),
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pi.itemName ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _infoChip(
                        'Ordered: ${pi.orderedQty?.toStringAsFixed(0) ?? 0} ${pi.itemUnit ?? ''}',
                        Colors.grey),
                    const SizedBox(width: 8),
                    _infoChip(
                        'Received: ${pi.receivedQty?.toStringAsFixed(0) ?? 0}',
                        Colors.green),
                    const SizedBox(width: 8),
                    _infoChip(
                        'Pending: ${pi.pendingQty.toStringAsFixed(0)}',
                        Colors.orange),
                  ]),
                ],
              ),
            ),
            if (row.needsExpiry)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.event_rounded,
                      size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text('Expiry Tracked',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700)),
                ]),
              ),
          ]),

          // ── Batch section (visible only when willReceive) ──
          if (row.willReceive) ...[
            const Divider(height: 20),

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                const SizedBox(width: 32), // badge width
                const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child: _colHeader(
                        'Qty to Receive', Icons.numbers_rounded)),
                const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child:
                    _colHeader('Batch No', Icons.qr_code_rounded)),
                if (row.needsExpiry) ...[
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 2,
                      child: _colHeader(
                          'Expiry Date', Icons.event_rounded)),
                ],
                const SizedBox(width: 40), // remove button width
              ]),
            ),
            const SizedBox(height: 6),

            // Batch sub-rows
            ...List.generate(
                row.batches.length,
                    (i) => _buildBatchRow(row, i)),

            const SizedBox(height: 4),

            // Add batch button
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => row.batches.add(_BatchRow())),
                icon: Icon(Icons.add_circle_outline_rounded,
                    size: 18, color: Colors.teal.shade600),
                label: Text('Add Another Batch',
                    style: TextStyle(
                        color: Colors.teal.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),

            // Total indicator
            _buildTotalIndicator(row),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BATCH SUB-ROW
  // ─────────────────────────────────────────────

  Widget _buildBatchRow(_ReceiveItemRow row, int index) {
    final b = row.batches[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Batch number badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${index + 1}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700)),
          ),
          const SizedBox(width: 8),

          // Qty
          Expanded(
            flex: 2,
            child: TextField(
              controller: b.qtyCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}), // refresh total indicator
              decoration: InputDecoration(
                hintText: '0',
                suffixText: row.purchaseItem.itemUnit ?? '',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Batch No
          Expanded(
            flex: 2,
            child: TextField(
              controller: b.batchCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. BATCH00${index + 1}',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                isDense: true,
              ),
            ),
          ),

          // Expiry Date — only shown when item.hasExpiry == true
          if (row.needsExpiry) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => _pickExpiry(b),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: b.expiryDateMs != null
                          ? Colors.green.shade400
                          : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: b.expiryDateMs != null
                        ? Colors.green.withOpacity(0.04)
                        : null,
                  ),
                  child: Row(children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: b.expiryDateMs != null
                          ? Colors.green.shade600
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      b.expiryDateMs != null
                          ? DateFormat('dd MMM yy').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              b.expiryDateMs!,
                              isUtc: true))
                          : 'Set expiry',
                      style: TextStyle(
                          fontSize: 12,
                          color: b.expiryDateMs != null
                              ? Colors.green.shade700
                              : Colors.grey.shade400),
                    ),
                  ]),
                ),
              ),
            ),
          ],

          // Remove batch button
          IconButton(
            onPressed: row.batches.length > 1
                ? () => setState(() => row.batches.removeAt(index))
                : null,
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              size: 20,
              color: row.batches.length > 1
                  ? Colors.red.shade400
                  : Colors.grey.shade300,
            ),
            tooltip: 'Remove batch',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TOTAL INDICATOR per item
  // ─────────────────────────────────────────────

  Widget _buildTotalIndicator(_ReceiveItemRow row) {
    final total = row.batches.fold<double>(
        0, (sum, b) => sum + (double.tryParse(b.qtyCtrl.text) ?? 0));
    final pending = row.purchaseItem.pendingQty;
    final isOver = total > pending;
    final isMatch = total > 0 && total == pending;

    return Container(
      margin: const EdgeInsets.only(top: 6, left: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOver
            ? Colors.red.withOpacity(0.06)
            : isMatch
            ? Colors.green.withOpacity(0.06)
            : Colors.blue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOver
              ? Colors.red.shade200
              : isMatch
              ? Colors.green.shade200
              : Colors.blue.shade100,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOver
                ? '⚠ Exceeds pending by ${(total - pending).toStringAsFixed(0)}'
                : isMatch
                ? '✓ Fully covered'
                : '${(pending - total).toStringAsFixed(0)} units still unassigned',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOver
                  ? Colors.red.shade700
                  : isMatch
                  ? Colors.green.shade700
                  : Colors.blue.shade700,
            ),
          ),
          Text(
            'Total: ${total.toStringAsFixed(0)} / ${pending.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOver ? Colors.red.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  Future<void> _pickExpiry(_BatchRow batch) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(
              () => batch.expiryDateMs = picked.toUtc().millisecondsSinceEpoch);
    }
  }

  Widget _buildAlreadyReceived() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.green.shade100, Colors.teal.shade100]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                size: 64, color: Colors.green.shade500),
          ),
          const SizedBox(height: 16),
          const Text('All items fully received!',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('This purchase order is complete.',
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Get.back(),
              child: const Text('Go Back')),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 2),
      Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color)),
      ),
    ]);
  }

  Widget _infoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
              color == Colors.grey ? Colors.grey.shade700 : color)),
    );
  }

  Widget _colHeader(String text, IconData icon) {
    return Row(children: [
      Icon(icon, size: 13, color: Colors.grey.shade500),
      const SizedBox(width: 4),
      Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600)),
    ]);
  }
}

// ─────────────────────────────────────────────
//  DATA CLASSES
// ─────────────────────────────────────────────

/// One row per PurchaseItem. Contains N batch sub-rows.
class _ReceiveItemRow {
  final EntityPurchaseItem purchaseItem;
  final bool needsExpiry;
  bool willReceive = true;

  /// Starts with one empty batch. User can add more.
  final List<_BatchRow> batches;

  _ReceiveItemRow(this.purchaseItem, {required this.needsExpiry})
      : batches = [_BatchRow()];
}

/// One batch entry: qty + batchNo + optional expiry date.
class _BatchRow {
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController batchCtrl = TextEditingController();
  int? expiryDateMs;
}
