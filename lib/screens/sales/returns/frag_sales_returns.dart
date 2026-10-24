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
          // Most Returned Items Analytics Button
          GradientActionButton(
            icon: Icons.leaderboard_rounded,
            label: 'Most Returned Items'.tr,
            gradientColors: isDark
                ? [Colors.purple.shade600, Colors.deepPurple.shade800]
                : [Colors.purple.shade500, Colors.deepPurple.shade700],
            onTap: () => _showMostReturnedItemsDialog(context, controller, currencyFmt, isDark),
          ),
          const SizedBox(width: 8),

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
          child: SearchAppBarField(
            controller: controller.searchController,
            hint: 'Search return no, invoice no, customer...'.tr,
            onChanged: controller.updateSearch,
            onSubmitted: controller.onSearchSubmitted,
            onClear: controller.clearSearch,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total Units Returned',
                      value: '${controller.rxTotalUnitsReturned.value} pcs',
                      icon: Icons.inventory_2_outlined,
                      gradientColors: [Colors.orange.shade600, Colors.amber.shade700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Top Returned Item',
                      value: controller.rxTopReturnedName.value == '-'
                          ? 'None'
                          : '${controller.rxTopReturnedName.value} (${controller.rxTopReturnedQty.value} pcs)',
                      icon: Icons.trending_up_rounded,
                      gradientColors: [Colors.purple.shade600, Colors.deepPurple.shade700],
                      onTap: () => _showMostReturnedItemsDialog(context, controller, currencyFmt, isDark),
                    ),
                  ),
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
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
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
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white70),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: cardContent,
        ),
      );
    }
    return cardContent;
  }
}

void _showMostReturnedItemsDialog(
  BuildContext context,
  ControllerSalesReturns controller,
  NumberFormat currencyFmt,
  bool isDark,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final searchFilter = ''.obs;
  final filterCtrl = TextEditingController();

  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 820,
        height: 640,
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Dialog Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.purple.shade900, Colors.deepPurple.shade800]
                      : [Colors.purple.shade700, Colors.deepPurple.shade900],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.leaderboard_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Most Returned Items Analytics',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track products frequently returned by customers to identify quality issues or defects.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ── Search & Metrics Subheader ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: filterCtrl,
                      onChanged: (val) => searchFilter.value = val.trim().toLowerCase(),
                      decoration: InputDecoration(
                        hintText: 'Search returned product name or barcode...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: Obx(() => searchFilter.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  filterCtrl.clear();
                                  searchFilter.value = '';
                                },
                              )
                            : const SizedBox.shrink()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${controller.rxMostReturnedItems.length} Products Tracked',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.purple.shade300 : Colors.purple.shade800,
                            fontSize: 13,
                          ),
                        ),
                      )),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Table Content ──
            Expanded(
              child: Obx(() {
                final query = searchFilter.value;
                final items = controller.rxMostReturnedItems.where((it) {
                  if (query.isEmpty) return true;
                  return it.itemName.toLowerCase().contains(query) ||
                      it.barcode.toLowerCase().contains(query);
                }).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          query.isEmpty
                              ? 'No customer return records yet.'
                              : 'No returned products match "$query"',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: DataTable(
                    columnSpacing: 18,
                    horizontalMargin: 8,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                    dataRowMaxHeight: 56,
                    columns: const [
                      DataColumn(label: Text('Rank')),
                      DataColumn(label: Text('Item Name & Barcode')),
                      DataColumn(label: Text('Units Returned')),
                      DataColumn(label: Text('Return Incidents')),
                      DataColumn(label: Text('Total Refund Value')),
                      DataColumn(label: Text('Last Return')),
                    ],
                    rows: List.generate(items.length, (index) {
                      final it = items[index];
                      final isTop3 = index < 3;
                      final badgeColor = index == 0
                          ? const Color(0xFFFFD700) // Gold
                          : index == 1
                              ? const Color(0xFFC0C0C0) // Silver
                              : index == 2
                                  ? const Color(0xFFCD7F32) // Bronze
                                  : Colors.grey.shade400;

                      return DataRow(
                        cells: [
                          // Rank
                          DataCell(
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isTop3
                                    ? badgeColor.withValues(alpha: 0.25)
                                    : Colors.grey.withValues(alpha: 0.1),
                                border: isTop3 ? Border.all(color: badgeColor, width: 1.5) : null,
                              ),
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isTop3 ? Colors.deepOrange.shade800 : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),

                          // Item Name & Barcode
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  it.itemName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (it.barcode.isNotEmpty)
                                  Text(
                                    'Barcode: ${it.barcode}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),

                          // Units Returned (Highlighted)
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${it.totalQty} pcs',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                          // Return Incidents
                          DataCell(
                            Text(
                              '${it.returnCount} ${it.returnCount == 1 ? "time" : "times"}',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ),

                          // Total Refund Value
                          DataCell(
                            Text(
                              currencyFmt.format(it.totalRefund),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.amber.shade300 : Colors.deepOrange.shade800,
                              ),
                            ),
                          ),

                          // Last Return Date
                          DataCell(
                            Text(
                              it.lastReturnDate ?? 'N/A',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              }),
            ),

            // ── Dialog Footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tip: Items at the top have the highest return rate.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

