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
  final ControllerHomeAccount controller = Get.find<ControllerHomeAccount>();
  final TextEditingController commentsCtrl = TextEditingController();

  static const List<int> denominations = [
    2000,
    1000,
    500,
    200,
    100,
    50,
    20,
    10,
    5,
    2,
    1,
  ];

  late final Map<int, TextEditingController> _countControllers;
  late final Map<int, int> _counts;

  @override
  void initState() {
    super.initState();
    _countControllers = {};
    _counts = {};
    for (var d in denominations) {
      _counts[d] = 0;
      _countControllers[d] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var c in _countControllers.values) {
      c.dispose();
    }
    commentsCtrl.dispose();
    super.dispose();
  }

  double get totalCashInDrawer {
    double total = 0;
    for (var d in denominations) {
      total += d * (_counts[d] ?? 0);
    }
    return total;
  }

  void _increment(int denom) {
    setState(() {
      _counts[denom] = (_counts[denom] ?? 0) + 1;
      _countControllers[denom]?.text = _counts[denom].toString();
    });
  }

  void _decrement(int denom) {
    setState(() {
      final current = _counts[denom] ?? 0;
      if (current > 0) {
        _counts[denom] = current - 1;
        _countControllers[denom]?.text = _counts[denom].toString();
      }
    });
  }

  void _onCountChanged(int denom, String val) {
    final parsed = int.tryParse(val) ?? 0;
    setState(() {
      _counts[denom] = parsed >= 0 ? parsed : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final nowFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    final title = 'Close Shift - $nowFormatted';

    return Dialog(
      backgroundColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 760),
        child: Column(
          children: [
            // ── Dark Teal Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              color: const Color(0xFF005963),
              child: Row(
                children: [
                  const Icon(Icons.alarm_on, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

            // ── Two Column Layout ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left Column: Currency Denominations Table ──
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF005963),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'Currency Denomination',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Center(
                                      child: Text(
                                        'Count',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Amount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // List of denominations
                            Expanded(
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: denominations.length,
                                separatorBuilder: (ctx, i) =>
                                    Divider(height: 1, color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : Colors.grey.shade200),
                                itemBuilder: (ctx, i) {
                                  final denom = denominations[i];
                                  final count = _counts[denom] ?? 0;
                                  final amount = (denom * count).toDouble();

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            '₹ $denom',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              InkWell(
                                                onTap: () => _decrement(denom),
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isDark ? colorScheme.outline : Colors.grey.shade400,
                                                    ),
                                                  ),
                                                  child: Icon(Icons.remove, size: 14, color: colorScheme.onSurface),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              SizedBox(
                                                width: 44,
                                                height: 28,
                                                child: TextField(
                                                  controller: _countControllers[denom],
                                                  textAlign: TextAlign.center,
                                                  keyboardType: TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly
                                                  ],
                                                  onChanged: (val) => _onCountChanged(denom, val),
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                                                    border: UnderlineInputBorder(),
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () => _increment(denom),
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isDark ? colorScheme.outline : Colors.grey.shade400,
                                                    ),
                                                  ),
                                                  child: Icon(Icons.add, size: 14, color: colorScheme.onSurface),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '₹ ${NumberFormat('#,##0.00').format(amount)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Total Cash In Drawer bottom bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFCFE1E3),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Total Cash In Drawer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? colorScheme.primary : const Color(0xFF00383F),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹ ${NumberFormat('#,##0.00').format(totalCashInDrawer)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? colorScheme.primary : const Color(0xFF00383F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ── Right Column: Payment Modes + Stats Badges + Comments ──
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Payment Mode Table ──
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                                        Text(
                                          'Payment Mode',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Actual',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Obx(() {
                                    final modes = controller.rxPaymentModes;
                                    final hasAny = modes.values.any((v) => v > 0);
                                    if (!hasAny) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        child: Center(
                                          child: Text(
                                            'No payment modes',
                                            style: TextStyle(
                                              color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF64748B),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return Column(
                                      children: modes.entries.map((e) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : Colors.grey.shade200,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                e.key,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              Text(
                                                '₹ ${NumberFormat('#,##0.00').format(e.value)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Statistics Badges ──
                            _buildStatPill('Closing Shift Summary'),
                            const SizedBox(height: 6),
                            _buildStatPill('Account Statistics'),
                            const SizedBox(height: 6),
                            Obx(() => _buildStatPill(
                                  'Opening Balance (Cash): ₹ ${NumberFormat('#,##0.00').format(controller.rxOpeningBalance.value)}',
                                )),
                            const SizedBox(height: 6),
                            Obx(() => _buildStatPill(
                                  'Expenses (Cash): ₹ ${NumberFormat('#,##0.00').format(controller.rxExpensesCashTotal.value)}',
                                )),
                            const SizedBox(height: 6),
                            Obx(() => _buildStatPill(
                                  'Username: ${controller.rxUsername.value.isNotEmpty ? controller.rxUsername.value : 'Cashier'}',
                                )),
                            const SizedBox(height: 6),
                            _buildStatPill('Order Statistics (Shift)'),
                            const SizedBox(height: 6),
                            Obx(() => _buildStatPill(
                                  'Fulfilled Orders: ${controller.rxFulfilledOrders.value}',
                                )),
                            const SizedBox(height: 6),
                            Obx(() => _buildStatPill(
                                  'Cancelled Orders: ${controller.rxCancelledOrders.value}',
                                )),
                            const SizedBox(height: 6),
                            Obx(() => _buildStatPill(
                                  'Complimentary Orders: ${controller.rxComplimentaryOrders.value}',
                                )),

                            const SizedBox(height: 12),

                            // ── Expected vs Actual Closing Summary ──
                            Obx(() {
                              final expected = controller.rxClosingBalance.value;
                              final actual = totalCashInDrawer;
                              final diff = actual - expected;
                              final isOver = diff > 0;
                              final isExact = diff.abs() < 0.01;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isExact
                                      ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
                                      : isOver
                                          ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2))
                                          : (isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isExact
                                        ? const Color(0xFF22C55E)
                                        : isOver
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFF59E0B),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Expected Closing Cash',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF475569),
                                          ),
                                        ),
                                        Text(
                                          '₹ ${NumberFormat('#,##0.00').format(expected)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Actual Cash in Drawer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF475569),
                                          ),
                                        ),
                                        Text(
                                          '₹ ${NumberFormat('#,##0.00').format(actual)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(
                                      height: 12,
                                      color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : Colors.grey.shade300,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isExact
                                              ? 'Balanced ✓'
                                              : isOver
                                                  ? 'Over by'
                                                  : 'Short by',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isExact
                                                ? const Color(0xFF16A34A)
                                                : isOver
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFFD97706),
                                          ),
                                        ),
                                        if (!isExact)
                                          Text(
                                            '₹ ${NumberFormat('#,##0.00').format(diff.abs())}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isOver
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFFD97706),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 8),

                            // ── Logout notice ──
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.3) : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.5) : const Color(0xFFFED7AA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You will be logged out after closing this shift.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: TextField(
                                controller: commentsCtrl,
                                maxLines: 3,
                                style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Comments Here',
                                  hintStyle: TextStyle(
                                    color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Cancel & Close Shift Buttons ──
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                      onPressed: () async {
                                        final total = totalCashInDrawer;
                                        final comments = commentsCtrl.text.trim();
                                        // Pop the dialog first before the controller
                                        // navigates away (offAllNamed handles the rest)
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                        await controller.closeShift(
                                          denominations: _counts,
                                          countedTotal: total,
                                          comments: comments.isNotEmpty ? comments : null,
                                        );
                                      },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF005963),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Close Shift',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFF005963),
        borderRadius: BorderRadius.circular(6),
        border: isDark ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? colorScheme.onSurface : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
