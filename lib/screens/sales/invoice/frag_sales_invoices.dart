import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_bill.dart';
import '../../../service/service_currency.dart';
import '../../../widget/generic_empty_state.dart';
import '../../../widget/gradient_action_button.dart';
import '../../../widget/gradient_app_bar_title.dart';
import '../../../widget/my_card.dart';
import '../../../widget/search_app_bar_field.dart';
import '../../home/fragment/bills/dialog_bill_detail.dart';
import '../returns/activity_create_sales_return.dart';
import 'controller_sales_invoices.dart';

class FragSalesInvoices extends StatefulWidget {
  const FragSalesInvoices({super.key});

  @override
  State<FragSalesInvoices> createState() => _FragSalesInvoicesState();
}

class _FragSalesInvoicesState extends State<FragSalesInvoices> {
  late final ControllerSalesInvoices controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ControllerSalesInvoices>()
        ? Get.find<ControllerSalesInvoices>()
        : Get.put(ControllerSalesInvoices());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currencySymbol = Get.isRegistered<ServiceCurrency>()
        ? Get.find<ServiceCurrency>().rxCurrency.value
        : '₹';
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: GradientAppBarTitle(
          icon: Icons.receipt_long_rounded,
          title: 'Sales Invoices'.tr,
          subtitle: 'Track and manage customer billing & invoices'.tr,
          gradientColors: isDark
              ? [Colors.teal.shade300, Colors.teal.shade600]
              : [Colors.teal.shade500, Colors.teal.shade800],
        ),
        actions: [
          // Date Filter Dropdown
          Obx(
            () => PopupMenuButton<InvoiceDateRange>(
              onSelected: controller.setDateRange,
              tooltip: 'Filter by date'.tr,
              itemBuilder: (ctx) => InvoiceDateRange.values
                  .map(
                    (r) => PopupMenuItem(
                      value: r,
                      child: Text(r.label),
                    ),
                  )
                  .toList(),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 15, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      controller.rxDateRange.value.label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Refresh Invoices Button (Replaces non-functional Bulk Actions)
          IconButton(
            tooltip: 'Refresh Invoices'.tr,
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
              ),
            ),
            icon: Icon(Icons.refresh_rounded, size: 18, color: colorScheme.primary),
            onPressed: () {
              controller.loadInvoices();
              Get.snackbar(
                'Invoices Refreshed'.tr,
                'Latest bills and invoices loaded'.tr,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
                margin: const EdgeInsets.all(12),
              );
            },
          ),
          const SizedBox(width: 8),

          // Create Sales Invoice Button
          GradientActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Create Invoice'.tr,
            gradientColors: isDark
                ? [Colors.teal.shade500, Colors.teal.shade800]
                : [Colors.teal.shade600, Colors.teal.shade900],
            onTap: () => controller.openCreateInvoice(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Obx(
            () => SearchAppBarField(
              controller: controller.searchController,
              hint: 'Search by Invoice No, Customer, Phone...'.tr,
              onChanged: controller.updateSearch,
              onClear: controller.clearSearch,
              hasQuery: controller.rxSearchQuery.isNotEmpty,
            ),
          ),
        ),
      ),

