import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/entity_item.dart';
import '../../../../util/snackbar_util.dart';
import 'controller_home_item.dart';

/// Dialog for adjusting stock (increment / decrement) of an EntityItem.
/// Uses GetX stateless pattern.
class DialogAdjustStock extends StatelessWidget {
  final EntityItem entityItem;

  const DialogAdjustStock({super.key, required this.entityItem});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeItem controller = Get.find();
    final qtyController = TextEditingController(text: '1');
    final RxBool isIncrement = true.obs;
    final RxString selectedReason = 'Received'.obs;

    final reasons = [
      'Received',
      'Damaged',
      'Returned',
      'Count Correction',
      'Expired',
      'Other',
    ];

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ── Header ──
            Text('Adjust Stock', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              entityItem.name ?? 'Unnamed Item',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Current Stock: ${entityItem.totalQty ?? 0}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const Divider(height: 24),

            /// ── Increment / Decrement Toggle ──
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _toggleButton(
                      context: context,
                      icon: Icons.add_circle_outline,
                      label: 'Increment',
                      isSelected: isIncrement.value,
                      color: Colors.green,
                      onTap: () => isIncrement.value = true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _toggleButton(
                      context: context,
                      icon: Icons.remove_circle_outline,
                      label: 'Decrement',
                      isSelected: !isIncrement.value,
                      color: Colors.red,
                      onTap: () => isIncrement.value = false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// ── Quantity Input with ± Buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(qtyController.text) ?? 1;
                    if (current > 1) {
                      qtyController.text = (current - 1).toString();
                    }
                  },
                  icon: const Icon(Icons.remove, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: qtyController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(qtyController.text) ?? 1;
                    qtyController.text = (current + 1).toString();
                  },
                  icon: const Icon(Icons.add, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// ── Reason Dropdown ──
            Obx(
              () => DropdownButtonFormField<String>(
                value: selectedReason.value,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedReason.value = val;
                },
              ),
            ),
            const SizedBox(height: 20),

            /// ── Action Buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text);
                    if (qty == null || qty <= 0) {
                      SnackbarUtil.showError('Enter a valid quantity');
                      return;
                    }

                    final delta = isIncrement.value ? qty : -qty;
                    final success = controller.adjustStock(entityItem, delta);

                    if (success) {
                      SnackbarUtil.showSuccess(
                        '${isIncrement.value ? "Added" : "Removed"} $qty '
                        'unit(s) — ${selectedReason.value}',
                      );
                      Get.back();
                    } else {
                      SnackbarUtil.showError('Stock cannot go below 0');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
