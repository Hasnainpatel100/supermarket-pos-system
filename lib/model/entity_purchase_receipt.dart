import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

/// Represents actual goods receipt (GRN) + supplier invoice.
/// This is the REAL transaction layer (what actually arrived).
@Entity()
class EntityPurchaseReceipt {
  @Id()
  int id = 0;

  /// FK → EntityPurchase.id (PO reference)
  @Index()
  int? purchaseId;

  /// Supplier snapshot (denormalized for fast UI)
  int? supplierId;
  String? supplierName;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id


  // ── Invoice Details (CRITICAL) ──

  /// Supplier invoice number
  @Index()
  String? invoiceNumber;

  /// Invoice date (UTC ms)
  int? invoiceDateUtcMs;

  /// Stored file path of uploaded bill (PDF/JPG)
  String? billFilePath;

  /// Invoice Financial Details (Optional) ──
  double? taxAmount;
  double? discountAmount;
  double? freightCharges;

  // ── Receipt Info ──

  /// When goods were actually received
  int? receivedDateUtcMs;


  /// Total amount based on actual received goods
  double? totalAmount;

  // ── Status ──
  /// 0 = draft, 1 = confirmed
  ///
  @Index()
  int? status;

  /// FK → EntityUser.id
  int? receivedByUserId;

  int? createdAtUtcMs;
  int? updatedAtUtcMs;

  EntityPurchaseReceipt({
    this.id = 0,
    this.purchaseId,
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.invoiceDateUtcMs,
    this.billFilePath,
    this.taxAmount,
    this.discountAmount,
    this.freightCharges,
    this.receivedDateUtcMs,
    this.totalAmount,
    this.status = 1,
    this.receivedByUserId,
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });
}