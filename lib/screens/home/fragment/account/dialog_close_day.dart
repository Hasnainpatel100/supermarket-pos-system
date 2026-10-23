import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'controller_home_account.dart';
import '../../../../service/service_z_report_pdf.dart';

class DialogCloseDay extends StatefulWidget {
  const DialogCloseDay({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DialogCloseDay(),
    );
  }

  @override
  State<DialogCloseDay> createState() => _DialogCloseDayState();
}

class _DialogCloseDayState extends State<DialogCloseDay> {
  final ControllerHomeAccount controller = Get.find<ControllerHomeAccount>();
  final TextEditingController commentsCtrl = TextEditingController();

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
    commentsCtrl.dispose();
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
    setState(() {
      final next = (_counts[d] ?? 0) + 1;
      _counts[d] = next;
      _countCtrl[d]?.text = '$next';
    });
  }

  void _decrement(int d) {
    final c = _counts[d] ?? 0;
    if (c > 0) {
      setState(() {
        _counts[d] = c - 1;
        _countCtrl[d]?.text = '${c - 1}';
      });
    }
  }

  void _onCountChanged(int d, String v) {
    final parsed = int.tryParse(v) ?? 0;
    setState(() => _counts[d] = parsed.clamp(0, 999999));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final nowFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    final title = 'End-of-Day Register Closing (Z-Report) - $nowFormatted';

    return Dialog(
      backgroundColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 780),
        child: Column(
          children: [
            // ── Red Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: const Color(0xFFDC2626),
              child: Row(
                children: [
                  const Icon(Icons.power_settings_new, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Cash drawer reconciliation, denomination counting & daily register closing audit',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
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

            // ── Main Body: 2 Columns (Denominations on Left, Summary on Right) ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Physical Denominations Counter (flex 5)
                    Expanded(
                      flex: 5,
                      child: _denominationsTable(isDark, colorScheme),
                    ),
                    const SizedBox(width: 16),

                    // Right Column: Reconciliation & Actions (flex 6)
                    Expanded(
                      flex: 6,
                      child: _rightColumn(isDark, colorScheme),
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

  Widget _denominationsTable(bool isDark, ColorScheme cs) {
    final borderColor = isDark ? cs.outlineVariant : Colors.grey.shade300;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text('Currency Note / Coin',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                      child: Text('Count',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('Subtotal',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ),
              ],
            ),
          ),

          // Denomination rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _denominations.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? cs.outlineVariant.withValues(alpha: 0.3) : Colors.grey.shade200,
              ),
              itemBuilder: (ctx, i) {
                final d = _denominations[i];
                final count = _counts[d] ?? 0;
                final amount = (d * count).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          d >= 10 ? '₹ $d Note' : '₹ $d Coin',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
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
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                                  border: UnderlineInputBorder(),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
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
                          child: Text(
                            '₹ ${NumberFormat('#,##0.00').format(amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: cs.onSurface,
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
              color: isDark ? cs.surfaceContainerHighest : const Color(0xFFFEE2E2),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, size: 20, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                const Text(
                  'Total Physical Cash Counted:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '₹ ${NumberFormat('#,##0.00').format(_totalCash)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn(bool isDark, ColorScheme cs, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: cs.onSurface),
      ),
    );
  }

  Widget _rightColumn(bool isDark, ColorScheme cs) {
    final expectedCash = controller.rxClosingBalance.value;
    final countedCash = _totalCash;
    final variance = countedCash - expectedCash;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.5) : const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Closing the business day finalizes all register drawers and automatically closes the active shift.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Payment Modes Table
          _paymentModesTable(isDark, cs),
          const SizedBox(height: 10),

          // Summary Metrics List
          Obx(() => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? cs.outlineVariant : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildRow('Opening Float', '₹ ${NumberFormat('#,##0.00').format(controller.rxOpeningBalance.value)}', isDark: isDark, cs: cs),
                    Divider(height: 12, color: cs.outlineVariant.withValues(alpha: 0.3)),
                    _buildRow('Total Cash Sales', '₹ ${NumberFormat('#,##0.00').format(controller.rxSalesCashTotal.value)}', isDark: isDark, cs: cs),
                    Divider(height: 12, color: cs.outlineVariant.withValues(alpha: 0.3)),
                    _buildRow('Total Cash In', '₹ ${NumberFormat('#,##0.00').format(controller.rxCashInTotal.value)}', isDark: isDark, cs: cs),
                    Divider(height: 12, color: cs.outlineVariant.withValues(alpha: 0.3)),
                    _buildRow('Total Cash Out / Drops', '₹ ${NumberFormat('#,##0.00').format(controller.rxCashOutTotal.value)}', isDark: isDark, cs: cs),
                    Divider(height: 12, color: cs.outlineVariant.withValues(alpha: 0.3)),
                    _buildRow('Operating Expenses', '₹ ${NumberFormat('#,##0.00').format(controller.rxExpensesCashTotal.value)}', isDark: isDark, cs: cs),
                    Divider(height: 12, color: cs.outlineVariant.withValues(alpha: 0.3)),
                    _buildRow(
                      'Expected Drawer Cash',
                      '₹ ${NumberFormat('#,##0.00').format(expectedCash)}',
                      isBold: true,
                      textColor: cs.onSurface,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),

          // Cash Variance & Status Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: variance == 0
                  ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5))
                  : (variance < 0
                      ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEF2F2))
                      : (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF))),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: variance == 0
                    ? const Color(0xFF10B981)
                    : (variance < 0 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  variance == 0
                      ? Icons.check_circle_rounded
                      : (variance < 0 ? Icons.error_rounded : Icons.info_rounded),
                  color: variance == 0
                      ? const Color(0xFF10B981)
                      : (variance < 0 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variance == 0
                            ? 'Drawer Perfectly Balanced (₹0.00)'
                            : (variance < 0
                                ? 'Cash Shortage / Deficit'
                                : 'Cash Overage / Excess'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: variance == 0
                              ? const Color(0xFF059669)
                              : (variance < 0 ? const Color(0xFFDC2626) : const Color(0xFF2563EB)),
                        ),
                      ),
                      Text(
                        'Counted: ₹${NumberFormat('#,##0.00').format(countedCash)}  |  Expected: ₹${NumberFormat('#,##0.00').format(expectedCash)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${variance >= 0 ? '+' : ''}₹ ${NumberFormat('#,##0.00').format(variance)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: variance == 0
                        ? const Color(0xFF059669)
                        : (variance < 0 ? const Color(0xFFDC2626) : const Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Comments
          TextField(
            controller: commentsCtrl,
            maxLines: 2,
            style: TextStyle(color: cs.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Day Closing Remarks / Notes...',
              hintStyle: TextStyle(
                color: isDark ? cs.onSurfaceVariant : Colors.grey.shade400,
                fontSize: 12.5,
              ),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? cs.outlineVariant : Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Print Z-Report Button
          OutlinedButton.icon(
            onPressed: () {
              final day = controller.rxActiveDay.value;
              final startTime = day?.startTimestampMs != null
                  ? DateTime.fromMillisecondsSinceEpoch(day!.startTimestampMs!)
                  : DateTime.now();

              ServiceZReportPdf.printZReport(
                reportType: 'END-OF-DAY REGISTER AUDIT (Z-REPORT)',
                storeName: controller.rxOutletName.value.isNotEmpty
                    ? controller.rxOutletName.value
                    : 'RH POS',
                branchName: controller.rxBranchName.value,
                terminalId: controller.rxDeviceName.value,
                cashierName: controller.rxUsername.value.isNotEmpty
                    ? controller.rxUsername.value
                    : 'Manager',
                startTime: startTime,
                endTime: DateTime.now(),
                openingCash: controller.rxOpeningBalance.value,
                salesCash: controller.rxSalesCashTotal.value,
                paymentModes: Map<String, double>.from(controller.rxPaymentModes),
                cashIn: controller.rxCashInTotal.value,
                cashOut: controller.rxCashOutTotal.value,
                expensesCash: controller.rxExpensesCashTotal.value,
                expectedClosingCash: expectedCash,
                physicalCountedCash: countedCash,
                denominations: Map<int, int>.from(_counts),
                fulfilledOrders: controller.rxFulfilledOrders.value,
                cancelledOrders: controller.rxCancelledOrders.value,
                complimentaryOrders: controller.rxComplimentaryOrders.value,
                comments: commentsCtrl.text.trim(),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Print / Preview Z-Report Slip', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
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
                    final comments = commentsCtrl.text.trim();
                    final counted = _totalCash;
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    await controller.closeDay(
                      comments: comments.isNotEmpty ? comments : null,
                      denominations: Map<int, int>.from(_counts),
                      countedTotal: counted,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close Day & Logout', style: TextStyle(fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHighest : Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                Text('Total Sales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              ],
            ),
          ),
          Obx(() {
            final modes = controller.rxPaymentModes;
            return Column(
              children: modes.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Row(
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      Text('₹ ${NumberFormat('#,##0.00').format(e.value)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
    required bool isDark,
    required ColorScheme cs,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? cs.onSurfaceVariant : const Color(0xFF475569),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: FontWeight.bold,
            color: textColor ?? (isDark ? cs.onSurface : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
