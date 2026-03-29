import 'package:objectbox/objectbox.dart';

/// Represents a Purchase Order (INTENT layer).
/// This entity stores what was ordered — NOT what arrived.
/// Stock is only updated via StockTransaction when goods are received.
@Entity()
class EntityPurchase {
  @Id()
  int id = 0;

  /// Unique internal purchase number e.g. PO-20250310-001
  @Unique()
  String? purchaseNo;

  /// Supplier's own invoice number (from their physical bill)
  /// Required for GST audit trail
  String? supplierInvoiceNo;

  /// FK → EntitySupplier.id
  @Index()
  int? supplierId;

  /// Denormalized supplier name — snapshot at time of order
  /// Does NOT change if supplier renames later
  String? supplierName;

  /// Purchase order date stored as UTC ms
  int? purchaseDateUtcMs;

  /// Expected delivery date stored as UTC ms (nullable)
  int? expectedDateUtcMs;

  /// PurchaseStatus.index
  /// 0=draft, 1=ordered, 2=partial, 3=received, 4=cancelled
  @Index()
  int? status;

  // ── Amount Breakdown (all computed & stored) ──

  /// Raw subtotal: sum of (orderedQty × unitCost) before discount/tax
  double? totalAmount;

  /// Total discount across all items
  double? totalDiscountAmount;

  /// Subtotal after discount, before tax
  double? totalExclTax;

  /// Total tax across all items
  double? totalTaxAmount;

  /// Small +/- adjustment to round to nearest rupee
  double? roundOff;

  /// Final payable amount = totalExclTax + totalTaxAmount + roundOff
  double? grandTotal;

  // ── Payment Tracking ──

  /// Amount paid to supplier so far
  double? paidAmount;

  /// 'UNPAID', 'PARTIAL', 'PAID'
  String? paymentStatus;

  // ── Meta ──

  /// Optional delivery/order notes
  String? notes;

  /// FK → EntityUser.id
  int? createdByUserId;

  int? createdAtUtcMs;
  int? updatedAtUtcMs;

  EntityPurchase({
    this.id = 0,
    this.purchaseNo,
    this.supplierInvoiceNo,
    this.supplierId,
    this.supplierName,
    this.purchaseDateUtcMs,
    this.expectedDateUtcMs,
    this.status,
    this.totalAmount,
    this.totalDiscountAmount,
    this.totalExclTax,
    this.totalTaxAmount,
    this.roundOff,
    this.grandTotal,
    this.paidAmount,
    this.paymentStatus = 'UNPAID',
    this.notes,
    this.createdByUserId,
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });

  /// Convenience: outstanding balance
  double get balanceDue => (grandTotal ?? 0) - (paidAmount ?? 0);
}
