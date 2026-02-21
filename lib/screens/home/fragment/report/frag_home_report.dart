import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'controller_home_report.dart';
import 'dialog_bill_detail.dart';

class FragHomeReport extends StatelessWidget {
  const FragHomeReport({super.key});

  @override
  Widget build(BuildContext context) {
    // Put controller
    final ControllerHomeReport controller = Get.put(ControllerHomeReport());
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// ── Header ──
            Text(
              "Sales Overview",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Today's Performance",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            /// ── Summary Cards ──
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => _SummaryCard(
                      title: "Today's Sales",
                      value: currencyFormat.format(controller.todaySales.value),
                      icon: Icons.attach_money_rounded,
                      color: Colors.green.shade600,
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(
                    () => _SummaryCard(
                      title: "Orders Today",
                      value: "${controller.todayOrders.value}",
                      icon: Icons.shopping_bag_rounded,
                      color: Colors.blue.shade600,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(
                    () => _SummaryCard(
                      title: "Avg. Bill Value",
                      value: currencyFormat.format(
                        controller.averageBillValue.value,
                      ),
                      icon: Icons.trending_up_rounded,
                      color: Colors.orange.shade600,
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// ── Recent Transactions Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Transactions",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: controller.loadData,
                  tooltip: "Refresh Data",
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// ── Transactions List ──
            Expanded(
              child: Obx(() {
                if (controller.rxListBill.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No transactions yet",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: controller.rxListBill.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.grey.shade100,
                    ),
                    itemBuilder: (context, index) {
                      final bill = controller.rxListBill[index];
                      final date = bill.createdAtUtcMs != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                              bill.createdAtUtcMs!,
                              isUtc: true,
                            ).toLocal()
                          : DateTime.now();

                      return ListTile(
                        onTap: () => Get.dialog(DialogBillDetail(bill: bill)),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.receipt_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          bill.customerName ?? "Walk-in Customer",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "${DateFormat('hh:mm a').format(date)} • Bill #${bill.billNo}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(bill.grandTotal ?? 0),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              bill.status ?? "PAID",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: (bill.status == "CANCELLED")
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
