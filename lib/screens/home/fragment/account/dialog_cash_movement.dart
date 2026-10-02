import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../util/snackbar_util.dart';
import 'controller_home_account.dart';

class DialogCashMovement extends StatefulWidget {
  final bool isCashIn; // true for Cash In, false for Cash Out

  const DialogCashMovement({super.key, required this.isCashIn});

  static Future<void> show(BuildContext context, {required bool isCashIn}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DialogCashMovement(isCashIn: isCashIn),
    );
  }

  @override
  State<DialogCashMovement> createState() => _DialogCashMovementState();
}

class _DialogCashMovementState extends State<DialogCashMovement> {
  late final ControllerHomeAccount controller = Get.isRegistered<ControllerHomeAccount>()
      ? Get.find<ControllerHomeAccount>()
      : Get.put(ControllerHomeAccount());
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController reasonCtrl = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    amountCtrl.dispose();
    reasonCtrl.dispose();
    super.dispose();
  }

  void _addQuickAmount(double value) {
    final current = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
    final updated = current + value;
    amountCtrl.text = updated % 1 == 0 ? updated.toInt().toString() : updated.toStringAsFixed(2);
    amountCtrl.selection = TextSelection.fromPosition(TextPosition(offset: amountCtrl.text.length));
    setState(() {});
  }

  Future<void> _submit() async {
    if (isSubmitting) return;
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      SnackbarUtil.showError('Please enter a valid amount greater than 0');
      return;
    }

    setState(() => isSubmitting = true);
    final reason = reasonCtrl.text.trim();

    try {
      if (widget.isCashIn) {
        await controller.recordCashIn(
          amount: amount,
          reason: reason.isEmpty ? 'Cash In' : reason,
        );
      } else {
        await controller.recordCashOut(
          amount: amount,
          reason: reason.isEmpty ? 'Cash Out' : reason,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.isCashIn ? 'Cash In (Add Cash)' : 'Cash Out (Withdraw Cash)';
    final primaryColor = widget.isCashIn ? const Color(0xFF005963) : const Color(0xFFE53935);

    return Dialog(
      backgroundColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: primaryColor,
              child: Row(
                children: [
                  Icon(
                    widget.isCashIn ? Icons.add_circle_outline : Icons.arrow_circle_up_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Amount (₹)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),

                  const SizedBox(height: 10),

                  // Quick presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [100.0, 500.0, 1000.0, 2000.0, 5000.0].map((amt) {
                      return ActionChip(
                        label: Text(
                          '+₹${amt.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? colorScheme.primary : primaryColor,
                          ),
                        ),
                        backgroundColor: (isDark ? colorScheme.primary : primaryColor).withValues(alpha: 0.12),
                        side: BorderSide(color: (isDark ? colorScheme.primary : primaryColor).withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        onPressed: () => _addQuickAmount(amt),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Reason / Remarks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.isCashIn
                          ? 'e.g. Added change float / Cash from vault'
                          : 'e.g. Bank deposit / Petty expense',
                      hintStyle: TextStyle(
                        color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: isDark ? BorderSide(color: colorScheme.outlineVariant) : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? colorScheme.onSurface : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  widget.isCashIn ? 'Record Cash In' : 'Record Cash Out',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
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
