import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'controller_home_account.dart';

class DialogCloseShift extends StatefulWidget {
  const DialogCloseShift({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DialogCloseShift(),
    );
  }

  @override
  State<DialogCloseShift> createState() => _DialogCloseShiftState();
}

class _DialogCloseShiftState extends State<DialogCloseShift> {
  final _controller = Get.find<ControllerHomeAccount>();
  final _commentsCtrl = TextEditingController();

  static const _denominations = <int>[2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

  late final Map<int, TextEditingController> _countCtrl;
  late final Map<int, int> _counts;

  @override
  void initState() {
    super.initState();
    _countCtrl = {};
    _counts = {};
    for (final d in _denominations) {
      _counts[d] = 0;
      _countCtrl[d] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (final c in _countCtrl.values) {
      c.dispose();
    }
    _commentsCtrl.dispose();
    super.dispose();
  }

  double get _totalCash {
    double t = 0;
    for (final d in _denominations) {
      t += d * (_counts[d] ?? 0);
    }
    return t;
  }

  void _increment(int d) {
    setState(() => _countCtrl[d]?.text = '${(_counts[d] ?? 0) + 1}');
  }

  void _decrement(int d) {
    final c = _counts[d] ?? 0;
    if (c > 0) setState(() => _countCtrl[d]?.text = '${c - 1}');
  }

  void _onCountChanged(int d, String v) {
    final parsed = int.tryParse(v) ?? 0;
    setState(() => _counts[d] = parsed.clamp(0, 999999));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final now = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    return Dialog(
      backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              color: const Color(0xFF005963),
              child: Row(
                children: [
                  const Icon(Icons.alarm_on, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Close Shift - $now',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _denominationsTable(isDark, cs)),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: _rightColumn(isDark, cs)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _denominationsTable(bool isDark, ColorScheme cs) {
    final borderColor = isDark ? cs.outlineVariant : Colors.grey.shade300;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF005963),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Currency Denomination', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Center(child: Text('Count', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
              ],
            ),
          ),

          // Table rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _denominations.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? cs.outlineVariant.withValues(alpha: 0.4) : Colors.grey.shade200),
              itemBuilder: (ctx, i) {
                final d = _denominations[i];
                final count = _counts[d] ?? 0;
                final amount = (d * count).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('₹ $d', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _stepperBtn(isDark, cs, Icons.remove, () => _decrement(d)),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 44,
                              height: 28,
                              child: TextField(
                                controller: _countCtrl[d],
                                textAlign: TextAlign.center,
                                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (v) => _onCountChanged(d, v),
                                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 2), border: UnderlineInputBorder()),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _stepperBtn(isDark, cs, Icons.add, () => _increment(d)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('₹ ${NumberFormat('#,##0.00').format(amount)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Total Cash In Drawer bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHighest : const Color(0xFFCFE1E3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Total Cash In Drawer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      color: isDark ? cs.primary : const Color(0xFF00383F)),
                  ),
                ),
                Text('₹ ${NumberFormat('#,##0.00').format(_totalCash)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                    color: isDark ? cs.primary : const Color(0xFF00383F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn(bool isDark, ColorScheme cs, IconData icon, VoidCallback onTap) {
    final fg = isDark ? cs.outline : const Color(0xFFB0B0B0);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: fg)),
        child: Icon(icon, size: 14, color: cs.onSurface),
      ),
    );
  }

  Widget _rightColumn(bool isDark, ColorScheme cs) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment Modes Table
          _paymentModesTable(isDark, cs),
          const SizedBox(height: 12),

