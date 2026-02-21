import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

class DialogItemBatches extends StatelessWidget {
  final EntityItem entityItem;

  const DialogItemBatches({super.key, required this.entityItem});

  @override
  Widget build(BuildContext context) {
    final ob = Get.find<ServiceObjectBox>();
    final boxBatch = ob.box<EntityItemBatch>();

    // Query batches for this item
    final batches = boxBatch
        .query(EntityItemBatch_.itemId.equals(entityItem.id ?? 0))
        .order(EntityItemBatch_.expiryDateUtcMs)
        .build()
        .find();

    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            /// Header
            Row(
              children: [
                Icon(Icons.history_edu_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Batches for ${entityItem.name}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),

            /// List of Batches
            Expanded(
              child: batches.isEmpty
                  ? Center(
                      child: Text(
                        "No batches found for this item.",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: batches.length,
                      itemBuilder: (context, index) {
                        final batch = batches[index];
                        final expiry = batch.expiryDateUtcMs != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                batch.expiryDateUtcMs!,
                                isUtc: true,
                              ).toLocal()
                            : null;

                        final received = batch.receivedAtUtcMs != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                batch.receivedAtUtcMs!,
                                isUtc: true,
                              ).toLocal()
                            : null;

                        final dateFormat = DateFormat('yyyy-MM-dd');

                        return Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                /// Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                /// Batch Info
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Batch: ${batch.batchNo ?? "N/A"}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (received != null)
                                        Text(
                                          'Rcvd: ${dateFormat.format(received)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                /// Expiry
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Qty: ${batch.quantity ?? 0}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (expiry != null)
                                        Text(
                                          'Exp: ${dateFormat.format(expiry)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade400,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
