import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../model/entity_finance_transaction.dart';
import '../../../../service/service_finance.dart';
import '../../../../service/service_object_box.dart';
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
      floatingActionButton: _buildFab(context, controller),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'Finance',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: controller.loadData,
                  icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Summary Row ────────────────────────────────────────────────────
          Obx(() {
            final currFmt = NumberFormat.compactCurrency(
              locale: 'en_IN',
              symbol: '₹',
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _MiniStat(
                    label: 'Expenses',
                    value: currFmt.format(controller.totalExpense.value),
                    icon: Icons.shopping_cart_rounded,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: 'Borrowed',
                    value: currFmt.format(controller.totalBorrow.value),
                    icon: Icons.call_received_rounded,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: 'Lent',
                    value: currFmt.format(controller.totalLend.value),
                    icon: Icons.call_made_rounded,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // ── Filter Chips ───────────────────────────────────────────────────
          Obx(() {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    icon: Icons.list_alt_rounded,
                    isSelected: controller.rxFilter.value == 'all',
                    color: colorScheme.primary,
                    onTap: () => controller.setFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Expense',
                    icon: Icons.shopping_cart_rounded,
                    isSelected: controller.rxFilter.value == 'expense',
                    color: Colors.red.shade600,
                    onTap: () => controller.setFilter('expense'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Borrow',
                    icon: Icons.call_received_rounded,
                    isSelected: controller.rxFilter.value == 'borrow',
                    color: Colors.orange.shade700,
                    onTap: () => controller.setFilter('borrow'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Lend',
                    icon: Icons.call_made_rounded,
                    isSelected: controller.rxFilter.value == 'lend',
                    color: Colors.blue.shade700,
                    onTap: () => controller.setFilter('lend'),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // ── Transaction List ───────────────────────────────────────────────
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
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap + to record an expense or transaction',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (context, i) => _TransactionTile(
                    tx: list[i],
                    onDelete: () {
                      controller.delete(list[i].id);
                    },
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 80), // FAB clearance
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context, ControllerHomeExpenses controller) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Get.to(() => const ActivityExpensesFrom());
        if (result == true) controller.loadData();
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text('New Transaction'),
      elevation: 4,
    );
  }
}

// ── Mini Stat Card ─────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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

// ── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction List Tile ─────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final EntityFinanceTransaction tx;
  final VoidCallback onDelete;

  const _TransactionTile({required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDebit = tx.isDebit ?? true;
    final (typeColor, typeIcon) = switch (tx.type) {
      'expense' => (Colors.red.shade600, Icons.shopping_cart_rounded),
      'borrow' => (Colors.orange.shade700, Icons.call_received_rounded),
      'lend' => (Colors.blue.shade700, Icons.call_made_rounded),
      _ => (colorScheme.primary, Icons.swap_horiz_rounded),
    };

    final displayDate = tx.dateUtcMs != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.fromMillisecondsSinceEpoch(tx.dateUtcMs!).toLocal())
        : '-';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(typeIcon, color: typeColor, size: 20),
      ),
      title: Text(
        tx.category ?? tx.type ?? '-',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Row(
        children: [
          if (tx.personName != null) ...[
            Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 3),
            Text(
              tx.personName!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.calendar_today_outlined,
            size: 11,
            color: Colors.grey.shade400,
          ),
          const SizedBox(width: 3),
          Text(
            displayDate,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${(tx.amount ?? 0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDebit ? Colors.red.shade600 : Colors.green.shade600,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: (isDebit ? Colors.red : Colors.green).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDebit ? 'DEBIT' : 'CREDIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isDebit
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.red.shade400,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