          // Stat Badges
          _statBadge('Closing Shift Summary', isDark, cs),
          const SizedBox(height: 6),
          _statBadge('Account Statistics', isDark, cs),
          const SizedBox(height: 6),
          Obx(() => _statBadge('Opening Balance (Cash): ${NumberFormat('#,##0.00').format(_controller.rxOpeningBalance.value)}', isDark, cs)),
          const SizedBox(height: 6),
          Obx(() => _statBadge('Expenses (Cash): ${NumberFormat('#,##0.00').format(_controller.rxExpensesCashTotal.value)}', isDark, cs)),
          const SizedBox(height: 6),
          Obx(() => _statBadge('Username: ${_controller.rxUsername.value.isNotEmpty ? _controller.rxUsername.value : 'Cashier'}', isDark, cs)),
          const SizedBox(height: 6),
          _statBadge('Order Statistics (Shift)', isDark, cs),
          const SizedBox(height: 6),
          Obx(() => _statBadge('Fulfilled Orders: ${_controller.rxFulfilledOrders.value}', isDark, cs)),
          const SizedBox(height: 6),
          Obx(() => _statBadge('Cancelled Orders: ${_controller.rxCancelledOrders.value}', isDark, cs)),
          const SizedBox(height: 6),
          Obx(() => _statBadge('Complimentary Orders: ${_controller.rxComplimentaryOrders.value}', isDark, cs)),
          const SizedBox(height: 12),

          // Balance Summary
          _balanceSummary(isDark, cs),
          const SizedBox(height: 8),

          // Logout Notice
          _logoutNotice(isDark),
          const SizedBox(height: 16),

          // Comments
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? cs.outlineVariant : Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: TextField(
              controller: _commentsCtrl,
              maxLines: 3,
              style: TextStyle(color: cs.onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Comments Here',
                hintStyle: TextStyle(color: isDark ? cs.onSurfaceVariant : const Color(0xFF94A3B8), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final total = _totalCash;
                    final comments = _commentsCtrl.text.trim();
                    if (context.mounted) Navigator.of(context).pop();
                    await _controller.closeShift(
                      denominations: Map<int, int>.from(_counts),
                      countedTotal: total,
                      comments: comments.isNotEmpty ? comments : null,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005963),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close Shift', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentModesTable(bool isDark, ColorScheme cs) {
    final borderColor = isDark ? cs.outlineVariant : Colors.grey.shade300;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF005963),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('Actual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          Obx(() {
            final modes = _controller.rxPaymentModes;
            final hasAny = modes.values.any((v) => v > 0);
            if (!hasAny) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text('No payment modes',
                    style: TextStyle(color: isDark ? cs.onSurfaceVariant : const Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              );
            }
            return Column(
              children: modes.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? cs.outlineVariant.withValues(alpha: 0.4) : Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: cs.onSurface)),
                      Text('₹ ${NumberFormat('#,##0.00').format(e.value)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _statBadge(String text, bool isDark, ColorScheme cs) {
    final bg = isDark ? cs.surfaceContainerHighest : const Color(0xFF005963);
    final fg = isDark ? cs.onSurface : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isDark ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)) : null,
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _balanceSummary(bool isDark, ColorScheme cs) {
    final expected = _controller.rxClosingBalance.value;
    final actual = _totalCash;
    final diff = actual - expected;
    final isOver = diff > 0.01;
    final isExact = diff.abs() < 0.01;

    final bg = isExact
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
        : isOver
            ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2))
            : (isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB));
    final border = isExact ? const Color(0xFF22C55E) : isOver ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: Column(
        children: [
          _summaryRow('Expected Closing Cash', '₹ ${NumberFormat('#,##0.00').format(expected)}', isDark, cs),
          const SizedBox(height: 6),
          _summaryRow('Actual Cash in Drawer', '₹ ${NumberFormat('#,##0.00').format(actual)}', isDark, cs),
          Divider(height: 12, color: isDark ? cs.outlineVariant.withValues(alpha: 0.4) : Colors.grey.shade300),
          _summaryRow(
            isExact ? 'Balanced ✓' : isOver ? 'Over by' : 'Short by',
            !isExact ? '₹ ${NumberFormat('#,##0.00').format(diff.abs())}' : '',
            isDark, cs,
            accent: isExact ? const Color(0xFF16A34A) : isOver ? const Color(0xFFDC2626) : const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, ColorScheme cs, {Color? accent}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? cs.onSurfaceVariant : const Color(0xFF475569))),
        if (value.isNotEmpty)
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent ?? cs.onSurface)),
      ],
    );
  }

  Widget _logoutNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.3) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.5) : const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text('You will be logged out after closing this shift.',
              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }
}
