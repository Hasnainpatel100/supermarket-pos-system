import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/home/fragment/pos/pos_item_card.dart';
import '../../../customer/activity_customer_form.dart';
import '../../../item_form/activity_item_form.dart';
import 'controller_home_pos.dart';

class FragmentHomePos extends StatelessWidget {
  const FragmentHomePos({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is found or put
    final controller = Get.put(ControllerHomePos());
    // Refresh data every time POS tab is shown
    controller.loadItems();
    controller.loadCustomers();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          /// ── LEFT SIDE (60%) ──
          Expanded(
            flex: 6,
            child: Container(
              color: colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  /// Search & New Item
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.searchController,
                          decoration: InputDecoration(
                            hintText: 'Search Item (Name, SKU, Barcode)...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            suffixIcon: Obx(
                              () => controller.rxSearchQuery.value.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        controller.searchController.clear();
                                        controller.rxSearchQuery.value = '';
                                      },
                                    )
                                  : const SizedBox(),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: colorScheme.surface,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (val) =>
                              controller.rxSearchQuery.value = val,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        onPressed: () async {
                          await Get.to(() => const ActivityItemForm());
                          controller.loadItems();
                        },
                        icon: const Icon(Icons.add_box_rounded),
                        label: const Text("New Item"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// Item Grid
                  Expanded(
                    child: Obx(() {
                      if (controller.rxListItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No items found",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  3, // Adjust based on screen width if needed
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: controller.rxListItems.length,
                        itemBuilder: (context, index) {
                          final item = controller.rxListItems[index];
                          return PosItemCard(
                            item: item,
                            onTap: () => controller.addToCart(item),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          /// ── RIGHT SIDE (40%) ──
          Expanded(
            flex: 4,
            child: Container(
              color: colorScheme.surface,
              child: Column(
                children: [
                  /// Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colorScheme.primary),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "New Bill",
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        /// Customer Selection
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Obx(() {
                              final selected =
                                  controller.rxSelectedCustomer.value;
                              return Card(
                                color: colorScheme.onPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () =>
                                      _showCustomerDialog(context, controller),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: colorScheme.onPrimary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            selected != null
                                                ? "${selected.name}"
                                                : "Select Customer (Optional)",
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (selected != null)
                                          InkWell(
                                            onTap: () =>
                                                controller.selectCustomer(null),
                                            child: Icon(
                                              Icons.close,
                                              color: colorScheme.onPrimary
                                                  .withValues(alpha: 0.7),
                                              size: 18,
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: colorScheme.onPrimary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        IconButton(
                          onPressed: controller.clearCart,
                          icon: Icon(
                            Icons.delete_sweep_rounded,
                            color: colorScheme.onPrimary,
                          ),
                          tooltip: "Clear Cart",
                        ),
                      ],
                    ),
                  ),

                  /// Cart List
                  Expanded(
                    child: Obx(() {
                      if (controller.rxCartItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Cart is empty",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.rxCartItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final cartItem = controller.rxCartItems[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              cartItem.itemName ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${cartItem.itemBarcode} | ${cartItem.unit}",
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                  color: Colors.red.shade400,
                                  onPressed: () =>
                                      controller.updateQty(index, -1),
                                ),
                                Text(
                                  "${cartItem.qty}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                  ),
                                  color: Colors.green.shade600,
                                  onPressed: () =>
                                      controller.updateQty(index, 1),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${controller.serviceCurrency.rxCurrency.value}${(cartItem.total ?? 0).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),

                  /// Totals Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      border: Border(
                        top: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Obx(
                      () => Column(
                        children: [
                          _SummaryRow(
                            label: "Subtotal",
                            value: controller.rxSubTotal.value,
                          ),

                          /// Tax & Discount Inputs
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "Tax (%)",
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      final rate = double.tryParse(val) ?? 0;
                                      controller.setTaxRate(rate);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "Discount (${controller.serviceCurrency.rxCurrency.value})",
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      final amount = double.tryParse(val) ?? 0;
                                      controller.setDiscount(amount);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _SummaryRow(
                            label: "Tax Amount",
                            value: controller.rxTaxAmount.value,
                            fontSize: 13,
                          ),
                          _SummaryRow(
                            label: "Discount",
                            value: controller.rxDiscountAmount.value,
                            isNegative: true,
                            fontSize: 13,
                          ),

                          const Divider(height: 24),

                          _SummaryRow(
                            label: "Grand Total",
                            value: controller.rxGrandTotal.value,
                            isBold: true,
                            fontSize: 24,
                            color: colorScheme.primary,
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text("HOLD"),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed: controller.settleBill,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text(
                                    "SETTLE BILL",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, ControllerHomePos controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Customer",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search customer...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) =>
                          controller.rxCustomerSearchQuery.value = val,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      Get.back(); // close dialog
                      await Get.to(
                        () => const ActivityCustomerForm(),
                      ); // Go to form
                      controller.loadCustomers(); // reload
                      _showCustomerDialog(
                        context,
                        controller,
                      ); // reopen (optional, maybe disjointed UX)
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text("New"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: Obx(() {
                  if (controller.rxListCustomers.isEmpty) {
                    return const Center(child: Text("No customers found"));
                  }
                  return ListView.separated(
                    itemCount: controller.rxListCustomers.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, idx) {
                      final cust = controller.rxListCustomers[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            cust.name != null && cust.name!.isNotEmpty
                                ? cust.name![0]
                                : '?',
                          ),
                        ),
                        title: Text("${cust.name}"),
                        subtitle: Text(cust.phone ?? ''),
                        onTap: () {
                          controller.selectCustomer(cust);
                          Get.back();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/*

class _ItemCard extends StatelessWidget {
  final EntityItem item;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stock = item.totalQty ?? 0;
    final isOutOfStock = stock <= 0;

    return Opacity(
      opacity: isOutOfStock ? 0.5 : 1.0,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                            colorScheme.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 36,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    // Stock Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOutOfStock ? "Out of Stock" : "Qty: $stock",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? 'Unknown',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Code: ${item.sku ?? '-'}",
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(///todo
                          "${(item.sellingPrice ?? 0).toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "/${item.unit ?? 'pc'}",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isNegative;
  final bool isBold;
  final double fontSize;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isBold = false,
    this.fontSize = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerHomePos());
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            "${isNegative ? '-' : ''}${controller.serviceCurrency.rxCurrency.value}${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: fontSize,
              color: color ?? (isNegative ? Colors.red : colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
