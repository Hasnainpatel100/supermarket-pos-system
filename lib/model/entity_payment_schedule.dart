import 'package:objectbox/objectbox.dart';

@Entity()
class EntityPaymentSchedule {
  @Id()
  int id;

  int? purchaseId;
  int? supplierId;
  double? amount;
  int? dueDateMs;       // UTC epoch milliseconds
  String? note;
  int? status;          // 0 = pending, 1 = paid
  int? paidAtMs;
  int? createdAtUtcMs;

  EntityPaymentSchedule({
    this.id = 0,
    this.purchaseId,
    this.supplierId,
    this.amount,
    this.dueDateMs,
    this.note,
    this.status = 0,
    this.paidAtMs,
    this.createdAtUtcMs,
  });

  bool get isPaid => status == 1;
}