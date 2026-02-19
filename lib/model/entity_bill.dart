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
  String? paymentMode; // CASH, CARD, UPI, etc.

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
    this.createdAtUtcMs,
    this.updatedAtUtcMs,
  });
}
