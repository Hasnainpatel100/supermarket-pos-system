import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../widget/my_card.dart';
import 'controller_home_reports.dart';

class FragHomeReport extends StatelessWidget {
  const FragHomeReport({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerHomeReports>()
        ? Get.find<ControllerHomeReports>()
        : Get.put(ControllerHomeReports());
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════
          // ── Header ──
          // ═══════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.indigo.shade600],
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
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 10,
                              color: Colors.teal.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              controller.formatDateRange(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Obx(() => controller.rxIsLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════════════
          // ── Filter Bar ──
          // ═══════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MyCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Report Type dropdown
                  SizedBox(
                    width: 200,
                    child: Obx(
                      () => DropdownButtonFormField<ReportType>(
                        value: controller.rxReportType.value,
                        decoration: InputDecoration(
                          labelText: 'Report Type',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.teal.shade400, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        items: ReportType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.rxReportType.value = v;
                        },
                      ),
                    ),
                  ),

                  // Start Date
                  _DatePickerButton(
                    label: 'From',
                    dateRx: controller.rxStartDate,
                    colorScheme: colorScheme,
                  ),

                  // End Date
                  _DatePickerButton(
                    label: 'To',
                    dateRx: controller.rxEndDate,
                    colorScheme: colorScheme,
                  ),

                  // Generate button
                  FilledButton.icon(
                    onPressed: controller.generateReport,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Generate'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Reset button
                  OutlinedButton.icon(
                    onPressed: controller.resetFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ═══════════════════════════════════════════════════════════
          // ── Action Bar (Export / Print) ──
          // ═══════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Obx(() => Text(
                      '${controller.rxRows.length} records',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    )),
                const Spacer(),
                _ActionChip(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Export PDF',
                  color: Colors.red.shade600,
                  onTap: controller.exportPdf,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.table_chart_rounded,
                  label: 'Export Excel',
                  color: Colors.green.shade700,
                  onTap: controller.exportExcel,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.print_rounded,
                  label: 'Print',
                  color: Colors.indigo.shade600,
                  onTap: controller.printReport,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ═══════════════════════════════════════════════════════════
          // ── Data Table ──
          // ═══════════════════════════════════════════════════════════
          Expanded(
            child: Obx(() {
              if (controller.rxRows.isEmpty && !controller.rxIsLoading.value) {
                return _buildEmpty();
              }

              final cols = controller.columns;
              final currFmt = currencyFormat;

              return MyCard(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16,
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
                      dataRowMaxHeight: 48,
                      columns: cols
                          .map((c) => _buildColumn(context, c.value, _iconForColumn(c.key), _colorForColumn(c.key)))
                          .toList(),
                      rows: controller.rxRows.map((row) {
                        return DataRow(
                          cells: cols.map((c) {
                            final val = row[c.key];
                            if (val is double) {
                              return DataCell(Text(
                                currFmt.format(val),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ));
                            }
                            if (val is int) {
                              return DataCell(Text(
                                val.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ));
                            }
                            return DataCell(Text(
                              val?.toString() ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            }),
          ),

          // ═══════════════════════════════════════════════════════════
          // ── Summary Footer ──
          // ═══════════════════════════════════════════════════════════
          Obx(() {
            if (controller.rxRows.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.shade50,
                    Colors.indigo.shade50,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: 'Bills',
                    value: '${controller.rxTotalBills.value}',
                    icon: Icons.receipt_rounded,
                    color: Colors.indigo,
                  ),
                  _SummaryItem(
                    label: 'Quantity',
                    value: '${controller.rxTotalQty.value}',
                    icon: Icons.inventory_2_rounded,
                    color: Colors.blue,
                  ),
                  _SummaryItem(
                    label: 'Gross Amount',
                    value: currencyFormat.format(controller.rxGrossAmount.value),
                    icon: Icons.attach_money_rounded,
                    color: Colors.orange,
                  ),
                  _SummaryItem(
                    label: 'Discount',
                    value: currencyFormat.format(controller.rxDiscount.value),
                    icon: Icons.local_offer_rounded,
                    color: Colors.pink,
                  ),
                  _SummaryItem(
                    label: 'Tax',
                    value: currencyFormat.format(controller.rxTax.value),
                    icon: Icons.account_balance_rounded,
                    color: Colors.amber.shade800,
                  ),
                  _SummaryItem(
                    label: 'Net Amount',
                    value: currencyFormat.format(controller.rxNetAmount.value),
                    icon: Icons.trending_up_rounded,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Empty state ──

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade100, Colors.indigo.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.bar_chart_rounded, size: 64, color: Colors.teal.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No report data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select a report type, date range and click Generate',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Column builder (matching Bills screen pattern) ──

  DataColumn _buildColumn(BuildContext context, String label, IconData icon, Color color) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color.withOpacity(0.8)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Icon / color for column keys ──

  IconData _iconForColumn(String key) {
    switch (key) {
      case 'date':
      case 'week':
      case 'month':
      case 'year':
      case 'hour':
        return Icons.calendar_today_rounded;
      case 'bills':
        return Icons.receipt_rounded;
      case 'qty':
      case 'itemsSold':
        return Icons.inventory_2_rounded;
      case 'gross':
        return Icons.attach_money_rounded;
      case 'discount':
        return Icons.local_offer_rounded;
      case 'tax':
        return Icons.account_balance_rounded;
      case 'net':
        return Icons.trending_up_rounded;
      case 'cashier':
        return Icons.person_rounded;
      case 'customer':
        return Icons.people_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'item':
        return Icons.widgets_rounded;
      case 'barcode':
        return Icons.qr_code_rounded;
      case 'method':
        return Icons.payment_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _colorForColumn(String key) {
    switch (key) {
      case 'date':
      case 'week':
      case 'month':
      case 'year':
      case 'hour':
        return Colors.indigo;
      case 'bills':
        return Colors.blue;
      case 'qty':
      case 'itemsSold':
        return Colors.purple;
      case 'gross':
        return Colors.orange;
      case 'discount':
        return Colors.pink;
      case 'tax':
        return Colors.amber.shade800;
      case 'net':
        return Colors.green;
      case 'cashier':
      case 'customer':
      case 'phone':
        return Colors.teal;
      case 'category':
        return Colors.deepPurple;
      case 'item':
      case 'barcode':
        return Colors.brown;
      case 'method':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// ── Reusable private widgets ──
// ═══════════════════════════════════════════════════════════

/// Compact date picker button used in the filter bar.
class _DatePickerButton extends StatelessWidget {
  final String label;
  final Rx<DateTime> dateRx;
  final ColorScheme colorScheme;

  const _DatePickerButton({
    required this.label,
    required this.dateRx,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fmt = DateFormat('dd MMM yyyy');
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: dateRx.value,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 1)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: colorScheme.copyWith(
                    primary: Colors.teal.shade600,
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) dateRx.value = picked;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade50,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: Colors.teal.shade400),
              const SizedBox(width: 6),
              Text(
                '$label: ${fmt.format(dateRx.value)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Action chip for export / print buttons.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary footer item with icon, label, and value.
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
