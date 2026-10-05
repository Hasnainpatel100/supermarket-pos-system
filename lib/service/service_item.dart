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
  ///
  /// ⚡ PERFORMANCE NOTE: For large catalogs (5000+ items), prefer using
  /// [searchItems] with pagination or [queryPaginated] instead of loading
  /// the entire table into memory.
  List<EntityItem> getAllItems() {
    return itemBox.getAll();
  }

  /// GET ITEMS — paginated query using ObjectBox offset/limit.
  ///
  /// ⚡ PERFORMANCE: Only loads [limit] items into memory at a time,
  ///    instead of the entire catalog. Essential for stores with
  ///    10,000+ SKUs.
  List<EntityItem> queryPaginated({
    int offset = 0,
    int limit = 20,
  }) {
    final query = itemBox.query().build()
      ..offset = offset
      ..limit = limit;
    final results = query.find();
    query.close();
    return results;
  }

  /// ⚡ HIGH-PERFORMANCE: Query, search, sort, and paginate at the native ObjectBox C engine level.
  /// Does NOT load the entire database into memory.
  ({List<EntityItem> items, int totalCount}) getItemsPaged({
    String query = '',
    String sortField = '',
    bool sortAsc = true,
    int offset = 0,
    int limit = 20,
  }) {
    final trimmed = query.trim();
    Condition<EntityItem>? condition;
    if (trimmed.isNotEmpty) {
      condition = EntityItem_.name
          .contains(trimmed, caseSensitive: false)
          .or(EntityItem_.barcode.contains(trimmed, caseSensitive: false))
          .or(EntityItem_.sku.contains(trimmed, caseSensitive: false));
    }

    final queryBuilder = itemBox.query(condition);

    if (sortField == 'name') {
      queryBuilder.order(EntityItem_.name, flags: sortAsc ? 0 : Order.descending);
    } else if (sortField == 'price') {
      queryBuilder.order(EntityItem_.sellingPrice, flags: sortAsc ? 0 : Order.descending);
    } else if (sortField == 'stock') {
      queryBuilder.order(EntityItem_.totalQty, flags: sortAsc ? 0 : Order.descending);
    }

    final q = queryBuilder.build();
    final total = q.count();
    q
      ..offset = offset
      ..limit = limit;
    final items = q.find();
    q.close();

    return (items: items, totalCount: total);
  }

  /// SEARCH BY BARCODE
  EntityItem? findByBarcode(String barcode) {
    final query = itemBox.query(EntityItem_.barcode.equals(barcode)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  /// SEARCH ITEMS by name or barcode (case-insensitive).
  ///
  /// ⚡ PERFORMANCE: Uses ObjectBox indexed queries with proper
  ///    query.close() to prevent C-library memory leaks.
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

  /// COUNT total items (no memory allocation — ObjectBox handles it natively).
  int count() => itemBox.count();
}