      body: Obx(() {
        if (controller.rxLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // ── KPI Summary Cards ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total Sales',
                      value: currencyFmt.format(controller.rxTotalSales.value),
                      icon: Icons.trending_up_rounded,
                      gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Paid',
                      value: currencyFmt.format(controller.rxTotalPaid.value),
                      icon: Icons.check_circle_rounded,
                      gradientColors: [Colors.teal.shade500, Colors.green.shade500],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Unpaid',
                      value: currencyFmt.format(controller.rxTotalUnpaid.value),
                      icon: Icons.pending_actions_rounded,
                      gradientColors: [Colors.orange.shade600, Colors.red.shade500],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: controller.rxCancelledCount.value > 0
                          ? 'Cancelled (${controller.rxCancelledCount.value})'
                          : 'Cancelled',
                      value: currencyFmt.format(controller.rxCancelledAmount.value),
                      icon: Icons.cancel_rounded,
                      gradientColors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
                    ),
                  ),
                ],
              ),
            ),

            // ── Table or Empty State ──
            Expanded(
              child: controller.rxInvoices.isEmpty
                  ? GenericEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Sales Invoices Found'.tr,
                      subtitle: 'Create your first sales invoice using the button above.'.tr,
                      gradientColors: [Colors.teal.shade300, Colors.teal.shade600],
                    )
                  : RepaintBoundary(
                      child: MyCard(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                                DataColumn(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('date'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.tag_rounded, size: 14, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Invoice No'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.person_rounded, size: 14, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Customer / Party'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.schedule_rounded, size: 14, color: isDark ? Colors.amber.shade300 : Colors.amber.shade800),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Due In'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  numeric: true,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.payments_rounded, size: 14, color: isDark ? Colors.green.shade300 : Colors.green.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('amount'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.toggle_on_rounded, size: 14, color: isDark ? Colors.purple.shade300 : Colors.purple.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('status'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.settings_rounded, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('actions'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                              rows: controller.pagedInvoices.map((EntityBill bill) {
                                final isCancelled = bill.status == 'CANCELLED';

                                return DataRow(
                                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                                    if (isCancelled) {
                                      return Colors.grey.withValues(alpha: isDark ? 0.08 : 0.04);
                                    }
                                    return null;
                                  }),
                                  cells: [
                                    // Date
                                    DataCell(Text(
                                      bill.billDate ?? '—',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isCancelled ? Colors.grey : colorScheme.onSurface,
                                      ),
                                    )),

                                    // Invoice Number
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          bill.billNo ?? '${bill.id}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isCancelled ? Colors.grey : colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: (bill.billNo?.startsWith('POS') == true || bill.invoicePrefix == null)
                                                    ? Colors.teal.withValues(alpha: 0.12)
                                                    : Colors.blue.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                (bill.billNo?.startsWith('POS') == true || bill.invoicePrefix == null) ? 'POS' : 'INV',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: (bill.billNo?.startsWith('POS') == true || bill.invoicePrefix == null)
                                                      ? (isDark ? Colors.teal.shade300 : Colors.teal.shade700)
                                                      : (isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                                                ),
                                              ),
                                            ),
                                            if (bill.paymentMode?.isNotEmpty == true) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  bill.paymentMode!.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    )),

                                    // Customer
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_outline_rounded, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                        const SizedBox(width: 6),
                                        Text(
                                          bill.customerName?.isNotEmpty == true ? bill.customerName! : 'Cash Sale'.tr,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isCancelled ? Colors.grey : colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    )),

                                    // Due In
                                    DataCell(_buildDueIn(context, bill)),

                                    // Amount
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          currencyFmt.format(bill.grandTotal ?? 0.0),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isCancelled ? Colors.grey : colorScheme.onSurface,
                                          ),
                                        ),
                                        if ((bill.dueAmount ?? 0.0) > 0 && !isCancelled)
                                          Text(
                                            '(${currencyFmt.format(bill.dueAmount)} due)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                            ),
                                          ),
                                      ],
                                    )),

                                    // Status Badge
                                    DataCell(_buildStatusBadge(context, bill)),

                                    // Actions Popup
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant),
                                        tooltip: 'Actions'.tr,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (val) {
                                          switch (val) {
                                            case 'view':
                                              controller.openDocumentView(bill);
                                              break;
                                            case 'print_thermal':
                                              Get.dialog(
                                                DialogBillDetail(bill: bill),
                                                barrierDismissible: true,
                                              );
                                              break;
                                            case 'edit':
                                              controller.openCreateInvoice(editBill: bill);
                                              break;
                                            case 'duplicate':
                                              controller.duplicateInvoice(bill);
                                              break;
                                            case 'return':
                                              Get.dialog(
                                                ActivityCreateSalesReturn(linkedBill: bill),
                                                barrierDismissible: false,
                                              ).then((_) => controller.loadInvoices());
                                              break;
                                            case 'cancel':
                                              controller.cancelInvoice(bill);
                                              break;
                                            case 'delete':
                                              controller.deleteInvoice(bill);
                                              break;
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(Icons.visibility_outlined, size: 18, color: colorScheme.primary),
                                                const SizedBox(width: 10),
                                                Text('View Tax Invoice'.tr),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'print_thermal',
                                            child: Row(
                                              children: [
                                                Icon(Icons.receipt_long_outlined, size: 18, color: isDark ? Colors.teal.shade300 : Colors.teal.shade600),
                                                const SizedBox(width: 10),
                                                Text('Print Thermal Bill'.tr),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined, size: 18, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600),
                                                const SizedBox(width: 10),
                                                Text('edit'.tr),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'duplicate',
                                            child: Row(
                                              children: [
                                                Icon(Icons.copy_outlined, size: 18, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600),
                                                const SizedBox(width: 10),
                                                Text('Duplicate'.tr),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'return',
                                            child: Row(
                                              children: [
                                                Icon(Icons.assignment_return_outlined, size: 18, color: isDark ? Colors.orange.shade300 : Colors.orange.shade700),
                                                const SizedBox(width: 10),
                                                Text('Issue Credit Note / Return'.tr),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(),
                                          PopupMenuItem(
                                            value: 'cancel',
                                            child: Row(
                                              children: [
                                                Icon(Icons.cancel_outlined, size: 18, color: isDark ? Colors.amber.shade300 : Colors.amber.shade700),
                                                const SizedBox(width: 10),
                                                Text('Cancel Invoice'.tr),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 18, color: isDark ? Colors.red.shade300 : Colors.red.shade600),
                                                const SizedBox(width: 10),
                                                Text('delete'.tr, style: TextStyle(color: isDark ? Colors.red.shade300 : Colors.red.shade600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            // ── Pagination Footer ──
            _buildPagination(context, controller),
          ],
        );
      }),
    );
  }



  Widget _buildDueIn(BuildContext context, EntityBill bill) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (bill.status == 'CANCELLED') {
      return const Text('—', style: TextStyle(color: Colors.grey));
    }
    if (bill.dueDate != null && bill.dueDate!.isNotEmpty) {
      return Text(
        bill.dueDate!,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
      );
    }
    if ((bill.dueAmount ?? 0) <= 0) {
      return const Text('—', style: TextStyle(color: Colors.grey));
    }
    return Text(
      '30 Days',
      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
    );
  }

  Widget _buildStatusBadge(BuildContext context, EntityBill bill) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = (bill.status ?? 'PAID').toUpperCase();

    Color bg;
    Color fg;
    String label = status;

    if (status == 'PAID') {
      bg = Colors.green.withValues(alpha: isDark ? 0.2 : 0.12);
      fg = isDark ? Colors.green.shade300 : Colors.green.shade700;
      label = 'Paid'.tr;
    } else if (status == 'CANCELLED') {
      bg = Colors.grey.withValues(alpha: isDark ? 0.2 : 0.12);
      fg = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
      label = 'Cancelled'.tr;
    } else if ((bill.dueAmount ?? 0) > 0 && (bill.amountReceived ?? 0) > 0) {
      bg = Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15);
      fg = isDark ? Colors.amber.shade300 : Colors.orange.shade800;
      label = 'Partially Paid'.tr;
    } else {
      bg = Colors.red.withValues(alpha: isDark ? 0.2 : 0.12);
      fg = isDark ? Colors.red.shade300 : Colors.red.shade700;
      label = 'Unpaid'.tr;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ControllerSalesInvoices controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Invoices: ${controller.totalCount.value}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
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
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'page_number'.trParams({'number': '${controller.currentPage.value + 1}'}),
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
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
}

// ═══════════════════════════════════════════════════════════════════════════
// SUMMARY CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent strip
          Container(
            height: 3.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gradientColors.first.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isDark ? gradientColors.first : gradientColors.first, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
