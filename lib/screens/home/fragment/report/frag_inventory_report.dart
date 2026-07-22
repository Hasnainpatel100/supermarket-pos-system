import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../widget/my_card.dart';
import 'controller_inventory_report.dart';

class FragInventoryReport extends StatelessWidget {
  final InventoryReportType? initialReportType;

  const FragInventoryReport({super.key, this.initialReportType});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerInventoryReport>()
        ? Get.find<ControllerInventoryReport>()
        : Get.put(ControllerInventoryReport());

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
          // 2. CONTEXTUAL FILTERS (Date Range or Expiry/Low Stock Thresholds)
          // ═══════════════════════════════════════════════════════════════
          _buildFilterBar(context, controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 3. SUMMARY STATS CARDS
          // ═══════════════════════════════════════════════════════════════
          _buildSummaryCards(controller),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // 4. SEARCH + WAREHOUSE
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
  // Header Widget
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, ControllerInventoryReport controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.inventory_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.grey.shade800,
                ),
              ),
              Obx(() => Text(
                controller.rxReportType.value.label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
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
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<InventoryReportType>(
                value: controller.rxReportType.value,
                isDense: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.orange.shade600),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                items: InventoryReportType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, size: 16, color: Colors.orange.shade600),
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
            tooltip: 'Refresh Data',
            color: Colors.orange.shade600,
            onTap: controller.loadData,
          ),

          const SizedBox(width: 6),

          // Excel Export
          _exportButton(
            icon: Icons.table_chart_rounded,
            label: 'Excel',
            color: Colors.green.shade600,
            bgColor: Colors.green.shade50,
            borderColor: Colors.green.shade200,
            onTap: controller.exportExcel,
          ),

          const SizedBox(width: 6),

          // PDF Export
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
  // Contextual Filter Bar
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildFilterBar(BuildContext context, ControllerInventoryReport controller) {
    return Obx(() {
      final type = controller.rxReportType.value;

      // Render date picker range only for movement and adjustments
      final isDateReport = type == InventoryReportType.stockMovement ||
          type == InventoryReportType.stockAdjustment;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (isDateReport) ...[
              GestureDetector(
                onTap: () => _pickDateRange(context, controller),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        controller.formatDateRange(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Placeholder when date range is not required
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'Snapshot Report (Realtime)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Context-specific threshold filter for Near Expiry
            if (type == InventoryReportType.nearExpiry) ...[
              Text(
                'Days Remaining: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.rxExpiryThresholdDays.value,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 Days')),
                      DropdownMenuItem(value: 30, child: Text('30 Days')),
                      DropdownMenuItem(value: 60, child: Text('60 Days')),
                      DropdownMenuItem(value: 90, child: Text('90 Days')),
                      DropdownMenuItem(value: 180, child: Text('180 Days')),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.setExpiryThresholdDays(val);
                    },
                  ),
                ),
              ),
            ],

            // Context-specific threshold filter for Low Stock
            if (type == InventoryReportType.lowStock) ...[
              Text(
                'Reorder Threshold: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.rxLowStockThreshold.value,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('< 5 units')),
                      DropdownMenuItem(value: 10, child: Text('< 10 units')),
                      DropdownMenuItem(value: 20, child: Text('< 20 units')),
                      DropdownMenuItem(value: 50, child: Text('< 50 units')),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.setLowStockThreshold(val);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Summary Stats Row
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(ControllerInventoryReport controller) {
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
                child: _InventorySummaryCard(data: c),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Search and Location filter
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSearchRow(BuildContext context, ControllerInventoryReport controller) {
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
                  hintText: 'Search items by name, SKU or barcode...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.orange.shade600),
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
                Icon(Icons.warehouse_outlined, size: 16, color: Colors.orange.shade600),
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
  // Dynamic DataTable
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildDataTable(
    BuildContext context,
    ControllerInventoryReport controller,
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

  List<DataColumn> _columnsFor(InventoryReportType type, BuildContext context) {
    return switch (type) {
      InventoryReportType.currentStock => [
        _col(context, 'SKU/Barcode', Icons.qr_code_rounded, Colors.indigo),
        _col(context, 'Name', Icons.inventory_2_rounded, Colors.orange),
        _col(context, 'Category', Icons.category_rounded, Colors.blue),
        _col(context, 'Unit', Icons.straighten_rounded, Colors.teal),
        _col(context, 'Quantity', Icons.unfold_more_rounded, Colors.green),
        _col(context, 'Cost Price', Icons.attach_money_rounded, Colors.purple),
        _col(context, 'Selling Price', Icons.monetization_on_rounded, Colors.pink),
        _col(context, 'Stock Value', Icons.account_balance_rounded, Colors.amber),
      ],
      InventoryReportType.lowStock => [
        _col(context, 'SKU/Barcode', Icons.qr_code_rounded, Colors.indigo),
        _col(context, 'Name', Icons.inventory_2_rounded, Colors.orange),
        _col(context, 'Category', Icons.category_rounded, Colors.blue),
        _col(context, 'Current Qty', Icons.warning_amber_rounded, Colors.red),
        _col(context, 'Reorder Level', Icons.flag_rounded, Colors.teal),
        _col(context, 'Shortage', Icons.trending_down_rounded, Colors.pink),
      ],
      InventoryReportType.outOfStock => [
        _col(context, 'SKU/Barcode', Icons.qr_code_rounded, Colors.indigo),
        _col(context, 'Name', Icons.inventory_2_rounded, Colors.orange),
        _col(context, 'Category', Icons.category_rounded, Colors.blue),
        _col(context, 'Cost Price', Icons.attach_money_rounded, Colors.purple),
        _col(context, 'Last Purchase', Icons.local_shipping_rounded, Colors.green),
        _col(context, 'Last Sale', Icons.shopping_cart_rounded, Colors.pink),
      ],
      InventoryReportType.stockMovement => [
        _col(context, 'Date & Time', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.orange),
        _col(context, 'Type', Icons.swap_horiz_rounded, Colors.blue),
        _col(context, 'Quantity', Icons.unfold_more_rounded, Colors.green),
        _col(context, 'Performed By', Icons.person_rounded, Colors.purple),
        _col(context, 'Reference/Remarks', Icons.receipt_long_rounded, Colors.teal),
      ],
      InventoryReportType.stockAdjustment => [
        _col(context, 'Date & Time', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.orange),
        _col(context, 'Prev Qty', Icons.unfold_more_rounded, Colors.grey),
        _col(context, 'New Qty', Icons.unfold_more_rounded, Colors.blue),
        _col(context, 'Difference', Icons.warning_amber_rounded, Colors.red),
        _col(context, 'Reason', Icons.question_answer_rounded, Colors.teal),
        _col(context, 'User', Icons.person_rounded, Colors.purple),
      ],
      InventoryReportType.stockValuation => [
        _col(context, 'SKU/Barcode', Icons.qr_code_rounded, Colors.indigo),
        _col(context, 'Name', Icons.inventory_2_rounded, Colors.orange),
        _col(context, 'Quantity', Icons.unfold_more_rounded, Colors.blue),
        _col(context, 'Cost Price', Icons.attach_money_rounded, Colors.purple),
        _col(context, 'Selling Price', Icons.monetization_on_rounded, Colors.pink),
        _col(context, 'Cost Value', Icons.account_balance_rounded, Colors.teal),
        _col(context, 'Selling Value', Icons.monetization_on_rounded, Colors.amber),
        _col(context, 'Expected Profit', Icons.trending_up_rounded, Colors.green),
      ],
      InventoryReportType.expiry => [
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.indigo),
        _col(context, 'Batch No', Icons.qr_code_rounded, Colors.orange),
        _col(context, 'Expiry Date', Icons.event_busy_rounded, Colors.red),
        _col(context, 'Quantity', Icons.unfold_more_rounded, Colors.blue),
        _col(context, 'Days Expired', Icons.timer_rounded, Colors.pink),
      ],
      InventoryReportType.nearExpiry => [
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.indigo),
        _col(context, 'Batch No', Icons.qr_code_rounded, Colors.orange),
        _col(context, 'Expiry Date', Icons.event_available_rounded, Colors.green),
        _col(context, 'Quantity', Icons.unfold_more_rounded, Colors.blue),
        _col(context, 'Days Remaining', Icons.timer_rounded, Colors.pink),
      ],
    };
  }

  List<DataRow> _rowsFor(
    InventoryReportType type,
    ControllerInventoryReport controller,
    BuildContext context,
    NumberFormat currFmt,
    ColorScheme colorScheme,
  ) {
    final rows = controller.rxRows;
    return switch (type) {
      InventoryReportType.currentStock => rows.map((r) {
        final row = r as CurrentStockRow;
        return DataRow(cells: [
          DataCell(_skuBadge(row.sku)),
          DataCell(Text(row.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(row.category, style: const TextStyle(fontSize: 13))),
          DataCell(Text(row.unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
          DataCell(_badge(row.quantity.toString(), Colors.green)),
          DataCell(Text(currFmt.format(row.costPrice), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.sellingPrice), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.stockValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ]);
      }).toList(),

      InventoryReportType.lowStock => rows.map((r) {
        final row = r as LowStockRow;
        return DataRow(cells: [
          DataCell(_skuBadge(row.sku)),
          DataCell(Text(row.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(row.category, style: const TextStyle(fontSize: 13))),
          DataCell(_badge(row.quantity.toString(), Colors.red)),
          DataCell(_badge(row.reorderLevel.toString(), Colors.teal)),
          DataCell(_badge(row.shortage.toString(), Colors.pink)),
        ]);
      }).toList(),

      InventoryReportType.outOfStock => rows.map((r) {
        final row = r as OutOfStockRow;
        return DataRow(cells: [
          DataCell(_skuBadge(row.sku)),
          DataCell(Text(row.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(row.category, style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.costPrice), style: const TextStyle(fontSize: 13))),
          DataCell(Text(row.lastPurchaseInfo, style: const TextStyle(fontSize: 12, color: Colors.green))),
          DataCell(Text(row.lastSaleInfo, style: const TextStyle(fontSize: 12, color: Colors.pink))),
        ]);
      }).toList(),

      InventoryReportType.stockMovement => rows.map((r) {
        final row = r as StockMovementRow;
        final isPositive = row.quantity > 0;
        return DataRow(cells: [
          DataCell(Text(row.dateTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.indigo.shade600))),
          DataCell(Text(row.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_movementTypeBadge(row.txnType)),
          DataCell(_badge(isPositive ? '+${row.quantity}' : '${row.quantity}', isPositive ? Colors.green : Colors.red)),
          DataCell(Text(row.performedBy, style: const TextStyle(fontSize: 13))),
          DataCell(Text(row.reference, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
        ]);
      }).toList(),

      InventoryReportType.stockAdjustment => rows.map((r) {
        final row = r as StockAdjustmentRow;
        final isPositive = row.difference > 0;
        return DataRow(cells: [
          DataCell(Text(row.dateTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.indigo.shade600))),
          DataCell(Text(row.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(row.previousQty.toString(), style: const TextStyle(fontSize: 13))),
          DataCell(Text(row.newQty.toString(), style: const TextStyle(fontSize: 13))),
          DataCell(_badge(isPositive ? '+${row.difference}' : '${row.difference}', isPositive ? Colors.green : Colors.red)),
          DataCell(Text(row.reason, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          DataCell(Text(row.user, style: const TextStyle(fontSize: 13))),
        ]);
      }).toList(),

      InventoryReportType.stockValuation => rows.map((r) {
        final row = r as StockValuationRow;
        return DataRow(cells: [
          DataCell(_skuBadge(row.sku)),
          DataCell(Text(row.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_badge(row.quantity.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.costPrice), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.sellingPrice), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.costValue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
          DataCell(Text(currFmt.format(row.sellingValue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
          DataCell(Text(currFmt.format(row.expectedProfit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade700))),
        ]);
      }).toList(),

      InventoryReportType.expiry => rows.map((r) {
        final row = r as ExpiryRow;
        return DataRow(cells: [
          DataCell(Text(row.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_skuBadge(row.batchNo)),
          DataCell(Text(row.expiryDate, style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600))),
          DataCell(_badge(row.quantity.toString(), Colors.red)),
          DataCell(_badge('${row.daysExpired} days ago', Colors.pink)),
        ]);
      }).toList(),

      InventoryReportType.nearExpiry => rows.map((r) {
        final row = r as NearExpiryRow;
        return DataRow(cells: [
          DataCell(Text(row.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_skuBadge(row.batchNo)),
          DataCell(Text(row.expiryDate, style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600))),
          DataCell(_badge(row.quantity.toString(), Colors.blue)),
          DataCell(_badge('${row.daysRemaining} days left', Colors.orange)),
        ]);
      }).toList(),
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Cell Components
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

  Widget _movementTypeBadge(String type) {
    final MaterialColor color = switch (type.toLowerCase()) {
      'sell' => Colors.red,
      'purchasein' => Colors.green,
      'add' => Colors.blue,
      'deduct' => Colors.purple,
      'adjust' => Colors.orange,
      'returnstock' => Colors.teal,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.shade700)),
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
                colors: [Colors.orange.shade100, Colors.deepOrange.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.orange.shade400),
          ),
          const SizedBox(height: 16),
          Text('No inventory records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text('Try adjusting filters or report types', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildPagination(ControllerInventoryReport controller) {
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
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

  void _pickDateRange(BuildContext context, ControllerInventoryReport controller) async {
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
// _InventorySummaryCard
// ═══════════════════════════════════════════════════════════════════════════

class _InventorySummaryCard extends StatelessWidget {
  final InventorySummaryCardData data;

  const _InventorySummaryCard({required this.data});

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
