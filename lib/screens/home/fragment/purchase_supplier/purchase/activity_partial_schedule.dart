import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../model/entity_payment_schedule.dart';
import '../../../../../model/entity_purchase.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/my_card.dart';
import '../../../../../model/entity_payment_schedule.dart';
import 'controller_home_purchase.dart';

/// Screen to schedule future partial payments for a Purchase Order.
///
/// Shows existing scheduled instalments and lets the user add new ones.
/// Relies on EntityPaymentSchedule model (see bottom of file for its shape).
///
/// Pass EntityPurchase as Get.arguments.
class ActivityPartialSchedule extends StatefulWidget {
  const ActivityPartialSchedule({super.key});

  @override
  State<ActivityPartialSchedule> createState() =>
      _ActivityPartialScheduleState();
}

class _ActivityPartialScheduleState extends State<ActivityPartialSchedule> {
  late final ControllerHomePurchase _controller;
  late final EntityPurchase _purchase;

  List<EntityPaymentSchedule> _schedules = [];
  bool _isSaving = false;

  // ── New instalment form state ──
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ControllerHomePurchase>()
        ? Get.find<ControllerHomePurchase>()
        : Get.put(ControllerHomePurchase());
    _purchase = Get.arguments as EntityPurchase;
    _loadSchedules();
  }

  void _loadSchedules() {
    setState(() {
      _schedules = _controller.getSchedulesForPurchase(_purchase.id);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── computed ──
  double get _outstanding => _purchase.outstandingAmount;

  double get _scheduledTotal =>
      _schedules.fold(0, (s, e) => s + (e.amount ?? 0));

  double get _pendingScheduled => _schedules
      .where((e) => !e.isPaid)
      .fold(0, (s, e) => s + (e.amount ?? 0));

  double get _unscheduled => (_outstanding - _pendingScheduled).clamp(0, double.infinity);

  // ── actions ──
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.green.shade700,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _addInstalment() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      SnackbarUtil.showError('Please pick a due date.'.tr);
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount > _unscheduled + 0.001) {
      SnackbarUtil.showError(
          'Amount exceeds unscheduled balance ₹${_unscheduled.toStringAsFixed(2)}');
      return;
    }

    setState(() => _isSaving = true);
    final error = _controller.addPaymentSchedule(
      purchaseId: _purchase.id,
      amount: amount,
      dueDate: _selectedDate!,
      note: _noteCtrl.text.trim(),
    );
    setState(() => _isSaving = false);

    if (error != null) {
      SnackbarUtil.showError(error);
      return;
    }

    _amountCtrl.clear();
    _noteCtrl.clear();
    setState(() => _selectedDate = null);
    _loadSchedules();
    SnackbarUtil.showSuccess('Instalment of ₹${amount.toStringAsFixed(2)} scheduled!');
  }

  void _markPaid(EntityPaymentSchedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark as Paid?'.tr),
        content: Text(
            'Mark instalment of ₹${(schedule.amount ?? 0).toStringAsFixed(2)} as paid?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Mark Paid'.tr,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final error = _controller.markSchedulePaid(schedule.id);
    if (error != null) {
      SnackbarUtil.showError(error);
    } else {
      _loadSchedules();
      SnackbarUtil.showSuccess('Marked as paid.'.tr);
    }
  }

  void _deleteSchedule(EntityPaymentSchedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Instalment?'.tr),
        content: Text('This will remove the scheduled payment.'.tr),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final error = _controller.deletePaymentSchedule(schedule.id);
    if (error != null) {
      SnackbarUtil.showError(error);
    } else {
      _loadSchedules();
    }
  }

  // ── build ──
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.orange.shade500, Colors.orange.shade800]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Payment Schedule'.tr,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(
                '${_purchase.purchaseNo} · ${_purchase.supplierName}',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Overview cards ──
            _buildOverviewRow(),
            const SizedBox(height: 16),

            // ── Add new instalment ──
            if (_unscheduled > 0.001) ...[
              _buildAddInstalmentCard(),
              const SizedBox(height: 16),
            ],

            // ── Schedule list ──
            if (_schedules.isEmpty)
              _buildEmptyState()
            else
              _buildScheduleList(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  OVERVIEW
  // ─────────────────────────────────────────────────────────

  Widget _buildOverviewRow() {
    return Row(
      children: [
        Expanded(
            child: _overviewTile(
                'Outstanding'.tr,
                '₹ ${_outstanding.toStringAsFixed(2)}',
                Colors.red.shade600,
                Icons.account_balance_wallet_rounded)),
        const SizedBox(width: 10),
        Expanded(
            child: _overviewTile(
                'Scheduled'.tr,
                '₹ ${_pendingScheduled.toStringAsFixed(2)}',
                Colors.orange.shade600,
                Icons.pending_actions_rounded)),
        const SizedBox(width: 10),
        Expanded(
            child: _overviewTile(
                'Unscheduled'.tr,
                '₹ ${_unscheduled.toStringAsFixed(2)}',
                _unscheduled < 0.01
                    ? Colors.green.shade600
                    : Colors.grey.shade600,
                Icons.hourglass_empty_rounded)),
      ],
    );
  }

  Widget _overviewTile(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ADD INSTALMENT CARD
  // ─────────────────────────────────────────────────────────

  Widget _buildAddInstalmentCard() {
    return MyCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Add Instalment', Icons.add_alarm_rounded,
                Colors.orange.shade700),
            const Divider(height: 20),

            // Amount + Date in a row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount *'.tr,
                    prefixText: '₹ ',
                    prefixIcon:
                    const Icon(Icons.currency_rupee_rounded, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    helperText:
                    'Max: ₹${_unscheduled.toStringAsFixed(2)}',
                    helperStyle:
                    TextStyle(color: Colors.orange.shade600),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required'.tr;
                    final a = double.tryParse(v.trim());
                    if (a == null || a <= 0) return 'Invalid amount'.tr;
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Due Date *'.tr,
                        hintText: _selectedDate == null
                            ? 'Pick a date'.tr
                            : DateFormat('dd MMM yyyy')
                            .format(_selectedDate!),
                        prefixIcon:
                        const Icon(Icons.calendar_today_rounded, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      controller: TextEditingController(
                        text: _selectedDate == null
                            ? ''
                            : DateFormat('dd MMM yyyy')
                            .format(_selectedDate!),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'Note (optional)'.tr,
                hintText: 'e.g. 2nd instalment'.tr,
                prefixIcon:
                const Icon(Icons.note_alt_outlined, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.orange.shade500,
                    Colors.orange.shade800,
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSaving ? null : _addInstalment,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _isSaving
                            ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.add_alarm_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Schedule Instalment'.tr,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SCHEDULE LIST
  // ─────────────────────────────────────────────────────────

  Widget _buildScheduleList() {
    // Sort: pending overdue first, then pending future, then paid
    final sorted = [..._schedules]..sort((a, b) {
      if (a.status == b.status) {
        return (a.dueDateMs ?? 0).compareTo(b.dueDateMs ?? 0);
      }
      return !a.isPaid ? -1 : 1;
    });

    return MyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Instalment Schedule'.tr,
              Icons.list_alt_rounded, Colors.orange.shade700),
          const Divider(height: 20),
          ...sorted.map((s) => _buildScheduleTile(s)),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(EntityPaymentSchedule schedule) {
    final isPaid = schedule.isPaid;
    final dueDate = schedule.dueDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(schedule.dueDateMs!, isUtc: true)
        .toLocal()
        : null;
    final isOverdue =
        !isPaid && dueDate != null && dueDate.isBefore(DateTime.now());
    final dueDateStr =
    dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : '-';

    Color tileColor = isPaid
        ? Colors.green.withOpacity(0.05)
        : isOverdue
        ? Colors.red.withOpacity(0.05)
        : Colors.orange.withOpacity(0.04);
    Color borderColor = isPaid
        ? Colors.green.shade100
        : isOverdue
        ? Colors.red.shade200
        : Colors.orange.shade100;
    Color accentColor = isPaid
        ? Colors.green.shade600
        : isOverdue
        ? Colors.red.shade600
        : Colors.orange.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        // Status icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPaid
                ? Icons.check_circle_rounded
                : isOverdue
                ? Icons.warning_rounded
                : Icons.schedule_rounded,
            size: 20,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    isPaid
                        ? 'Paid'.tr
                        : isOverdue
                        ? 'Overdue'.tr
                        : 'Pending'.tr,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: accentColor),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text('OVERDUE'.tr,
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                Text('Due: $dueDateStr',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                if (schedule.note?.isNotEmpty == true)
                  Text(schedule.note!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
              ]),
        ),

        // Amount
        Text(
          '₹ ${(schedule.amount ?? 0).toStringAsFixed(2)}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: accentColor),
        ),
        const SizedBox(width: 8),

        // Actions
        if (!isPaid) ...[
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                  value: 'paid',
                  child: Row(children: [
                    const Icon(Icons.check_rounded,
                        size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Mark as Paid'.tr),
                  ])),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Delete'.tr),
                  ])),
            ],
            onSelected: (v) {
              if (v == 'paid') _markPaid(schedule);
              if (v == 'delete') _deleteSchedule(schedule);
            },
            child: Icon(Icons.more_vert_rounded,
                color: Colors.grey.shade400, size: 20),
          ),
        ],
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          Icon(Icons.calendar_today_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No instalments scheduled yet.'.tr,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9))),
    ]);
  }
}
