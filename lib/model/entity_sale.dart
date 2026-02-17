import 'package:objectbox/objectbox.dart';

@Entity()
class EntitySale {
  @Id()
  int? id;

  @Unique()
  String? billNo;

  int? customerId;

  double? totalAmount;
  double? paidAmount;

  int? createdAtUtcMs;

  EntitySale({
    this.id,
    this.billNo,
    this.customerId,
    this.totalAmount,
    this.paidAmount,
    this.createdAtUtcMs,
  });
}

