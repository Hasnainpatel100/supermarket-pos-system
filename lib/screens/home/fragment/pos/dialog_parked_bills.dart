import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../service/service_currency.dart';
import 'controller_home_pos.dart';

/// Modal dialog displaying all currently parked / held customer bills.
/// Allows cashiers to quickly restore a parked customer cart back to active billing.
class DialogParkedBills extends StatelessWidget {
  final ControllerHomePos posController;

  const DialogParkedBills({super.key, required this.posController});

  static void show(BuildContext context, ControllerHomePos posController) {
    Get.dialog(
      DialogParkedBills(posController: posController),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyService = Get.find<ServiceCurrency>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 680,
        height: 600,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 36,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause_circle_filled_rounded,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parked / Held Bills',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Obx(() => Text(
                              '${posController.rxParkedBills.length} suspended order(s) waiting to be recalled',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.65),
                              ),
                            )),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // ── Body / List of Parked Bills ──
            Expanded(
              child: Obx(() {
                final parked = posController.rxParkedBills;

                if (parked.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: cs.outlineVariant,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Parked Bills',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Press F5 or click "Hold Bill" in the POS to suspend an active cart.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: parked.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = parked[index];
                    final custName = item.customerName?.isNotEmpty == true
                        ? item.customerName!
                        : (item.customer?.name ?? 'Walk-in Customer');

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.ticketId,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Customer & Items Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      custName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.timeAgo,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.totalItemCount} items: ${item.items.map((e) => "${e.qty}x ${e.itemName}").take(3).join(', ')}${item.items.length > 3 ? "..." : ""}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.65),
                                  ),
                                ),
                                if (item.note?.isNotEmpty == true) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Note: ${item.note}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Total Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${currencyService.rxCurrency.value} ${item.grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              Text(
                                item.parkedAtTime,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red, size: 20),
                                tooltip: 'Discard Hold',
                                onPressed: () {
                                  posController.discardParkedBill(index);
                                },
                              ),
                              const SizedBox(width: 4),
                              FilledButton.icon(
                                onPressed: () {
                                  Get.back();
                                  posController.recallParkedBill(index);
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                label: const Text('Recall'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Press F6 from anywhere on the POS screen to open this dialog.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
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
