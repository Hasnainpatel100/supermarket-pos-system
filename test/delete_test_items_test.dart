import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/objectbox.g.dart';
import 'package:super_market/model/entity_item.dart';
import 'package:super_market/model/entity_item_batch.dart';

void main() {
  test('Test deletion of test items on backup directory', () {
    final dir = Directory('market_backup_safety_check');
    expect(dir.existsSync(), true);

    final store = Store(getObjectBoxModel(), directory: dir.path);
    final itemBox = store.box<EntityItem>();
    final batchBox = store.box<EntityItemBatch>();

    final initialCount = itemBox.count();
    print('Initial item count in backup: $initialCount');

    // 1. Find all items to delete
    final q = itemBox
        .query(
          EntityItem_.sku.startsWith('TEST-SKU-')
              .or(EntityItem_.barcode.startsWith('TEST-BAR-')),
        )
        .build();
    final testItemIds = q.findIds();
    q.close();

    print('Found ${testItemIds.length} test item IDs to delete.');

    // 2. Delete in chunks of 2,000
    const chunkSize = 2000;
    int deleted = 0;
    for (int i = 0; i < testItemIds.length; i += chunkSize) {
      final end = (i + chunkSize < testItemIds.length) ? i + chunkSize : testItemIds.length;
      final chunk = testItemIds.sublist(i, end);
      store.runInTransaction(TxMode.write, () {
        itemBox.removeMany(chunk);
      });
      deleted += chunk.length;
      print('Deleted $deleted / ${testItemIds.length} items...');
    }

    // 3. Remove orphaned batches (batches where itemId is null or item no longer exists)
    final allBatches = batchBox.getAll();
    final orphanBatchIds = <int>[];
    for (final b in allBatches) {
      if (b.id != null && (b.itemId == null || itemBox.get(b.itemId!) == null)) {
        orphanBatchIds.add(b.id!);
      }
    }
    if (orphanBatchIds.isNotEmpty) {
      batchBox.removeMany(orphanBatchIds);
      print('Removed ${orphanBatchIds.length} orphaned batches.');
    }

    // 4. Verification
    final finalCount = itemBox.count();
    final remainingBatches = batchBox.count();
    print('Final item count: $finalCount');
    print('Remaining batches count: $remainingBatches');

    final remainingItems = itemBox.getAll();
    print('\nRemaining items:');
    for (final item in remainingItems) {
      print('  - [id: ${item.id}] "${item.name}" | sku: "${item.sku}" | barcode: "${item.barcode}"');
    }

    expect(finalCount, 4);
    expect(remainingItems.any((it) => it.name == 'Crunches'), true);
    expect(remainingItems.any((it) => it.name == 'Basmati katta'), true);

    store.close();
    print('\nTest run completed successfully!');
  });
}
