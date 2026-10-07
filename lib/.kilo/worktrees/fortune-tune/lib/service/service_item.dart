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
    item.updatedAtUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    itemBox.put(item);
  }

  /// GET ALL ITEMS
  List<EntityItem> getAllItems() {
    return itemBox.getAll();
  }

  /// SEARCH BY BARCODE
  EntityItem? findByBarcode(String barcode) {
    final query = itemBox.query(EntityItem_.barcode.equals(barcode)).build();

    final result = query.findFirst();
    query.close();

    return result;
  }

  /// SEARCH ITEMS by name or barcode (case-insensitive)
  List<EntityItem> searchItems(String query) {
    if (query.trim().isEmpty) return getAllItems();

    final q = itemBox
        .query(
          EntityItem_.name
              .contains(query, caseSensitive: false)
              .or(EntityItem_.barcode.contains(query, caseSensitive: false))
              .or(EntityItem_.sku.contains(query, caseSensitive: false)),
        )
        .build();

    final results = q.find();
    q.close();
    return results;
  }

  /// ADJUST STOCK — increment or decrement totalQty
  /// Returns true on success, false if stock would go negative
  bool adjustStock(EntityItem item, int delta) {
    final currentQty = item.totalQty ?? 0;
    final newQty = currentQty + delta;

    if (newQty < 0) return false;

    item.totalQty = newQty;
    item.updatedAtUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    itemBox.put(item);
    return true;
  }

  /// DELETE ITEM
  bool deleteItem(int id) {
    return itemBox.remove(id);
  }
}
