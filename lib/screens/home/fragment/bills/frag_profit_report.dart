import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../widget/my_card.dart';
import '../../../../widget/report_date_filter_dropdown.dart';
import 'controller_profit_report.dart';

class FragProfitReport extends StatelessWidget {
  final ProfitReportType? initialReportType;

  const FragProfitReport({super.key, this.initialReportType});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerProfitReport>()
        ? Get.find<ControllerProfitReport>()
        : Get.put(ControllerProfitReport());

    if (initialReportType != null &&
        controller.rxReportType.value != initialReportType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setReportType(initialReportType!);
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    final currFmt = NumberFormat.simpleCurrency(locale: 'en_IN');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════════
          // 1. HEADER ROW — Title, Report-Type Dropdown, Export Actions
          // ═══════════════════════════════════════════════════════════════
          _buildHeader(context, controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 2. REPORT TYPE BAR (Horizontal Pills)
          // ═══════════════════════════════════════════════════════════════
          _buildReportTypeBar(context, controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 3. SUMMARY STATS CARDS
          // ═══════════════════════════════════════════════════════════════
          _buildSummaryCards(controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 4. SEARCH + BRANCH/LOCATION
          // ═══════════════════════════════════════════════════════════════
          _buildSearchRow(context, controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 5. DATA TABLE
          // ═══════════════════════════════════════════════════════════════
          Expanded(
            child: Obx(() {
              if (controller.rxLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.rxRows.isEmpty) {
                return _buildEmpty();
              }
              return MyCard(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: _buildDataTable(context, controller, colorScheme, currFmt),
                  ),
                ),
              );
            }),
          ),

          // ═══════════════════════════════════════════════════════════════
          // 6. PAGINATION FOOTER
          // ═══════════════════════════════════════════════════════════════
          Obx(() => controller.rxRows.isNotEmpty
              ? _buildPagination(controller)
              : const SizedBox.shrink()),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Header Component
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, ControllerProfitReport controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profit Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.grey.shade800,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 10, color: Colors.teal.shade400),
                    const SizedBox(width: 4),
                    Text(
                      controller.formatDateRange(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal.shade700),
                    ),
                  ],
                ),
              )),
            ],
          ),

          const Spacer(),

          // Date Filter Dropdown
          Obx(() => ReportDateFilterDropdown(
            selectedFilter: controller.rxDateFilter.value,
            onFilterChanged: (filter) => controller.setDateFilter(filter),
            onPickCustomRange: () => _pickDateRange(context, controller),
            themeColor: Colors.teal.shade600,
          )),

          const SizedBox(width: 10),

          // Refresh
          _headerAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            color: Colors.teal.shade600,
            onTap: controller.loadData,
          ),

          const SizedBox(width: 6),

          // Excel
          _exportButton(
            icon: Icons.table_chart_rounded,
            label: 'Excel',
            color: Colors.green.shade600,
            bgColor: Colors.green.shade50,
            borderColor: Colors.green.shade200,
            onTap: controller.exportExcel,
          ),

          if (kDebugMode) ...[
            const SizedBox(width: 6),
            _exportButton(
              icon: Icons.file_upload_rounded,
              label: 'Import Excel',
              color: Colors.amber.shade900,
              bgColor: Colors.amber.shade50,
              borderColor: Colors.amber.shade200,
              onTap: controller.importTestExcel,
            ),
          ],

          const SizedBox(width: 6),

          // PDF
          _exportButton(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            color: Colors.red.shade600,
            bgColor: Colors.red.shade50,
            borderColor: Colors.red.shade200,
            onTap: controller.exportPdf,
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, color: color),
        iconSize: 20,
        splashRadius: 20,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _exportButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // REPORT TYPE NAVIGATION BAR
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildReportTypeBar(BuildContext context, ControllerProfitReport controller) {
    return Obx(() {
      final selected = controller.rxReportType.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: ProfitReportType.values.map((type) {
            final isSelected = selected == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _reportTypeChip(
                label: type.label,
                icon: type.icon,
                isSelected: isSelected,
                primaryColor: Colors.teal.shade600,
                onTap: () => controller.setReportType(type),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _reportTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Summary Stats row
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(ControllerProfitReport controller) {
    return Obx(() {
      final cards = controller.rxSummaryCards;
      if (cards.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: cards.map((c) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: cards.last == c ? 0 : 10,
                ),
                child: _ProfitSummaryCard(data: c),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Search and Location
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSearchRow(BuildContext context, ControllerProfitReport controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                onChanged: controller.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search items, categories, or brands...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.teal.shade600),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warehouse_outlined, size: 16, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                Obx(() => Text(
                  controller.rxBranch.value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                )),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DataTable layout
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildDataTable(
    BuildContext context,
    ControllerProfitReport controller,
    ColorScheme colorScheme,
    NumberFormat currFmt,
  ) {
    final type = controller.rxReportType.value;

    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 16,
      headingRowColor: WidgetStateProperty.all(colorScheme.primary.withOpacity(0.04)),
      headingTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colorScheme.onSurface),
      dividerThickness: 0.5,
      dataRowMaxHeight: 52,
      columns: _columnsFor(type, context),
      rows: _rowsFor(type, controller, context, currFmt, colorScheme),
    );
  }

  List<DataColumn> _columnsFor(ProfitReportType type, BuildContext context) {
    return switch (type) {
      ProfitReportType.profitSummary => [
        _col(context, 'Metric KPI', Icons.bar_chart_rounded, Colors.indigo),
        _col(context, 'Value', Icons.monetization_on_rounded, Colors.teal),
        _col(context, 'Details / Description', Icons.info_outline_rounded, Colors.grey),
      ],
      ProfitReportType.itemProfit => [
        _col(context, 'Barcode/SKU', Icons.qr_code_rounded, Colors.indigo),
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.orange),
        _col(context, 'Qty Sold', Icons.unfold_more_rounded, Colors.blue),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Product Cost', Icons.shopping_bag_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.teal),
        _col(context, 'Margin %', Icons.pie_chart_rounded, Colors.purple),
      ],
      ProfitReportType.categoryProfit => [
        _col(context, 'Category Name', Icons.category_rounded, Colors.indigo),
        _col(context, 'Qty Sold', Icons.unfold_more_rounded, Colors.blue),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.shopping_bag_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.teal),
        _col(context, 'Margin %', Icons.pie_chart_rounded, Colors.purple),
      ],
      ProfitReportType.brandProfit => [
        _col(context, 'Brand Name', Icons.branding_watermark_rounded, Colors.indigo),
        _col(context, 'Qty Sold', Icons.unfold_more_rounded, Colors.blue),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.shopping_bag_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.teal),
        _col(context, 'Margin %', Icons.pie_chart_rounded, Colors.purple),
      ],
      ProfitReportType.dailyProfit => [
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.shopping_bag_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.teal),
        _col(context, 'Margin %', Icons.pie_chart_rounded, Colors.purple),
      ],
      ProfitReportType.monthlyProfit => [
        _col(context, 'Month', Icons.calendar_view_month_rounded, Colors.indigo),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.shopping_bag_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.teal),
        _col(context, 'Margin %', Icons.pie_chart_rounded, Colors.purple),
      ],
    };
  }

  List<DataRow> _rowsFor(
    ProfitReportType type,
    ControllerProfitReport controller,
    BuildContext context,
    NumberFormat currFmt,
    ColorScheme colorScheme,
  ) {
    final rows = controller.rxRows;
    return switch (type) {
      ProfitReportType.profitSummary => rows.map((r) {
        final row = r as ProfitSummaryRow;
        final isMargin = row.metric.contains('Margin');
        return DataRow(cells: [
          DataCell(Text(row.metric, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(isMargin ? '${row.value.toStringAsFixed(1)}%' : currFmt.format(row.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataCell(Text(row.details, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
        ]);
      }).toList(),

      ProfitReportType.itemProfit => rows.map((r) {
        final row = r as ItemProfitRow;
        return DataRow(cells: [
          DataCell(_skuBadge(row.sku)),
          DataCell(Text(row.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_badge(row.quantitySold.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.revenue), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.cost), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade700))),
          DataCell(_marginBadge(row.margin)),
        ]);
      }).toList(),

      ProfitReportType.categoryProfit => rows.map((r) {
        final row = r as CategoryProfitRow;
        return DataRow(cells: [
          DataCell(Text(row.categoryName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_badge(row.quantitySold.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.revenue), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.cost), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade700))),
          DataCell(_marginBadge(row.margin)),
        ]);
      }).toList(),

      ProfitReportType.brandProfit => rows.map((r) {
        final row = r as BrandProfitRow;
        return DataRow(cells: [
          DataCell(Text(row.brandName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_badge(row.quantitySold.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.revenue), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.cost), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade700))),
          DataCell(_marginBadge(row.margin)),
        ]);
      }).toList(),

      ProfitReportType.dailyProfit => rows.map((r) {
        final row = r as DailyProfitRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.indigo.shade600))),
          DataCell(Text(currFmt.format(row.revenue), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.cost), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade700))),
          DataCell(_marginBadge(row.margin)),
        ]);
      }).toList(),

      ProfitReportType.monthlyProfit => rows.map((r) {
        final row = r as MonthlyProfitRow;
        return DataRow(cells: [
          DataCell(Text(row.month, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.indigo.shade600))),
          DataCell(Text(currFmt.format(row.revenue), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.cost), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade700))),
          DataCell(_marginBadge(row.margin)),
        ]);
      }).toList(),
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Badge Elements
  // ═════════════════════════════════════════════════════════════════════════

  DataColumn _col(BuildContext context, String label, IconData icon, Color color) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 14, color: color.withOpacity(0.8)),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color.shade700)),
    );
  }

  Widget _skuBadge(String sku) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(sku, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
    );
  }

  Widget _marginBadge(double margin) {
    final color = margin >= 20
        ? Colors.green
        : margin >= 10
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text('${margin.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color.shade700)),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Empty State and Pagination
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade100, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.show_chart_outlined, size: 64, color: Colors.teal.shade400),
          ),
          const SizedBox(height: 16),
          Text('No profit records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text('Try adjusting the date range or filters', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildPagination(ControllerProfitReport controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => Text(
            'Total: ${controller.totalCount.value} records',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          )),
          Row(
            children: [
              Obx(() => OutlinedButton.icon(
                onPressed: controller.hasPrev ? controller.prevPage : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text('Prev'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
              const SizedBox(width: 12),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              )),
              const SizedBox(width: 12),
              Obx(() => OutlinedButton.icon(
                onPressed: controller.hasNext ? controller.nextPage : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Next'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  void _pickDateRange(BuildContext context, ControllerProfitReport controller) async {
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
      controller.setDateRange(picked.start, picked.end);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ProfitSummaryCard
// ═══════════════════════════════════════════════════════════════════════════

class _ProfitSummaryCard extends StatelessWidget {
  final ProfitSummaryCardData data;

  const _ProfitSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: data.gradientColors.first.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.label,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
