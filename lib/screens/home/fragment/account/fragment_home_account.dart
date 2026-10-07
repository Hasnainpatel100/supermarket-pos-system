import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../enums/enum_main_menu.dart';
import '../../../../model/entity_shift_session.dart';
import '../../../../util/app_colors.dart';
import '../../../../util/app_spacing.dart';
import '../../../../util/snackbar_util.dart';
import '../../controller_home.dart';
import 'controller_home_account.dart';
import 'dialog_close_day.dart';
import 'dialog_close_shift.dart';
import 'dialog_start_day_shift.dart';

class FragmentHomeAccount extends StatelessWidget {
  const FragmentHomeAccount({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerHomeAccount());
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(controller: controller, isDark: isDark, cs: cs),
              const SizedBox(height: AppSpacing.xl),
              _KpiCards(controller: controller, isDark: isDark, cs: cs),
              const SizedBox(height: AppSpacing.xl),
              _ActionButtons(controller: controller, isDark: isDark, cs: cs),
              const SizedBox(height: AppSpacing.xl),
              _ShiftHistory(controller: controller, isDark: isDark, cs: cs),
              const SizedBox(height: AppSpacing.xl),
              _OutletDetails(controller: controller, isDark: isDark, cs: cs),
              const SizedBox(height: AppSpacing.xl),
              _SyncBar(controller: controller, isDark: isDark, cs: cs),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 1. Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _Header({required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.brandTealDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          child: const Row(
            children: [
              Text('RH', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              SizedBox(width: 4),
              Icon(Icons.point_of_sale, color: AppColors.textWhite, size: 16),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHigh : AppColors.textWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            border: Border.all(color: isDark ? cs.outlineVariant : AppColors.borderLight),
            boxShadow: [BoxShadow(color: AppColors.shadowSubtle, blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (Get.isRegistered<ControllerHome>()) {
                    Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.logout;
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.logout, color: AppColors.error, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.rxUsername.value.isNotEmpty ? controller.rxUsername.value : 'Cashier',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                  ),
                  Text(
                    controller.rxUserRole.value.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: isDark ? cs.onSurfaceVariant : AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                ],
              )),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: isDark ? cs.surfaceContainerHighest : AppColors.dividerLight,
                child: Icon(Icons.person, color: isDark ? cs.onSurfaceVariant : AppColors.textSecondaryDark, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 2. KPI Cards ─────────────────────────────────────────────────────────────

class _KpiCards extends StatelessWidget {
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _KpiCards({required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    final items = <_KpiItem>[
      _KpiItem.opening(controller.rxOpeningBalance.value, controller.rxOpeningTxnCount.value, isDark),
      _KpiItem.cashIn(controller.rxCashInTotal.value, controller.rxCashInTxnCount.value, isDark),
      _KpiItem.sales(controller.rxSalesCashTotal.value, controller.rxSalesCashTxnCount.value, isDark),
      _KpiItem.cashOut(controller.rxCashOutTotal.value, controller.rxCashOutTxnCount.value, isDark),
      _KpiItem.expenses(controller.rxExpensesCashTotal.value, controller.rxExpensesCashTxnCount.value, isDark),
      _KpiItem.closing(controller.rxClosingBalance.value, controller.rxClosingTxnCount.value, isDark),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth > 900) {
        return Row(
          children: List.generate(items.length, (i) {
            final spacing = (items.length - 1) * AppSpacing.md;
            return Expanded(child: _KpiCard(item: items[i], width: (constraints.maxWidth - spacing) / items.length, isDark: isDark, cs: cs));
          }),
        );
      }
      return Column(
        children: List.generate(3, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row < 2 ? AppSpacing.sm : 0),
            child: Row(
              children: [
                Expanded(child: _KpiCard(item: items[row * 2], width: (constraints.maxWidth - AppSpacing.sm) / 2, isDark: isDark, cs: cs)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _KpiCard(item: items[row * 2 + 1], width: (constraints.maxWidth - AppSpacing.sm) / 2, isDark: isDark, cs: cs)),
              ],
            ),
          );
        }),
      );
    });
  }
}

class _KpiItem {
  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final double amount;
  final int txnCount;
  final bool isHighlighted;
  final Widget? action;

  const _KpiItem._({
    required this.title, required this.icon, required this.iconBg, required this.iconColor,
    required this.amount, required this.txnCount, this.isHighlighted = false, this.action,
  });

  factory _KpiItem.opening(double amount, int count, bool isDark) => _KpiItem._(
    title: 'opening_balance_cash'.tr, icon: Icons.account_balance_wallet_outlined,
    iconColor: AppColors.info, iconBg: isDark ? AppColors.info.withValues(alpha: 0.2) : AppColors.infoLight,
    amount: amount, txnCount: count,
    action: Icon(Icons.arrow_outward, color: AppColors.info, size: 16),
  );

  factory _KpiItem.cashIn(double amount, int count, bool isDark) => _KpiItem._(
    title: 'cash_in_cash'.tr, icon: Icons.add,
    iconColor: AppColors.success, iconBg: isDark ? AppColors.success.withValues(alpha: 0.2) : AppColors.successLight,
    amount: amount, txnCount: count,
  );

  factory _KpiItem.sales(double amount, int count, bool isDark) => _KpiItem._(
    title: 'sales_cash'.tr, icon: Icons.payments_outlined,
    iconColor: AppColors.success, iconBg: isDark ? AppColors.success.withValues(alpha: 0.2) : AppColors.successLight,
    amount: amount, txnCount: count,
    action: Icon(Icons.arrow_outward, color: AppColors.success, size: 16),
  );

  factory _KpiItem.cashOut(double amount, int count, bool isDark) => _KpiItem._(
    title: 'cash_out_cash'.tr, icon: Icons.upload,
    iconColor: AppColors.error, iconBg: isDark ? AppColors.error.withValues(alpha: 0.2) : AppColors.errorLight,
    amount: amount, txnCount: count,
  );

  factory _KpiItem.expenses(double amount, int count, bool isDark) => _KpiItem._(
    title: 'expenses_cash'.tr, icon: Icons.credit_card,
    iconColor: AppColors.error, iconBg: isDark ? AppColors.error.withValues(alpha: 0.2) : AppColors.errorLight,
    amount: amount, txnCount: count, isHighlighted: false,
  );

  factory _KpiItem.closing(double amount, int count, bool isDark) => _KpiItem._(
    title: 'closing_balance_cash'.tr, icon: Icons.account_balance,
    iconColor: AppColors.teal, iconBg: isDark ? AppColors.teal.withValues(alpha: 0.2) : AppColors.tealLight,
    amount: amount, txnCount: count, isHighlighted: true,
    action: Icon(Icons.arrow_outward, color: AppColors.teal, size: 16),
  );
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;
  final double width;
  final bool isDark;
  final ColorScheme cs;

  const _KpiCard({required this.item, required this.width, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : AppColors.textWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: item.isHighlighted
              ? (isDark ? cs.primary : AppColors.brandTealDark)
              : (isDark ? cs.outlineVariant.withValues(alpha: 0.6) : AppColors.borderLight),
          width: item.isHighlighted ? 1.8 : 1.0,
        ),
        boxShadow: [BoxShadow(color: AppColors.shadowSubtle, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 28, height: 28,
                decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(6)),
                child: Icon(item.icon, color: item.iconColor, size: 16),
              ),
              if (item.action != null) item.action!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
              color: isDark ? cs.onSurfaceVariant : AppColors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('₹${NumberFormat('#,##0.00').format(item.amount)}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          const SizedBox(height: 2),
          Text('${item.txnCount} ${item.txnCount == 1 ? 'transaction'.tr : 'Transactions'.tr}',
            style: TextStyle(fontSize: 10,
              color: isDark ? cs.onSurfaceVariant.withValues(alpha: 0.7) : AppColors.textSecondaryLight),
          ),
        ],
      ),
    );

    return content;
  }
}

// ─── 3. Action Buttons ────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _ActionButtons({required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ShiftButton(controller: controller, isDark: isDark, cs: cs)),
        const SizedBox(width: 18),
        Expanded(child: _DayButton(controller: controller, isDark: isDark, cs: cs)),
      ],
    );
  }
}

