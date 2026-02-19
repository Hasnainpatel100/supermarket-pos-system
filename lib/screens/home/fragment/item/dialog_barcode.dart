import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/entity_item.dart';
import 'controller_home_item.dart';

/// Dialog to display and auto-generate barcode/QR for an EntityItem.
/// Uses GetX stateless pattern.
class DialogBarcode extends StatelessWidget {
  final EntityItem entityItem;

  const DialogBarcode({super.key, required this.entityItem});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeItem controller = Get.find();
    final hasBarcode =
        entityItem.barcode != null && entityItem.barcode!.trim().isNotEmpty;

    return Dialog(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ── Header ──
              Text(
                entityItem.name ?? 'Unnamed Item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (entityItem.sku != null && entityItem.sku!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'SKU: ${entityItem.sku}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 20),

              if (hasBarcode) ...[
                /// ── 1D Barcode (Code128) ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '1D Barcode',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: entityItem.barcode!,
                        width: 300,
                        height: 80,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                /// ── 2D QR Code ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '2D QR Code',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BarcodeWidget(
                        barcode: Barcode.qrCode(),
                        data: entityItem.barcode!,
                        width: 180,
                        height: 180,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                /// ── Barcode value label ──
                SelectableText(
                  entityItem.barcode!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                /// ── No barcode — show generate option ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 48,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No barcode assigned to this item.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          controller.generateBarcode(entityItem);
                          Get.back();
                          // Re-open dialog with updated item
                          final updated = controller.rxListItem
                              .firstWhereOrNull((e) => e.id == entityItem.id);
                          if (updated != null) {
                            Get.dialog(DialogBarcode(entityItem: updated));
                          }
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Auto Generate Barcode'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              /// ── Close button ──
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
