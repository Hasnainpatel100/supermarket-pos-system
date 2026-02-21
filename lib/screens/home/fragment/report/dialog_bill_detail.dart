import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';

class DialogBillDetail extends StatelessWidget {
  final EntityBill bill;

  const DialogBillDetail({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    final date = bill.createdAtUtcMs != null
        ? DateTime.fromMillisecondsSinceEpoch(
            bill.createdAtUtcMs!,
            isUtc: true,
          ).toLocal()
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            /// Header
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Bill #${bill.billNo ?? "N/A"}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),

            /// Customer Info
            _buildInfoRow("Customer", bill.customerName ?? "Walk-in"),
            _buildInfoRow("Date", date != null ? dateFormat.format(date) : "-"),
            _buildInfoRow("Status", bill.status ?? "-"),
            _buildInfoRow("Payment", bill.paymentMode ?? "-"),

            const SizedBox(height: 16),
            const Divider(),

            /// Items List
            Expanded(
              child: ListView.separated(
                itemCount: bill.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = bill.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName ?? "Unknown Item",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Qty: ${item.qty} x ${currencyFormat.format(item.price ?? 0)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            currencyFormat.format(item.total ?? 0),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            /// Totals
            _buildTotalRow("Subtotal", bill.totalAmount ?? 0, currencyFormat),
            _buildTotalRow("Tax", bill.tax ?? 0, currencyFormat),
            _buildTotalRow(
              "Discount",
              bill.discount ?? 0,
              currencyFormat,
              isNegative: true,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  currencyFormat.format(bill.grandTotal ?? 0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double value,
    NumberFormat format, {
    bool isNegative = false,
  }) {
    if (value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "${isNegative ? '-' : ''}${format.format(value)}",
            style: TextStyle(color: isNegative ? Colors.red : null),
          ),
        ],
      ),
    );
  }
}
