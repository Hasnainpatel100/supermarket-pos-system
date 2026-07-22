import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../widget/my_card.dart';
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
          // 2. DATE FILTER CHIP BAR
          // ═══════════════════════════════════════════════════════════════
          _buildDateChips(context, controller),

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
          // 6. PAGINATION
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
  // HEADER
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, ControllerSalesReport controller) {
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
                'Sales Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.grey.shade800,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 10, color: Colors.indigo.shade400),
                    const SizedBox(width: 4),
                    Text(
                      controller.formatDateRange(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
                    ),
                  ],
                ),
              )),
            ],
          ),

          const Spacer(),

          // Report Type Dropdown
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SalesReportType>(
                value: controller.rxReportType.value,
                isDense: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo.shade400),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                items: SalesReportType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, size: 16, color: Colors.indigo.shade400),
                      const SizedBox(width: 8),
                      Text(t.label),
                    ],
                  ),
                )).toList(),
                onChanged: (v) {
                  if (v != null) controller.setReportType(v);
                },
              ),
            ),
          )),

          const SizedBox(width: 10),

          // Refresh
          _headerAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            color: Colors.indigo.shade600,
            onTap: controller.loadData,
          ),

          const SizedBox(width: 6),

          // Export Excel
          _exportButton(
            icon: Icons.table_chart_rounded,
            label: 'Excel',
            color: Colors.green.shade600,
            bgColor: Colors.green.shade50,
            borderColor: Colors.green.shade200,
            onTap: controller.exportExcel,
          ),

          const SizedBox(width: 6),

          // Export PDF
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
  // DATE FILTER CHIPS
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildDateChips(BuildContext context, ControllerSalesReport controller) {
    return Obx(() {
      final selected = controller.rxDateFilter.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _dateChip(
              label: 'Today',
              icon: Icons.today_rounded,
              isSelected: selected == SalesDateFilter.today,
              onTap: () => controller.setDateFilter(SalesDateFilter.today),
            ),
            const SizedBox(width: 8),
            _dateChip(
              label: 'Yesterday',
              icon: Icons.event_rounded,
              isSelected: selected == SalesDateFilter.yesterday,
              onTap: () => controller.setDateFilter(SalesDateFilter.yesterday),
            ),
            const SizedBox(width: 8),
            _dateChip(
              label: 'This Week',
              icon: Icons.date_range_rounded,
              isSelected: selected == SalesDateFilter.thisWeek,
              onTap: () => controller.setDateFilter(SalesDateFilter.thisWeek),
            ),
            const SizedBox(width: 8),
            _dateChip(
              label: 'This Month',
              icon: Icons.calendar_month_rounded,
              isSelected: selected == SalesDateFilter.thisMonth,
              onTap: () => controller.setDateFilter(SalesDateFilter.thisMonth),
            ),
            const SizedBox(width: 8),
            _dateChip(
              label: 'Custom',
              icon: Icons.edit_calendar_rounded,
              isSelected: selected == SalesDateFilter.custom,
              onTap: () => _pickDateRange(context, controller),
            ),
          ],
        ),
      );
    });
  }

  Widget _dateChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
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
          children: cards.map((c) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: cards.last == c ? 0 : 10,
                ),
                child: _SummaryCard(data: c),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SEARCH + BRANCH
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSearchRow(BuildContext context, ControllerSalesReport controller) {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
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
    return switch (type) {
      SalesReportType.salesSummary => rows.map((r) {
        final row = r as SalesSummaryRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo.shade600))),
          DataCell(_badge(row.orders.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.totalSales), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataCell(Text(currFmt.format(row.discount), style: TextStyle(fontSize: 13, color: Colors.orange.shade700))),
          DataCell(Text(currFmt.format(row.tax), style: TextStyle(fontSize: 13, color: Colors.purple.shade600))),
          DataCell(Text(currFmt.format(row.netSales), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade700))),
        ]);
      }).toList(),

      SalesReportType.salesDetail => rows.map((r) {
        final row = r as SalesDetailRow;
        return DataRow(cells: [
          DataCell(Text(row.dateTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.indigo.shade600))),
          DataCell(_billNoBadge(row.billNo)),
          DataCell(Text(row.customer, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_paymentBadge(row.payment)),
          DataCell(_badge(row.items.toString(), Colors.orange)),
          DataCell(Text(currFmt.format(row.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataCell(_statusBadge(row.status)),
        ]);
      }).toList(),

      SalesReportType.itemSales => rows.map((r) {
        final row = r as ItemSalesRow;
        return DataRow(cells: [
          DataCell(Text(row.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(row.barcode, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
          DataCell(Text(row.unit, style: TextStyle(fontSize: 13, color: Colors.teal.shade600))),
          DataCell(_badge(row.qtySold.toString(), Colors.green)),
          DataCell(Text(currFmt.format(row.revenue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataCell(Text(currFmt.format(row.avgPrice), style: TextStyle(fontSize: 13, color: Colors.purple.shade600))),
        ]);
      }).toList(),

      SalesReportType.categorySales => rows.map((r) {
        final row = r as CategorySalesRow;
        return DataRow(cells: [
          DataCell(Text(row.category, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_badge(row.itemCount.toString(), Colors.blue)),
          DataCell(_badge(row.qtySold.toString(), Colors.green)),
          DataCell(Text(currFmt.format(row.revenue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataCell(_percentBar(row.percentOfTotal)),
        ]);
      }).toList(),

      SalesReportType.paymentReport => rows.map((r) {
        final row = r as PaymentReportRow;
        return DataRow(cells: [
          DataCell(_paymentBadge(row.paymentMode)),
          DataCell(_badge(row.transactions.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
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
            DataCell(Text(row.hourSlot, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo.shade600))),
            DataCell(_badge(row.orders.toString(), Colors.blue)),
            DataCell(Text(currFmt.format(row.totalSales), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            DataCell(Text(currFmt.format(row.avgBill), style: TextStyle(fontSize: 13, color: Colors.orange.shade700))),
            DataCell(row.isPeak
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade400]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        const Text('PEAK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  )
                : Text('—', style: TextStyle(color: Colors.grey.shade400)),
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
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _billNoBadge(String billNo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text('#$billNo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
    );
  }

  Widget _paymentBadge(String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Text(mode, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.teal.shade700)),
    );
  }

  Widget _statusBadge(String status) {
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
                BoxShadow(color: Colors.indigo.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.assessment_outlined, size: 64, color: Colors.indigo.shade400),
          ),
          const SizedBox(height: 16),
          Text('No data found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text('Try adjusting the date range or report type', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PAGINATION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildPagination(ControllerSalesReport controller) {
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
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
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
