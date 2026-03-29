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

  /// Denormalized HSN code — snapshot at time of purchase
  String? hsnCode;

  /// How many units were ordered
  double? orderedQty;

  /// Price per unit as entered by staff
  /// May be inclusive or exclusive of tax depending on isTaxInclusive
  double? unitCost;

  // ── Discount ──

  /// Discount percentage on this line e.g. 5.0 = 5%
  double? discountPercent;

  /// Computed discount amount = (unitCost × qty) × discountPercent/100
  /// Stored for audit trail
  double? discountAmount;

  // ── Tax ──
  /// Auto-filled from EntityItem.taxRate, overridable by staff
  double? taxRate;

  /// 'GST', 'IGST', or null (no tax)
  /// Auto-filled from EntityItem.taxType, overridable
  String? taxType;

  /// true  = With Tax    → unitCost already includes tax, extract it
  /// false = Without Tax → unitCost is base, add tax on top
  /// Auto-filled from EntityItem.isTaxInclusive, overridable
  bool? isTaxInclusive;

  // ── Computed Amounts (stored for audit) ──

  /// Line amount after discount, BEFORE tax
  double? lineAmountExcl;

  /// Tax amount for this line
  double? taxAmount;

  /// Final line total = lineAmountExcl + taxAmount (Without Tax)
  ///                  = unitCost × qty - discountAmount (With Tax)
  double? lineAmountIncl;

  // ── Receiving ──

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
    this.hsnCode,
    this.orderedQty,
    this.unitCost,
    this.discountPercent,
    this.discountAmount,
    this.taxRate,
    this.taxType,
    this.isTaxInclusive = false,
    this.lineAmountExcl,
    this.taxAmount,
    this.lineAmountIncl,
    this.receivedQty = 0,
  });

  /// Remaining qty not yet received
  double get pendingQty => (orderedQty ?? 0) - (receivedQty ?? 0);

  /// True when all ordered quantity has been received
  bool get isFullyReceived => pendingQty <= 0;

  /// Final line total for display
  double get lineTotal => lineAmountIncl ?? (orderedQty ?? 0) * (unitCost ?? 0);
}
