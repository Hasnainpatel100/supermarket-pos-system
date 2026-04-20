import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../enums/enum_payement_mode.dart';
import '../../../../../model/entity_payment.dart';
import '../../../../../model/entity_purchase.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/my_card.dart';
import 'controller_home_purchase.dart';
import 'activity_partial_schedule.dart';
import 'service_payment_receipt.dart';

/// A single split entry: one payment mode + its amount.
class _SplitEntry {
  PaymentMode mode;
  final TextEditingController amountCtrl;
  final TextEditingController referenceCtrl;

  _SplitEntry({
    this.mode = PaymentMode.cash,
    String initialAmount = '',
  })  : amountCtrl = TextEditingController(text: initialAmount),
        referenceCtrl = TextEditingController();

  double get amount => double.tryParse(amountCtrl.text.trim()) ?? 0;

  void dispose() {
    amountCtrl.dispose();
    referenceCtrl.dispose();
  }
}

/// Screen to record a payment against a Purchase Order.
/// Supports single payment mode OR split across multiple modes.
/// Pass EntityPurchase as Get.arguments.
class ActivityPaymentForm extends StatefulWidget {
  const ActivityPaymentForm({super.key});

  @override
  State<ActivityPaymentForm> createState() => _ActivityPaymentFormState();
}

class _ActivityPaymentFormState extends State<ActivityPaymentForm> {
  late final ControllerHomePurchase _controller;
  late final EntityPurchase _purchase;

  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();

  bool _isSplitMode = false;
  bool _isSaving = false;
  List<EntityPayment> _pastPayments = [];

  // Single-mode state
  PaymentMode _singleMode = PaymentMode.cash;
  final _singleAmountCtrl = TextEditingController();
  final _singleReferenceCtrl = TextEditingController();

  // Split-mode state
  final List<_SplitEntry> _splits = [];

  // ─── helpers ───────────────────────────────────────────
  double get _outstanding => _purchase.outstandingAmount;

  double get _splitTotal =>
      _splits.fold(0, (sum, s) => sum + s.amount);

  double get _splitRemaining => _outstanding - _splitTotal;

  bool _hasDuplicateMode() {
    final modes = _splits.map((s) => s.mode).toList();
    return modes.toSet().length != modes.length;
  }

  // ─── lifecycle ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ControllerHomePurchase>()
        ? Get.find<ControllerHomePurchase>()
        : Get.put(ControllerHomePurchase());

    _purchase = Get.arguments as EntityPurchase;
    _pastPayments = _controller.getPaymentsForPurchase(_purchase.id);

    if (_outstanding > 0) {
      _singleAmountCtrl.text = _outstanding.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _singleAmountCtrl.dispose();
    _singleReferenceCtrl.dispose();
    for (final s in _splits) {
      s.dispose();
    }
    super.dispose();
  }

  // ─── toggle split mode ─────────────────────────────────
  void _enableSplit() {
    final existing = double.tryParse(_singleAmountCtrl.text.trim()) ?? 0;
    // Seed two splits: one for the existing mode, one empty with a different mode
    final firstMode = _singleMode;
    final secondMode = PaymentMode.values.firstWhere((m) => m != firstMode);

    setState(() {
      _isSplitMode = true;
      _splits.clear();
      _splits.add(_SplitEntry(
        mode: firstMode,
        initialAmount: existing > 0 ? existing.toStringAsFixed(2) : '',
      ));
      _splits.add(_SplitEntry(mode: secondMode));
    });
  }

  void _disableSplit() {
    setState(() {
      _isSplitMode = false;
      // Restore single amount to outstanding
      _singleAmountCtrl.text = _outstanding.toStringAsFixed(2);
      for (final s in _splits) {
        s.dispose();
      }
      _splits.clear();
    });
  }

  void _addSplit() {
    if (_splits.length >= PaymentMode.values.length) return;
    final usedModes = _splits.map((s) => s.mode).toSet();
    final nextMode =
    PaymentMode.values.firstWhere((m) => !usedModes.contains(m));
    setState(() => _splits.add(_SplitEntry(mode: nextMode)));
  }

  void _removeSplit(int index) {
    if (_splits.length <= 2) return; // keep at least 2 splits
    setState(() {
      _splits[index].dispose();
      _splits.removeAt(index);
    });
  }

