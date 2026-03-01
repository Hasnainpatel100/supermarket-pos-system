import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'controller_home_report.dart';
import 'dialog_bill_detail.dart';

class FragHomeReport extends StatelessWidget {
  const FragHomeReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeReport controller =
        Get.isRegistered<ControllerHomeReport>()
        ? Get.find<ControllerHomeReport>()
        : Get.put(ControllerHomeReport());
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // ── Top Bar with Title + Date Range + Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bills Report",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.grey.shade800,
                          ),
                    ),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.indigo.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 10,
                              color: Colors.indigo.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              controller.formatDateRange(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: controller.loadData,
                    tooltip: "Refresh",
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Colors.indigo.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Search & Filter ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: controller.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: "Search by customer name or phone...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Colors.indigo.shade400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() {
                  final selected = controller.rxDateFilter.value;
                  final isCustom = selected == DateFilterType.custom;
                  return Tooltip(
                    message: "Filter by Date Range",
                    child: InkWell(
                      onTap: () => _pickDateRange(context, controller),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isCustom
                              ? LinearGradient(
                                  colors: [
                                    Colors.indigo.shade400,
                                    Colors.purple.shade400,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isCustom ? null : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isCustom
                              ? null
                              : Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: isCustom
                                  ? Colors.indigo.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.date_range_rounded,
                          size: 24,
                          color: isCustom
                              ? Colors.white
                              : Colors.indigo.shade400,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 16),

          // ── Transactions Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  "Transactions",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade400,
                          Colors.purple.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${controller.rxListBill.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Bill List ──
          Expanded(
            child: Obx(() {
              if (controller.rxListBill.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo.shade100,
                              Colors.purple.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.indigo.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No transactions found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Try adjusting the date filter",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount:
                      controller.rxListBill.length +
                      (controller.rxHasMore.value ? 1 : 0),
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    // "Load More" button at the end
                    if (index >= controller.rxListBill.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Obx(
                            () => controller.rxIsLoadingMore.value
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : TextButton.icon(
                                    onPressed: controller.loadMore,
                                    icon: const Icon(Icons.expand_more_rounded),
                                    label: const Text('Load More'),
                                  ),
                          ),
                        ),
                      );
                    }

                    final bill = controller.rxListBill[index];
                    final displayDate = bill.billDate ?? '-';
                    final isCancelled = bill.status == "CANCELLED";

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => Get.dialog(DialogBillDetail(bill: bill)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCancelled
                                  ? [Colors.red.shade400, Colors.red.shade700]
                                  : [
                                      Colors.indigo.shade400,
                                      Colors.purple.shade400,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isCancelled ? Colors.red : Colors.indigo)
                                        .withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isCancelled
                                ? Icons.cancel_outlined
                                : Icons.receipt_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          bill.customerName ?? "Walk-in Customer",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isCancelled
                                ? Colors.grey
                                : Colors.grey.shade800,
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Colors.indigo.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              displayDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.indigo.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                '#${bill.billNo ?? "-"}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(bill.grandTotal ?? 0),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isCancelled
                                    ? Colors.grey
                                    : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCancelled
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                bill.status ?? "PAID",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCancelled
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _pickDateRange(
    BuildContext context,
    ControllerHomeReport controller,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: controller.rxStartDate.value,
        end: controller.rxEndDate.value,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme.copyWith(
              primary: colorScheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setCustomRange(picked.start, picked.end);
    }
  }
}
