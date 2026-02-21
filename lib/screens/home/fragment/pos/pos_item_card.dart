
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/entity_item.dart';
import 'controller_home_pos.dart';

class PosItemCard extends StatelessWidget {
  final EntityItem item;
  final VoidCallback onTap;

  const PosItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerHomePos());

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
                        Text(
                          "${controller.serviceCurrency.rxCurrency.value}${(item.sellingPrice ?? 0).toStringAsFixed(2)}",
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
