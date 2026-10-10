import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_quotation.dart';
import '../../../service/service_currency.dart';
import '../../../widget/generic_empty_state.dart';
import '../../../widget/gradient_action_button.dart';
import '../../../widget/gradient_app_bar_title.dart';
import '../../../widget/my_card.dart';
import '../../../widget/search_app_bar_field.dart';
import 'controller_quotations.dart';

class FragQuotations extends StatelessWidget {
  const FragQuotations({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerQuotations>()
        ? Get.find<ControllerQuotations>()
        : Get.put(ControllerQuotations());

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currencySymbol = Get.isRegistered<ServiceCurrency>()
        ? Get.find<ServiceCurrency>().rxCurrency.value
        : '₹';
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: GradientAppBarTitle(
          icon: Icons.request_quote_rounded,
          title: 'Quotation / Estimate'.tr,
          subtitle: 'Create price quotes & convert to invoices'.tr,
          gradientColors: isDark
              ? [Colors.amber.shade400, Colors.orange.shade700]
              : [Colors.amber.shade700, Colors.orange.shade800],
        ),
        actions: [
          // Create Quotation Button
          GradientActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Create Quotation'.tr,
            gradientColors: isDark
                ? [Colors.amber.shade500, Colors.orange.shade700]
                : [Colors.amber.shade600, Colors.orange.shade800],
            onTap: () => controller.openCreateQuotation(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Obx(
            () => SearchAppBarField(
              controller: controller.searchController,
              hint: 'Search quotation, customer, phone...'.tr,
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
            // ── Status Filter Chips ──
            _buildStatusChips(context, controller),

            // ── Table or Empty State ──
            Expanded(
              child: controller.rxQuotations.isEmpty
                  ? GenericEmptyState(
                      icon: Icons.request_quote_outlined,
                      title: 'No Quotations Found'.tr,
                      subtitle: 'Provide price estimates to potential customers and convert them to invoices.'.tr,
                      gradientColors: [Colors.amber.shade300, Colors.orange.shade400],
                    )
                  : RepaintBoundary(
                      child: MyCard(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 18,
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
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.tag_rounded, size: 14, color: isDark ? Colors.amber.shade300 : Colors.amber.shade800),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Quote No'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                                          color: Colors.purple.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.timer_outlined, size: 14, color: isDark ? Colors.purple.shade300 : Colors.purple.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Validity / Due'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                                          color: Colors.teal.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.payments_rounded, size: 14, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700),
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
                                          color: Colors.green.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.toggle_on_rounded, size: 14, color: isDark ? Colors.green.shade300 : Colors.green.shade700),
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
                              rows: controller.pagedQuotations.map((EntityQuotation quote) {
                                final isConverted = quote.status == 'Converted';
                                final isExpired = quote.status == 'Expired';

                                return DataRow(
                                  cells: [
                                    // Date
                                    DataCell(Text(
                                      quote.quotationDate ?? '—',
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                                    )),

                                    // Quotation Number
                                    DataCell(Text(
                                      quote.quotationNo ?? '${quote.id}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                                      ),
                                    )),

                                    // Customer
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_outline_rounded, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                        const SizedBox(width: 6),
                                        Text(
                                          quote.customerName?.isNotEmpty == true ? quote.customerName! : 'Cash Customer'.tr,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                        ),
                                      ],
                                    )),

                                    // Validity
                                    DataCell(Text(
                                      quote.validUntilDate ?? '${quote.validDays ?? 30} Days',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isExpired
                                            ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                      ),
                                    )),

                                    // Amount
                                    DataCell(Text(
                                      currencyFmt.format(quote.grandTotal ?? 0.0),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    )),

                                    // Status Badge
                                    DataCell(_buildStatusBadge(context, quote.status ?? 'Open')),

                                    // Actions
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant),
                                        tooltip: 'Actions'.tr,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (val) {
                                          switch (val) {
                                            case 'view':
                                              controller.openDocumentView(quote);
                                              break;
                                            case 'convert':
                                              controller.convertToInvoice(quote);
                                              break;
                                            case 'edit':
                                              controller.openCreateQuotation(editQuotation: quote);
                                              break;
                                            case 'delete':
                                              controller.deleteQuotation(quote);
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
                                                Text('View Quotation'.tr),
                                              ],
                                            ),
                                          ),
                                          if (!isConverted)
                                            PopupMenuItem(
                                              value: 'convert',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.transform_rounded, size: 18, color: Colors.green.shade600),
                                                  const SizedBox(width: 10),
                                                  Text('Convert to Invoice'.tr, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                          if (!isConverted)
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 18, color: Colors.blue.shade600),
                                                  const SizedBox(width: 10),
                                                  Text('edit'.tr),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuDivider(),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade600),
                                                const SizedBox(width: 10),
                                                Text('delete'.tr, style: TextStyle(color: Colors.red.shade600)),
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

  Widget _buildStatusChips(BuildContext context, ControllerQuotations controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statuses = ['All', 'Open', 'Converted', 'Expired'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statuses.map((status) {
              final isSelected = controller.rxStatusFilter.value == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    status == 'All' ? 'All Quotations'.tr : status.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                    ),
                  ),
                  selectedColor: isDark ? Colors.amber.shade700 : Colors.amber.shade800,
                  checkmarkColor: Colors.white,
                  backgroundColor: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  onSelected: (_) => controller.setStatusFilter(status),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    final upper = status.toUpperCase();

    if (upper == 'CONVERTED') {
      bg = Colors.green.withValues(alpha: isDark ? 0.2 : 0.12);
      fg = isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (upper == 'EXPIRED') {
      bg = Colors.red.withValues(alpha: isDark ? 0.2 : 0.12);
      fg = isDark ? Colors.red.shade300 : Colors.red.shade700;
    } else {
      bg = Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15);
      fg = isDark ? Colors.amber.shade300 : Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.tr,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ControllerQuotations controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Quotations: ${controller.totalCount.value}',
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
