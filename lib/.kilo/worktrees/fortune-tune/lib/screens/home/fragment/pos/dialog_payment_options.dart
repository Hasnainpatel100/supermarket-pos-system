import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/home/fragment/pos/controller_payment_options.dart';

class DialogPaymentOptions extends StatelessWidget {
  final double grandTotal;

  const DialogPaymentOptions({super.key, required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ControllerPaymentOptions(grandTotal: grandTotal),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final currency = controller.serviceCurrency.rxCurrency.value;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Settle Payment",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Grand Total:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    "$currency${grandTotal.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// Payment Modes
            Text(
              "Select Payment Mode",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildModeChips(controller, "CASH", Icons.money),
                  _buildModeChips(controller, "UPI", Icons.qr_code_scanner),
                  _buildModeChips(
                    controller,
                    "NETBANKING",
                    Icons.account_balance,
                  ),
                  _buildModeChips(controller, "SPLIT", Icons.pie_chart),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// Dynamic Inputs based on View
            Obx(() {
              final mode = controller.rxSelectedMode.value;

              if (mode == "CASH") {
                return _buildGenericInputs(controller, colorScheme, currency, showUtr: false);
              } else if (mode == "UPI" || mode == "NETBANKING") {
                return _buildGenericInputs(controller, colorScheme, currency, showUtr: true);
              } else if (mode == "SPLIT") {
                return _buildSplitInputs(controller, currency, colorScheme);
              }
              return const SizedBox();
            }),

            const SizedBox(height: 32),

            /// Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("CANCEL"),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => controller.validateAndConfirm(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text("CONFIRM & SETTLE"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChips(
    ControllerPaymentOptions controller,
    String mode,
    IconData icon,
  ) {
    final isSelected = controller.rxSelectedMode.value == mode;
    return ChoiceChip(
      label: Text(mode),
      avatar: Icon(icon, color: isSelected ? Colors.white : null, size: 18),
      selected: isSelected,
      onSelected: (_) => controller.setPaymentMode(mode),
      selectedColor: Get.theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Get.theme.colorScheme.onPrimary
            : Get.theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildGenericInputs(
    ControllerPaymentOptions controller,
    ColorScheme colorScheme,
    String currency, {
    required bool showUtr,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Amount Received",
            prefixText: "$currency ",
            border: const OutlineInputBorder(),
          ),
          onChanged: controller.onAmountChanged,
        ),
        if (showUtr) ...[
          const SizedBox(height: 16),
          TextField(
            controller: controller.utrController,
            decoration: const InputDecoration(
              labelText: "UTR / Transaction Reference Number",
              hintText: "Enter 12-digit UTR or Reference ID",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt_long),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Obx(() {
          final dueAmt = controller.rxDueAmount.value;
          final returnAmt = controller.rxChangeReturned.value;
          final isDue = dueAmt > 0;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDue
                  ? Colors.orange.withValues(alpha: 0.1)
                  : colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDue
                    ? Colors.orange.withValues(alpha: 0.4)
                    : colorScheme.secondaryContainer,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDue ? "Amount Due:" : "Change to Return:",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDue
                        ? Colors.orange.shade800
                        : colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "$currency${(isDue ? dueAmt : returnAmt).toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDue
                        ? Colors.orange.shade800
                        : colorScheme.secondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSplitInputs(
    ControllerPaymentOptions controller,
    String currency,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Split Details",
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            TextButton.icon(
              onPressed: controller.addSplitEntry,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text("Add Payer"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => Column(
          children: List.generate(controller.rxSplitEntries.length, (index) {
            final entry = controller.rxSplitEntries[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(() => DropdownButtonFormField<String>(
                          value: entry.mode.value,
                          decoration: const InputDecoration(
                            labelText: "Mode",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'CASH', child: Text('CASH')),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                            DropdownMenuItem(value: 'NETBANKING', child: Text('NETBANKING')),
                          ],
                          onChanged: (val) {
                            if (val != null) entry.mode.value = val;
                          },
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: entry.amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "Amount",
                            prefixText: "$currency ",
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      if (controller.rxSplitEntries.length > 2)
                        IconButton(
                          onPressed: () => controller.removeSplitEntry(index),
                          icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
                        ),
                    ],
                  ),
                  Obx(() {
                    if (entry.mode.value == 'UPI' || entry.mode.value == 'NETBANKING') {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextField(
                          controller: entry.utrController,
                          decoration: const InputDecoration(
                            labelText: "UTR / Transaction Reference Number",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixIcon: Icon(Icons.receipt_long, size: 18),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  }),
                ],
              ),
            );
          }),
        )),
        const SizedBox(height: 8),
        Obx(() {
          final totalOut = controller.rxSplitTotal.value;
          final diff = totalOut - controller.grandTotal;
          final isMatch = diff.abs() <= 0.01;
          final isDue = diff < -0.01;
          final isOver = diff > 0.01;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMatch
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : (isDue 
                      ? Colors.orange.withValues(alpha: 0.1) 
                      : colorScheme.errorContainer.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMatch
                    ? colorScheme.secondaryContainer
                    : (isDue ? Colors.orange.withValues(alpha: 0.4) : colorScheme.errorContainer),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Input: $currency${totalOut.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMatch ? colorScheme.secondary : (isDue ? Colors.orange.shade800 : colorScheme.error),
                  ),
                ),
                if (isDue)
                  Text(
                    "Amount Due: $currency${diff.abs().toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  )
                else if (isOver)
                  Text(
                    "Overpaid: $currency${diff.abs().toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
