import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../enums/enum_main_menu.dart';
import '../../../../model/entity_shift_session.dart';
import '../../../../util/snackbar_util.dart';
import '../../../expenses_form/activity_expenses_from.dart';
import '../../controller_home.dart';
import 'controller_home_account.dart';
import 'dialog_cash_movement.dart';
import 'dialog_close_day.dart';
import 'dialog_close_shift.dart';
import 'dialog_start_day_shift.dart';

class FragmentHomeAccount extends StatelessWidget {
  const FragmentHomeAccount({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeAccount controller = Get.put(ControllerHomeAccount());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Bar ──
              _buildHeader(context, controller),

              const SizedBox(height: 24),

              // ── 6 KPI Cards ──
              _buildKpiCards(context, controller),

              const SizedBox(height: 24),

              // ── 2 Big Primary Action Buttons (Close Shift / Close Day) ──
              _buildActionButtons(context, controller),

              const SizedBox(height: 24),

              // ── Shift History ──
              _buildShiftHistory(context, controller),

              const SizedBox(height: 24),

              // ── Outlet Details Card ──
              _buildOutletDetailsCard(context, controller),

              const SizedBox(height: 24),

              // ── Bottom Sync Data Bar ──
              _buildSyncDataBar(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header ──
  Widget _buildHeader(BuildContext context, ControllerHomeAccount controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand/Outlet Title + Logo
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Text(
                    'RH',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.point_of_sale, color: Colors.white, size: 16),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => Text(
                  controller.rxOutletName.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                )),
          ],
        ),

        // User Pill with avatar and logout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? colorScheme.outlineVariant : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logout button
              InkWell(
                onTap: () {
                  if (Get.isRegistered<ControllerHome>()) {
                    Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.logout;
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.rxUsername.value.isNotEmpty
                            ? controller.rxUsername.value
                            : 'Cashier',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        controller.rxUserRole.value.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF475569),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2. The 6 KPI Cards ──
  Widget _buildKpiCards(BuildContext context, ControllerHomeAccount controller) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final bool isWide = constraints.maxWidth > 900;

      if (!isWide) {
        // Fallback for smaller screens: 3 columns x 2 rows
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildOpeningCard(context, controller, width: (constraints.maxWidth - 24) / 3),
            _buildCashInCard(context, controller, width: (constraints.maxWidth - 24) / 3),
            _buildSalesCard(context, controller, width: (constraints.maxWidth - 24) / 3),
            _buildCashOutCard(context, controller, width: (constraints.maxWidth - 24) / 3),
            _buildExpensesCard(context, controller, width: (constraints.maxWidth - 24) / 3),
            _buildClosingCard(context, controller, width: (constraints.maxWidth - 24) / 3),
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: _buildOpeningCard(context, controller)),
          const SizedBox(width: 14),
          Expanded(child: _buildCashInCard(context, controller)),
          const SizedBox(width: 14),
          Expanded(child: _buildSalesCard(context, controller)),
          const SizedBox(width: 14),
          Expanded(child: _buildCashOutCard(context, controller)),
          const SizedBox(width: 14),
          Expanded(child: _buildExpensesCard(context, controller)),
          const SizedBox(width: 14),
          Expanded(child: _buildClosingCard(context, controller)),
        ],
      );
    });
  }

  // Card 1: Opening Balance
  Widget _buildOpeningCard(BuildContext context, ControllerHomeAccount controller, {double? width}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    return Obx(() => _buildSummaryCard(
          context: context,
          title: 'opening_balance_cash'.tr,
          amount: controller.rxOpeningBalance.value,
          txnCount: controller.rxOpeningTxnCount.value,
          icon: Icons.account_balance_wallet_outlined,
          iconBg: isDark ? const Color(0xFF0369A1).withValues(alpha: 0.2) : const Color(0xFFE0F2FE),
          iconColor: iconColor,
          actionWidget: Icon(Icons.arrow_outward, color: iconColor, size: 16),
          width: width,
        ));
  }

  // Card 2: Cash In
  Widget _buildCashInCard(BuildContext context, ControllerHomeAccount controller, {double? width}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Obx(() => _buildSummaryCard(
          context: context,
          title: 'cash_in_cash'.tr,
          amount: controller.rxCashInTotal.value,
          txnCount: controller.rxCashInTxnCount.value,
          icon: Icons.add,
          iconBg: isDark ? const Color(0xFF16A34A).withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
          iconColor: iconColor,
          onTap: () => DialogCashMovement.show(context, isCashIn: true),
          actionWidget: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => DialogCashMovement.show(context, isCashIn: true),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF00796B) : const Color(0xFF005963),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'cash_in'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          width: width,
        ));
  }

  // Card 3: Sales (Cash)
  Widget _buildSalesCard(BuildContext context, ControllerHomeAccount controller, {double? width}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Obx(() => _buildSummaryCard(
          context: context,
          title: 'sales_cash'.tr,
          amount: controller.rxSalesCashTotal.value,
          txnCount: controller.rxSalesCashTxnCount.value,
          icon: Icons.payments_outlined,
          iconBg: isDark ? const Color(0xFF16A34A).withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
          iconColor: iconColor,
          actionWidget: Icon(Icons.arrow_outward, color: iconColor, size: 16),
          width: width,
        ));
  }

  // Card 4: Cash Out
  Widget _buildCashOutCard(BuildContext context, ControllerHomeAccount controller, {double? width}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    return Obx(() => _buildSummaryCard(
          context: context,
          title: 'cash_out_cash'.tr,
          amount: controller.rxCashOutTotal.value,
          txnCount: controller.rxCashOutTxnCount.value,
          icon: Icons.upload,
          iconBg: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.2) : const Color(0xFFFEE2E2),
          iconColor: iconColor,
          onTap: () => DialogCashMovement.show(context, isCashIn: false),
          actionWidget: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => DialogCashMovement.show(context, isCashIn: false),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF00796B) : const Color(0xFF005963),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'cash_out'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          width: width,
        ));
  }

  // Card 5: Expenses (Cash) — tappable, opens ActivityExpensesFrom dialog
  Widget _buildExpensesCard(BuildContext context, ControllerHomeAccount controller, {double? width}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    return Obx(() => _buildSummaryCard(
          context: context,
          title: 'expenses_cash'.tr,
          amount: controller.rxExpensesCashTotal.value,
          txnCount: controller.rxExpensesCashTxnCount.value,
          icon: Icons.credit_card,
          iconBg: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.2) : const Color(0xFFFEE2E2),
          iconColor: iconColor,
          onTap: () async {
            final result = await Get.dialog(
              const ActivityExpensesFrom(),
              barrierDismissible: false,
            );
            if (result == true) {
              controller.refreshAll();
            }
          },
          actionWidget: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await Get.dialog(
                    const ActivityExpensesFrom(),
                    barrierDismissible: false,
                  );
                  if (result == true) {
                    controller.refreshAll();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Add'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          width: width,
        ));
  }

  // Card 6: Closing Balance (Cash)
  Widget _buildClosingCard(BuildContext context, ControllerHomeAccount controller, {double? width}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
    return Obx(() => _buildSummaryCard(
          context: context,
          title: 'closing_balance_cash'.tr,
          amount: controller.rxClosingBalance.value,
          txnCount: controller.rxClosingTxnCount.value,
          icon: Icons.account_balance,
          iconBg: isDark ? const Color(0xFF0D9488).withValues(alpha: 0.2) : const Color(0xFFCCFBF1),
          iconColor: iconColor,
          actionWidget: Icon(Icons.arrow_outward, color: iconColor, size: 16),
          isHighlighted: true,
          width: width,
        ));
  }

  // Base Summary Card UI
  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required double amount,
    required int txnCount,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Widget actionWidget,
    bool isHighlighted = false,
    double? width,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    Widget cardContent = Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? (isDark ? colorScheme.primary : const Color(0xFF00796B))
              : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.6) : Colors.grey.shade200),
          width: isHighlighted ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              actionWidget,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$txnCount ${txnCount == 1 ? 'transaction'.tr : 'Transactions'.tr}',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }

  // ── 3. Big Action Buttons: Close Shift & Close Day ──
  Widget _buildActionButtons(BuildContext context, ControllerHomeAccount controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Left Button: Shift Action (Close or Start)
        Expanded(
          child: Obx(() {
            final isShiftOpen = controller.isShiftOpen;
            final isDayOpen = controller.isDayOpen;

            return InkWell(
              onTap: () {
                if (isShiftOpen) {
                  DialogCloseShift.show(context);
                } else {
                  DialogStartDayShift.show(context, isShiftOnly: isDayOpen);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF004D56) : const Color(0xFF005963),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF005963).withValues(alpha: isDark ? 0.4 : 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isShiftOpen ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isShiftOpen ? 'close_shift'.tr : 'start_shift'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isShiftOpen
                                ? '${'start_date'.tr}: ${controller.formatTimestamp(controller.rxActiveShift.value?.startTimestampMs)}'
                                : 'shift_closed_msg'.tr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(width: 18),

        // Right Button: Day Action (Close or Start)
        Expanded(
          child: Obx(() {
            final isDayOpen = controller.isDayOpen;

            return InkWell(
              onTap: () {
                if (isDayOpen) {
                  DialogCloseDay.show(context);
                } else {
                  DialogStartDayShift.show(context, isShiftOnly: false);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFDC2626) : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.4 : 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDayOpen ? Icons.power_settings_new : Icons.wb_sunny_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDayOpen ? 'close_day'.tr : 'start_day'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDayOpen
                                ? '${'start_date'.tr}: ${controller.formatTimestamp(controller.rxActiveDay.value?.startTimestampMs)}'
                                : 'day_closed_msg'.tr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── 4. Outlet Details Card ──
  Widget _buildOutletDetailsCard(BuildContext context, ControllerHomeAccount controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.6) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'outlet_details'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => Column(
                children: [
                  _buildDetailRow(context, 'ip_address'.tr, controller.rxIpAddress.value),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'outlet_phone'.tr,
                    controller.rxOutletPhone.value.isNotEmpty
                        ? controller.rxOutletPhone.value
                        : '+91 9876543210',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Address'.tr,
                    controller.rxOutletAddress.value.isNotEmpty
                        ? controller.rxOutletAddress.value
                        : 'Latur, Maharashtra, India',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'user_id'.tr, controller.rxUserId.value),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ── 5. Shift History ──
  Widget _buildShiftHistory(BuildContext context, ControllerHomeAccount controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final shifts = controller.rxShiftHistory;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.6) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0369A1).withValues(alpha: 0.2) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.history_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'shift_history'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${shifts.length} ${'shifts'.tr}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (shifts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'no_shift_history'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: shifts.map((shift) => _buildShiftHistoryRow(context, shift, controller)).toList(),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildShiftHistoryRow(BuildContext context, EntityShiftSession shift, ControllerHomeAccount controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0.00');
    final isOpen = shift.isOpen;
    final startMs = shift.startTimestampMs;
    final endMs = shift.endTimestampMs;
    final opening = shift.openingCash;
    final closing = shift.closingCash;
    final sales = shift.salesCash;
    final expenses = shift.expensesCash;
    final cashIn = shift.cashIn;
    final cashOut = shift.cashOut;
    final username = shift.startedByUsername ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOpen
            ? (isDark ? const Color(0xFF003830) : const Color(0xFFECFDF5))
            : (isDark ? colorScheme.surfaceContainer : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOpen
              ? (isDark ? colorScheme.primary : const Color(0xFF00796B))
              : (isDark ? colorScheme.outlineVariant.withValues(alpha: 0.5) : Colors.grey.shade200),
          width: isOpen ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen
                      ? (isDark ? const Color(0xFF0D9488) : const Color(0xFF00796B))
                      : (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFF64748B)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOpen ? 'ACTIVE'.tr : 'closed'.tr.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${'cashier'.tr}: $username',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                controller.formatTimestamp(startMs),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildShiftStat(
                context,
                'opening'.tr,
                '₹${fmt.format(opening)}',
                isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
              _buildShiftStat(
                context,
                'Sales'.tr,
                '₹${fmt.format(sales)}',
                isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
              ),
              _buildShiftStat(
                context,
                'cash_in'.tr,
                '₹${fmt.format(cashIn)}',
                isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
              ),
              _buildShiftStat(
                context,
                'Expenses'.tr,
                '₹${fmt.format(expenses)}',
                isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
              ),
              _buildShiftStat(
                context,
                'cash_out'.tr,
                '₹${fmt.format(cashOut)}',
                isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
              ),
              _buildShiftStat(
                context,
                isOpen ? 'calculated'.tr : 'closing'.tr,
                '₹${fmt.format(closing)}',
                isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
              ),
            ],
          ),
          if (endMs != null && !isOpen) ...
          [
            const SizedBox(height: 6),
            Text(
              '${'closed'.tr}: ${controller.formatTimestamp(endMs)}',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftStat(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ── 6. Bottom Sync Data Bar ──
  Widget _buildSyncDataBar(BuildContext context, ControllerHomeAccount controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        controller.refreshAll();
        SnackbarUtil.showSuccess('Data synced and metrics refreshed successfully');
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHigh : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sync,
              color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF475569),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'sync_data'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
