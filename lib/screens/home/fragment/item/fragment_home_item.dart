import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/item_form/activity_item_form.dart';
import '../../../../item_form/activity_item_batch_form.dart';
import 'package:super_market/widget/my_card.dart';

import '../../../../model/entity_item.dart';
import '../../../../util/snackbar_util.dart';
import 'controller_home_item.dart';
import 'dialog_adjust_stock.dart';
import 'dialog_item_detail.dart';

class FragmentHomeItem extends StatelessWidget {
  const FragmentHomeItem({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeItem controller = Get.put(ControllerHomeItem());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.inventory_2_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          /// ── Button: Adjust Stock ──
          OutlinedButton.icon(
            onPressed: () => _showSelectItemForAdjust(context, controller),
            icon: Icon(
              Icons.tune_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            label: Text(
              'Adjust Stock',
              style: TextStyle(color: colorScheme.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 8),

          /// ── Button: New Item ──
          FilledButton.icon(
            onPressed: () async {
              await Get.to(() => const ActivityItemForm());
              controller.loadItems();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Item'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, or barcode...',
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

      body: Obx(
        () => controller.rxListItem.isEmpty
            ? Center(
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
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add a new item to get started',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              )
            : MyCard(
                margin: const EdgeInsets.all(16),
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
                      columns: [
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.label_outlined,
                                size: 15,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              const Text('Name'),
                            ],
                          ),
                        ),
                        const DataColumn(label: Text('SKU')),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 15,
                                color: Colors.deepPurple.shade400,
                              ),
                              const SizedBox(width: 4),
                              const Text('Barcode'),
                            ],
                          ),
                        ),
                        const DataColumn(label: Text('Unit')),
                        DataColumn(
                          numeric: true,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 14,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 3),
                              const Text('Cost'),
                            ],
                          ),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 14,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 3),
                              const Text('Price'),
                            ],
                          ),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warehouse_outlined,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              const Text('Stock'),
                            ],
                          ),
                        ),
                        const DataColumn(label: Text('Status')),
                        const DataColumn(label: Text('')),
                      ],
                      rows: controller.rxListItem.map((EntityItem item) {
                        final isActive = item.isActive ?? true;

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((
                            states,
                          ) {
                            if (!isActive) {
                              return Colors.grey.withValues(alpha: 0.05);
                            }
                            return null;
                          }),
                          cells: [
                            /// Name — bold for active
                            DataCell(
                              Text(
                                item.name ?? '-',
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isActive ? null : Colors.grey,
                                  fontStyle: isActive
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            /// SKU
                            DataCell(
                              Text(
                                item.sku ?? '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive
                                      ? Colors.grey.shade700
                                      : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            /// Barcode
                            DataCell(
                              Text(
                                item.barcode != null && item.barcode!.isNotEmpty
                                    ? item.barcode!
                                    : '-',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: isActive
                                      ? Colors.deepPurple.shade400
                                      : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            /// Unit
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.blueGrey.withValues(alpha: 0.08)
                                      : Colors.grey.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.unit ?? '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isActive
                                        ? Colors.blueGrey.shade700
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),

                            /// Cost Price
                            DataCell(
                              Text(
                                item.costPrice != null
                                    ? '₹${item.costPrice!.toStringAsFixed(2)}'
                                    : '-',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isActive
                                      ? Colors.orange.shade700
                                      : Colors.grey,
                                ),
                              ),
                            ),

                            /// Selling Price
                            DataCell(
                              Text(
                                item.sellingPrice != null
                                    ? '₹${item.sellingPrice!.toStringAsFixed(2)}'
                                    : '-',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.teal.shade700
                                      : Colors.grey,
                                ),
                              ),
                            ),

                            /// Stock
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? ((item.totalQty ?? 0) <= 0
                                            ? Colors.red.withValues(alpha: 0.08)
                                            : Colors.green.withValues(
                                                alpha: 0.08,
                                              ))
                                      : Colors.grey.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.totalQty ?? 0}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isActive
                                        ? ((item.totalQty ?? 0) <= 0
                                              ? Colors.red.shade700
                                              : Colors.green.shade700)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),

                            /// Status badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.shade600
                                            : Colors.red.shade500,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// ── Action Column: PopupMenuButton ──
                            DataCell(
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.grey.shade500,
                                ),
                                tooltip: 'Actions',
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _onEdit(item, controller);
                                      break;
                                    case 'add_batch':
                                      // Using full path or ensuring import is available
                                      // I need to make sure ActivityItemBatchForm is imported
                                      _onAddBatch(item);
                                      break;
                                    case 'details':
                                      _onDetails(item);
                                      break;
                                    case 'toggle':
                                      _confirmToggleActive(
                                        context,
                                        item,
                                        controller,
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  if (item.hasExpiry == true)
                                    PopupMenuItem(
                                      value: 'add_batch',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.post_add_rounded,
                                            size: 20,
                                            color: Colors.orange.shade600,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text('Add Batch'),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 20,
                                          color: Colors.deepPurple.shade400,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(
                                          isActive
                                              ? Icons.toggle_off_rounded
                                              : Icons.toggle_on_rounded,
                                          size: 22,
                                          color: isActive
                                              ? Colors.red.shade400
                                              : Colors.green.shade500,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          isActive ? 'Deactivate' : 'Activate',
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.red.shade400
                                                : Colors.green.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
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
    );
  }

  /// ── Edit Item ──
  void _onEdit(EntityItem item, ControllerHomeItem controller) async {
    await Get.to(() => const ActivityItemForm(), arguments: item);
    controller.loadItems();
  }

  /// ── Add Batch ──
  void _onAddBatch(EntityItem item) {
    Get.to(() => const ActivityItemBatchForm(), arguments: item);
  }

  /// ── View Item Details ──
  void _onDetails(EntityItem item) {
    Get.dialog(DialogItemDetail(entityItem: item));
  }

  /// ── Confirm before toggling active/inactive ──
  void _confirmToggleActive(
    BuildContext context,
    EntityItem item,
    ControllerHomeItem controller,
  ) {
    final isCurrentlyActive = item.isActive ?? true;
    final colorScheme = Theme.of(context).colorScheme;

    Get.defaultDialog(
      title: isCurrentlyActive ? 'Deactivate Item?' : 'Activate Item?',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText:
          'Are you sure you want to ${isCurrentlyActive ? "deactivate" : "activate"} "${item.name}"?',
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentlyActive
              ? Colors.red.shade400
              : Colors.green.shade500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: Icon(
          isCurrentlyActive
              ? Icons.toggle_off_rounded
              : Icons.toggle_on_rounded,
          size: 20,
        ),
        onPressed: () {
          controller.toggleActive(item);
          Get.back();
          SnackbarUtil.showSuccess(
            '${item.name} ${!(isCurrentlyActive) ? "activated" : "deactivated"}',
          );
        },
        label: Text(isCurrentlyActive ? 'Deactivate' : 'Activate'),
      ),
      cancel: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }

  /// Show a quick select dialog for the AppBar "Adjust Stock" button
  void _showSelectItemForAdjust(
    BuildContext context,
    ControllerHomeItem controller,
  ) {
    if (controller.rxListItem.isEmpty) {
      SnackbarUtil.showError('No items available');
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 420,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Select Item to Adjust',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 4),
              Expanded(
                child: Obx(
                  () => ListView.separated(
                    itemCount: controller.rxListItem.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, index) {
                      final item = controller.rxListItem[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          item.name ?? 'Unnamed',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Stock: ${item.totalQty ?? 0}',
                          style: TextStyle(
                            color: (item.totalQty ?? 0) <= 0
                                ? Colors.red.shade400
                                : Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        onTap: () {
                          Get.back();
                          Get.dialog(DialogAdjustStock(entityItem: item));
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
