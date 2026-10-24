import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:super_market/widget/gradient_action_button.dart';
import 'package:super_market/widget/gradient_app_bar_title.dart';
import 'package:super_market/widget/generic_empty_state.dart';
import 'package:super_market/widget/search_app_bar_field.dart';
import 'package:super_market/widget/my_card.dart';

import '../../../../model/entity_item.dart';
import '../../../../util/snackbar_util.dart';
import '../../../item_form/activity_item_form.dart';
import 'controller_home_item.dart';
import '../../../../core/auth/app_permissions.dart';
import '../../../../widget/permission_widget.dart';
import '../../controller_home.dart';
import 'dialogs/dialog_adjust_stock.dart';
import 'dialogs/dialog_item_detail.dart';
import 'dialogs/dialog_item_batches.dart';
import 'dialogs/dialog_print_barcode.dart';

class FragmentHomeItem extends StatelessWidget {
  const FragmentHomeItem({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeItem controller = Get.put(ControllerHomeItem());
    final ControllerHome? homeCtrl = Get.isRegistered<ControllerHome>() ? Get.find<ControllerHome>() : null;
    final canUpdate = homeCtrl?.hasPermission(AppPermissions.inventoryUpdate) ?? true;
    final canAdjust = (homeCtrl?.hasPermission(AppPermissions.stockAdjust) ?? true) || canUpdate;
    final canDelete = homeCtrl?.hasPermission(AppPermissions.inventoryDelete) ?? true;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: GradientAppBarTitle(
          icon: Icons.inventory_2_rounded,
          title: 'item_list_title'.tr,
          subtitle: 'manage_inventory'.tr,
          gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
        actions: [
          PermissionWidget(
            permission: AppPermissions.reportExport,
            child: TextButton.icon(
              onPressed: () => controller.exportExcel(),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text('export'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          PermissionWidget(
            permission: AppPermissions.bulkItemImport,
            child: GradientActionButton(
              icon: Icons.file_upload_outlined,
              label: 'import'.tr,
              gradientColors: [Colors.orange.shade400, Colors.orange.shade700],
              onTap: controller.importExcel,
            ),
          ),
          PermissionWidget(
            permission: AppPermissions.inventoryCreate,
            child: GradientActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'add_item'.tr,
              gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
              onTap: () async {
                await Get.dialog(
                  const ActivityItemForm(),
                  barrierDismissible: false,
                );
                controller.loadItems();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SearchAppBarField(
            controller: controller.searchController,
            hint: 'search_item'.tr,
            onChanged: controller.updateSearch,
            onClear: controller.clearSearch,
          ),
        ),
      ),

      body: Column(
        children: [
          // ── Expiry Filter Chips ── ALWAYS visible at the top
          _buildExpiryFilterBar(context, controller),

          // ── Bulk Action Bar ── Visible when items are selected
          _buildBulkActionBar(context, controller, canUpdate, canDelete),

          // ── Table or Filter-aware Empty State ──
          Expanded(
            child: Obx(() {
              if (controller.rxListItem.isEmpty) {
                final filter = controller.rxExpiryFilter.value;
                String title = 'No items found';
                String subtitle = 'No items in this category';
                IconData icon = Icons.inventory_2_outlined;

                if (filter == ExpiryFilter.expired) {
                  title = 'No expired items 🎉';
                  subtitle = 'Great news! None of your tracked items have expired batches.';
                  icon = Icons.verified_rounded;
                } else if (filter == ExpiryFilter.expiring) {
                  title = 'No items expiring soon';
                  subtitle = 'No items have batches expiring within the next 30 days.';
                  icon = Icons.schedule_rounded;
                } else if (filter == ExpiryFilter.safe) {
                  title = 'No safe batch items';
                  subtitle = 'No items currently have batches with > 30 days validity.';
                  icon = Icons.calendar_today_rounded;
                } else if (controller.searchQuery.isNotEmpty) {
                  title = 'No items match "${controller.searchQuery.value}"';
                  subtitle = 'Try checking for typos or searching a different term.';
                } else {
                  title = 'No items found';
                  subtitle = 'Add a new item to get started';
                }

                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GenericEmptyState(
                          icon: icon,
                          title: title,
                          subtitle: subtitle,
                          gradientColors: (filter == ExpiryFilter.expired || filter == ExpiryFilter.expiring)
                              ? [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)]
                              : const [Color(0xFFBFDBFE), Color(0xFFA5F3FC)],
                        ),
                        if (filter != ExpiryFilter.all) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => controller.setExpiryFilter(ExpiryFilter.all),
                            icon: const Icon(Icons.apps_rounded, size: 16),
                            label: const Text('Show All Items'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: RepaintBoundary(
                      child: MyCard(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Scrollbar(
                      controller: controller.horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: controller.horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SingleChildScrollView(
                            child: DataTable(
                      showCheckboxColumn: true,
                      onSelectAll: (val) {
                        if (val == true) {
                          controller.selectAllVisible();
                        } else {
                          controller.clearSelection();
                        }
                      },
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
                            label: 'name'.tr,
                            icon: Icons.label_outlined,
                            iconColor: Colors.blue.shade600,
                            bgColor: Colors.blue.shade50,
                          ),
                        ),
                        DataColumn(
                          label: Text('SKU'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                              Text('barcode'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Text('unit'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text('cost'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        ),
                        // ── PRICE (sortable) ──
                        DataColumn(
                          numeric: true,
                          label: _SortableHeader(
                            controller: controller,
                            field: SortField.price,
                            label: 'price'.tr,
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
                            label: 'stock'.tr,
                            icon: Icons.warehouse_outlined,
                            iconColor: Colors.blue.shade600,
                            bgColor: Colors.blue.shade50,
                          ),
                        ),
                        // ── EXPIRY ──
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.event_busy_rounded, size: 16, color: Colors.orange.shade700),
                              ),
                              const SizedBox(width: 8),
                              Text('Expiry', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                            ],
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
                              Text('status'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
                              Text('actions'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      rows: controller.rxListItem.map((EntityItem item) {
                        final isActive = item.isActive ?? true;
                        final itemId = item.id ?? 0;
                        final isSelected = controller.isSelected(itemId);

                        return DataRow(
                          selected: isSelected,
                          onSelectChanged: (val) {
                            controller.toggleSelection(itemId);
                          },
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return colorScheme.primary.withValues(alpha: 0.08);
                            }
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
                              child: Text(item.unit ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? colorScheme.onSurface : Colors.grey)),
                            )),

                            // Cost
                            DataCell(Text(
                              item.costPrice != null ? '${controller.serviceCurrency.rxCurrency.value}${item.costPrice!.toStringAsFixed(2)}' : '-',
                              style: TextStyle(fontSize: 13, color: isActive ? (Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade300 : Colors.orange.shade800) : Colors.grey),
                            )),

                            // Price
                            DataCell(Text(
                              item.sellingPrice != null ? '${controller.serviceCurrency.rxCurrency.value}${item.sellingPrice!.toStringAsFixed(2)}' : '-',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? (Theme.of(context).brightness == Brightness.dark ? Colors.teal.shade300 : Colors.teal.shade700) : Colors.grey),
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
                                  color: isActive ? ((item.totalQty ?? 0) <= 0 ? (Theme.of(context).brightness == Brightness.dark ? Colors.red.shade300 : Colors.red.shade700) : (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade700)) : Colors.grey,
                                ),
                              ),
                            )),

                            // Expiry Badge
                            DataCell(_ExpiryBadge(item: item, controller: controller)),

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
                                    isActive ? 'active'.tr : 'inactive'.tr,
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
                                tooltip: 'Actions'.tr,
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
                                    case 'delete':
                                      controller.confirmSingleDelete(context, item);
                                      break;
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (canUpdate)
                                    PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined, size: 20, color: colorScheme.primary),
                                      const SizedBox(width: 12),
                                      Text('edit'.tr),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'print_barcode',
                                    child: Row(children: [
                                      Icon(Icons.print_rounded, size: 20, color: Colors.deepPurple.shade400),
                                      const SizedBox(width: 12),
                                      Text('print_barcode'.tr),
                                    ]),
                                  ),
                                  if (canAdjust)
                                    PopupMenuItem(
                                    value: 'adjust_stock',
                                    child: Row(children: [
                                      Icon(Icons.tune_rounded, size: 20, color: Colors.teal.shade600),
                                      const SizedBox(width: 12),
                                      Text('adjust_stock'.tr),
                                    ]),
                                  ),
                                  if (item.hasExpiry == true)
                                    PopupMenuItem(
                                      value: 'view_batches',
                                      child: Row(children: [
                                        Icon(Icons.history_edu_rounded, size: 20, color: Colors.blue.shade600),
                                        const SizedBox(width: 12),
                                        Text('view_batches'.tr),
                                      ]),
                                    ),
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Row(children: [
                                      Icon(Icons.visibility_outlined, size: 20, color: Colors.deepPurple.shade400),
                                      const SizedBox(width: 12),
                                      Text('view_details'.tr),
                                    ]),
                                  ),
                                  if (canDelete) ...[
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
                                          isActive ? 'deactivate'.tr : 'activate'.tr,
                                          style: TextStyle(color: isActive ? Colors.red.shade400 : Colors.green.shade600),
                                        ),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Delete Item',
                                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                        ),
                                      ]),
                                    ),
                                  ],
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
            );
          },
        ),
      ),
    ),
  ),
  // ── Pagination Footer ──
  _buildPagination(context, controller),
],
);
      }),
    ),
  ],
),
    );
  }

  /// Bulk Action Bar for multi-selected items
  Widget _buildBulkActionBar(
    BuildContext context,
    ControllerHomeItem controller,
    bool canUpdate,
    bool canDelete,
  ) {
    return Obx(() {
      if (!controller.hasSelection) return const SizedBox.shrink();
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final count = controller.selectedCount;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$count item${count > 1 ? 's' : ''} selected',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Spacer(),
            if (canUpdate) ...[
              FilledButton.tonalIcon(
                onPressed: () => controller.bulkToggleActive(true),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Activate', style: TextStyle(fontSize: 12.5)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => controller.bulkToggleActive(false),
                icon: const Icon(Icons.block_rounded, size: 16),
                label: const Text('Deactivate', style: TextStyle(fontSize: 12.5)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.withValues(alpha: 0.18),
                  foregroundColor: const Color(0xFFB45309),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (canDelete) ...[
              FilledButton.icon(
                onPressed: () => controller.confirmBulkDelete(context),
                icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: () => controller.clearSelection(),
              tooltip: 'Deselect all',
              icon: const Icon(Icons.close_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    });
  }

  /// Expiry filter chip bar
  Widget _buildExpiryFilterBar(BuildContext context, ControllerHomeItem controller) {
    return Obx(() {
      final selected = controller.rxExpiryFilter.value;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ExpiryChip(
                label: 'All Items',
                icon: Icons.apps_rounded,
                value: ExpiryFilter.all,
                selected: selected,
                count: controller.countAll.value,
                color: Colors.blue.shade600,
                onTap: () => controller.setExpiryFilter(ExpiryFilter.all),
              ),
              const SizedBox(width: 8),
              _ExpiryChip(
                label: 'Expiring Soon',
                icon: Icons.schedule_rounded,
                value: ExpiryFilter.expiring,
                selected: selected,
                count: controller.countExpiring.value,
                color: Colors.orange.shade700,
                onTap: () => controller.setExpiryFilter(ExpiryFilter.expiring),
              ),
              const SizedBox(width: 8),
              _ExpiryChip(
                label: 'Expired',
                icon: Icons.dangerous_outlined,
                value: ExpiryFilter.expired,
                selected: selected,
                count: controller.countExpired.value,
                color: Colors.red.shade600,
                onTap: () => controller.setExpiryFilter(ExpiryFilter.expired),
              ),
              const SizedBox(width: 8),
              _ExpiryChip(
                label: 'Safe',
                icon: Icons.verified_rounded,
                value: ExpiryFilter.safe,
                selected: selected,
                count: controller.countSafe.value,
                color: Colors.green.shade600,
                onTap: () => controller.setExpiryFilter(ExpiryFilter.safe),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPagination(BuildContext context, ControllerHomeItem controller) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'total_items_count'.trParams({'count': '${controller.totalCount.value}'}),
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          ),
          // ── Horizontal Table Scroll Navigation ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.compare_arrows_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Scroll Table:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  tooltip: 'Scroll Left',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.scrollLeft,
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  tooltip: 'Scroll Right (Expiry & Actions)',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.scrollRight,
                ),
              ],
            ),
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
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('page_number'.trParams({'number': '${controller.currentPage.value + 1}'}),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
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

  void _onEdit(EntityItem item, ControllerHomeItem controller) async {
    await Get.dialog(
      const ActivityItemForm(),
      arguments: item,
      barrierDismissible: false,
    );
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
      title: isCurrentlyActive ? 'deactivate_item'.tr : 'activate_item'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText: (isCurrentlyActive ? 'deactivate_item_confirm' : 'activate_item_confirm')
          .trParams({'item': item.name ?? ''}),
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
          SnackbarUtil.showSuccess(
            (!(isCurrentlyActive) ? 'item_activated' : 'item_deactivated').trParams({'item': item.name ?? ''}),
          );
        },
        label: Text(isCurrentlyActive ? 'deactivate'.tr : 'activate'.tr),
      ),
      cancel: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: Text('cancel'.tr),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                  color: isSelected ? iconColor.withValues(alpha:0.15) : bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Expiry Badge — colour-coded expiry cell in the DataTable
// ─────────────────────────────────────────────────────────────────────────────

class _ExpiryBadge extends StatelessWidget {
  final EntityItem item;
  final ControllerHomeItem controller;

  const _ExpiryBadge({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Items without expiry tracking
    if (item.hasExpiry != true) {
      return Text('—', style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    }

    final expiryMs = controller.getNearestExpiryMsForItem(item.id ?? 0);
    if (expiryMs == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('No batch', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      );
    }

    final now = DateTime.now();
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    final daysLeft = expiryDate.difference(now).inDays;
    final dateStr = DateFormat('dd MMM yy').format(expiryDate);

    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (daysLeft < 0) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = 'Expired';
      icon = Icons.dangerous_outlined;
    } else if (daysLeft == 0) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = 'Today!';
      icon = Icons.warning_amber_rounded;
    } else if (daysLeft <= 7) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = '$daysLeft days';
      icon = Icons.warning_amber_rounded;
    } else if (daysLeft <= 30) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      label = '$daysLeft days';
      icon = Icons.schedule_rounded;
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      label = dateStr;
      icon = Icons.check_circle_outline_rounded;
    }

    return Tooltip(
      message: 'Nearest batch expiry: $dateStr',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: textColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expiry Filter Chip
// ─────────────────────────────────────────────────────────────────────────────

class _ExpiryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  const _ExpiryChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.color,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    final activeColor = color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.14)
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.22)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

