import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../model/entity_finance_transaction.dart';
import '../../../../service/service_finance.dart';
import '../../../../service/service_object_box.dart';
import '../../../../widget/my_card.dart';
import '../../../expenses_form/activity_expenses_from.dart';
import 'controller_home_expenses.dart';

class FragmentHomeExpenses extends StatelessWidget {
  const FragmentHomeExpenses({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Get.put(
      ControllerHomeExpenses(
        ServiceFinance(
          Get.find<ServiceObjectBox>().box<EntityFinanceTransaction>(),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Modern Header Row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade300.withValues(alpha: .3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finance'.tr,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Track your expenses'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // ── Actions Row: Date Range + Refresh (grouped) ──────────────
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date Range Filter
                      Obx(() {
                        final active = controller.rxDateRangeActive.value;
                        return Tooltip(
                          message: active
                              ? 'Clear date filter'.tr
                              : 'Filter by date range'.tr,
                          child: GestureDetector(
                            onTap: () async {
                              if (active) {
                                controller.clearDateRange();
                              } else {
                                await controller.pickDateRange(context);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: active
                                    ? LinearGradient(
                                  colors: [
                                    Colors.blue.shade500,
                                    Colors.purple.shade500,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    active
                                        ? Icons.date_range_rounded
                                        : Icons.date_range_outlined,
                                    size: 15,
                                    color: active
                                        ? Colors.white
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    active
                                        ? _rangeLabel(controller)
                                        : 'Filter'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.white
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Divider
                      Container(
                        width: 1,
                        height: 18,
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),

                      // Refresh Button
                      Tooltip(
                        message: 'Refresh'.tr,
                        child: InkWell(
                          onTap: controller.loadData,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ── New Transaction Text Button ───────────────────────────────
                FilledButton.icon(
                  onPressed: () async {
                    final result = await Get.dialog(
                      const ActivityExpensesFrom(),
                      barrierDismissible: false,
                    );
                    if (result == true) controller.loadData();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'New Transaction'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.green.shade300.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Date range active banner
          Obx(() {
            if (!controller.rxDateRangeActive.value) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Showing: ${_rangeLabel(controller)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.clearDateRange,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // ── Summary Row ─────────────────────────────────────────────────────
          Obx(() {
            final currFmt = NumberFormat.compactCurrency(
              locale: 'en_IN',
              symbol: '₹',
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ModernMiniStat(
                    label: 'Expenses'.tr,
                    value: currFmt.format(controller.totalExpense.value),
                    icon: Icons.shopping_cart_rounded,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade500, Colors.orange.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ModernMiniStat(
                    label: 'Borrowed'.tr,
                    value: currFmt.format(controller.totalBorrow.value),
                    icon: Icons.call_received_rounded,
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade500, Colors.amber.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ModernMiniStat(
                    label: 'Lent'.tr,
                    value: currFmt.format(controller.totalLend.value),
                    icon: Icons.call_made_rounded,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade500, Colors.indigo.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // ── Filter Chips ────────────────────────────────────────────────────
          Obx(() {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ModernFilterChip(
                    label: 'All'.tr,
                    icon: Icons.list_alt_rounded,
                    isSelected: controller.rxFilter.value == 'all',
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade500, Colors.indigo.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => controller.setFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _ModernFilterChip(
                    label: 'Expense'.tr,
                    icon: Icons.shopping_cart_rounded,
                    isSelected: controller.rxFilter.value == 'expense',
                    gradient: LinearGradient(
                      colors: [Colors.red.shade500, Colors.orange.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => controller.setFilter('expense'),
                  ),
                  const SizedBox(width: 8),
                  _ModernFilterChip(
                    label: 'Borrow'.tr,
                    icon: Icons.call_received_rounded,
                    isSelected: controller.rxFilter.value == 'borrow',
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade500, Colors.amber.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => controller.setFilter('borrow'),
                  ),
                  const SizedBox(width: 8),
                  _ModernFilterChip(
                    label: 'Lend'.tr,
                    icon: Icons.call_made_rounded,
                    isSelected: controller.rxFilter.value == 'lend',
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade500, Colors.teal.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => controller.setFilter('lend'),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // ── Transaction List ────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final list = controller.rxList;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 56,
                          color: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet'.tr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap + to record an expense or transaction'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return MyCard(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 16,
                      headingRowColor: WidgetStateProperty.all(
                        colorScheme.primary.withValues(alpha: 0.04),
                      ),
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      dividerThickness: 0.5,
                      dataRowMaxHeight: 52,
                      columns: [
                        DataColumn(label: Text('Date'.tr)),
                        DataColumn(label: Text('Type'.tr)),
                        DataColumn(label: Text('Category'.tr)),
                        DataColumn(label: Text('Person'.tr)),
                        DataColumn(label: Text('Amount'.tr)),
                        DataColumn(label: Text('Note'.tr)),
                        DataColumn(label: Text('Actions'.tr)),
                      ],
                      rows: list.map((tx) {
                        final typeColor = switch (tx.type) {
                          'expense' => Colors.red.shade600,
                          'borrow' => Colors.orange.shade700,
                          'lend' => Colors.blue.shade700,
                          _ => colorScheme.primary,
                        };
                        final typeIcon = switch (tx.type) {
                          'expense' => Icons.shopping_cart_rounded,
                          'borrow' => Icons.call_received_rounded,
                          'lend' => Icons.call_made_rounded,
                          _ => Icons.swap_horiz_rounded,
                        };
                        final displayDate = tx.createdDate != null
                            ? tx.createdDate!
                            : (tx.dateUtcMs != null
                            ? DateFormat('yyyy-MM-dd').format(
                          DateTime.fromMillisecondsSinceEpoch(tx.dateUtcMs!).toLocal(),
                        )
                            : '-');
                        return DataRow(
                          cells: [
                            DataCell(Text(displayDate, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon, size: 14, color: typeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      (tx.type ?? '').toUpperCase(),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: typeColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(Text(tx.category ?? '-')),
                            DataCell(Text(tx.personName ?? '-')),
                            DataCell(Text(
                              '₹${(tx.amount ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: typeColor),
                            )),
                            DataCell(Text(tx.note ?? '-', overflow: TextOverflow.ellipsis)),
                            DataCell(
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete'.tr,
                                onPressed: () => _confirmDelete(context, controller, tx),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            }),
          ),

          // ── Pagination Footer ──
          Obx(() => controller.rxList.isNotEmpty ? _buildPagination(controller) : const SizedBox.shrink()),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPagination(ControllerHomeExpenses controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${controller.totalCount.value} records',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.hasPrev ? controller.prevPage : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: Text('Prev'.tr),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: controller.hasNext ? controller.nextPage : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: Text('Next'.tr),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format the active date range for display
  String _rangeLabel(ControllerHomeExpenses c) {
    if (c.rxFromDate.value == null || c.rxToDate.value == null) return '';
    final fmt = DateFormat('dd MMM');
    return '${fmt.format(c.rxFromDate.value!)} – ${fmt.format(c.rxToDate.value!)}';
  }

  /// Show a confirmation dialog before deleting
  void _confirmDelete(
      BuildContext context,
      ControllerHomeExpenses controller,
      EntityFinanceTransaction tx,
      ) {
    final typeColor = switch (tx.type) {
      'expense' => Colors.red.shade600,
      'borrow' => Colors.orange.shade700,
      'lend' => Colors.blue.shade700,
      _ => Theme.of(context).colorScheme.primary,
    };

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.red,
            size: 28,
          ),
        ),
        title: Text(
          'Delete Transaction?'.tr,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete this transaction?'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: typeColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tx.category ?? tx.type ?? '-',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                  Text(
                    '₹${(tx.amount ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This action cannot be undone.'.tr,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Cancel'.tr),
          ),
          FilledButton.icon(
            onPressed: () {
              Get.back();
              controller.delete(tx.id);
            },
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: Text('Delete'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

// ── Modern Mini Stat Card ────────────────────────────────────────────────────
class _ModernMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _ModernMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modern Filter Chip ────────────────────────────────────────────────────
class _ModernFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ModernFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

