import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/widget/my_card.dart';

import '../../../../model/entity_item.dart';
import '../../../../util/snackbar_util.dart';
import '../../../item_form/activity_item_form.dart';
import 'controller_home_item.dart';
import 'dialogs/dialog_adjust_stock.dart';
import 'dialogs/dialog_item_detail.dart';
import 'dialogs/dialog_item_batches.dart';
import 'dialogs/dialog_print_barcode.dart';

class FragmentHomeItem extends StatelessWidget {
  const FragmentHomeItem({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeItem controller = Get.put(ControllerHomeItem());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  'Manage your inventory',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await Get.to(() => const ActivityItemForm());
                  controller.loadItems();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('New Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, or barcode...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.blue.shade600, size: 22),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 20),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),

      body: Obx(
        () => controller.rxListItem.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.cyan.shade100]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.blue.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text('No items found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    Text('Add a new item to get started', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: MyCard(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 18,
                      horizontalMargin: 18,
                      headingRowColor: WidgetStateProperty.all(colorScheme.primary.withValues(alpha: 0.04)),
                      headingTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colorScheme.onSurface),
                      dividerThickness: 0.5,
                      columns: [
                        // ── NAME (sortable) ──
                        DataColumn(
                          label: _SortableHeader(
                            controller: controller,
                            field: SortField.name,
                            label: 'Name',
                            icon: Icons.label_outlined,
                            iconColor: Colors.blue.shade600,
                            bgColor: Colors.blue.shade50,
                          ),
                        ),
                        DataColumn(
                          label: Text('SKU', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.deepPurple.shade400),
                              ),
                              const SizedBox(width: 8),
                              Text('Barcode', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Text('Unit', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text('Cost', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                        ),
                        // ── PRICE (sortable) ──
                        DataColumn(
                          numeric: true,
                          label: _SortableHeader(
                            controller: controller,
                            field: SortField.price,
                            label: 'Price',
                            icon: Icons.arrow_upward_rounded,
                            iconColor: Colors.teal.shade600,
                            bgColor: Colors.teal.shade50,
                          ),
                        ),
                        // ── STOCK (sortable) ──
                        DataColumn(
                          numeric: true,
                          label: _SortableHeader(
                            controller: controller,
                            field: SortField.stock,
                            label: 'Stock',
                            icon: Icons.warehouse_outlined,
                            iconColor: Colors.blue.shade600,
                            bgColor: Colors.blue.shade50,
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.toggle_on_rounded, size: 16, color: Colors.purple.shade600),
                              ),
                              const SizedBox(width: 8),
                              Text('Status', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.settings_rounded, size: 16, color: Colors.grey.shade700),
                              ),
                              const SizedBox(width: 8),
                              Text('Actions', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      rows: controller.rxListItem.map((EntityItem item) {
                        final isActive = item.isActive ?? true;

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (!isActive) return Colors.grey.withValues(alpha: 0.05);
                            return null;
                          }),
                          cells: [
                            // Name
                            DataCell(Text(
                              item.name ?? '-',
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                color: isActive ? null : Colors.grey,
                                fontStyle: isActive ? FontStyle.normal : FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),

                            // SKU
                            DataCell(Text(
                              item.sku ?? '-',
                              style: TextStyle(fontSize: 12, color: isActive ? Colors.grey.shade700 : Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            )),

                            // Barcode
                            DataCell(Text(
                              item.barcode?.isNotEmpty == true ? item.barcode! : '-',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: isActive ? Colors.deepPurple.shade400 : Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            )),

                            // Unit
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.blueGrey.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(item.unit ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? Colors.blueGrey.shade700 : Colors.grey)),
                            )),

                            // Cost
                            DataCell(Text(
                              item.costPrice != null ? '${controller.serviceCurrency.rxCurrency.value}${item.costPrice!.toStringAsFixed(2)}' : '-',
                              style: TextStyle(fontSize: 13, color: isActive ? Colors.orange.shade700 : Colors.grey),
                            )),

                            // Price
                            DataCell(Text(
                              item.sellingPrice != null ? '${controller.serviceCurrency.rxCurrency.value}${item.sellingPrice!.toStringAsFixed(2)}' : '-',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.teal.shade700 : Colors.grey),
                            )),

                            // Stock
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? ((item.totalQty ?? 0) <= 0 ? Colors.red.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08))
                                    : Colors.grey.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.totalQty ?? 0}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isActive ? ((item.totalQty ?? 0) <= 0 ? Colors.red.shade700 : Colors.green.shade700) : Colors.grey,
                                ),
                              ),
                            )),

                            // Status badge
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.shade600 : Colors.red.shade500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )),

                            // Actions
                            DataCell(
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
                                tooltip: 'Actions',
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _onEdit(item, controller);
                                      break;
                                    case 'print_barcode':
                                      Get.dialog(DialogPrintBarcode(item: item));
                                      break;
                                    case 'adjust_stock':
                                      _onAdjustStock(item);
                                      break;
                                    case 'view_batches':
                                      _onViewBatches(item);
                                      break;
                                    case 'details':
                                      _onDetails(item);
                                      break;
                                    case 'toggle':
                                      _confirmToggleActive(context, item, controller);
                                      break;
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined, size: 20, color: colorScheme.primary),
                                      const SizedBox(width: 12),
                                      const Text('Edit'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'print_barcode',
                                    child: Row(children: [
                                      Icon(Icons.print_rounded, size: 20, color: Colors.deepPurple.shade400),
                                      const SizedBox(width: 12),
                                      const Text('Print Barcode'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'adjust_stock',
                                    child: Row(children: [
                                      Icon(Icons.tune_rounded, size: 20, color: Colors.teal.shade600),
                                      const SizedBox(width: 12),
                                      const Text('Adjust Stock'),
                                    ]),
                                  ),
                                  if (item.hasExpiry == true)
                                    PopupMenuItem(
                                      value: 'view_batches',
                                      child: Row(children: [
                                        Icon(Icons.history_edu_rounded, size: 20, color: Colors.blue.shade600),
                                        const SizedBox(width: 12),
                                        const Text('View Batches'),
                                      ]),
                                    ),
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Row(children: [
                                      Icon(Icons.visibility_outlined, size: 20, color: Colors.deepPurple.shade400),
                                      const SizedBox(width: 12),
                                      const Text('View Details'),
                                    ]),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(children: [
                                      Icon(
                                        isActive ? Icons.toggle_off_rounded : Icons.toggle_on_rounded,
                                        size: 22,
                                        color: isActive ? Colors.red.shade400 : Colors.green.shade500,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isActive ? 'Deactivate' : 'Activate',
                                        style: TextStyle(color: isActive ? Colors.red.shade400 : Colors.green.shade600),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      dataRowMaxHeight: 52,
                    ),
                  ),
                ),
              ),
            ),
            // ── Pagination Footer ──
            Obx(() => _buildPagination(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(ControllerHomeItem controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${controller.totalCount.value} items',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.hasPrev ? controller.prevPage : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text('Prev'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('Page ${controller.currentPage.value + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: controller.hasNext ? controller.nextPage : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Next'),
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

  void _onEdit(EntityItem item, ControllerHomeItem controller) async {
    await Get.to(() => const ActivityItemForm(), arguments: item);
    controller.loadItems();
  }

  void _onAdjustStock(EntityItem item) {
    Get.dialog(DialogAdjustStock(entityItem: item));
  }

  void _onViewBatches(EntityItem item) {
    Get.dialog(DialogItemBatches(entityItem: item));
  }

  void _onDetails(EntityItem item) {
    Get.dialog(DialogItemDetail(entityItem: item));
  }

  void _confirmToggleActive(BuildContext context, EntityItem item, ControllerHomeItem controller) {
    final isCurrentlyActive = item.isActive ?? true;
    Get.defaultDialog(
      title: isCurrentlyActive ? 'Deactivate Item?' : 'Activate Item?',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText: 'Are you sure you want to ${isCurrentlyActive ? "deactivate" : "activate"} "${item.name}"?',
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentlyActive ? Colors.red.shade400 : Colors.green.shade500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: Icon(isCurrentlyActive ? Icons.toggle_off_rounded : Icons.toggle_on_rounded, size: 20),
        onPressed: () {
          controller.toggleActive(item);
          Get.back();
          SnackbarUtil.showSuccess('${item.name} ${!(isCurrentlyActive) ? "activated" : "deactivated"}');
        },
        label: Text(isCurrentlyActive ? 'Deactivate' : 'Activate'),
      ),
      cancel: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sortable Column Header Widget
// ─────────────────────────────────────────────────────────────────────────────

class _SortableHeader extends StatelessWidget {
  final ControllerHomeItem controller;
  final String field;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _SortableHeader({
    required this.controller,
    required this.field,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.rxSortField.value == field;
      final asc = controller.rxSortAsc.value;

      // Sort indicator icon
      IconData sortIcon;
      if (!isSelected) {
        sortIcon = Icons.unfold_more_rounded; // neutral
      } else if (asc) {
        sortIcon = Icons.arrow_upward_rounded; // ascending
      } else {
        sortIcon = Icons.arrow_downward_rounded; // descending
      }

      return InkWell(
        onTap: () => controller.toggleSort(field),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? iconColor.withOpacity(0.15) : bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(
                sortIcon,
                size: 14,
                color: isSelected ? iconColor : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      );
    });
  }
}
