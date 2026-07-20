import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widget/my_card.dart';
import 'package:intl/intl.dart';

import 'controller_home_bills.dart';
import 'dialog_bill_detail.dart';

class FragHomeBills extends StatelessWidget {
  const FragHomeBills({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeBills controller =
        Get.isRegistered<ControllerHomeBills>()
        ? Get.find<ControllerHomeBills>()
        : Get.put(ControllerHomeBills());
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
                      'bills_report'.tr,
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
                    tooltip: 'refresh'.tr,
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
                        hintText: 'search_customer_phone_hint'.tr,
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
                    message: 'filter_by_date_range'.tr,
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
                  'transactions_label'.tr,
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
                return _buildEmpty();
              }

              return MyCard(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 16,
                      headingRowColor: WidgetStateProperty.all(
                        colorScheme.primary.withValues(alpha: 0.04),
                      ),
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      dividerThickness: 0.5,
                      dataRowMaxHeight: 52,
                      columns: [
                        _col(context, 'date_and_time_col'.tr, Icons.calendar_today_rounded, Colors.indigo),
                        _col(context, 'bill_no_col'.tr, Icons.receipt_rounded, Colors.blue),
                        _col(context, 'customer_col'.tr, Icons.person_outline_rounded, Colors.green),
                        _col(context, 'payment_col'.tr, Icons.payment_rounded, Colors.teal),
                        _col(context, 'total_col'.tr, Icons.attach_money_rounded, Colors.orange),
                        _col(context, 'due_col'.tr, Icons.pending_actions_rounded, Colors.red),
                        _col(context, 'status_col'.tr, Icons.toggle_on_rounded, Colors.purple),
                        _col(context, 'actions_col'.tr, Icons.settings_rounded, Colors.grey),
                      ],
                      rows: controller.rxListBill.map((b) => _buildRow(context, b, controller, colorScheme, currencyFormat)).toList(),
                    ),
                  ),
                ),
              );
            }),
          ),

          // ── Pagination Footer ──
          Obx(() => controller.rxListBill.isNotEmpty ? _buildPagination(controller) : const SizedBox.shrink()),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPagination(ControllerHomeBills controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'total_bills_count'.trParams({'count': '${controller.totalCount.value}'}),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.hasPrev ? controller.prevPage : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: Text('prev'.tr),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('page_number'.trParams({'number': '${controller.currentPage.value + 1}'}),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: controller.hasNext ? controller.nextPage : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: Text('next'.tr),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade100, Colors.purple.shade100],
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
            child: Icon(Icons.receipt_long_outlined, size: 64, color: Colors.indigo.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'no_transactions_found'.tr,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            'try_adjust_date_filter'.tr,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  DataColumn _col(BuildContext context, String label, IconData icon, Color color) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color.withOpacity(0.8)),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    var bill,
    ControllerHomeBills controller,
    ColorScheme colorScheme,
    NumberFormat currencyFormat,
  ) {
    final isCancelled = bill.status == "CANCELLED";
    final isDue = bill.status == "DUE";

    String formattedDateTime = bill.billDate ?? '-';
    if (bill.createdAtUtcMs != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!, isUtc: true);
      formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((_) {
        if (isCancelled) return Colors.grey.withValues(alpha: 0.05);
        return null;
      }),
      cells: [
        // Date & Time
        DataCell(Text(
          formattedDateTime,
          style: TextStyle(fontSize: 13, color: Colors.indigo.shade600, fontWeight: FontWeight.w500),
        )),

        // Bill No
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '#${bill.billNo ?? "-"}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
        ),

        // Customer
        DataCell(Text(
          bill.customerName ?? 'walk_in_customer'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isCancelled ? Colors.grey : Colors.grey.shade800,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
          ),
        )),

        // Payment
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Text(
              bill.paymentMode ?? '-',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.teal.shade700),
            ),
          ),
        ),

        // Total
        DataCell(Text(
          currencyFormat.format(bill.grandTotal ?? 0),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isCancelled ? Colors.grey : Colors.grey.shade800,
          ),
        )),

        // Due Amount
        DataCell(Text(
          isDue ? currencyFormat.format(bill.dueAmount ?? 0) : '-',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDue ? Colors.red.shade700 : Colors.grey,
          ),
        )),

        // Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isCancelled
                  ? Colors.grey.withOpacity(0.1)
                  : (isDue ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCancelled
                    ? Colors.grey.withOpacity(0.3)
                    : (isDue ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
              ),
            ),
            child: Text(
              bill.status ?? "PAID",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isCancelled
                    ? Colors.grey.shade700
                    : (isDue ? Colors.orange.shade800 : Colors.green.shade700),
              ),
            ),
          ),
        ),

        // Actions
        DataCell(
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
            tooltip: 'actions'.tr,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'preview') {
                Get.dialog(DialogBillDetail(bill: bill));
              } else if (value == 'settle_due') {
                controller.settleDuePayment(bill);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'preview',
                child: Row(children: [
                  Icon(Icons.visibility_outlined, size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Text('preview_bill'.tr),
                ]),
              ),
              if (isDue)
                PopupMenuItem(
                  value: 'settle_due',
                  child: Row(children: [
                    Icon(Icons.payment_rounded, size: 20, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Text('settle_due'.tr),
                  ]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickDateRange(
    BuildContext context,
    ControllerHomeBills controller,
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
