import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/stock_txn_type.dart';
import '../../../../widget/my_card.dart';
import 'controller_home_stock.dart';

class FragmentHomeStock extends StatelessWidget {
  const FragmentHomeStock({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerHomeStock());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.inventory_rounded, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Stock Ledger',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by item name or remarks...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // ── Type Filter Chips ──
          Obx(() {
            final selected = controller.rxFilterType.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    color: Colors.grey.shade600,
                    isSelected: selected == null,
                    onTap: () => controller.setTypeFilter(null),
                  ),
                  const SizedBox(width: 8),
                  ...StockTxnType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: _typeLabel(type),
                        color: _typeColor(type),
                        isSelected: selected == type,
                        onTap: () => controller.setTypeFilter(type),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Table ──
          Expanded(
            child: Obx(() {
              if (controller.rxListTxn.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          size: 56,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No stock movements yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stock changes will appear here automatically',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return MyCard(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      dataRowMaxHeight: 56,
                      columns: const [
                        DataColumn(label: Text('Date & Time')),
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Qty'), numeric: true),
                        DataColumn(label: Text('Remarks')),
                      ],
                      rows: controller.rxListTxn.map((txn) {
                        final type = _typeFromIndex(txn.type);
                        final qty = txn.quantity ?? 0;
                        final isPositive = qty > 0;

                        return DataRow(
                          cells: [
                            // Date
                            DataCell(
                              Text(
                                controller.formatDate(txn.createdAtUtcMs),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            // Item name
                            DataCell(
                              Text(
                                txn.referenceId ??
                                    controller.getItemName(txn.itemId),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Type badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _typeColor(
                                    type,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _typeColor(
                                      type,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _typeIcon(type),
                                      size: 13,
                                      color: _typeColor(type),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _typeLabel(type),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _typeColor(type),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Qty (+/-)
                            DataCell(
                              Text(
                                '${isPositive ? '+' : ''}$qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isPositive
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                ),
                              ),
                            ),
                            // Remarks
                            DataCell(
                              Text(
                                txn.remarks ?? '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  StockTxnType _typeFromIndex(int? index) {
    if (index == null) return StockTxnType.adjust;
    return StockTxnType.values[index.clamp(0, StockTxnType.values.length - 1)];
  }

  String _typeLabel(StockTxnType? type) {
    switch (type) {
      case StockTxnType.sell:
        return 'SELL';
      case StockTxnType.add:
        return 'ADD';
      case StockTxnType.adjust:
        return 'ADJUST';
      case StockTxnType.deduct:
        return 'DEDUCT';
      default:
        return 'ALL';
    }
  }

  Color _typeColor(StockTxnType? type) {
    switch (type) {
      case StockTxnType.sell:
        return Colors.red.shade600;
      case StockTxnType.add:
        return Colors.green.shade600;
      case StockTxnType.adjust:
        return Colors.blue.shade600;
      case StockTxnType.deduct:
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _typeIcon(StockTxnType? type) {
    switch (type) {
      case StockTxnType.sell:
        return Icons.point_of_sale_rounded;
      case StockTxnType.add:
        return Icons.add_circle_outline_rounded;
      case StockTxnType.adjust:
        return Icons.tune_rounded;
      case StockTxnType.deduct:
        return Icons.remove_circle_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ── Filter Chip Widget ──
class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
