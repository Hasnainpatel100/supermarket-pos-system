import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntitySale {
  @Id()
  int? id;

  @Unique()
  String? billNo;

  int? customerId;

  double? totalAmount;
  double? paidAmount;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id


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

