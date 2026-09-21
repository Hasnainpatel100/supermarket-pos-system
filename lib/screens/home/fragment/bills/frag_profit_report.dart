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
                return _buildEmpty(context);
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
              ? _buildPagination(context, controller)
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: Colors.teal.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.show_chart_outlined, color: Colors.white, size: 24),
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
                  color: colorScheme.onSurface,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.teal.withValues(alpha: 0.18) : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? Colors.teal.withValues(alpha: 0.35) : Colors.teal.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 10, color: Colors.teal.shade400),
                    const SizedBox(width: 4),
                    Text(
                      controller.formatDateRange(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.teal.shade200 : Colors.teal.shade700),
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
            context,
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            color: Colors.teal.shade600,
            onTap: controller.loadData,
          ),

          const SizedBox(width: 6),

          // Excel
          _exportButton(
            context,
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
              context,
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
            context,
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

  Widget _headerAction(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: colorScheme.outlineVariant) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, color: isDark && color is MaterialColor ? color.shade300 : color),
        iconSize: 20,
        splashRadius: 20,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _exportButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = isDark && color is MaterialColor ? color.shade300 : color;
    final effectiveBg = isDark ? color.withValues(alpha: 0.18) : bgColor;
    final effectiveBorder = isDark ? color.withValues(alpha: 0.35) : borderColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: effectiveBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: effectiveColor)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Report Type Navigation Bar
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
                context,
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

  Widget _reportTypeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : (isDark ? colorScheme.surfaceContainerHigh : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? colorScheme.outlineVariant : Colors.grey.shade200),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? colorScheme.primary : primaryColor)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Summary Stats Cards
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
  // 4. Search and Location
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSearchRow(BuildContext context, ControllerProfitReport controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
              color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? colorScheme.outlineVariant : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warehouse_outlined, size: 16, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                Obx(() => Text(
                  controller.rxBranch.value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
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
  // 5. DataTable layout
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
      headingRowColor: WidgetStateProperty.all(colorScheme.primary.withValues(alpha: 0.04)),
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
        _col(context, 'SKU', Icons.qr_code_rounded, Colors.teal),
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.blue),
        _col(context, 'Qty Sold', Icons.unfold_more_rounded, Colors.orange),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.money_off_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.indigo),
        _col(context, 'Margin %', Icons.percent_rounded, Colors.purple),
      ],
      ProfitReportType.categoryProfit => [
        _col(context, 'Category Name', Icons.category_rounded, Colors.teal),
        _col(context, 'Qty Sold', Icons.unfold_more_rounded, Colors.orange),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.money_off_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.indigo),
        _col(context, 'Margin %', Icons.percent_rounded, Colors.purple),
      ],
      ProfitReportType.brandProfit => [
        _col(context, 'Brand Name', Icons.branding_watermark_rounded, Colors.teal),
        _col(context, 'Qty Sold', Icons.unfold_more_rounded, Colors.orange),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.money_off_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.indigo),
        _col(context, 'Margin %', Icons.percent_rounded, Colors.purple),
      ],
      ProfitReportType.dailyProfit => [
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.teal),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.money_off_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.blue),
        _col(context, 'Margin %', Icons.percent_rounded, Colors.purple),
      ],
      ProfitReportType.monthlyProfit => [
        _col(context, 'Month', Icons.calendar_view_month_rounded, Colors.teal),
        _col(context, 'Revenue', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Cost', Icons.money_off_rounded, Colors.red),
        _col(context, 'Gross Profit', Icons.trending_up_rounded, Colors.blue),
        _col(context, 'Margin %', Icons.percent_rounded, Colors.purple),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (type) {
      ProfitReportType.profitSummary => rows.map((r) {
        final row = r as ProfitSummaryRow;
        final isMargin = row.metric.contains('Margin');
        return DataRow(cells: [
          DataCell(Text(row.metric, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(Text(isMargin ? '${row.value.toStringAsFixed(1)}%' : currFmt.format(row.value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(row.details, style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant))),
        ]);
      }).toList(),

      ProfitReportType.itemProfit => rows.map((r) {
        final row = r as ItemProfitRow;
        return DataRow(cells: [
          DataCell(_skuBadge(context, row.sku)),
          DataCell(Text(row.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(_badge(context, row.quantitySold.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.revenue), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.cost), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700))),
          DataCell(_marginBadge(context, row.margin)),
        ]);
      }).toList(),

      ProfitReportType.categoryProfit => rows.map((r) {
        final row = r as CategoryProfitRow;
        return DataRow(cells: [
          DataCell(Text(row.categoryName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(_badge(context, row.quantitySold.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.revenue), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.cost), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700))),
          DataCell(_marginBadge(context, row.margin)),
        ]);
      }).toList(),

      ProfitReportType.brandProfit => rows.map((r) {
        final row = r as BrandProfitRow;
        return DataRow(cells: [
          DataCell(Text(row.brandName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(_badge(context, row.quantitySold.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.revenue), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.cost), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700))),
          DataCell(_marginBadge(context, row.margin)),
        ]);
      }).toList(),

      ProfitReportType.dailyProfit => rows.map((r) {
        final row = r as DailyProfitRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.indigo.shade600))),
          DataCell(Text(currFmt.format(row.revenue), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.cost), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700))),
          DataCell(_marginBadge(context, row.margin)),
        ]);
      }).toList(),

      ProfitReportType.monthlyProfit => rows.map((r) {
        final row = r as MonthlyProfitRow;
        return DataRow(cells: [
          DataCell(Text(row.month, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.indigo.shade600))),
          DataCell(Text(currFmt.format(row.revenue), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.cost), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.grossProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700))),
          DataCell(_marginBadge(context, row.margin)),
        ]);
      }).toList(),
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Badge Elements
  // ═════════════════════════════════════════════════════════════════════════

  DataColumn _col(BuildContext context, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 14, color: isDark && color is MaterialColor ? color.shade300 : color.withValues(alpha: 0.8)),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, MaterialColor color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.4 : 0.25)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? color.shade300 : color.shade700)),
    );
  }

  Widget _skuBadge(BuildContext context, String sku) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300),
      ),
      child: Text(sku, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : colorScheme.onSurface)),
    );
  }

  Widget _marginBadge(BuildContext context, double margin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = margin >= 20
        ? Colors.green
        : margin >= 10
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.5 : 0.3)),
      ),
      child: Text('${margin.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? color.shade200 : color.shade700)),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Empty State and Pagination
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                BoxShadow(color: Colors.teal.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.show_chart_outlined, size: 64, color: Colors.teal.shade400),
          ),
          const SizedBox(height: 16),
          Text('No profit records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text('Try adjusting the date range or filters', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ControllerProfitReport controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => Text(
            'Total: ${controller.totalCount.value} records',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.teal.shade300 : Colors.teal.shade700),
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
            color: data.gradientColors.first.withValues(alpha: 0.3),
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
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
