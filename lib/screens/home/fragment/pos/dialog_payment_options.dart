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
                return _buildCashInputs(controller, colorScheme, currency);
              } else if (mode == "UPI" || mode == "NETBANKING") {
                return _buildOnlineInputs(controller);
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

  Widget _buildCashInputs(
    ControllerPaymentOptions controller,
    ColorScheme colorScheme,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.cashAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Cash Received",
            prefixText: "$currency ",
            border: const OutlineInputBorder(),
          ),
          onChanged: controller.onCashAmountChanged,
        ),
        const SizedBox(height: 16),
        Obx(() {
          final returnAmt = controller.rxChangeReturned.value;
          final isNegative = returnAmt < 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNegative
                  ? colorScheme.errorContainer.withValues(alpha: 0.3)
                  : colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isNegative
                    ? colorScheme.errorContainer
                    : colorScheme.secondaryContainer,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isNegative ? "Amount Due:" : "Change to Return:",
                  style: TextStyle(
                    fontSize: 16,
                    color: isNegative
                        ? colorScheme.error
                        : colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "$currency${returnAmt.abs().toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isNegative
                        ? colorScheme.error
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

  Widget _buildOnlineInputs(ControllerPaymentOptions controller) {
    return TextField(
      controller: controller.utrController,
      decoration: const InputDecoration(
        labelText: "UTR / Transaction Reference Number",
        hintText: "Enter 12-digit UTR or Reference ID",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.receipt_long),
      ),
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
          children: [
            Expanded(
              child: TextField(
                controller: controller.splitCashController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Cash Amount",
                  prefixText: "$currency ",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.money),
                ),
                onChanged: controller.onSplitCashChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller.splitOnlineController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Online Amount",
                  prefixText: "$currency ",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                onChanged: controller.onSplitOnlineChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildOnlineInputs(controller), // UTR is needed for the online part
        const SizedBox(height: 16),
        Obx(() {
          final totalOut =
              controller.rxSplitCash.value + controller.rxSplitOnline.value;
          final diff = totalOut - controller.grandTotal;
          final isMatch = diff.abs() <= 0.01;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMatch
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMatch
                    ? colorScheme.secondaryContainer
                    : colorScheme.errorContainer,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Input: $currency${totalOut.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMatch ? colorScheme.secondary : colorScheme.error,
                  ),
                ),
                if (!isMatch)
                  Text(
                    "Need: $currency${diff > 0 ? '-' : '+'}${diff.abs().toStringAsFixed(2)}",
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
