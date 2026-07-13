import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

/// Represents a single payment made to a supplier.
/// Linked to a specific Purchase Order and Supplier.
@Entity()
class EntityPayment {
  @Id()
  int id = 0;

  /// FK → EntitySupplier.id
  @Index()
  int? supplierId;

  /// FK → EntityPurchase.id (nullable: supports advance payments not tied to a PO)
  @Index()
  int? purchaseId;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id

  /// Denormalized for fast display
  String? supplierName;
  String? purchaseNo;

  /// Amount paid in this transaction
  double? amount;

  /// PaymentMode.index — cash, cheque, bank transfer, UPI
  int? paymentMode;

  /// Optional reference: cheque number, UTR, UPI txn ID, etc.
  String? referenceNo;

  /// Optional note e.g. "Advance for next order"
  String? note;

  int? createdByUserId;

  @Index()
  int? createdAtUtcMs;

  EntityPayment({
    this.id = 0,
    this.supplierId,
    this.purchaseId,
    this.supplierName,
    this.purchaseNo,
    this.amount,
    this.paymentMode,
    this.referenceNo,
    this.note,
    this.createdByUserId,
    this.createdAtUtcMs,
  });
}