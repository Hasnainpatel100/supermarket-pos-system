import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_sales_return.dart';
import '../../../service/service_currency.dart';
import '../../../widget/generic_empty_state.dart';
import '../../../widget/gradient_action_button.dart';
import '../../../widget/gradient_app_bar_title.dart';
import '../../../widget/my_card.dart';
import '../../../widget/search_app_bar_field.dart';
import 'controller_sales_returns.dart';

class FragSalesReturns extends StatelessWidget {
  const FragSalesReturns({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerSalesReturns>()
        ? Get.find<ControllerSalesReturns>()
        : Get.put(ControllerSalesReturns());

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
          icon: Icons.assignment_return_rounded,
          title: 'Sales Return'.tr,
          subtitle: 'Credit notes & return merchandise'.tr,
          gradientColors: isDark
              ? [Colors.red.shade300, Colors.red.shade600]
              : [Colors.red.shade500, Colors.red.shade800],
        ),
        actions: [
          // Create Return Button
          GradientActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Create Return'.tr,
            gradientColors: isDark
                ? [Colors.red.shade500, Colors.red.shade700]
                : [Colors.red.shade600, Colors.red.shade800],
            onTap: () => controller.openCreateReturn(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Obx(
            () => SearchAppBarField(
              controller: controller.searchController,
              hint: 'Search return no, invoice no, customer...'.tr,
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
                      label: 'Total Refunds Issued',
                      value: currencyFmt.format(controller.rxTotalRefunded.value),
                      icon: Icons.assignment_return_rounded,
                      gradientColors: [Colors.red.shade600, Colors.deepOrange.shade500],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total Return Records',
                      value: '${controller.rxTotalCount.value}',
                      icon: Icons.receipt_long_rounded,
                      gradientColors: [Colors.teal.shade500, Colors.cyan.shade600],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),

            // ── Table or Empty State ──
            Expanded(
              child: controller.rxReturns.isEmpty
                  ? GenericEmptyState(
                      icon: Icons.assignment_return_outlined,
                      title: 'No Sales Returns Found'.tr,
                      subtitle: 'Track and issue credit notes for customer item returns.'.tr,
                      gradientColors: [Colors.red.shade300, Colors.red.shade400],
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
                                          color: Colors.red.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.tag_rounded, size: 14, color: isDark ? Colors.red.shade300 : Colors.red.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Return No'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                                        child: Icon(Icons.receipt_long_rounded, size: 14, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Original Invoice'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                                  numeric: true,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.payments_rounded, size: 14, color: isDark ? Colors.red.shade300 : Colors.red.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Refund Amount'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                                        child: Icon(Icons.payment_rounded, size: 14, color: isDark ? Colors.purple.shade300 : Colors.purple.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Mode'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                              rows: controller.pagedReturns.map((EntitySalesReturn ret) {
                                return DataRow(
                                  cells: [
                                    // Date
                                    DataCell(Text(
                                      ret.returnDate ?? '—',
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                                    )),

                                    // Return Number
                                    DataCell(Text(
                                      ret.returnNo ?? '${ret.id}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                      ),
                                    )),

                                    // Original Invoice
                                    DataCell(Text(
                                      ret.originalBillNo?.isNotEmpty == true ? ret.originalBillNo! : '—',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    )),

                                    // Customer
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_outline_rounded, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                        const SizedBox(width: 6),
                                        Text(
                                          ret.customerName?.isNotEmpty == true ? ret.customerName! : 'Walk-in Customer'.tr,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                        ),
                                      ],
                                    )),

                                    // Refund Amount
                                    DataCell(Text(
                                      currencyFmt.format(ret.refundAmount ?? 0.0),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                      ),
                                    )),

                                    // Mode
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ret.paymentMode ?? 'Cash',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary),
                                      ),
                                    )),

                                    // Actions
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant),
                                        tooltip: 'Actions'.tr,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (val) {
                                          switch (val) {
                                            case 'view':
                                              controller.openDocumentView(ret);
                                              break;
                                            case 'edit':
                                              controller.openCreateReturn(editReturn: ret);
                                              break;
                                            case 'delete':
                                              controller.deleteReturn(ret);
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
                                                Text('View Credit Note'.tr),
                                              ],
                                            ),
                                          ),
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



  Widget _buildPagination(BuildContext context, ControllerSalesReturns controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Returns: ${controller.rxReturns.length}',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
