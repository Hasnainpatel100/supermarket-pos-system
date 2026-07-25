import '../enums/enum_audit_action.dart';
import '../enums/enum_audit_module.dart';
import '../model/entity_item.dart';
import '../objectbox.g.dart';
import 'service_audit_log.dart';

class ItemService {
  final Box<EntityItem> itemBox;

  ItemService(this.itemBox);

  /// CREATE ITEM
  void createItem(EntityItem item) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    item.createdAtUtcMs = now;
    item.updatedAtUtcMs = now;
    item.totalQty = item.totalQty ?? 0;
    item.isActive = true;

    final id = itemBox.put(item);
    item.id = id;

    AuditLogService.instance.logCreate(
      module: AuditModule.inventory,
      entityType: 'EntityItem',
      entityId: '$id',
      description: 'Created item "${item.name}" (SKU: ${item.sku ?? item.barcode ?? 'N/A'}).',
    );
  }

  /// UPDATE ITEM
  void updateItem(EntityItem item) {
    item.updatedAtUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    itemBox.put(item);

    AuditLogService.instance.logUpdate(
      module: AuditModule.inventory,
      entityType: 'EntityItem',
      entityId: '${item.id}',
      description: 'Updated item "${item.name}" (Price: ₹${item.sellingPrice}).',
    );
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

    AuditLogService.instance.logAction(
      module: AuditModule.inventory,
      action: AuditAction.update,
      entityType: 'EntityItem',
      entityId: '${item.id}',
      description: 'Adjusted stock for "${item.name}" by ${delta >= 0 ? "+$delta" : delta}. New total: $newQty.',
      reason: 'Stock Adjustment',
    );

    return true;
  }

  /// DELETE ITEM
  bool deleteItem(int id) {
    final item = itemBox.get(id);
    final name = item?.name ?? 'Item #$id';
    final result = itemBox.remove(id);

    if (result) {
      AuditLogService.instance.logDelete(
        module: AuditModule.inventory,
        entityType: 'EntityItem',
        entityId: '$id',
        description: 'Deleted item "$name".',
      );
    }

    return result;
  }
}
