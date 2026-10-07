import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../model/entity_item.dart';

/// Dialog to display all details of an EntityItem.
/// Uses GetX stateless pattern.
class DialogItemDetail extends StatelessWidget {
  final EntityItem entityItem;

  const DialogItemDetail({super.key, required this.entityItem});

  @override
  Widget build(BuildContext context) {
    final hasBarcode =
        entityItem.barcode != null && entityItem.barcode!.trim().isNotEmpty;

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ── Header ──
              Center(
                child: Text(
                  'Item Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 24),

              /// ── Info Rows ──
              _infoRow(context, 'Name', entityItem.name),
              _infoRow(context, 'SKU', entityItem.sku),
              _infoRow(context, 'Barcode', entityItem.barcode),
              _infoRow(context, 'Unit', entityItem.unit),
              _infoRow(
                context,
                'Cost Price',
                entityItem.costPrice?.toStringAsFixed(2),
              ),
              _infoRow(
                context,
                'Selling Price',
                entityItem.sellingPrice?.toStringAsFixed(2),
              ),
              if (entityItem.taxName != null && entityItem.taxName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tax Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade600)),
                const Divider(),
                _infoRow(context, 'Tax Type', entityItem.taxType ?? 'Inclusive'),
                _infoRow(context, 'Tax Name', entityItem.taxName),
                _infoRow(context, 'Tax Rate', entityItem.taxRate != null ? '${entityItem.taxRate}%' : null),
                _infoRow(context, 'Tax Amount', entityItem.taxAmount?.toStringAsFixed(2)),
                _infoRow(context, 'Base Price', entityItem.priceBeforeTax?.toStringAsFixed(2)),
                const Divider(),
                const SizedBox(height: 8),
              ],
              _infoRow(context, 'Stock Qty', '${entityItem.totalQty ?? 0}'),
              _infoRow(
                context,
                'Has Expiry',
                (entityItem.hasExpiry ?? false) ? 'Yes' : 'No',
              ),
              _infoRow(
                context,
                'Status',
                (entityItem.isActive ?? true) ? 'Active' : 'Inactive',
              ),
              _infoRow(
                context,
                'Created',
                entityItem.createdAtUtcMs != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        entityItem.createdAtUtcMs!,
                        isUtc: true,
                      ).toLocal().toString().substring(0, 16)
                    : null,
              ),
              _infoRow(
                context,
                'Last Updated',
                entityItem.updatedAtUtcMs != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        entityItem.updatedAtUtcMs!,
                        isUtc: true,
                      ).toLocal().toString().substring(0, 16)
                    : null,
              ),

              /// ── Barcode / QR Section ──
              if (hasBarcode) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),

                /// 1D Barcode
                Center(
                  child: Container(
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
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: entityItem.barcode!,
                          width: 280,
                          height: 70,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                /// 2D QR Code
                Center(
                  child: Container(
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
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        BarcodeWidget(
                          barcode: Barcode.qrCode(),
                          data: entityItem.barcode!,
                          width: 150,
                          height: 150,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              /// ── Close ──
              Center(
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}
