import 'package:objectbox/objectbox.dart';

/// Represents a Purchase Order (INTENT layer).
/// This entity stores what was ordered — NOT what arrived.
/// Stock is only updated via StockTransaction when goods are received.
@Entity()
class EntityPurchase {
  @Id()
  int id = 0;

  /// Unique purchase number e.g. PO-20250310-001
  @Unique()
  String? purchaseNo;

  /// FK → EntitySupplier.id
  @Index()
  int? supplierId;

  /// Denormalized supplier name for fast display (no join needed)
  String? supplierName;

  /// Purchase order date stored as UTC ms
  int? purchaseDateUtcMs;

  /// Expected delivery date stored as UTC ms (nullable)
  int? expectedDateUtcMs;

  /// PurchaseStatus.index
  /// 0=draft, 1=ordered, 2=partial, 3=received, 4=cancelled
  @Index()
  int? status;

  /// Sum of (orderedQty × unitCost) for all items
  double? totalAmount;

  /// Total amount paid against this PO (sum of EntityPayment.amount)
  double? amountPaid;

  /// Computed: totalAmount - amountPaid. Cached for fast queries.
  double? amountDue;

  String? notes;


  /// FK → EntityUser.id
  int? createdByUserId;

  int? createdAtUtcMs;
  int? updatedAtUtcMs;

  EntityPurchase({
    this.id = 0,
    this.purchaseNo,
    this.supplierId,
    this.supplierName,
    this.purchaseDateUtcMs,
    this.expectedDateUtcMs,
    this.status,
    this.totalAmount,
    this.amountPaid,
    this.amountDue,
    this.notes,
    this.createdByUserId,
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });

  double get outstandingAmount => (totalAmount ?? 0) - (amountPaid ?? 0);
  bool get isFullyPaid => outstandingAmount <= 0;
}