class _ShiftButton extends StatelessWidget {
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _ShiftButton({required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Obx(() => _actionBtn(
      context,
      icon: controller.isShiftOpen ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
      label: controller.isShiftOpen ? 'close_shift'.tr : 'start_shift'.tr,
      sub: controller.isShiftOpen
          ? '${'start_date'.tr}: ${controller.formatTimestamp(controller.rxActiveShift.value?.startTimestampMs)}'
          : 'shift_closed_msg'.tr,
      bg: AppColors.brandTealDark,
      onTap: () {
        if (controller.isShiftOpen) {
          DialogCloseShift.show(context);
        } else {
          DialogStartDayShift.show(context, isShiftOnly: controller.isDayOpen);
        }
      },
    ));
  }
}

class _DayButton extends StatelessWidget {
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _DayButton({required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Obx(() => _actionBtn(
      context,
      icon: controller.isDayOpen ? Icons.power_settings_new : Icons.wb_sunny_rounded,
      label: controller.isDayOpen ? 'close_day'.tr : 'start_day'.tr,
      sub: controller.isDayOpen
          ? '${'start_date'.tr}: ${controller.formatTimestamp(controller.rxActiveDay.value?.startTimestampMs)}'
          : 'day_closed_msg'.tr,
      bg: AppColors.error,
      onTap: () {
        if (controller.isDayOpen) {
          DialogCloseDay.show(context);
        } else {
          DialogStartDayShift.show(context, isShiftOnly: false);
        }
      },
    ));
  }
}

Widget _actionBtn(BuildContext context, {
  required IconData icon, required String label, required String sub,
  required Color bg, required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44,
            decoration: const BoxDecoration(color: AppColors.textWhiteOverlay18, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.textWhite, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(color: AppColors.textWhite.withValues(alpha: 0.85), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── 4. Shift History ─────────────────────────────────────────────────────────

class _ShiftHistory extends StatelessWidget {
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _ShiftHistory({required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return _ScaffoldCard(
      isDark: isDark, cs: cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.info.withValues(alpha: 0.2) : AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history_rounded, color: isDark ? AppColors.infoLight : AppColors.info, size: 18),
              ),
              const SizedBox(width: 10),
              Text('shift_history'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
              const Spacer(),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? cs.surfaceContainerHighest : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${controller.rxShiftHistory.length} ${'shifts'.tr}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: isDark ? cs.onSurfaceVariant : AppColors.textSecondaryDark),
                ),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final shifts = controller.rxShiftHistory;
            if (shifts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('no_shift_history'.tr,
                    style: TextStyle(fontSize: 13, color: isDark ? cs.onSurfaceVariant : AppColors.textSecondaryLight)),
                ),
              );
            }
            return Column(children: shifts.map((s) => _ShiftRow(shift: s, controller: controller, isDark: isDark, cs: cs)).toList());
          }),
        ],
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  final EntityShiftSession shift;
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _ShiftRow({required this.shift, required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isOpen = shift.isOpen;
    final openedBy = shift.startedByUsername ?? 'Unknown';
    final closedBy = shift.closedByUsername;
    final isDiffUser = !isOpen && closedBy != null && closedBy.trim().isNotEmpty && closedBy.trim().toLowerCase() != openedBy.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOpen
            ? (isDark ? AppColors.success.withValues(alpha: 0.1) : AppColors.successLight)
            : (isDark ? cs.surfaceContainer : AppColors.backgroundLight),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOpen
              ? (isDark ? cs.primary : AppColors.brandTealDark)
              : (isDark ? cs.outlineVariant.withValues(alpha: 0.5) : AppColors.borderLight),
          width: isOpen ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _statusBadge(isOpen, isDark, cs),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8, runSpacing: 4,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_outline, size: 14, color: isDark ? cs.onSurfaceVariant : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Opened by: $openedBy',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  ]),
                  if (isDiffUser) _closedByChip(closedBy, isDark, cs)
                  else if (closedBy != null && closedBy.isNotEmpty)
                    Text('(Closed by $closedBy)',
                      style: TextStyle(fontSize: 11, color: isDark ? cs.onSurfaceVariant : AppColors.textSecondary)),
                ],
              ),
            ),
            Text(controller.formatTimestamp(shift.startTimestampMs),
              style: TextStyle(fontSize: 11, color: isDark ? cs.onSurfaceVariant : AppColors.textSecondaryLight)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _shiftStat(context, 'opening'.tr, '₹${NumberFormat('#,##0.00').format(shift.openingCash)}', AppColors.info),
            _shiftStat(context, 'Sales'.tr, '₹${NumberFormat('#,##0.00').format(shift.salesCash)}', AppColors.success),
            _shiftStat(context, 'cash_in'.tr, '₹${NumberFormat('#,##0.00').format(shift.cashIn)}', AppColors.teal),
            _shiftStat(context, 'Expenses'.tr, '₹${NumberFormat('#,##0.00').format(shift.expensesCash)}', AppColors.error),
            _shiftStat(context, 'cash_out'.tr, '₹${NumberFormat('#,##0.00').format(shift.cashOut)}', AppColors.errorRed),
            _shiftStat(context, isOpen ? 'calculated'.tr : 'closing'.tr, '₹${NumberFormat('#,##0.00').format(shift.closingCash)}', AppColors.purple),
          ]),
          if (shift.endTimestampMs != null && !isOpen) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 13,
                color: isDiffUser ? AppColors.warningDark : (isDark ? cs.onSurfaceVariant : AppColors.textSecondaryLight)),
              const SizedBox(width: 5),
              Text(closedBy != null && closedBy.trim().isNotEmpty
                  ? 'Closed by $closedBy on ${controller.formatTimestamp(shift.endTimestampMs)}'
                  : '${'closed'.tr}: ${controller.formatTimestamp(shift.endTimestampMs)}',
                style: TextStyle(
                  fontSize: 11, fontWeight: isDiffUser ? FontWeight.w600 : FontWeight.normal,
                  color: isDiffUser ? AppColors.warningDark : (isDark ? cs.onSurfaceVariant : AppColors.textSecondaryLight),
                ),
              ),
              if (shift.comments != null && shift.comments!.trim().isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.comment_outlined, size: 12,
                  color: isDark ? cs.onSurfaceVariant : AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Note: ${shift.comments}',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                      color: isDark ? cs.onSurfaceVariant : AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ]),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(bool isOpen, bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? (isDark ? AppColors.teal : AppColors.brandTealDark)
            : (isDark ? cs.surfaceContainerHighest : AppColors.textSecondary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(isOpen ? 'ACTIVE'.tr : 'closed'.tr.toUpperCase(),
        style: const TextStyle(color: AppColors.textWhite, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _closedByChip(String closedBy, bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.warningDark.withValues(alpha: 0.2) : AppColors.warningLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? AppColors.warning : AppColors.warningDark, width: 0.8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_clock, size: 11, color: isDark ? AppColors.warningLight : AppColors.warningDark),
        const SizedBox(width: 4),
        Text('Closed by: $closedBy',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold,
            color: isDark ? AppColors.warningLight : AppColors.warningDark),
        ),
      ]),
    );
  }

  Widget _shiftStat(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final labelColor = isDark ? cs.onSurfaceVariant : AppColors.textSecondaryLight;
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

// ─── 5. Outlet Details ────────────────────────────────────────────────────────

class _OutletDetails extends StatelessWidget {
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _OutletDetails({required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return _ScaffoldCard(
      isDark: isDark, cs: cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('outlet_details'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 16),
          Obx(() => Column(children: [
            _detailRow('ip_address'.tr, controller.rxIpAddress.value, isDark, cs),
            const SizedBox(height: 12),
            _detailRow('outlet_phone'.tr, controller.rxOutletPhone.value.isNotEmpty ? controller.rxOutletPhone.value : '+91 9876543210', isDark, cs),
            const SizedBox(height: 12),
            _detailRow('Address'.tr, controller.rxOutletAddress.value.isNotEmpty ? controller.rxOutletAddress.value : 'Latur, Maharashtra, India', isDark, cs),
            const SizedBox(height: 12),
            _detailRow('user_id'.tr, controller.rxUserId.value, isDark, cs),
          ])),
        ],
      ),
    );
  }
}

Widget _detailRow(String label, String value, bool isDark, ColorScheme cs) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 13,
        color: isDark ? cs.onSurfaceVariant : AppColors.textSecondary, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface))),
    ],
  );
}

// ─── 6. Sync Bar ──────────────────────────────────────────────────────────────

class _SyncBar extends StatelessWidget {
  final ControllerHomeAccount controller;
  final bool isDark;
  final ColorScheme cs;

  const _SyncBar({required this.controller, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        controller.refreshAll();
        SnackbarUtil.showSuccess('sync_success'.tr);
      },
      borderRadius: BorderRadius.circular(10),
      child: _ScaffoldCard(
        isDark: isDark, cs: cs, center: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sync, color: isDark ? cs.onSurfaceVariant : AppColors.textSecondaryDark, size: 18),
            const SizedBox(width: 8),
            Text('sync_data'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Card Wrapper ──────────────────────────────────────────────────────

class _ScaffoldCard extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  final Widget child;
  final bool center;

  const _ScaffoldCard({required this.isDark, required this.cs, required this.child, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(center ? AppSpacing.md : AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : AppColors.textWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? cs.outlineVariant.withValues(alpha: 0.6) : AppColors.borderLight),
        boxShadow: [BoxShadow(color: AppColors.shadowSubtle, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
