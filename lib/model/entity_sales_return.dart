import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';
import 'entity_sales_return_item.dart';

@Entity()
class EntitySalesReturn {
  @Id()
  int id = 0;

  @Unique()
  String? returnNo;

  @Unique()
  String objectId = ObjectId().hexString;

  String? prefix;

  @Index()
  String? originalBillNo;

  @Index()
  String? customerName;

  @Index()
  String? customerPhone;

  String? customerAddress;
  String? customerGstin;

  @Index()
  String? returnDate; // "dd/MM/yyyy"
  String? paymentMode; // CASH, CREDIT_NOTE, UPI, BANK
  String? returnReason; // DAMAGED, EXPIRED, WRONG_ITEM, CUSTOMER_REQUEST, OTHER

  double? subtotal;
  double? tax;
  double? refundAmount;

  @Index()
  String? status; // 'Paid', 'Unpaid', 'Completed', 'Cancelled'

  String? note;
  String? termsConditions;

  int? createdAtUtcMs;
  int? updatedAtUtcMs;

  @Backlink('salesReturn')
  final items = ToMany<EntitySalesReturnItem>();

  EntitySalesReturn({
    this.id = 0,
    this.returnNo,
    this.prefix,
    this.originalBillNo,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerGstin,
    this.returnDate,
    this.paymentMode = 'CASH',
    this.returnReason,
    this.subtotal,
    this.tax,
    this.refundAmount,
    this.status = 'Paid',
    this.note,
    this.termsConditions,
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });
}
