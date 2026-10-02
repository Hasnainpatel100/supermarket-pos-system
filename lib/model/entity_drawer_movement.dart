import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityDrawerMovement {
  @Id()
  int id = 0;

  @Unique()
  String objectId = ObjectId().hexString;

  int shiftSessionId = 0;
  int daySessionId = 0;

  /// 'CASH_IN', 'CASH_OUT', 'EXPENSE'
  String type = 'CASH_IN';

  double amount = 0.0;
  String? reason;
  String? remarks;

  int? timestampMs;
  String? userId;
  String? username;

  String? branchId;
  String? brandId;

  int? createdAtUtcMs;

  EntityDrawerMovement({
    this.id = 0,
    this.shiftSessionId = 0,
    this.daySessionId = 0,
    this.type = 'CASH_IN',
    this.amount = 0.0,
    this.reason,
    this.remarks,
    this.timestampMs,
    this.userId,
    this.username,
    this.branchId,
    this.brandId,
    this.createdAtUtcMs,
  });
}
