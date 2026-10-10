import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';
import 'entity_quotation_item.dart';

@Entity()
class EntityQuotation {
  @Id()
  int id = 0;

  @Unique()
  String? quotationNo;

  @Unique()
  String objectId = ObjectId().hexString;

  String? prefix;

  @Index()
  String? customerName;

  @Index()
  String? customerPhone;

  String? customerEmail;
  String? customerAddress;
  String? customerGstin;

  @Index()
  String? quotationDate; // "dd/MM/yyyy"
  int? validDays;
  String? validUntilDate; // "dd/MM/yyyy"

  String? poNo;
  String? ewayBillNo;
  String? vehicleNo;

  double? subtotal;
  double? discount;
  double? tax;
  double? taxableAmount;
  double? cgstAmount;
  double? sgstAmount;
  double? igstAmount;
  double? additionalCharges;
  double? roundOff;
  double? grandTotal;

  @Index()
  String? status; // 'Open', 'Converted', 'Expired', 'Cancelled'

  String? convertedBillNo;

  String? note;
  String? termsConditions;

  int? createdAtUtcMs;
  int? updatedAtUtcMs;

  @Backlink('quotation')
  final items = ToMany<EntityQuotationItem>();

  EntityQuotation({
    this.id = 0,
    this.quotationNo,
    this.prefix,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.customerGstin,
    this.quotationDate,
    this.validDays = 30,
    this.validUntilDate,
    this.poNo,
    this.ewayBillNo,
    this.vehicleNo,
    this.subtotal,
    this.discount,
    this.tax,
    this.taxableAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.additionalCharges,
    this.roundOff,
    this.grandTotal,
    this.status = 'Open',
    this.convertedBillNo,
    this.note,
    this.termsConditions,
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });
}
