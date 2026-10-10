import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';
import 'entity_bill_item.dart';

@Entity()
class EntityBill {
  @Id()
  int id = 0;

  @Unique()
  String? billNo;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id

  @Index()
  String? customerName;

  @Index()
  String? customerPhone;

  double? totalAmount;
  double? discount;
  double? tax;
  double? grandTotal;

  @Index()
  String? status; // PAID, HOLD, CANCELLED
  String? paymentMode; // CASH, CARD, UPI, NETBANKING, SPLIT

  // Payment Tracking Fields
  double? amountReceived; // Cash received from customer
  double? changeReturned; // Change given back to customer
  String? utrNumber; // UPI/Netbanking Reference No.
  double? splitCash; // Amount paid in cash in SPLIT mode
  double? splitOnline; // Amount paid online in SPLIT mode
  double? dueAmount; // Amount pending for DUE status

  /// Date-only field stored as "d/MM/yyyy" e.g. "22/02/2025"
  @Index()
  String? billDate;

  String? note;

  // ── Sales Invoice Specific Fields ──
  String? invoicePrefix;
  int? paymentTerms; // Days, e.g. 30
  String? dueDate; // "dd/MM/yyyy"
  String? poNo;
  String? ewayBillNo;
  String? vehicleNo;
  double? taxableAmount;
  double? cgstAmount;
  double? sgstAmount;
  double? igstAmount;
  double? additionalCharges;
  double? roundOff;
  String? customerAddress;
  String? customerGstin;
  String? termsConditions;
  String? quotationNo; // If converted from quotation

  int? createdAtUtcMs;
  int? updatedAtUtcMs;

  @Backlink('bill')
  final items = ToMany<EntityBillItem>();

  EntityBill({
    this.id = 0,
    this.billNo,
    this.customerName,
    this.customerPhone,
    this.totalAmount,
    this.discount,
    this.tax,
    this.grandTotal,
    this.status,
    this.paymentMode,
    this.amountReceived,
    this.changeReturned,
    this.utrNumber,
    this.splitCash,
    this.splitOnline,
    this.dueAmount,
    this.billDate,
    this.note,
    this.invoicePrefix,
    this.paymentTerms,
    this.dueDate,
    this.poNo,
    this.ewayBillNo,
    this.vehicleNo,
    this.taxableAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.additionalCharges,
    this.roundOff,
    this.customerAddress,
    this.customerGstin,
    this.termsConditions,
    this.quotationNo,
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });
}
