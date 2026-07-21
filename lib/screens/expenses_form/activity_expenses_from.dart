import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widget/app_dialog_components.dart';
import 'controller_expenses_from.dart';

class ActivityExpensesFrom extends StatelessWidget {
  const ActivityExpensesFrom({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerExpensesFrom());
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final type = controller.rxType.value;
      final (label, color) = switch (type) {
        TransactionType.expense => ('save_expense'.tr, Colors.red.shade600),
        TransactionType.borrow => ('save_borrow'.tr, Colors.orange.shade700),
        TransactionType.lend => ('save_lend'.tr, Colors.blue.shade700),
      };

      return AppDialog(
        maxWidth: 700,
        maxHeight: 700,
        header: DialogHeader(
          title: 'new_transaction'.tr,
          icon: Icons.add_card_rounded,
        ),
        body: DialogBody(
          child: Form(
            key: controller.formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 550;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Transaction Type ────────────────────────────────
                    FormSection(
                      icon: Icons.category_rounded,
                      color: colorScheme.primary,
                      title: 'transaction_type'.tr,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _TypeButton(
                          label: 'expense'.tr,
                          icon: Icons.shopping_cart_rounded,
                          color: Colors.red.shade600,
                          isSelected: controller.rxType.value == TransactionType.expense,
                          onTap: () => controller.rxType.value = TransactionType.expense,
                        ),
                        const SizedBox(width: 10),
                        _TypeButton(
                          label: 'borrow'.tr,
                          icon: Icons.call_received_rounded,
                          color: Colors.orange.shade700,
                          isSelected: controller.rxType.value == TransactionType.borrow,
                          onTap: () => controller.rxType.value = TransactionType.borrow,
                        ),
                        const SizedBox(width: 10),
                        _TypeButton(
                          label: 'lend'.tr,
                          icon: Icons.call_made_rounded,
                          color: Colors.blue.shade700,
                          isSelected: controller.rxType.value == TransactionType.lend,
                          onTap: () => controller.rxType.value = TransactionType.lend,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Debit / Credit Toggle ───────────────────────────
                    Obx(() {
                      final isDebit = controller.rxIsDebit.value;
                      final activeColor = isDebit ? Colors.red : Colors.green;
                      return Container(
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: activeColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: activeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              color: isDebit ? Colors.red.shade600 : Colors.green.shade600,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            isDebit ? 'debit_money_out'.tr : 'credit_money_in'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                          ),
                          subtitle: Text(
                            isDebit ? 'money_going_out'.tr : 'money_coming_in'.tr,
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

                    const SizedBox(height: 20),

                    // ── Category ────────────────────────────────────────
                    FormSection(
                      icon: Icons.label_rounded,
                      color: Colors.purple.shade600,
                      title: 'category'.tr,
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final cats = controller.currentCategories;
                      if (!cats.contains(controller.rxCategory.value)) {
                        controller.rxCategory.value = cats.first;
                      }
                      return AppDropdown<String>(
                        value: controller.rxCategory.value,
                        label: 'category'.tr,
                        prefixIcon: Icons.tag_rounded,
                        items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.rxCategory.value = val;
                          }
                        },
                      );
                    }),

                    const SizedBox(height: 20),

                    // ── Amount & Date ───────────────────────────────────
                    FormSection(
                      icon: Icons.attach_money_rounded,
                      color: Colors.teal.shade600,
                      title: 'amount'.tr,
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final dateController = TextEditingController(text: controller.formattedDate);
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppNumberField(
                                controller: controller.amountController,
                                label: 'amount'.tr,
                                required: true,
                                prefixIcon: Icons.currency_rupee_rounded,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppDatePicker(
                                controller: dateController,
                                label: 'date'.tr,
                                onTap: () => controller.pickDate(context),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppNumberField(
                              controller: controller.amountController,
                              label: 'amount'.tr,
                              required: true,
                              prefixIcon: Icons.currency_rupee_rounded,
                            ),
                            const SizedBox(height: 16),
                            AppDatePicker(
                              controller: dateController,
                              label: 'date'.tr,
                              onTap: () => controller.pickDate(context),
                            ),
                          ],
                        );
                      }
                    }),

                    const SizedBox(height: 20),

                    // ── Person Name ─────────────────────────────────────
                    Obx(() {
                      final req = controller.rxType.value != TransactionType.expense;
                      final labelText = controller.rxType.value == TransactionType.expense
                          ? 'vendor_person_optional'.tr
                          : controller.rxType.value == TransactionType.borrow
                              ? 'borrowed_from'.tr
                              : 'lent_to'.tr;

                      return AppTextField(
                        controller: controller.personNameController,
                        label: labelText,
                        required: req,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) {
                          if (req && (v == null || v.trim().isEmpty)) {
                            return 'required'.tr;
                          }
                          return null;
                        },
                      );
                    }),

                    const SizedBox(height: 16),

                    // ── Note ────────────────────────────────────────────
                    AppTextField(
                      controller: controller.noteController,
                      label: 'note_optional'.tr,
                      maxLines: 2,
                      prefixIcon: Icons.notes_rounded,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        footer: DialogFooter(
          onCancel: () => Get.back(),
          onSave: controller.saveTransaction,
          saveLabel: label,
          saveButtonColor: color,
        ),
      );
    });
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
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              const SizedBox(height: 4),
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