  // ─── save ──────────────────────────────────────────────
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_isSplitMode) {
      // Extra cross-field validations
      if (_hasDuplicateMode()) {
        SnackbarUtil.showError('Each payment mode must be unique in a split.');
        return;
      }
      final total = _splitTotal;
      if ((total - _outstanding).abs() > 0.001 && total > _outstanding + 0.001) {
        SnackbarUtil.showError(
            'Split total ₹${total.toStringAsFixed(2)} exceeds outstanding ₹${_outstanding.toStringAsFixed(2)}');
        return;
      }
      if (total <= 0) {
        SnackbarUtil.showError('Split total must be greater than zero.');
        return;
      }
    }

    setState(() => _isSaving = true);

    String? error;

    if (_isSplitMode) {
      // Record each split as a separate payment linked by a shared reference
      final splitGroupRef =
          'SPLIT-${DateTime.now().millisecondsSinceEpoch}';

      for (final split in _splits) {
        if (split.amount <= 0) continue;
        error = _controller.recordPayment(
          purchase: _purchase,
          amount: split.amount,
          paymentMode: split.mode,
          referenceNo: split.referenceCtrl.text.isNotEmpty
              ? split.referenceCtrl.text
              : splitGroupRef,
          note: _noteCtrl.text.isNotEmpty
              ? '[Split] ${_noteCtrl.text}'
              : '[Split Payment]',
        );
        if (error != null) break;
      }
    } else {
      final amount = double.tryParse(_singleAmountCtrl.text.trim()) ?? 0;
      error = _controller.recordPayment(
        purchase: _purchase,
        amount: amount,
        paymentMode: _singleMode,
        referenceNo: _singleReferenceCtrl.text,
        note: _noteCtrl.text,
      );
    }

    setState(() => _isSaving = false);

    if (error != null) {
      SnackbarUtil.showError(error);
      return;
    }

    final totalPaid = _isSplitMode
        ? _splitTotal
        : (double.tryParse(_singleAmountCtrl.text.trim()) ?? 0);

    SnackbarUtil.showSuccess(
        'Payment of ₹${totalPaid.toStringAsFixed(2)} recorded!');

    // Refresh payments list and offer to print receipt
    final updatedPayments =
    _controller.getPaymentsForPurchase(_purchase.id);
    final sessionCount = _isSplitMode
        ? _splits.where((s) => s.amount > 0).length
        : 1;
    final sessionPayments = updatedPayments.length >= sessionCount
        ? updatedPayments.sublist(updatedPayments.length - sessionCount)
        : updatedPayments;

    if (mounted) _showReceiptDialog(sessionPayments, totalPaid);
  }

  void _showReceiptDialog(List<EntityPayment> sessionPayments, double totalPaid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 28),
          const SizedBox(width: 10),
          const Text('Payment Recorded!'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            '₹${totalPaid.toStringAsFixed(2)} recorded successfully.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Would you like to print or share a payment voucher?',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Get.back(); },
            child: const Text('Skip'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.green.shade500, Colors.green.shade700]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ServicePaymentReceipt.generateAndShare(
                    purchase: _purchase,
                    payments: sessionPayments,
                    isSplit: _isSplitMode,
                  );
                  Get.back();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.print_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Print Voucher',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFullyPaid = _outstanding <= 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade500, Colors.green.shade800],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.payments_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Record Payment',
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
        actions: [
          IconButton(
            tooltip: 'Schedule Payments',
            icon: Icon(Icons.calendar_month_rounded,
                color: Colors.orange.shade600),
            onPressed: () => Get.to(
                  () => const ActivityPartialSchedule(),
              arguments: _purchase,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary ──
              _buildSummaryCard(isFullyPaid),
              const SizedBox(height: 16),

              if (isFullyPaid) ...[
                _buildAlreadyPaidBanner(),
              ] else ...[
                // ── Split toggle header ──
                _buildSplitToggleRow(),
                const SizedBox(height: 12),

                // ── Payment Form ──
                MyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                          _isSplitMode ? 'Split Payment' : 'Payment Details',
                          _isSplitMode
                              ? Icons.call_split_rounded
                              : Icons.edit_rounded),
                      const Divider(height: 24),

                      if (_isSplitMode) ...[
                        _buildSplitForm(),
                      ] else ...[
                        _buildSingleForm(),
                      ],

                      const SizedBox(height: 20),

                      // ── Shared Note ──
                      TextFormField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          hintText:
                          'e.g. Advance payment for next order',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                          prefixIcon: const Icon(
                              Icons.note_alt_outlined,
                              size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Action Buttons ──
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
                          _buildSaveButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // ── Payment History ──
              if (_pastPayments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPaymentHistory(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SPLIT TOGGLE
  // ─────────────────────────────────────────────────────────

  Widget _buildSplitToggleRow() {
    return Row(
      children: [
        Icon(Icons.call_split_rounded,
            size: 18, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Text(
          'Split Payment',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: _isSplitMode,
          activeColor: Colors.green.shade600,
          onChanged: (_) =>
          _isSplitMode ? _disableSplit() : _enableSplit(),
        ),
        const Spacer(),
        if (_isSplitMode)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _splitRemaining.abs() < 0.01
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _splitRemaining.abs() < 0.01
                    ? Colors.green.shade300
                    : Colors.orange.shade300,
              ),
            ),
            child: Text(
              _splitRemaining.abs() < 0.01
                  ? '✓ Balanced'
                  : 'Remaining: ₹${_splitRemaining.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _splitRemaining.abs() < 0.01
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SINGLE PAYMENT FORM
  // ─────────────────────────────────────────────────────────

  Widget _buildSingleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount
        TextFormField(
          controller: _singleAmountCtrl,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount *',
            prefixText: '₹ ',
            prefixIcon:
            const Icon(Icons.currency_rupee_rounded, size: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            helperText:
            'Outstanding: ₹${_outstanding.toStringAsFixed(2)}',
            helperStyle: TextStyle(color: Colors.orange.shade700),
          ),
          validator: (v) => _validateAmount(v, _outstanding),
        ),
        const SizedBox(height: 20),

        // Payment Mode
        Text('Payment Mode *',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        _buildPaymentModeSelector(
          selected: _singleMode,
          onSelect: (m) => setState(() => _singleMode = m),
        ),
        const SizedBox(height: 20),

        // Reference (conditional)
        if (_singleMode != PaymentMode.cash) ...[
          TextFormField(
            controller: _singleReferenceCtrl,
            decoration: InputDecoration(
              labelText: _referenceLabel(_singleMode),
              prefixIcon: const Icon(
                  Icons.confirmation_number_rounded,
                  size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SPLIT PAYMENT FORM
  // ─────────────────────────────────────────────────────────

  Widget _buildSplitForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info chip
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Outstanding ₹${_outstanding.toStringAsFixed(2)} · Split across multiple payment modes.',
                style: TextStyle(
                    fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Split entries
        ...List.generate(_splits.length, (i) => _buildSplitRow(i)),

        // Add split button
        if (_splits.length < PaymentMode.values.length) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addSplit,
            icon: Icon(Icons.add_circle_outline_rounded,
                size: 18, color: Colors.green.shade600),
            label: Text('Add another payment mode',
                style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }

  Widget _buildSplitRow(int index) {
    final split = _splits[index];
    final usedModes =
    _splits.asMap().entries.where((e) => e.key != index).map((e) => e.value.mode).toSet();

    return StatefulBuilder(
      builder: (context, setRowState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: label + remove button
              Row(children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text('Payment ${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                if (_splits.length > 2)
                  IconButton(
                    onPressed: () => _removeSplit(index),
                    icon: Icon(Icons.remove_circle_outline_rounded,
                        color: Colors.red.shade400, size: 20),
                    tooltip: 'Remove',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ]),
              const SizedBox(height: 12),

              // Mode selector (only available modes)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentMode.values.map((mode) {
                  final isSelected = split.mode == mode;
                  final isUsed = usedModes.contains(mode);
                  return GestureDetector(
                    onTap: isUsed
                        ? null
                        : () {
                      setState(() => split.mode = mode);
                      setRowState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isUsed
                            ? Colors.grey.shade100
                            : isSelected
                            ? Colors.green.shade600
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isUsed
                              ? Colors.grey.shade200
                              : isSelected
                              ? Colors.green.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          _modeIcon(mode),
                          size: 16,
                          color: isUsed
                              ? Colors.grey.shade300
                              : isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mode.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUsed
                                ? Colors.grey.shade300
                                : isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Amount + optional reference in a row
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: split.amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (_) => setState(() {}), // refresh remaining
                    decoration: InputDecoration(
                      labelText: 'Amount *',
                      prefixText: '₹ ',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      final amt = double.tryParse(v.trim());
                      if (amt == null || amt <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                if (split.mode != PaymentMode.cash) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: split.referenceCtrl,
                      decoration: InputDecoration(
                        labelText: _referenceLabel(split.mode),
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SUMMARY CARD
  // ─────────────────────────────────────────────────────────

  Widget _buildSummaryCard(bool isFullyPaid) {
    return MyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Purchase Summary', Icons.receipt_long_rounded),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                  child: _summaryTile(
                      'Total Amount',
                      '₹ ${(_purchase.totalAmount ?? 0).toStringAsFixed(2)}',
                      Colors.grey.shade700)),
              Expanded(
                  child: _summaryTile(
                      'Amount Paid',
                      '₹ ${(_purchase.amountPaid ?? 0).toStringAsFixed(2)}',
                      Colors.green.shade600)),
              Expanded(
                child: _summaryTile(
                  'Outstanding',
                  '₹ ${_outstanding.toStringAsFixed(2)}',
                  isFullyPaid
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  isBold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color valueColor,
      {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight:
                isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ALREADY PAID BANNER
  // ─────────────────────────────────────────────────────────

  Widget _buildAlreadyPaidBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(children: [
        Icon(Icons.check_circle_rounded,
            color: Colors.green.shade500, size: 40),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fully Paid',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700)),
          const SizedBox(height: 2),
          Text('This purchase order has been fully settled.',
              style: TextStyle(
                  fontSize: 13, color: Colors.green.shade600)),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PAYMENT MODE SELECTOR (single mode)
  // ─────────────────────────────────────────────────────────

  Widget _buildPaymentModeSelector({
    required PaymentMode selected,
    required ValueChanged<PaymentMode> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: PaymentMode.values.map((mode) {
        final isSelected = selected == mode;
        return GestureDetector(
          onTap: () => onSelect(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.shade600
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.green.shade600
                    : Colors.grey.shade300,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
                  : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _modeIcon(mode),
                size: 18,
                color:
                isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                mode.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey.shade700,
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PAYMENT HISTORY
  // ─────────────────────────────────────────────────────────

  Widget _buildPaymentHistory() {
    return MyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Payment History', Icons.history_rounded),
          const Divider(height: 20),
          ..._pastPayments.map((p) => _buildPaymentTile(p)),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(EntityPayment p) {
    final mode = PaymentMode.values[p.paymentMode ?? 0];
    final date = p.createdAtUtcMs != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(
        DateTime.fromMillisecondsSinceEpoch(p.createdAtUtcMs!,
            isUtc: true)
            .toLocal())
        : '-';
    final isSplit = (p.note ?? '').startsWith('[Split');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_modeIcon(mode),
              size: 18, color: Colors.green.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(mode.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  if (isSplit) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.purple.shade200),
                      ),
                      child: Text('Split',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple.shade600,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
                if (p.referenceNo != null)
                  Text('Ref: ${p.referenceNo}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                if (p.note != null && !isSplit)
                  Text(p.note!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                Text(date,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ]),
        ),
        Text(
          '₹ ${(p.amount ?? 0).toStringAsFixed(2)}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.green.shade700),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SAVE BUTTON
  // ─────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.green.shade500, Colors.green.shade800]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _save,
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
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text('Record Payment',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: Colors.green.shade600),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800)),
    ]);
  }

  String? _validateAmount(String? v, double maxAmount) {
    if (v == null || v.trim().isEmpty) return 'Amount is required';
    final amt = double.tryParse(v.trim());
    if (amt == null || amt <= 0) return 'Enter a valid amount';
    if (amt > maxAmount + 0.001) {
      return 'Cannot exceed ₹${maxAmount.toStringAsFixed(2)}';
    }
    return null;
  }

  String _referenceLabel(PaymentMode mode) => switch (mode) {
    PaymentMode.cheque => 'Cheque Number',
    PaymentMode.bankTransfer => 'UTR / Transaction ID',
    PaymentMode.upi => 'UPI Transaction ID',
    _ => 'Reference No',
  };

  IconData _modeIcon(PaymentMode mode) => switch (mode) {
    PaymentMode.cash => Icons.payments_rounded,
    PaymentMode.cheque => Icons.description_rounded,
    PaymentMode.bankTransfer => Icons.account_balance_rounded,
    PaymentMode.upi => Icons.phone_android_rounded,
  };
}
