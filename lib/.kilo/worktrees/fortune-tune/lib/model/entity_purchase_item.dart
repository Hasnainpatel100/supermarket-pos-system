import 'package:objectbox/objectbox.dart';

/// One line item inside a Purchase Order.
/// receivedQty is updated when goods arrive via StockTransaction.
@Entity()
class EntityPurchaseItem {
  @Id()
  int id = 0;

  /// FK → EntityPurchase.id
  @Index()
  int? purchaseId;

  /// FK → EntityItem.id
  int? itemId;

  /// Denormalized item name for display without joins
  String? itemName;

  /// Denormalized unit for display
  String? itemUnit;

  /// How many units were ordered
  double? orderedQty;

  /// Cost per unit at time of purchase
  double? unitCost;

  /// Cumulative quantity received so far.
  /// Updated each time goods are received (StockTransaction created).
  /// DO NOT update manually — always driven by receive goods flow.
  double? receivedQty;

  EntityPurchaseItem({
    this.id = 0,
    this.purchaseId,
    this.itemId,
    this.itemName,
    this.itemUnit,
    this.orderedQty,
    this.unitCost,
    this.receivedQty = 0,
  });

  /// Convenience: total cost for this line
  double get lineTotal => (orderedQty ?? 0) * (unitCost ?? 0);

  /// Convenience: remaining qty not yet received
  double get pendingQty => (orderedQty ?? 0) - (receivedQty ?? 0);

  /// True when all ordered quantity has been received
  bool get isFullyReceived => pendingQty <= 0;
}
