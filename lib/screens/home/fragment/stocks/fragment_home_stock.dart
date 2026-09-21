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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'stock_ledger'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'track_inventory_movements'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'search_stock_hint'.tr,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.orange.shade600,
                  size: 22,
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
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
                    label: 'all'.tr,
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
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade100,
                              Colors.deepOrange.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: Colors.orange.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_stock_movements'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'stock_movements_hint'.tr,
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
                        color: isDark ? Colors.white : colorScheme.onSurface,
                      ),
                      dividerThickness: 0.5,
                      dataRowMaxHeight: 56,
                      columns: [
                        DataColumn(label: Text('date_time'.tr, style: TextStyle(color: isDark ? Colors.white : null, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('item'.tr, style: TextStyle(color: isDark ? Colors.white : null, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('type'.tr, style: TextStyle(color: isDark ? Colors.white : null, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('qty'.tr, style: TextStyle(color: isDark ? Colors.white : null, fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('remarks'.tr, style: TextStyle(color: isDark ? Colors.white : null, fontWeight: FontWeight.bold))),
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
                                  color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            // Item name
                            DataCell(
                              Text(
                                txn.referenceId ??
                                    controller.getItemName(txn.itemId),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : colorScheme.onSurface,
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
                                  ).withValues(alpha: isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _typeColor(
                                      type,
                                    ).withValues(alpha: isDark ? 0.45 : 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _typeIcon(type),
                                      size: 13,
                                      color: isDark && _typeColor(type) is MaterialColor ? (_typeColor(type) as MaterialColor).shade300 : _typeColor(type),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _typeLabel(type),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark && _typeColor(type) is MaterialColor ? (_typeColor(type) as MaterialColor).shade300 : _typeColor(type),
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
                                      ? (isDark ? Colors.green.shade400 : Colors.green.shade600)
                                      : (isDark ? Colors.red.shade400 : Colors.red.shade600),
                                ),
                              ),
                            ),
                            // Remarks
                            DataCell(
                              Text(
                                txn.remarks ?? '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600,
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
          // ── Pagination Footer ──
          Obx(() => _buildPagination(context, controller)),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ControllerHomeStock controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${'total'.tr}: ${controller.totalCount.value} ${'transactions'.tr}',
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
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('${'page'.tr} ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
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

  StockTxnType _typeFromIndex(int? index) {
    if (index == null) return StockTxnType.adjust;
    return StockTxnType.values[index.clamp(0, StockTxnType.values.length - 1)];
  }

  String _typeLabel(StockTxnType? type) {
    switch (type) {
      case StockTxnType.sell:
        return 'txn_sell'.tr;
      case StockTxnType.add:
        return 'txn_add'.tr;
      case StockTxnType.adjust:
        return 'txn_adjust'.tr;
      case StockTxnType.deduct:
        return 'txn_deduct'.tr;
      case StockTxnType.purchaseIn:
        return 'txn_purchase'.tr;
      default:
        return 'all'.tr;
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
        case StockTxnType.purchaseIn:
        return Colors.purple.shade600;
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
        case StockTxnType.purchaseIn:
        return Icons.shopping_cart_rounded;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? colorScheme.surfaceContainerHigh : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? colorScheme.outlineVariant : Colors.grey.shade300),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
