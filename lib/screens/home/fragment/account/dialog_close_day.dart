import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'controller_home_account.dart';

class DialogCloseDay extends StatefulWidget {
  const DialogCloseDay({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DialogCloseDay(),
    );
  }

  @override
  State<DialogCloseDay> createState() => _DialogCloseDayState();
}

class _DialogCloseDayState extends State<DialogCloseDay> {
  final ControllerHomeAccount controller = Get.find<ControllerHomeAccount>();
  final TextEditingController commentsCtrl = TextEditingController();

  @override
  void dispose() {
    commentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final nowFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    final title = 'Close Day - $nowFormatted';

    return Dialog(
      backgroundColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Red Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              color: const Color(0xFFEF4444),
              child: Row(
                children: [
                  const Icon(Icons.power_settings_new, color: Colors.white, size: 22),
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.5) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Closing the day will finalize all drawer cash records and automatically close any ongoing shift.',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary metrics list
                  Obx(() => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? colorScheme.outlineVariant : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildRow('Opening Cash', '₹ ${NumberFormat('#,##0.00').format(controller.rxOpeningBalance.value)}', isDark: isDark, colorScheme: colorScheme),
                            Divider(height: 16, color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : null),
                            _buildRow('Total Cash In', '₹ ${NumberFormat('#,##0.00').format(controller.rxCashInTotal.value)}', isDark: isDark, colorScheme: colorScheme),
                            Divider(height: 16, color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : null),
                            _buildRow('Total Cash Sales', '₹ ${NumberFormat('#,##0.00').format(controller.rxSalesCashTotal.value)}', isDark: isDark, colorScheme: colorScheme),
                            Divider(height: 16, color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : null),
                            _buildRow('Total Cash Out', '₹ ${NumberFormat('#,##0.00').format(controller.rxCashOutTotal.value)}', isDark: isDark, colorScheme: colorScheme),
                            Divider(height: 16, color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : null),
                            _buildRow('Total Expenses', '₹ ${NumberFormat('#,##0.00').format(controller.rxExpensesCashTotal.value)}', isDark: isDark, colorScheme: colorScheme),
                            Divider(height: 16, color: isDark ? colorScheme.outlineVariant.withValues(alpha: 0.4) : null),
                            _buildRow(
                              'Calculated Closing Drawer Cash',
                              '₹ ${NumberFormat('#,##0.00').format(controller.rxClosingBalance.value)}',
                              isBold: true,
                              textColor: colorScheme.onSurface,
                              isDark: isDark,
                              colorScheme: colorScheme,
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 16),

                  // Comments
                  Text(
                    'Comments',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentsCtrl,
                    maxLines: 2,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Comments here...',
                      hintStyle: TextStyle(
                        color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Redirect notice
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.3) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.5) : const Color(0xFFFED7AA),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Color(0xFFEA580C), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will be redirected to the login screen after closing the day.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: isDark ? BorderSide(color: colorScheme.outlineVariant) : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          onPressed: () async {
                            final comments = commentsCtrl.text.trim();
                            // Pop dialog first; controller will navigate to login
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            await controller.closeDay(
                              comments: comments.isNotEmpty ? comments : null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Close Day',
                            style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? colorScheme.onSurfaceVariant : const Color(0xFF475569),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: textColor ?? (isDark ? colorScheme.onSurface : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
