import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../model/entity_item.dart';
import '../../../../../model/entity_item_batch.dart';
import '../../../../../objectbox.g.dart';
import '../../../../../service/service_object_box.dart';

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

                                /// Expiry & Status
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Qty: ${batch.quantity ?? 0}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildExpiryBadge(expiry),
                                        ],
                                      ),
                                      if (expiry != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Exp: ${dateFormat.format(expiry)}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
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

  Widget _buildExpiryBadge(DateTime? expiry) {
    if (expiry == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Text(
          'No Expiry',
          style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDate = DateTime(expiry.year, expiry.month, expiry.day);
    final diffDays = expDate.difference(today).inDays;

    if (diffDays < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFEF4444)),
            const SizedBox(width: 3),
            Text(
              diffDays == -1 ? 'Expired yesterday' : 'Expired ${-diffDays}d ago',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (diffDays <= 7) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFEF4444)),
            const SizedBox(width: 3),
            Text(
              diffDays == 0 ? 'Expires TODAY' : 'Expires in ${diffDays}d',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (diffDays <= 30) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFD97706)),
            const SizedBox(width: 3),
            Text(
              'Expires in ${diffDays}d',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 3),
            Text(
              'Fresh (${diffDays}d)',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
  }
}
