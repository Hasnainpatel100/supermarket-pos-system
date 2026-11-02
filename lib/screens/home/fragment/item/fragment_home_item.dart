import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const double _minTableWidth = 1180.0;

  @override
  Widget build(BuildContext context) {
    final ControllerHomeItem controller = Get.isRegistered<ControllerHomeItem>()
        ? Get.find<ControllerHomeItem>()
        : Get.put(ControllerHomeItem());
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
        ),
        actions: [
          PermissionWidget(
            permission: AppPermissions.reportExport,
            child: TextButton.icon(
              onPressed: () => controller.exportExcel(),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text('export'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          PermissionWidget(
            permission: AppPermissions.bulkItemImport,
            child: GradientActionButton(
              icon: Icons.file_upload_outlined,
              label: 'import'.tr,
              onTap: controller.importExcel,
            ),
          ),
          PermissionWidget(
            permission: AppPermissions.inventoryCreate,
            child: GradientActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'add_item'.tr,
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
          // ── Expiry Filter Chips Bar with Expand All Toggle ──
          _buildExpiryFilterBar(context, controller),

          // ── Bulk Actions Floating Ribbon ──
          _buildBulkActionBar(context, controller, canUpdate, canDelete),

          // ── Main Content Area ──
          Expanded(
            child: Obx(() {
              if (controller.rxListItem.isEmpty) {
                final isFiltered = controller.rxExpiryFilter.value != ExpiryFilter.all ||
                    controller.searchQuery.value.isNotEmpty;
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GenericEmptyState(
                          title: isFiltered ? 'No matching items' : 'no_items_found'.tr,
                          subtitle: isFiltered
                              ? 'Try switching the filter tab or clearing your search.'
                              : 'Add your first product to get started.',
                          icon: Icons.inventory_2_outlined,
                        ),
                        if (isFiltered) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => controller.setExpiryFilter(ExpiryFilter.all),
                            icon: const Icon(Icons.apps_rounded, size: 16),
                            label: const Text('Show All Items'),
                            style: FilledButton.styleFrom(
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

              // Pinned table layout with expandable rows inside
              return RepaintBoundary(
                child: MyCard(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tableWidth = constraints.maxWidth > _minTableWidth
                          ? constraints.maxWidth
                          : _minTableWidth;

                      return Scrollbar(
                        controller: controller.horizontalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: controller.horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              children: [
                                // ── Table Header Row ──
                                _buildTableHeader(context, controller, colorScheme),
                                const Divider(height: 1, thickness: 1),

                                // ── Scrollable Expandable Rows ──
                                Expanded(
                                  child: Scrollbar(
                                    controller: controller.verticalScrollController,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      controller: controller.verticalScrollController,
                                      itemCount: controller.rxListItem.length,
                                      itemBuilder: (context, index) {
                                        final item = controller.rxListItem[index];
                                        return _ExpandableItemRow(
                                          key: ValueKey('item_row_${item.id > 0 ? item.id : item.objectId}'),
                                          item: item,
                                          controller: controller,
                                          canUpdate: canUpdate,
                                          canAdjust: canAdjust,
                                          canDelete: canDelete,
                                          onEdit: () => _onEdit(item, controller),
                                          onAdjustStock: () => _onAdjustStock(item),
                                          onViewBatches: () => _onViewBatches(item),
                                          onDetails: () => _onDetails(item),
                                          onToggleStatus: () => _confirmToggleActive(context, item, controller),
                                          onDelete: () => controller.confirmSingleDelete(context, item),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

  /// Pinned Header matching columns
  Widget _buildTableHeader(BuildContext context, ControllerHomeItem controller, ColorScheme colorScheme) {
    return Obx(() {
      final isAllSelected = controller.isAllVisibleSelected;

      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 36,
              child: Checkbox(
                value: isAllSelected,
                tristate: controller.hasSelection && !isAllSelected,
                activeColor: colorScheme.primary,
                onChanged: (val) {
                  if (val == true) {
                    controller.selectAllVisible();
                  } else {
                    controller.deselectAllVisible();
                  }
                },
              ),
            ),

            // Expand icon spacer
            const SizedBox(width: 34),

            // Name (sortable)
            Expanded(
              flex: 4,
              child: _SortableHeader(
                controller: controller,
                field: SortField.name,
                label: 'name'.tr,
                icon: Icons.label_outlined,
                iconColor: colorScheme.primary,
                bgColor: colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(width: 12),

            // SKU
            SizedBox(
              width: 105,
              child: Text(
                'SKU'.tr,
                style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),

            // Barcode
            SizedBox(
              width: 125,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(5)),
                    child: Icon(Icons.qr_code_2_rounded, size: 14, color: Colors.deepPurple.shade400),
                  ),
                  const SizedBox(width: 6),
                  Text('barcode'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Unit
            SizedBox(
              width: 65,
              child: Text(
                'unit'.tr,
                style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),

            // Cost
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'cost'.tr,
                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Price (sortable)
            SizedBox(
              width: 95,
              child: Align(
                alignment: Alignment.centerRight,
                child: _SortableHeader(
                  controller: controller,
                  field: SortField.price,
                  label: 'price'.tr,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: colorScheme.primary,
                  bgColor: colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Stock (sortable)
            SizedBox(
              width: 85,
              child: Align(
                alignment: Alignment.centerRight,
                child: _SortableHeader(
                  controller: controller,
                  field: SortField.stock,
                  label: 'stock'.tr,
                  icon: Icons.warehouse_outlined,
                  iconColor: colorScheme.primary,
                  bgColor: colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Expiry
            SizedBox(
              width: 110,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(5)),
                    child: Icon(Icons.event_busy_rounded, size: 14, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 6),
                  Text('Expiry', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Status
            SizedBox(
              width: 90,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(5)),
                    child: Icon(Icons.toggle_on_rounded, size: 14, color: Colors.purple.shade600),
                  ),
                  const SizedBox(width: 6),
                  Text('status'.tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Actions
            SizedBox(
              width: 50,
              child: Center(
                child: Icon(Icons.settings_rounded, size: 16, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Bulk Action Bar for multi-selected items
  Widget _buildBulkActionBar(
    BuildContext context,
    ControllerHomeItem controller,
    bool canUpdate,
    bool canDelete,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      if (!controller.hasSelection) return const SizedBox.shrink();
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final totalCount = controller.selectedCount;
      final pageSelectedCount = controller.rxListItem
          .where((item) => controller.isSelected(item.id))
          .length;

      final labelText = (pageSelectedCount == totalCount)
          ? '$totalCount item${totalCount > 1 ? 's' : ''} selected'
          : '$totalCount item${totalCount > 1 ? 's' : ''} selected ($pageSelectedCount on this page)';

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
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                labelText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Spacer(),
            if (canUpdate) ...[
              FilledButton.tonalIcon(
                onPressed: () => controller.bulkToggleActive(true),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Activate'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                  foregroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => controller.bulkToggleActive(false),
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Deactivate'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                  foregroundColor: Colors.orange.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (canDelete)
              FilledButton.tonalIcon(
                onPressed: () => controller.confirmBulkDelete(context),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Clear selection',
              onPressed: controller.clearSelection,
            ),
          ],
        ),
      );
    });
  }

  /// Expiry filter chip bar with Expand All / Collapse All button
  Widget _buildExpiryFilterBar(BuildContext context, ControllerHomeItem controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final selected = controller.rxExpiryFilter.value;
      final areAllExpanded = controller.areAllExpanded;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Expanded(
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
                      color: colorScheme.primary,
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
                      color: colorScheme.error,
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
            ),
            const SizedBox(width: 12),

            // ── Expand All / Collapse All Button ──
            OutlinedButton.icon(
              onPressed: () {
                if (areAllExpanded) {
                  controller.collapseAll();
                } else {
                  controller.expandAll();
                }
              },
              icon: Icon(
                areAllExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              label: Text(
                areAllExpanded ? 'Collapse All' : 'Expand All',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
            ),
          ],
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
                decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Text('page_number'.trParams({'number': '${controller.currentPage.value + 1}'}),
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrentlyActive = item.isActive ?? true;
    Get.defaultDialog(
      title: isCurrentlyActive ? 'deactivate_item'.tr : 'activate_item'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText: (isCurrentlyActive ? 'deactivate_item_confirm' : 'activate_item_confirm')
          .trParams({'item': item.name ?? ''}),
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(
          isCurrentlyActive ? Icons.toggle_off_rounded : Icons.toggle_on_rounded,
          size: 20,
          color: isCurrentlyActive ? colorScheme.error : colorScheme.primary,
        ),
        onPressed: () {
          controller.toggleActive(item);
          Get.back();
          SnackbarUtil.showSuccess(
            (!(isCurrentlyActive) ? 'item_activated' : 'item_deactivated').trParams({'item': item.name ?? ''}),
          );
        },
        label: Text(
          isCurrentlyActive ? 'deactivate'.tr : 'activate'.tr,
          style: TextStyle(color: isCurrentlyActive ? colorScheme.error : colorScheme.primary, fontWeight: FontWeight.bold),
        ),
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
// Expandable Item Row (Main Row + Accordion Body)
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandableItemRow extends StatelessWidget {
  final EntityItem item;
  final ControllerHomeItem controller;
  final bool canUpdate;
  final bool canAdjust;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onAdjustStock;
  final VoidCallback onViewBatches;
  final VoidCallback onDetails;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _ExpandableItemRow({
    super.key,
    required this.item,
    required this.controller,
    required this.canUpdate,
    required this.canAdjust,
    required this.canDelete,
    required this.onEdit,
    required this.onAdjustStock,
    required this.onViewBatches,
    required this.onDetails,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = item.isActive ?? true;

    return Obx(() {
      final isSelected = controller.isSelected(item.id);
      final isExpanded = controller.isExpanded(item.id);

      Color rowBg;
      if (isSelected) {
        rowBg = colorScheme.primary.withValues(alpha: 0.09);
      } else if (isExpanded) {
        rowBg = colorScheme.primary.withValues(alpha: 0.04);
      } else if (!isActive) {
        rowBg = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.04);
      } else {
        rowBg = Colors.transparent;
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExpanded
                ? colorScheme.primary.withValues(alpha: 0.25)
                : (isSelected ? colorScheme.primary.withValues(alpha: 0.4) : Colors.transparent),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // ── Main Compact Row ──
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.toggleExpand(item.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // Checkbox
                    SizedBox(
                      width: 36,
                      child: Checkbox(
                        value: isSelected,
                        activeColor: colorScheme.primary,
                        onChanged: (val) {
                          if (item.id > 0) {
                            controller.toggleSelection(item.id);
                          }
                        },
                      ),
                    ),

                    // Expand Chevron Button
                    SizedBox(
                      width: 34,
                      child: IconButton(
                        icon: AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: isExpanded ? colorScheme.primary : Colors.grey.shade500,
                          ),
                        ),
                        onPressed: () => controller.toggleExpand(item.id),
                        splashRadius: 18,
                        tooltip: isExpanded ? 'Collapse' : 'Expand full details',
                      ),
                    ),

                    // Name Column
                    Expanded(
                      flex: 4,
                      child: Tooltip(
                        message: item.name ?? '-',
                        waitDuration: const Duration(milliseconds: 500),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                item.name ?? '-',
                                style: TextStyle(
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive ? colorScheme.onSurface : Colors.grey,
                                  fontStyle: isActive ? FontStyle.normal : FontStyle.italic,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.category != null && item.category!.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category!,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // SKU Column
                    SizedBox(
                      width: 105,
                      child: Text(
                        item.sku ?? '-',
                        style: TextStyle(fontSize: 12, color: isActive ? colorScheme.onSurface.withValues(alpha: 0.8) : Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Barcode Column
                    SizedBox(
                      width: 125,
                      child: Text(
                        item.barcode?.isNotEmpty == true ? item.barcode! : '-',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: isActive ? Colors.deepPurple.shade400 : colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Unit Column
                    SizedBox(
                      width: 65,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.5) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.unit ?? '-',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Cost Column
                    SizedBox(
                      width: 80,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.costPrice != null ? '${controller.serviceCurrency.rxCurrency.value}${item.costPrice!.toStringAsFixed(2)}' : '-',
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive ? (isDark ? Colors.amber.shade300 : Colors.orange.shade800) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Price Column
                    SizedBox(
                      width: 95,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.sellingPrice != null ? '${controller.serviceCurrency.rxCurrency.value}${item.sellingPrice!.toStringAsFixed(2)}' : '-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? (isDark ? Colors.teal.shade300 : Colors.teal.shade700) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Stock Column
                    SizedBox(
                      width: 85,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
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
                              fontSize: 12.5,
                              color: isActive
                                  ? ((item.totalQty ?? 0) <= 0
                                      ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                                      : (isDark ? Colors.green.shade300 : Colors.green.shade700))
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Expiry Badge Column
                    SizedBox(
                      width: 110,
                      child: _ExpiryBadge(item: item, controller: controller),
                    ),
                    const SizedBox(width: 12),

                    // Status Column
                    SizedBox(
                      width: 90,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Actions Menu
                    SizedBox(
                      width: 50,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
                        tooltip: 'Actions'.tr,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit();
                              break;
                            case 'print_barcode':
                              Get.dialog(DialogPrintBarcode(item: item));
                              break;
                            case 'adjust_stock':
                              onAdjustStock();
                              break;
                            case 'view_batches':
                              onViewBatches();
                              break;
                            case 'details':
                              onDetails();
                              break;
                            case 'toggle':
                              onToggleStatus();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          if (canUpdate)
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
                                const SizedBox(width: 12),
                                Text('edit'.tr),
                              ]),
                            ),
                          PopupMenuItem(
                            value: 'print_barcode',
                            child: Row(children: [
                              Icon(Icons.print_rounded, size: 18, color: colorScheme.primary.withValues(alpha: 0.8)),
                              const SizedBox(width: 12),
                              Text('print_barcode'.tr),
                            ]),
                          ),
                          if (canAdjust)
                            PopupMenuItem(
                              value: 'adjust_stock',
                              child: Row(children: [
                                Icon(Icons.tune_rounded, size: 18, color: colorScheme.primary),
                                const SizedBox(width: 12),
                                Text('adjust_stock'.tr),
                              ]),
                            ),
                          if (item.hasExpiry == true)
                            PopupMenuItem(
                              value: 'view_batches',
                              child: Row(children: [
                                Icon(Icons.history_edu_rounded, size: 18, color: colorScheme.primary),
                                const SizedBox(width: 12),
                                Text('view_batches'.tr),
                              ]),
                            ),
                          PopupMenuItem(
                            value: 'details',
                            child: Row(children: [
                              Icon(Icons.visibility_outlined, size: 18, color: Colors.deepPurple.shade400),
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
                                  size: 20,
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
                              child: const Row(children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Delete Item', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Accordion Expandable Details Body ──
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: isExpanded
                  ? _ItemDetailExpandedPanel(
                      item: item,
                      controller: controller,
                      canUpdate: canUpdate,
                      canAdjust: canAdjust,
                      canDelete: canDelete,
                      onEdit: onEdit,
                      onAdjustStock: onAdjustStock,
                      onViewBatches: onViewBatches,
                      onToggleStatus: onToggleStatus,
                      onDelete: onDelete,
                    )
                  : const SizedBox.shrink(),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 240),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich Item Details Expanded Panel
// ─────────────────────────────────────────────────────────────────────────────

class _ItemDetailExpandedPanel extends StatelessWidget {
  final EntityItem item;
  final ControllerHomeItem controller;
  final bool canUpdate;
  final bool canAdjust;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onAdjustStock;
  final VoidCallback onViewBatches;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _ItemDetailExpandedPanel({
    required this.item,
    required this.controller,
    required this.canUpdate,
    required this.canAdjust,
    required this.canDelete,
    required this.onEdit,
    required this.onAdjustStock,
    required this.onViewBatches,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cur = controller.serviceCurrency.rxCurrency.value;

    final cost = item.costPrice ?? 0.0;
    final selling = item.sellingPrice ?? 0.0;
    final profit = selling - cost;
    final marginPct = cost > 0 ? (profit / cost * 100) : 0.0;

    final batches = controller.getAllBatches(item.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F2E) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 4 Top Information Tiles ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pricing & Profit Margin Tile
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'Pricing & Margin',
                  icon: Icons.monetization_on_outlined,
                  iconColor: Colors.teal,
                  children: [
                    _keyValRow('Cost Price', '$cur${cost.toStringAsFixed(2)}'),
                    _keyValRow('Selling Price', '$cur${selling.toStringAsFixed(2)}'),
                    _keyValRow(
                      'Gross Profit',
                      '$cur${profit.toStringAsFixed(2)}',
                      valueColor: profit >= 0 ? Colors.teal : Colors.red,
                      trailingBadge: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (profit >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${profit >= 0 ? '+' : ''}${marginPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                    _keyValRow('Price Before Tax', item.priceBeforeTax != null ? '$cur${item.priceBeforeTax!.toStringAsFixed(2)}' : '—'),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 2. Tax & Compliance Tile
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'Tax & Compliance',
                  icon: Icons.account_balance_outlined,
                  iconColor: Colors.indigo,
                  children: [
                    _keyValRow('Tax Type', item.taxType ?? 'Inclusive'),
                    _keyValRow('Tax Rate', item.taxRate != null ? '${item.taxRate}%' : '0%'),
                    _keyValRow('Tax Amount', item.taxAmount != null ? '$cur${item.taxAmount!.toStringAsFixed(2)}' : '—'),
                    _keyValRow('HSN Code', item.hsnCode?.isNotEmpty == true ? item.hsnCode! : '—'),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 3. Identification & Category Tile
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'Classification',
                  icon: Icons.category_outlined,
                  iconColor: Colors.purple,
                  children: [
                    _keyValRow('Category', item.category?.isNotEmpty == true ? item.category! : 'General'),
                    _keyValRow('Unit of Measure', item.unit ?? 'Pcs'),
                    _keyValRow(
                      'Barcode',
                      item.barcode?.isNotEmpty == true ? item.barcode! : '—',
                      trailingBadge: item.barcode?.isNotEmpty == true
                          ? InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: item.barcode!));
                                SnackbarUtil.showSuccess('Barcode copied: ${item.barcode}');
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.copy_rounded, size: 14, color: Colors.purple),
                              ),
                            )
                          : null,
                    ),
                    _keyValRow('Track Expiry', item.hasExpiry == true ? 'Yes (Batch Managed)' : 'No'),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 4. Audit & Record Metadata Tile
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'Audit & Records',
                  icon: Icons.history_rounded,
                  iconColor: Colors.blueGrey,
                  children: [
                    _keyValRow('Internal ID', '#${item.id}'),
                    _keyValRow(
                      'Created On',
                      item.createdAtUtcMs != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(item.createdAtUtcMs!, isUtc: true).toLocal())
                          : '—',
                    ),
                    _keyValRow(
                      'Last Updated',
                      item.updatedAtUtcMs != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(item.updatedAtUtcMs!, isUtc: true).toLocal())
                          : '—',
                    ),
                    _keyValRow(
                      'Current Status',
                      (item.isActive ?? true) ? 'Active' : 'Inactive',
                      valueColor: (item.isActive ?? true) ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Batches Inventory Sub-Table ──
          if (item.hasExpiry == true || batches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Batch Inventory (${batches.length} batch${batches.length == 1 ? '' : 'es'})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (canAdjust)
                  TextButton.icon(
                    onPressed: onViewBatches,
                    icon: const Icon(Icons.tune_rounded, size: 15),
                    label: const Text('Manage Batches', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (batches.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'No batches registered yet for this expiry-tracked item. Adjust stock to record a batch.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.4), // Batch No
                      1: FlexColumnWidth(1.6), // Expiry
                      2: FlexColumnWidth(1.4), // Mfg Date
                      3: FlexColumnWidth(1.2), // MRP
                      4: FlexColumnWidth(1.2), // Sale Price
                      5: FlexColumnWidth(1.2), // Cost Price
                      6: FlexColumnWidth(1.2), // Qty
                      7: FlexColumnWidth(1.4), // Status
                    },
                    children: [
                      // Table Header
                      TableRow(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF273549) : const Color(0xFFF1F5F9),
                        ),
                        children: [
                          _batchHeaderCell('Batch No'),
                          _batchHeaderCell('Expiry Date'),
                          _batchHeaderCell('Mfg Date'),
                          _batchHeaderCell('MRP'),
                          _batchHeaderCell('Sale Price'),
                          _batchHeaderCell('Cost Price'),
                          _batchHeaderCell('Stock Qty'),
                          _batchHeaderCell('Status'),
                        ],
                      ),
                      // Batch Rows
                      ...batches.map((b) {
                        final expMs = b.expiryDateUtcMs;
                        String expDateStr = '—';
                        String expBadge = 'Safe';
                        Color expBadgeColor = Colors.green;

                        if (expMs != null) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(expMs);
                          expDateStr = DateFormat('dd MMM yyyy').format(dt);
                          final diff = dt.difference(DateTime.now()).inDays;
                          if (diff < 0) {
                            expBadge = 'Expired';
                            expBadgeColor = Colors.red;
                          } else if (diff <= 30) {
                            expBadge = '$diff days left';
                            expBadgeColor = Colors.orange;
                          }
                        }

                        final mfgStr = b.mfgDateUtcMs != null
                            ? DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(b.mfgDateUtcMs!))
                            : '—';

                        return TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              ),
                            ),
                          ),
                          children: [
                            _batchDataCell(b.batchNo?.isNotEmpty == true ? b.batchNo! : '—', isBold: true),
                            _batchDataCell(expDateStr),
                            _batchDataCell(mfgStr),
                            _batchDataCell(b.mrp != null ? '$cur${b.mrp!.toStringAsFixed(2)}' : '—'),
                            _batchDataCell(b.salePrice != null ? '$cur${b.salePrice!.toStringAsFixed(2)}' : '—'),
                            _batchDataCell(b.costPrice != null ? '$cur${b.costPrice!.toStringAsFixed(2)}' : '—'),
                            _batchDataCell('${b.quantity ?? 0}', isBold: true),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: expBadgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: expBadgeColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    expBadge,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: expBadgeColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

          // ── Bottom Quick Action Toolbar ──
          Row(
            children: [
              if (canAdjust)
                FilledButton.tonalIcon(
                  onPressed: onAdjustStock,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Adjust Stock', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              const SizedBox(width: 8),
              if (canUpdate)
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Item'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => Get.dialog(DialogPrintBarcode(item: item)),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Print Barcode'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              if (item.hasExpiry == true)
                OutlinedButton.icon(
                  onPressed: onViewBatches,
                  icon: const Icon(Icons.layers_rounded, size: 16),
                  label: const Text('Batch History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              const Spacer(),
              if (canDelete) ...[
                TextButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    (item.isActive ?? true) ? Icons.block_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: (item.isActive ?? true) ? Colors.orange.shade700 : Colors.green.shade600,
                  ),
                  label: Text(
                    (item.isActive ?? true) ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                      color: (item.isActive ?? true) ? Colors.orange.shade700 : Colors.green.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _keyValRow(String key, String value, {Color? valueColor, Widget? trailingBadge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 5),
                trailingBadge,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _batchHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _batchDataCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
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

      IconData sortIcon;
      if (!isSelected) {
        sortIcon = Icons.unfold_more_rounded;
      } else if (asc) {
        sortIcon = Icons.arrow_upward_rounded;
      } else {
        sortIcon = Icons.arrow_downward_rounded;
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
                  color: isSelected ? iconColor.withValues(alpha: 0.15) : bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: iconColor),
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
// Expiry Badge
// ─────────────────────────────────────────────────────────────────────────────

class _ExpiryBadge extends StatelessWidget {
  final EntityItem item;
  final ControllerHomeItem controller;

  const _ExpiryBadge({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (item.hasExpiry != true) {
      return Text('—', style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    }

    final expiryMs = controller.getNearestExpiryMsForItem(item.id);
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
