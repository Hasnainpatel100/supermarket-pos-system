import 'package:objectbox/objectbox.dart';

/// Represents actual items received under a receipt.
/// This is NOT the same as ordered items.
@Entity()
class EntityPurchaseReceiptItem {
  @Id()
  int id = 0;

  /// FK → EntityPurchaseReceipt.id
  @Index()
  int? receiptId;

  /// 🔥 IMPORTANT LINK → EntityPurchaseItem.id
  /// Helps map ordered item → received item
  int? purchaseItemId;

  /// FK → EntityItem.id
  int? itemId;

  /// Denormalized for UI
  String? itemName;
  String? itemUnit;

  // ── Actual Receiving Data ──

  /// Quantity actually received
  double? receivedQty;

  /// Final unit cost from supplier invoice
  double? unitCost;

  /// Computed line total
  double? lineAmount;

  // ── Batch Tracking (VERY PRO FEATURE) ──

  String? batchNo;

  /// Expiry date (UTC ms)
  int? expiryDateUtcMs;

  /// Optional: damaged quantity (not added to stock)
  double? damagedQty;

  EntityPurchaseReceiptItem({
    this.id = 0,
    this.receiptId,
    this.purchaseItemId,
    this.itemId,
    this.itemName,
    this.itemUnit,
    this.receivedQty,
    this.unitCost,
    this.lineAmount,
    this.batchNo,
    this.expiryDateUtcMs,
    this.damagedQty = 0,
  });

  /// Accepted quantity = received - damaged
  double get acceptedQty =>
      (receivedQty ?? 0) - (damagedQty ?? 0);
}