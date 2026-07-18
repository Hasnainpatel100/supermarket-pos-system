import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:super_market/screens/home/fragment/purchase_supplier/purchase/controller_home_purchase.dart';

import '../../../../enums/enum_purchase_status.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../model/entity_purchase_item.dart';
import '../../../../model/entity_purchase_receipt.dart';
import '../../../../util/snackbar_util.dart';
import '../../../../widget/my_card.dart';
import '../../../../widget/app_dialog_components.dart';

/// Receive Goods Screen.
///
/// Supports MULTI-BATCH per item:
///   Milk 100 units → BATCH001 (60 units, exp 01 Apr) + BATCH002 (40 units, exp 15 Apr)
///
/// For each item row, user can add N batch sub-rows.
/// Each batch sub-row has: qty + batchNo + expiryDate (if hasExpiry).
///
/// Invoice Details section collects:
///   Invoice Number (required), Invoice Date (required), Bill file (optional)
///   Optional: Tax, Discount, Freight charges.
///
/// Summary section shows total items received, total amount, diff from PO.
///
/// On confirm → for each batch sub-row:
///   StockTransaction (purchaseIn)   ← one per batch
///   ItemBatch (if hasExpiry)        ← one per batch
///   EntityItem.totalQty += qty      ← cumulative
///   PurchaseItem.receivedQty += qty ← cumulative
///   EntityPurchaseReceipt saved     ← with invoice details
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
  bool _confirmed = false; // locks editing after confirmation

  // ── Invoice Detail Controllers ──
  final _invoiceNoCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _freightCtrl = TextEditingController();

  int? _invoiceDateMs;
  String? _billFilePath;

  // ── Validation error flags ──
  bool _invoiceNoError = false;
  bool _invoiceDateError = false;

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

    final allItems = _controller.getAllActiveItems();

    _rows = pendingItems.map((pi) {
      final item = allItems.where((i) => i.id == pi.itemId).firstOrNull;
      final needsExpiry = item?.hasExpiry ?? false;
      return _ReceiveItemRow(pi, needsExpiry: needsExpiry);
    }).toList();
  }

  @override
  void dispose() {
    _invoiceNoCtrl.dispose();
    _taxCtrl.dispose();
    _discountCtrl.dispose();
    _freightCtrl.dispose();
    for (final row in _rows) {
      for (final b in row.batches) {
        b.qtyCtrl.dispose();
        b.batchCtrl.dispose();
      }
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  COMPUTED SUMMARY VALUES
  // ─────────────────────────────────────────────

  int get _totalItemsReceived {
    int count = 0;
    for (final row in _rows) {
      if (!row.willReceive) continue;
      for (final b in row.batches) {
        final qty = double.tryParse(b.qtyCtrl.text) ?? 0;
        if (qty > 0) count++;
      }
    }
    return count;
  }

  late final allPayments = _controller.getPaymentsForPurchase(_purchase.id);

  /// Sum of (receivedQty × unitCost) across all active batch rows.
  /// Uses the batch-level unit cost if provided, else falls back to PO unit cost.
  double get _totalAmount {
    double total = 0;
    for (final row in _rows) {
      if (!row.willReceive) continue;
      final unitCost = row.purchaseItem.unitCost ?? 0;
      for (final b in row.batches) {
        final qty = double.tryParse(b.qtyCtrl.text) ?? 0;
        total += qty * unitCost;
      }
    }
    // Add freight, subtract discount
    total += double.tryParse(_freightCtrl.text) ?? 0;
    total -= double.tryParse(_discountCtrl.text) ?? 0;
    total += double.tryParse(_taxCtrl.text) ?? 0;
    return total < 0 ? 0 : total;
  }

  double get _poDifference => _totalAmount - (_purchase.totalAmount ?? 0);

  // ─────────────────────────────────────────────
  //  FILE PICKER
  // ─────────────────────────────────────────────

  Future<void> _pickFile() async {
    if (_confirmed) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _billFilePath = result.files.single.path);
    }
  }

  Future<void> _pickInvoiceDate() async {
    if (_confirmed) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _invoiceDateMs = picked.toUtc().millisecondsSinceEpoch;
        _invoiceDateError = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  //  VALIDATE & CONFIRM
  // ─────────────────────────────────────────────

  void _confirm() {
    if (_confirmed) return;

    // ── Invoice validations ──
    bool hasError = false;
    if (_invoiceNoCtrl.text.trim().isEmpty) {
      setState(() => _invoiceNoError = true);
      hasError = true;
    }
    if (_invoiceDateMs == null) {
      setState(() => _invoiceDateError = true);
      hasError = true;
    }
    if (hasError) {
      SnackbarUtil.showError('Please fill required invoice details');
      return;
    }

    // ── Item / batch validations ──
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

    // ── Build flat list of ReceiveItemInput ──
    final inputs = <ReceiveItemInput>[];
    for (final row in activeRows) {
      for (final b in row.batches) {
        final qty = (double.tryParse(b.qtyCtrl.text) ?? 0).toInt();
        if (qty <= 0) continue;
        inputs.add(ReceiveItemInput(
          itemId: row.purchaseItem.itemId!,
          purchaseItemId: row.purchaseItem.id,
          receivedQty: qty,
          unitCost: row.purchaseItem.unitCost ?? 0,
          batchNo: b.batchCtrl.text.trim().isNotEmpty
              ? b.batchCtrl.text.trim()
              : null,
          expiryDateUtcMs: b.expiryDateMs,
        ));
      }
    }

    // ── Build receipt entity ──
    final receipt = EntityPurchaseReceipt(
      purchaseId: _purchase.id,
      supplierId: _purchase.supplierId,
      supplierName: _purchase.supplierName,
      invoiceNumber: _invoiceNoCtrl.text.trim(),
      invoiceDateUtcMs: _invoiceDateMs,
      billFilePath: _billFilePath,
      taxAmount: double.tryParse(_taxCtrl.text),
      discountAmount: double.tryParse(_discountCtrl.text),
      freightCharges: double.tryParse(_freightCtrl.text),
      receivedDateUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      totalAmount: _totalAmount,
      status: 1,
      createdAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    );

    setState(() => _isSaving = true);

    final error = _controller.receiveGoods(
      purchase: _purchase,
      receivedItems: inputs,
      receipt: receipt,
    );

    setState(() => _isSaving = false);

    if (error != null) {
      SnackbarUtil.showError(error);
      return;
    }

    setState(() => _confirmed = true);
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

    return AppDialog(
      maxWidth: 950,
      maxHeight: 750,
      header: DialogHeader(
        title: 'Receive Goods',
        icon: Icons.move_to_inbox_rounded,
        iconColor: Colors.green.shade600,
      ),
      body: DialogBody(
        child: _rows.isEmpty
            ? _buildAlreadyReceived()
            : Column(
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
                      _summaryChip(
                          'Status', status.label, Color(status.colorValue)),
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

                  const SizedBox(height: 8),

                  // ── Invoice Details Section ──
                  _buildInvoiceDetailsSection(),
                  const SizedBox(height: 16),

                  // ── Summary Section ──
                  _buildSummarySection(),
                ],
              ),
      ),
      footer: _rows.isEmpty
          ? null
          : DialogFooter(
              onCancel: () => Get.back(),
              onSave: _confirm,
              saveLabel: _confirmed ? 'Confirmed' : 'Confirm Goods Received',
              isSaving: _isSaving,
              saveButtonColor: _confirmed ? Colors.grey : Colors.green.shade600,
            ),
    );
  }

  // ─────────────────────────────────────────────
  //  INVOICE DETAILS SECTION
  // ─────────────────────────────────────────────

  Widget _buildInvoiceDetailsSection() {
    final bool locked = _confirmed;

    return MyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  color: Colors.indigo.shade600, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Invoice Details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700)),
            const Spacer(),
            if (locked)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.lock_rounded,
                      size: 13, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text('Confirmed',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── Row 1: Invoice No + Invoice Date ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Number (required)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Invoice Number', required: true),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _invoiceNoCtrl,
                      enabled: !locked,
                      onChanged: (_) {
                        if (_invoiceNoError && _invoiceNoCtrl.text.isNotEmpty) {
                          setState(() => _invoiceNoError = false);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. INV-2025-001',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: _invoiceNoError
                                    ? Colors.red
                                    : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: _invoiceNoError
                                    ? Colors.red.shade400
                                    : Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: _invoiceNoError
                                    ? Colors.red
                                    : Colors.indigo.shade400,
                                width: 1.5)),
                        errorText:
                        _invoiceNoError ? 'Invoice number is required' : null,
                        filled: locked,
                        fillColor:
                        locked ? Colors.grey.shade100 : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Invoice Date (required)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Invoice Date', required: true),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: locked ? null : _pickInvoiceDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _invoiceDateError
                                ? Colors.red.shade400
                                : _invoiceDateMs != null
                                ? Colors.indigo.shade300
                                : Colors.grey.shade300,
                            width: _invoiceDateMs != null ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: locked
                              ? Colors.grey.shade100
                              : _invoiceDateMs != null
                              ? Colors.indigo.withOpacity(0.04)
                              : Colors.transparent,
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 18,
                              color: _invoiceDateError
                                  ? Colors.red.shade400
                                  : _invoiceDateMs != null
                                  ? Colors.indigo.shade500
                                  : Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(
                            _invoiceDateMs != null
                                ? DateFormat('dd MMM yyyy').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    _invoiceDateMs!,
                                    isUtc: true))
                                : 'Select date',
                            style: TextStyle(
                                fontSize: 14,
                                color: _invoiceDateMs != null
                                    ? Colors.indigo.shade700
                                    : Colors.grey.shade400),
                          ),
                        ]),
                      ),
                    ),
                    if (_invoiceDateError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text('Invoice date is required',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade600)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Upload Invoice File ──
          _fieldLabel('Upload Invoice File'),
          const SizedBox(height: 6),
          _buildFileUploadWidget(locked),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Optional: Tax / Discount / Freight ──
          Text('Optional Charges',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 12),

          Row(
            children: [
              // Tax / GST
              Expanded(
                child: _optionalAmountField(
                  controller: _taxCtrl,
                  label: 'Tax / GST',
                  hint: '0.00',
                  icon: Icons.percent_rounded,
                  color: Colors.teal,
                  locked: locked,
                ),
              ),
              const SizedBox(width: 12),
              // Discount
              Expanded(
                child: _optionalAmountField(
                  controller: _discountCtrl,
                  label: 'Discount',
                  hint: '0.00',
                  icon: Icons.discount_rounded,
                  color: Colors.orange,
                  locked: locked,
                ),
              ),
              const SizedBox(width: 12),
              // Freight
              Expanded(
                child: _optionalAmountField(
                  controller: _freightCtrl,
                  label: 'Freight / Loading',
                  hint: '0.00',
                  icon: Icons.local_shipping_rounded,
                  color: Colors.blue,
                  locked: locked,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadWidget(bool locked) {
    final hasFile = _billFilePath != null;

    return GestureDetector(
      onTap: locked ? null : _pickFile,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? Colors.green.shade300 : Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: hasFile
            ? Row(children: [
          // Preview icon based on type
          _filePreviewIcon(_billFilePath!),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _billFilePath!.split('/').last,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.green.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('Tap to preview or change',
                    style: TextStyle(
                        fontSize: 11, color: Colors.green.shade600)),
              ],
            ),
          ),
          if (!locked)
            IconButton(
              onPressed: () =>
                  setState(() => _billFilePath = null),
              icon: Icon(Icons.close_rounded,
                  size: 18, color: Colors.red.shade400),
              tooltip: 'Remove file',
            ),
          if (_billFilePath!.toLowerCase().endsWith('.jpg') ||
              _billFilePath!.toLowerCase().endsWith('.jpeg') ||
              _billFilePath!.toLowerCase().endsWith('.png'))
            IconButton(
              onPressed: () => _previewImage(_billFilePath!),
              icon: Icon(Icons.visibility_rounded,
                  size: 18, color: Colors.indigo.shade400),
              tooltip: 'Preview',
            ),
        ])
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_rounded,
                color: Colors.grey.shade400, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tap to upload invoice',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey.shade600)),
                Text('PDF, JPG, PNG supported',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filePreviewIcon(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.picture_as_pdf_rounded,
            color: Colors.red.shade500, size: 24),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_rounded, color: Colors.blue.shade500, size: 24),
    );
  }

  void _previewImage(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Invoice Preview'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded))
              ],
            ),
            Image.file(File(path), fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  Widget _optionalAmountField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required bool locked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !locked,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}), // refresh summary
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 16, color: color),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            isDense: true,
            filled: locked,
            fillColor: locked ? Colors.grey.shade100 : Colors.transparent,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SUMMARY SECTION
  // ─────────────────────────────────────────────

  Widget _buildSummarySection() {
    final diff = _poDifference;
    final diffColor = diff > 0
        ? Colors.red.shade600
        : diff < 0
        ? Colors.green.shade600
        : Colors.grey.shade600;
    final diffIcon = diff > 0
        ? Icons.trending_up_rounded
        : diff < 0
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return MyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.summarize_rounded,
                  color: Colors.purple.shade600, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Receipt Summary',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700)),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          Row(
            children: [
              // Total Items Received
              Expanded(
                child: _summaryTile(
                  label: 'Items Being Received',
                  value: '$_totalItemsReceived',
                  icon: Icons.inventory_2_rounded,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              // Total Amount
              Expanded(
                child: _summaryTile(
                  label: 'Total Amount',
                  value: '₹${_totalAmount.toStringAsFixed(2)}',
                  icon: Icons.currency_rupee_rounded,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              // Difference from PO
              Expanded(
                child: _summaryTile(
                  label: 'Diff from PO',
                  value: diff == 0
                      ? 'Matched'
                      : '${diff > 0 ? '+' : ''}₹${diff.toStringAsFixed(2)}',
                  icon: diffIcon,
                  color: diffColor,
                  subtitleWidget: diff != 0
                      ? Text(
                    diff > 0
                        ? 'Invoice exceeds PO'
                        : 'Invoice below PO',
                    style: TextStyle(
                        fontSize: 10, color: diffColor.withOpacity(0.8)),
                  )
                      : null,
                ),
              ),
            ],
          ),

          if (_purchase.totalAmount != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PO Total Amount',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  Text('₹${(_purchase.totalAmount ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    Widget? subtitleWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color)),
          if (subtitleWidget != null) ...[
            const SizedBox(height: 2),
            subtitleWidget,
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ITEM CARD — one card per PurchaseItem,
  //  contains expandable batch sub-rows
  // ─────────────────────────────────────────────

  Widget _buildItemCard(_ReceiveItemRow row) {
    final pi = row.purchaseItem;
    final bool locked = _confirmed;

    return MyCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Item header ──
          Row(children: [
            Checkbox(
              value: row.willReceive,
              onChanged: locked
                  ? null
                  : (val) => setState(() => row.willReceive = val ?? false),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const SizedBox(width: 32),
                const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child:
                    _colHeader('Qty to Receive', Icons.numbers_rounded)),
                const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child:
                    _colHeader('Batch No', Icons.qr_code_rounded)),
                if (row.needsExpiry) ...[
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 2,
                      child:
                      _colHeader('Expiry Date', Icons.event_rounded)),
                ],
                const SizedBox(width: 40),
              ]),
            ),
            const SizedBox(height: 6),

            ...List.generate(
                row.batches.length, (i) => _buildBatchRow(row, i)),

            const SizedBox(height: 4),

            if (!locked)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton.icon(
                  onPressed: () => setState(() => row.batches.add(_BatchRow())),
                  icon: Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: Colors.teal.shade600),
                  label: Text('Add Another Batch',
                      style: TextStyle(
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),

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
    final bool locked = _confirmed;

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
              enabled: !locked,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: row.purchaseItem.itemUnit ?? '',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                isDense: true,
                filled: locked,
                fillColor: locked ? Colors.grey.shade100 : Colors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Batch No
          Expanded(
            flex: 2,
            child: TextField(
              controller: b.batchCtrl,
              enabled: !locked,
              decoration: InputDecoration(
                hintText: 'e.g. BATCH00${index + 1}',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                isDense: true,
                filled: locked,
                fillColor: locked ? Colors.grey.shade100 : Colors.transparent,
              ),
            ),
          ),

          // Expiry Date
          if (row.needsExpiry) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: locked ? null : () => _pickExpiry(b),
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
            onPressed: (!locked && row.batches.length > 1)
                ? () => setState(() => row.batches.removeAt(index))
                : null,
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              size: 20,
              color: (!locked && row.batches.length > 1)
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

  Widget _fieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        if (required)
          Text(' *',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade500)),
      ],
    );
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('This purchase order is complete.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Get.back(), child: const Text('Go Back')),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
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
              color: color == Colors.grey ? Colors.grey.shade700 : color)),
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
