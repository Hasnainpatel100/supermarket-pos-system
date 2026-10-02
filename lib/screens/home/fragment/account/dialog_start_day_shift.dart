import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../enums/enum_main_menu.dart';
import '../../../../features/authentication/data/auth_repository.dart';
import '../../../../repository/repo_storage.dart';
import '../../../../util/app_route.dart';
import '../../controller_home.dart';
import 'controller_home_account.dart';

class DialogStartDayShift extends StatefulWidget {
  final bool isShiftOnly;

  const DialogStartDayShift({super.key, this.isShiftOnly = false});

  static Future<void> show(BuildContext context, {bool isShiftOnly = false}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DialogStartDayShift(isShiftOnly: isShiftOnly),
    );
  }

  @override
  State<DialogStartDayShift> createState() => _DialogStartDayShiftState();
}

class _DialogStartDayShiftState extends State<DialogStartDayShift> {
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

  Future<void> _handleCancelOrLogout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 24),
            SizedBox(width: 8),
            Text('Exit Without Starting?'),
          ],
        ),
        content: Text(
          widget.isShiftOnly
              ? 'Starting a shift is required to operate the POS terminal.\n\nDo you want to log out instead?'
              : 'Starting the business day & shift is required to operate the POS terminal.\n\nDo you want to log out instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay & Start'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      Navigator.of(context).pop();
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().logout();
      }
      if (Get.isRegistered<RepoStorage>()) {
        await Get.find<RepoStorage>().logout();
      }
      Get.offAllNamed(AppRoute.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final nowFormatted = DateFormat('dd/MM/yyyy hh:mm:ss a').format(DateTime.now());
    final username = controller.rxUsername.value.isNotEmpty
        ? controller.rxUsername.value
        : 'User';
    final title = widget.isShiftOnly
        ? 'Start Shift - User: $username | $nowFormatted'
        : 'Start Day & Shift - User: $username | $nowFormatted';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleCancelOrLogout(context);
        }
      },
      child: Dialog(
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
          child: Column(
            children: [
              // ── Teal/Indigo Header ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00796B), Color(0xFF0288D1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleCancelOrLogout(context),
                    ),
                  ],
                ),
              ),

            // ── Scrollable Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Previous Shift Remaining Cash Banner ──
                    Obx(() {
                      final prevShift = controller.rxPreviousShift.value;
                      final prevDay = controller.rxPreviousDay.value;

                      // Show previous shift's closing cash if available
                      if (prevShift != null) {
                        final prevCash = prevShift.closingCash;
                        final prevUsername = prevShift.closedByUsername ?? prevShift.startedByUsername ?? 'Previous Cashier';
                        final prevTime = controller.formatTimestamp(prevShift.endTimestampMs);
                        final fmt = NumberFormat('#,##0.00');

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D47A1).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Previous Shift Remaining Cash',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '₹ ${fmt.format(prevCash)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Closed by $prevUsername on $prevTime',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quick fill button
                                  InkWell(
                                    onTap: () => _autoFillFromAmount(prevCash),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 16),
                                          SizedBox(height: 2),
                                          Text(
                                            'Auto Fill',
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Hint text
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 13, color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF64748B)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'This is the remaining cash from the previous shift. Count the actual cash in drawer below.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }

                      // If no previous shift but there's a previous day, show day info
                      if (prevDay != null && prevShift == null) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 16, color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Previous Day Closed: ${controller.formatTimestamp(prevDay.endTimestampMs)}  •  Closing: ₹${prevDay.closingCash.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }

                      return const SizedBox.shrink();
                    }),

                    // ── Denomination Table Container ──
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00796B),
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
                                      fontSize: 13,
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
                                        fontSize: 13,
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
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Denomination Rows
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: denominations.length,
                            separatorBuilder: (ctx, i) => Divider(
                              height: 1,
                              color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : Colors.grey.shade200,
                            ),
                            itemBuilder: (ctx, i) {
                              final denom = denominations[i];
                              final count = _counts[denom] ?? 0;
                              final amount = (denom * count).toDouble();

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Row(
                                  children: [
                                    // Denomination Name
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        '₹ $denom',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),

                                    // Stepper
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: () => _decrement(denom),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark ? colorScheme.outline : Colors.grey.shade400,
                                                ),
                                              ),
                                              child: Icon(Icons.remove, size: 16, color: colorScheme.onSurface),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 50,
                                            height: 32,
                                            child: TextField(
                                              controller: _countControllers[denom],
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              onChanged: (val) => _onCountChanged(denom, val),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                                border: UnderlineInputBorder(),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => _increment(denom),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark ? colorScheme.outline : Colors.grey.shade400,
                                                ),
                                              ),
                                              child: Icon(Icons.add, size: 16, color: colorScheme.onSurface),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Amount Column
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '₹ ${NumberFormat('#,##0.00').format(amount)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── TOTAL CASH IN DRAWER BOX ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL CASH IN DRAWER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDark ? colorScheme.onSurface : const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'This will be set as Opening Balance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Compare with previous shift
                              Obx(() {
                                final prev = controller.rxPreviousShift.value;
                                if (prev == null) return const SizedBox.shrink();
                                final diff = totalCashInDrawer - prev.closingCash;
                                final isExact = diff.abs() < 0.01;
                                final isOver = diff > 0;
                                if (isExact) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '✓ Matched',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isOver
                                          ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEE2E2))
                                          : (isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF9C3)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isOver
                                          ? '+₹${NumberFormat('#,##0.00').format(diff)} over'
                                          : '-₹${NumberFormat('#,##0.00').format(diff.abs())} short',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isOver
                                            ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                                            : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? colorScheme.surfaceContainer : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: isDark ? Border.all(color: colorScheme.outlineVariant) : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '₹ ${NumberFormat('#,##0.00').format(totalCashInDrawer)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Comments Input ──
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: commentsCtrl,
                      maxLines: 2,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Comments here...',
                        hintStyle: TextStyle(
                          color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? colorScheme.outlineVariant : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: show opening amount summary
                  Obx(() {
                    final prev = controller.rxPreviousShift.value;
                    if (prev == null) return const SizedBox.shrink();
                    return Text(
                      'Previous remaining: ₹${NumberFormat('#,##0.00').format(prev.closingCash)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                  // Right: Start button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final total = totalCashInDrawer;
                      final comments = commentsCtrl.text.trim();
                      if (widget.isShiftOnly) {
                        await controller.startShiftOnly(
                          openingCash: total,
                          denominations: _counts,
                          comments: comments.isNotEmpty ? comments : null,
                        );
                      } else {
                        await controller.startDayAndShift(
                          openingCash: total,
                          denominations: _counts,
                          comments: comments.isNotEmpty ? comments : null,
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      if (Get.isRegistered<ControllerHome>()) {
                        Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.pos;
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      widget.isShiftOnly ? 'Start Shift' : 'Start Day & Shift',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Auto-fill denominations to approximately match the given amount.
  /// Uses a greedy algorithm (largest denomination first).
  void _autoFillFromAmount(double targetAmount) {
    int remaining = targetAmount.round();
    final newCounts = <int, int>{};

    for (final denom in denominations) {
      final count = remaining ~/ denom;
      newCounts[denom] = count;
      remaining -= count * denom;
    }

    setState(() {
      for (final denom in denominations) {
        _counts[denom] = newCounts[denom] ?? 0;
        _countControllers[denom]?.text = (_counts[denom] ?? 0).toString();
      }
    });
  }
}
