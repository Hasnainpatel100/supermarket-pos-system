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

  Widget _buildHeader(BuildContext context, ControllerPurchaseReport controller) {
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
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchase Reports',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.grey.shade800,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 10, color: Colors.purple.shade400),
                    const SizedBox(width: 4),
                    Text(
                      controller.formatDateRange(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple.shade700),
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
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            color: Colors.purple.shade600,
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
  // Search and Location
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSearchRow(BuildContext context, ControllerPurchaseReport controller) {
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
                  hintText: 'Search purchase orders...',
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
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping_outlined, size: 16, color: Colors.purple.shade600),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: controller.rxSelectedSupplierId.value,
                    isDense: true,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Suppliers'),
                      ),
                      ...controller.rxSuppliersList.map((supplier) => DropdownMenuItem<int?>(
                        value: supplier.id,
                        child: Text(supplier.name ?? 'Supplier'),
                      )),
                    ],
                    onChanged: (val) {
                      controller.setSelectedSupplier(val);
                    },
                  ),
                ),
              ],
            ),
          )),
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
                Icon(Icons.warehouse_outlined, size: 16, color: Colors.purple.shade600),
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
    ControllerPurchaseReport controller,
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

  List<DataColumn> _columnsFor(PurchaseReportType type, BuildContext context) {
    return switch (type) {
      PurchaseReportType.purchaseSummary => [
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Purchase No', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Supplier', Icons.local_shipping_rounded, Colors.orange),
        _col(context, 'Total Amount', Icons.attach_money_rounded, Colors.green),
        _col(context, 'Paid Amount', Icons.check_circle_outline_rounded, Colors.teal),
        _col(context, 'Outstanding Due', Icons.pending_actions_rounded, Colors.red),
        _col(context, 'Status', Icons.toggle_on_rounded, Colors.purple),
      ],
      PurchaseReportType.purchaseDetail => [
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'Purchase No', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Supplier', Icons.local_shipping_rounded, Colors.orange),
        _col(context, 'Item Name', Icons.inventory_2_rounded, Colors.teal),
        _col(context, 'Order Qty', Icons.unfold_more_rounded, Colors.green),
        _col(context, 'Cost Price', Icons.attach_money_rounded, Colors.purple),
        _col(context, 'Total Value', Icons.monetization_on_rounded, Colors.pink),
      ],
      PurchaseReportType.supplierPurchase => [
        _col(context, 'Supplier Name', Icons.local_shipping_rounded, Colors.indigo),
        _col(context, 'No. of Bills', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Qty Purchased', Icons.inventory_2_rounded, Colors.green),
        _col(context, 'Total Purchase', Icons.attach_money_rounded, Colors.orange),
        _col(context, 'Paid Amount', Icons.check_circle_outline_rounded, Colors.teal),
        _col(context, 'Outstanding Balance', Icons.pending_actions_rounded, Colors.red),
      ],
      PurchaseReportType.pendingPurchaseOrders => [
        _col(context, 'Date', Icons.calendar_today_rounded, Colors.indigo),
        _col(context, 'PO Number', Icons.receipt_rounded, Colors.blue),
        _col(context, 'Supplier', Icons.local_shipping_rounded, Colors.orange),
        _col(context, 'Expected Date', Icons.date_range_rounded, Colors.teal),
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
    return switch (type) {
      PurchaseReportType.purchaseSummary => rows.map((r) {
        final row = r as PurchaseSummaryRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.indigo.shade600))),
          DataCell(_poBadge(row.purchaseNo)),
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(currFmt.format(row.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataCell(Text(currFmt.format(row.paidAmount), style: TextStyle(fontSize: 13, color: Colors.green.shade700))),
          DataCell(Text(currFmt.format(row.outstandingAmount), style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.bold))),
          DataCell(_statusBadge(row.status)),
        ]);
      }).toList(),

      PurchaseReportType.purchaseDetail => rows.map((r) {
        final row = r as PurchaseDetailRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: const TextStyle(fontSize: 13))),
          DataCell(_poBadge(row.purchaseNo)),
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(row.itemName, style: const TextStyle(fontSize: 13))),
          DataCell(_badge(row.quantity.toString(), Colors.blue)),
          DataCell(Text(currFmt.format(row.costPrice), style: const TextStyle(fontSize: 13))),
          DataCell(Text(currFmt.format(row.totalValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ]);
      }).toList(),

      PurchaseReportType.supplierPurchase => rows.map((r) {
        final row = r as SupplierPurchaseRow;
        return DataRow(cells: [
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(_badge(row.numBills.toString(), Colors.blue)),
          DataCell(_badge(row.qtyPurchased.toString(), Colors.green)),
          DataCell(Text(currFmt.format(row.totalPurchaseAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataCell(Text(currFmt.format(row.paidAmount), style: TextStyle(fontSize: 13, color: Colors.green.shade700))),
          DataCell(Text(currFmt.format(row.outstandingBalance), style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.bold))),
        ]);
      }).toList(),

      PurchaseReportType.pendingPurchaseOrders => rows.map((r) {
        final row = r as PendingPurchaseOrderRow;
        return DataRow(cells: [
          DataCell(Text(row.date, style: const TextStyle(fontSize: 13))),
          DataCell(_poBadge(row.purchaseNo)),
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(row.expectedDate, style: TextStyle(fontSize: 13, color: Colors.teal.shade700, fontWeight: FontWeight.w500))),
          DataCell(Text(row.orderedQty.toString(), style: const TextStyle(fontSize: 13))),
          DataCell(Text(row.receivedQty.toString(), style: const TextStyle(fontSize: 13))),
          DataCell(_badge(row.pendingQty.toString(), Colors.red)),
          DataCell(_statusBadge(row.status)),
        ]);
      }).toList(),

      PurchaseReportType.purchaseReturn => rows.map((r) {
        final row = r as PurchaseReturnRow;
        return DataRow(cells: [
          DataCell(_poBadge(row.returnNo)),
          DataCell(Text(row.date, style: const TextStyle(fontSize: 13))),
          DataCell(Text(row.supplierName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800))),
          DataCell(Text(row.itemName, style: const TextStyle(fontSize: 13))),
          DataCell(_badge(row.quantityReturned.toString(), Colors.red)),
          DataCell(Text(currFmt.format(row.returnAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DataCell(Text(row.returnReason, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
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

  Widget _poBadge(String purchaseNo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(purchaseNo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.shade700)),
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
                colors: [Colors.purple.shade100, Colors.deepPurple.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.purple.shade400),
          ),
          const SizedBox(height: 16),
          Text('No purchase records found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text('Try adjusting the date range or filters', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildPagination(ControllerPurchaseReport controller) {
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700),
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
