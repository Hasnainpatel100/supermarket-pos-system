import 'package:objectbox/objectbox.dart';
import 'entity_bill_item.dart';

@Entity()
class EntityBill {
  @Id()
  int id = 0;

  @Unique()
  String? billNo;

  String? customerName;
  String? customerPhone;

  double? totalAmount;
  double? discount;
  double? tax;
  double? grandTotal;

  String? status; // PAID, HOLD, CANCELLED
  String? paymentMode; // CASH, CARD, UPI, NETBANKING, SPLIT

  // Payment Tracking Fields
  double? amountReceived; // Cash received from customer
  double? changeReturned; // Change given back to customer
  String? utrNumber; // UPI/Netbanking Reference No.
  double? splitCash; // Amount paid in cash in SPLIT mode
  double? splitOnline; // Amount paid online in SPLIT mode

  /// Date-only field stored as "d/MM/yyyy" e.g. "22/02/2025"
  String? billDate;

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
    this.billDate,
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });
}
