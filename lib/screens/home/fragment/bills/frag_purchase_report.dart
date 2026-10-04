import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../widget/my_card.dart';
import '../../../../widget/report_date_filter_dropdown.dart';
import 'controller_purchase_report.dart';

class FragPurchaseReport extends StatelessWidget {
  final PurchaseReportType? initialReportType;

  const FragPurchaseReport({super.key, this.initialReportType});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerPurchaseReport>()
        ? Get.find<ControllerPurchaseReport>()
        : Get.put(ControllerPurchaseReport());

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

  Widget _buildHeader(BuildContext context, ControllerPurchaseReport controller) {
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
                colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'purchase_reports'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colorScheme.onSurface,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.purple.withValues(alpha: 0.18) : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? Colors.purple.withValues(alpha: 0.35) : Colors.purple.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 10, color: Colors.purple.shade400),
                    const SizedBox(width: 4),
                    Text(
                      controller.formatDateRange(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.purple.shade200 : Colors.purple.shade700),
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
            themeColor: Colors.purple.shade600,
          )),

          const SizedBox(width: 10),

          // Refresh
          _headerAction(
            context,
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            color: Colors.purple.shade600,
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
            const SizedBox(width: 6),
            _exportButton(
              context,
              icon: Icons.bolt_rounded,
              label: '+ 30k Purchases',
              color: Colors.deepPurple.shade700,
              bgColor: Colors.deepPurple.shade50,
              borderColor: Colors.deepPurple.shade200,
              onTap: controller.seed30kTestPurchases,
            ),
            const SizedBox(width: 6),
            _exportButton(
              context,
              icon: Icons.delete_sweep_rounded,
              label: 'Clear Seeded',
              color: Colors.red.shade700,
              bgColor: Colors.red.shade50,
              borderColor: Colors.red.shade200,
              onTap: controller.clearSeededPurchases,
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

  Widget _buildReportTypeBar(BuildContext context, ControllerPurchaseReport controller) {
    return Obx(() {
      final selected = controller.rxReportType.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: PurchaseReportType.values.map((type) {
            final isSelected = selected == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _reportTypeChip(
                context,
                label: type.label,
                icon: type.icon,
                isSelected: isSelected,
                primaryColor: Colors.purple.shade600,
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

  Widget _buildSummaryCards(ControllerPurchaseReport controller) {
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
                child: _PurchaseSummaryCard(data: c),
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

  Widget _buildSearchRow(BuildContext context, ControllerPurchaseReport controller) {
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
                  hintText: 'Search purchases by PO, supplier, or item...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.purple.shade600),
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
                Icon(Icons.warehouse_outlined, size: 16, color: Colors.purple.shade600),
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
    ControllerPurchaseReport controller,
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

  List<DataColumn> _columnsFor(PurchaseReportType type, BuildContext context) {
    return switch (type) {
      PurchaseReportType.purchaseSummary => [
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Purchase No', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Supplier', Icons.local_shipping_rounded, Colors.orange),
        _col(context, 'Total Amount', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Paid Amount', Icons.check_circle_outline_rounded, Colors.teal),
        _col(context, 'Outstanding', Icons.warning_amber_rounded, Colors.red),
        _col(context, 'Status', Icons.toggle_on_rounded, Colors.purple),
      ],
      PurchaseReportType.purchaseDetail => [
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Purchase No', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Supplier', Icons.local_shipping_rounded, Colors.orange),
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.teal),
        _col(context, 'Quantity', Icons.unfold_more_rounded, Colors.purple),
        _col(context, 'Unit Cost', Icons.attach_money_rounded, Colors.red),
        _col(context, 'Total Value', Icons.monetization_on_rounded, Colors.green),
      ],
      PurchaseReportType.supplierPurchase => [
        _col(context, 'Supplier Name', Icons.local_shipping_rounded, Colors.indigo),
        _col(context, 'Bills Count', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Qty Purchased', Icons.unfold_more_rounded, Colors.teal),
        _col(context, 'Total Purchase', Icons.monetization_on_rounded, Colors.green),
        _col(context, 'Paid Amount', Icons.check_circle_outline_rounded, Colors.purple),
        _col(context, 'Outstanding Balance', Icons.warning_amber_rounded, Colors.red),
      ],
      PurchaseReportType.pendingPurchaseOrders => [
        _col(context, 'Order Date', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'PO Number', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Supplier', Icons.local_shipping_rounded, Colors.orange),
        _col(context, 'Expected Date', Icons.event_available_rounded, Colors.teal),
        _col(context, 'Ordered Qty', Icons.unfold_more_rounded, Colors.blue),
        _col(context, 'Received Qty', Icons.check_circle_outline_rounded, Colors.green),
        _col(context, 'Pending Qty', Icons.warning_amber_rounded, Colors.red),
        _col(context, 'Status', Icons.toggle_on_rounded, Colors.purple),
      ],
      PurchaseReportType.purchaseReturn => [
        _col(context, 'Return No', Icons.receipt_rounded, Colors.indigo),
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.blue),
        _col(context, 'Supplier', Icons.local_shipping_rounded, Colors.orange),
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.teal),
        _col(context, 'Qty Returned', Icons.remove_circle_outline_rounded, Colors.red),
        _col(context, 'Return Amount', Icons.attach_money_rounded, Colors.pink),
        _col(context, 'Return Reason', Icons.question_answer_rounded, Colors.purple),
      ],
    };
  }

  List<DataRow> _rowsFor(
    PurchaseReportType type,
    ControllerPurchaseReport controller,
    BuildContext context,
    NumberFormat currFmt,
    ColorScheme colorScheme,
  ) {
    final rows = controller.rxRows;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (type) {
      PurchaseReportType.purchaseSummary => rows.map((r) {
        final row = r as PurchaseSummaryRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.indigo.shade600))),
          DataCell(_poBadge(context, row.purchaseNo)),
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(Text(currFmt.format(row.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.paidAmount), style: TextStyle(fontSize: 13, color: isDark ? Colors.green.shade300 : Colors.green.shade700))),
          DataCell(Text(currFmt.format(row.outstandingAmount), style: TextStyle(fontSize: 13, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fontWeight: FontWeight.bold))),
          DataCell(_statusBadge(row.status)),
        ]);
      }).toList(),

      PurchaseReportType.purchaseDetail => rows.map((r) {
        final row = r as PurchaseDetailRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.9) : null))),
          DataCell(_poBadge(context, row.purchaseNo)),
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(Text(row.itemName, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(_badge(context, row.quantity.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.costPrice), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.totalValue), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
        ]);
      }).toList(),

      PurchaseReportType.supplierPurchase => rows.map((r) {
        final row = r as SupplierPurchaseRow;
        return DataRow(cells: [
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(_badge(context, row.numBills.toString(), Colors.blue)),
          DataCell(_badge(context, row.qtyPurchased.toString(), Colors.green)),
          DataCell(Text(currFmt.format(row.totalPurchaseAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(currFmt.format(row.paidAmount), style: TextStyle(fontSize: 13, color: isDark ? Colors.green.shade300 : Colors.green.shade700))),
          DataCell(Text(currFmt.format(row.outstandingBalance), style: TextStyle(fontSize: 13, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fontWeight: FontWeight.bold))),
        ]);
      }).toList(),

      PurchaseReportType.pendingPurchaseOrders => rows.map((r) {
        final row = r as PendingPurchaseOrderRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.9) : null))),
          DataCell(_poBadge(context, row.purchaseNo)),
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(Text(row.expectedDate, style: TextStyle(fontSize: 13, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700, fontWeight: FontWeight.w500))),
          DataCell(Text(row.orderedQty.toString(), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(row.receivedQty.toString(), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(_badge(context, row.pendingQty.toString(), Colors.red)),
          DataCell(_statusBadge(row.status)),
        ]);
      }).toList(),

      PurchaseReportType.purchaseReturn => rows.map((r) {
        final row = r as PurchaseReturnRow;
        return DataRow(cells: [
          DataCell(_poBadge(context, row.returnNo)),
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.9) : null))),
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : colorScheme.onSurface))),
          DataCell(Text(row.itemName, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(_badge(context, row.quantityReturned.toString(), Colors.red)),
          DataCell(Text(currFmt.format(row.returnAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : null))),
          DataCell(Text(row.returnReason, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))),
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
          Text(label.tr, style: TextStyle(color: isDark ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _poBadge(BuildContext context, String purchaseNo) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? colorScheme.outlineVariant : Colors.grey.shade300),
      ),
      child: Text(purchaseNo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
    );
  }

  Widget _statusBadge(String status) {
    final MaterialColor color = switch (status) {
      'RECEIVED' => Colors.green,
      'ORDERED' => Colors.blue,
      'PARTIAL' => Colors.orange,
      'CANCELLED' => Colors.red,
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
                colors: [Colors.purple.shade100, Colors.deepPurple.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.purple.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.purple.shade400),
          ),
          const SizedBox(height: 16),
          Text('No purchase records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text('Try adjusting the date range or filters', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ControllerPurchaseReport controller) {
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
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.purple.shade300 : Colors.purple.shade700),
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

  void _pickDateRange(BuildContext context, ControllerPurchaseReport controller) async {
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
// _PurchaseSummaryCard
// ═══════════════════════════════════════════════════════════════════════════

class _PurchaseSummaryCard extends StatelessWidget {
  final PurchaseSummaryCardData data;

  const _PurchaseSummaryCard({required this.data});

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
