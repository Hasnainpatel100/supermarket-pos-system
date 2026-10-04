import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../widget/my_card.dart';
import '../../../../widget/report_date_filter_dropdown.dart';
import 'controller_sales_report.dart';

class FragSalesReport extends StatelessWidget {
  /// Optional: pre-select a report type from the drawer navigation
  final SalesReportType? initialReportType;

  const FragSalesReport({super.key, this.initialReportType});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerSalesReport>()
        ? Get.find<ControllerSalesReport>()
        : Get.put(ControllerSalesReport());

    // Apply initial report type if provided and different
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
          // 1. HEADER ROW — Icon, Title, Report-Type Dropdown, Actions
          // ═══════════════════════════════════════════════════════════════
          _buildHeader(context, controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 2. REPORT TYPE BAR (Horizontal Pills)
          // ═══════════════════════════════════════════════════════════════
          _buildReportTypeBar(context, controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 3. SUMMARY CARDS
          // ═══════════════════════════════════════════════════════════════
          _buildSummaryCards(controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 4. SEARCH + BRANCH
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
          // 6. PAGINATION
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
  // HEADER
  // ═════════════════════════════════════════════════════════════════════════

  // ═════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, ControllerSalesReport controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          // Gradient icon
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
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          // Title + date range badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sales_reports'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colorScheme.onSurface,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.withValues(alpha: 0.18) : Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.withValues(alpha: 0.35) : Colors.indigo.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 10, color: Colors.indigo.shade400),
                    const SizedBox(width: 4),
                    Text(
                      controller.formatDateRange(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade200 : Colors.indigo.shade700),
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
            themeColor: Colors.indigo.shade600,
          )),

          const SizedBox(width: 10),

          // Refresh
          _headerAction(
            context,
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            color: Colors.indigo.shade600,
            onTap: controller.loadData,
          ),

          const SizedBox(width: 6),

          // Export Excel
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
            const SizedBox(width: 6),
            _exportButton(
              context,
              icon: Icons.bolt_rounded,
              label: '+ 30k Bills',
              color: Colors.deepPurple.shade700,
              bgColor: Colors.deepPurple.shade50,
              borderColor: Colors.deepPurple.shade200,
              onTap: controller.seed30kTestBills,
            ),
            const SizedBox(width: 6),
            _exportButton(
              context,
              icon: Icons.delete_sweep_rounded,
              label: 'Clear Seeded',
              color: Colors.red.shade700,
              bgColor: Colors.red.shade50,
              borderColor: Colors.red.shade200,
              onTap: controller.clearSeededSales,
            ),
          ],

          const SizedBox(width: 6),

          // Export PDF
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

  // ═════════════════════════════════════════════════════════════════════════
  // REPORT TYPE BAR
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildReportTypeBar(
    BuildContext context,
    ControllerSalesReport controller,
  ) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: SalesReportType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = SalesReportType.values[index];
          return Obx(() {
            final isSelected = controller.rxReportType.value == type;
            return _reportTypeChip(
              context,
              label: type.label,
              icon: type.icon,
              isSelected: isSelected,
              primaryColor: Colors.indigo.shade600,
              onTap: () => controller.setReportType(type),
            );
          });
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SUMMARY CARDS
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(ControllerSalesReport controller) {
    return Obx(() {
      final cards = controller.rxSummaryCards;
      if (cards.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: cards.map((card) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _SummaryCard(data: card),
              ),
            );
          }).toList(),
        ),
      );
    });
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
              label.tr,
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
  // SEARCH + BRANCH
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSearchRow(BuildContext context, ControllerSalesReport controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search
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
                  hintText: _searchHint(controller.rxReportType.value),
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.indigo.shade400),
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
          // Branch dropdown (placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? colorScheme.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? colorScheme.outlineVariant : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store_rounded, size: 16, color: Colors.indigo.shade400),
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

  String _searchHint(SalesReportType type) => switch (type) {
    SalesReportType.salesSummary   => 'Search by date...',
    SalesReportType.salesDetail    => 'Search by bill no or customer...',
    SalesReportType.itemSales      => 'Search by item name or barcode...',
    SalesReportType.categorySales  => 'Search by category name...',
    SalesReportType.paymentReport  => 'Search...',
    SalesReportType.hourWiseSales  => 'Search...',
  };

  // ═════════════════════════════════════════════════════════════════════════
  // DATA TABLE — dynamically builds columns + rows per report type
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildDataTable(
    BuildContext context,
    ControllerSalesReport controller,
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

  List<DataColumn> _columnsFor(SalesReportType type, BuildContext context) {
    return switch (type) {
      SalesReportType.salesSummary => [
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Orders', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Total Sales', Icons.attach_money_rounded, Colors.green),
        _col(context, 'Discount', Icons.discount_rounded, Colors.orange),
        _col(context, 'Tax', Icons.account_balance_rounded, Colors.purple),
        _col(context, 'Net Sales', Icons.trending_up_rounded, Colors.teal),
      ],
      SalesReportType.salesDetail => [
        _col(context, 'Date & Time', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Bill No', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Customer', Icons.person_outline_rounded, Colors.green),
        _col(context, 'Payment', Icons.payment_rounded, Colors.teal),
        _col(context, 'Items', Icons.inventory_2_rounded, Colors.orange),
        _col(context, 'Total', Icons.attach_money_rounded, Colors.amber),
        _col(context, 'Status', Icons.toggle_on_rounded, Colors.purple),
      ],
      SalesReportType.itemSales => [
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.indigo),
        _col(context, 'Barcode', Icons.qr_code_rounded, Colors.blue),
        _col(context, 'Unit', Icons.straighten_rounded, Colors.teal),
        _col(context, 'Qty Sold', Icons.shopping_cart_rounded, Colors.green),
        _col(context, 'Revenue', Icons.attach_money_rounded, Colors.orange),
        _col(context, 'Avg Price', Icons.analytics_rounded, Colors.purple),
      ],
      SalesReportType.categorySales => [
        _col(context, 'Category', Icons.category_rounded, Colors.indigo),
        _col(context, 'Items', Icons.inventory_2_rounded, Colors.blue),
        _col(context, 'Qty Sold', Icons.shopping_cart_rounded, Colors.green),
        _col(context, 'Revenue', Icons.attach_money_rounded, Colors.orange),
        _col(context, '% of Total', Icons.pie_chart_rounded, Colors.purple),
      ],
      SalesReportType.paymentReport => [
        _col(context, 'Payment Mode', Icons.payment_rounded, Colors.indigo),
        _col(context, 'Transactions', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Total Amount', Icons.attach_money_rounded, Colors.green),
        _col(context, '% Share', Icons.pie_chart_rounded, Colors.purple),
      ],
      SalesReportType.hourWiseSales => [
        _col(context, 'Hour Slot', Icons.schedule_rounded, Colors.indigo),
        _col(context, 'Orders', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Total Sales', Icons.attach_money_rounded, Colors.green),
        _col(context, 'Avg Bill', Icons.analytics_rounded, Colors.orange),
        _col(context, 'Peak', Icons.flash_on_rounded, Colors.purple),
      ],
    };
  }

  List<DataRow> _rowsFor(
    SalesReportType type,
    ControllerSalesReport controller,
    BuildContext context,
    NumberFormat currFmt,
    ColorScheme colorScheme,
  ) {
    final rows = controller.rxRows;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (type) {
      SalesReportType.salesSummary => rows.map((r) {
        final row = r as SalesSummaryRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.indigo.shade600))),
          DataCell(_badge(context, row.orders.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.totalSales), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.discount), style: TextStyle(fontSize: 13, color: isDark ? Colors.orange.shade300 : Colors.orange.shade700))),
          DataCell(Text(currFmt.format(row.tax), style: TextStyle(fontSize: 13, color: isDark ? Colors.purple.shade300 : Colors.purple.shade600))),
          DataCell(Text(currFmt.format(row.netSales), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700))),
        ]);
      }).toList(),

      SalesReportType.salesDetail => rows.map((r) {
        final row = r as SalesDetailRow;
        return DataRow(cells: [
          DataCell(Text(row.dateTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.indigo.shade600))),
          DataCell(_billNoBadge(context, row.billNo)),
          DataCell(Text(row.customer, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800))),
          DataCell(_paymentBadge(context, row.payment)),
          DataCell(_badge(context, row.items.toString(), Colors.orange)),
          DataCell(Text(currFmt.format(row.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(_statusBadge(context, row.status)),
        ]);
      }).toList(),

      SalesReportType.itemSales => rows.map((r) {
        final row = r as ItemSalesRow;
        return DataRow(cells: [
          DataCell(Text(row.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800))),
          DataCell(Text(row.barcode, style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade500))),
          DataCell(Text(row.unit, style: TextStyle(fontSize: 13, color: isDark ? Colors.teal.shade300 : Colors.teal.shade600))),
          DataCell(_badge(context, row.qtySold.toString(), Colors.green)),
          DataCell(Text(currFmt.format(row.revenue), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.avgPrice), style: TextStyle(fontSize: 13, color: isDark ? Colors.purple.shade300 : Colors.purple.shade600))),
        ]);
      }).toList(),

      SalesReportType.categorySales => rows.map((r) {
        final row = r as CategorySalesRow;
        return DataRow(cells: [
          DataCell(Text(row.category, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800))),
          DataCell(_badge(context, row.itemCount.toString(), Colors.blue)),
          DataCell(_badge(context, row.qtySold.toString(), Colors.green)),
          DataCell(Text(currFmt.format(row.revenue), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(_percentBar(row.percentOfTotal)),
        ]);
      }).toList(),

      SalesReportType.paymentReport => rows.map((r) {
        final row = r as PaymentReportRow;
        return DataRow(cells: [
          DataCell(_paymentBadge(context, row.paymentMode)),
          DataCell(_badge(context, row.transactions.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(_percentBar(row.percentShare)),
        ]);
      }).toList(),

      SalesReportType.hourWiseSales => rows.map((r) {
        final row = r as HourWiseSalesRow;
        return DataRow(
          color: WidgetStateProperty.resolveWith<Color?>((_) {
            if (row.isPeak) return Colors.amber.withValues(alpha: 0.08);
            return null;
          }),
          cells: [
            DataCell(Text(row.hourSlot, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.indigo.shade600))),
            DataCell(_badge(context, row.orders.toString(), Colors.blue)),
            DataCell(Text(currFmt.format(row.totalSales), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
            DataCell(Text(currFmt.format(row.avgBill), style: TextStyle(fontSize: 13, color: isDark ? Colors.orange.shade300 : Colors.orange.shade700))),
            DataCell(row.isPeak
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade400]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 3),
                        Text('PEAK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  )
                : Text('—', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400)),
            ),
          ],
        );
      }).toList(),
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CELL WIDGETS
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
            child: Icon(icon, size: 14, color: isDark && color is MaterialColor ? color.shade300 : color),
          ),
          const SizedBox(width: 6),
          Text(label.tr, style: TextStyle(color: isDark ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.4 : 0.25)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark && color is MaterialColor ? color.shade300 : color)),
    );
  }

  Widget _billNoBadge(BuildContext context, String billNo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300),
      ),
      child: Text('#$billNo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade700)),
    );
  }

  Widget _paymentBadge(BuildContext context, String mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.withValues(alpha: isDark ? 0.4 : 0.3)),
      ),
      child: Text(mode, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.teal.shade200 : Colors.teal.shade700)),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final MaterialColor color = switch (status) {
      'PAID' => Colors.green,
      'DUE' => Colors.orange,
      'HOLD' => Colors.blue,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.shade700)),
    );
  }

  Widget _percentBar(double percent) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.purple.shade700)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.purple.shade50,
              valueColor: AlwaysStoppedAnimation(Colors.purple.shade400),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
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
                colors: [Colors.indigo.shade100, Colors.purple.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.indigo.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.assessment_outlined, size: 64, color: Colors.indigo.shade400),
          ),
          const SizedBox(height: 16),
          Text('No data found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text('Try adjusting the date range or report type', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PAGINATION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildPagination(BuildContext context, ControllerSalesReport controller) {
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
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade300 : Colors.indigo.shade700),
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

  // ═════════════════════════════════════════════════════════════════════════
  // DATE RANGE PICKER
  // ═════════════════════════════════════════════════════════════════════════

  void _pickDateRange(BuildContext context, ControllerSalesReport controller) async {
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

// ═══════════════════════════════════════════════════════════════════════════
// SUMMARY CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final SummaryCardData data;

  const _SummaryCard({required this.data});

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
                  data.label.tr,
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
