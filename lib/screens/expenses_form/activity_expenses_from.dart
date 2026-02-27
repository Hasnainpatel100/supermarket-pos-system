import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller_expenses_from.dart';

class ActivityExpensesFrom extends StatelessWidget {
  const ActivityExpensesFrom({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerExpensesFrom());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_card_rounded, size: 22),
            SizedBox(width: 10),
            Text(
              'New Transaction',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: controller.formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Transaction Type ──────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.category_rounded,
                  color: colorScheme.primary,
                  title: 'Transaction Type',
                ),
                const SizedBox(height: 12),
                Obx(() {
                  return Row(
                    children: [
                      _TypeButton(
                        label: 'Expense',
                        icon: Icons.shopping_cart_rounded,
                        color: Colors.red.shade600,
                        isSelected:
                            controller.rxType.value == TransactionType.expense,
                        onTap: () =>
                            controller.rxType.value = TransactionType.expense,
                      ),
                      const SizedBox(width: 10),
                      _TypeButton(
                        label: 'Borrow',
                        icon: Icons.call_received_rounded,
                        color: Colors.orange.shade700,
                        isSelected:
                            controller.rxType.value == TransactionType.borrow,
                        onTap: () =>
                            controller.rxType.value = TransactionType.borrow,
                      ),
                      const SizedBox(width: 10),
                      _TypeButton(
                        label: 'Lend',
                        icon: Icons.call_made_rounded,
                        color: Colors.blue.shade700,
                        isSelected:
                            controller.rxType.value == TransactionType.lend,
                        onTap: () =>
                            controller.rxType.value = TransactionType.lend,
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 24),

                // ── Debit / Credit Toggle ──────────────────────────────────────
                Obx(() {
                  final isDebit = controller.rxIsDebit.value;
                  return Container(
                    decoration: BoxDecoration(
                      color: (isDebit ? Colors.red : Colors.green).withValues(
                        alpha: 0.06,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (isDebit ? Colors.red : Colors.green).withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDebit ? Colors.red : Colors.green)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDebit
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: isDebit
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        isDebit ? 'Debit (Money Out)' : 'Credit (Money In)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDebit
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      subtitle: Text(
                        isDebit
                            ? 'Money is going out of your pocket'
                            : 'Money is coming into your pocket',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      value: isDebit,
                      activeThumbColor: Colors.red.shade600,
                      inactiveThumbColor: Colors.green.shade600,
                      inactiveTrackColor: Colors.green.withValues(alpha: 0.3),
                      onChanged: (val) => controller.rxIsDebit.value = val,
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // ── Category ──────────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.label_rounded,
                  color: Colors.purple.shade600,
                  title: 'Category',
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final cats = controller.currentCategories;
                  // If current category is not in new list, reset
                  if (!cats.contains(controller.rxCategory.value)) {
                    controller.rxCategory.value = cats.first;
                  }
                  return DropdownButtonFormField<String>(
                    value: controller.rxCategory.value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.tag_rounded),
                      labelText: 'Category',
                    ),
                    items: cats
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) controller.rxCategory.value = val;
                    },
                  );
                }),

                const SizedBox(height: 20),

                // ── Amount ────────────────────────────────────────────────────
                TextFormField(
                  controller: controller.amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount *',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Person Name ───────────────────────────────────────────────
                Obx(() {
                  final type = controller.rxType.value;
                  final label = type == TransactionType.expense
                      ? 'Vendor / Person (optional)'
                      : type == TransactionType.borrow
                      ? 'Borrowed From *'
                      : 'Lent To *';
                  return TextFormField(
                    controller: controller.personNameController,
                    decoration: InputDecoration(
                      labelText: label,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (type != TransactionType.expense &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Person name is required for ${controller.typeName}';
                      }
                      return null;
                    },
                  );
                }),

                const SizedBox(height: 20),

                // ── Date Picker ───────────────────────────────────────────────
                Obx(() {
                  return InkWell(
                    onTap: () => controller.pickDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        controller.formattedDate,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // ── Note ──────────────────────────────────────────────────────
                TextFormField(
                  controller: controller.noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes_rounded),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Action Buttons ────────────────────────────────────────────
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        final type = controller.rxType.value;
                        final (label, color) = switch (type) {
                          TransactionType.expense => (
                            'Save Expense',
                            Colors.red.shade600,
                          ),
                          TransactionType.borrow => (
                            'Save Borrow',
                            Colors.orange.shade700,
                          ),
                          TransactionType.lend => (
                            'Save Lend',
                            Colors.blue.shade700,
                          ),
                        };
                        return FilledButton.icon(
                          onPressed: controller.saveTransaction,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(label),
                          style: FilledButton.styleFrom(
                            backgroundColor: color,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Type Selection Button ─────────────────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
      ],
    );
  }
}
