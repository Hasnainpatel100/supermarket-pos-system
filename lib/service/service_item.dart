import '../model/entity_item.dart';
import '../objectbox.g.dart';

class ItemService {
  final Box<EntityItem> itemBox;

  ItemService(this.itemBox);

  /// CREATE ITEM
  void createItem(EntityItem item) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    item.createdAtUtcMs = now;
    item.updatedAtUtcMs = now;
    item.totalQty = 0;
    item.isActive = true;

    itemBox.put(item);
  }

  /// UPDATE ITEM
  void updateItem(EntityItem item) {
    item.updatedAtUtcMs =
        DateTime.now().toUtc().millisecondsSinceEpoch;

    itemBox.put(item);
  }

  /// GET ALL ITEMS
  List<EntityItem> getAllItems() {
    return itemBox.getAll();
  }

  /// SEARCH BY BARCODE
  EntityItem? findByBarcode(String barcode) {
    final query = itemBox
        .query(EntityItem_.barcode.equals(barcode))
        .build();

    final result = query.findFirst();
    query.close();

    return result;
  }
}
