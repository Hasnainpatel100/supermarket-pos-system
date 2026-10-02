import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityDaySession {
  @Id()
  int id = 0;

  @Unique()
  String objectId = ObjectId().hexString;

  int? startTimestampMs;
  int? endTimestampMs;
  bool isOpen = true;

  double openingCash = 0.0;
  double closingCash = 0.0;

  String? startedByUserId;
  String? startedByUsername;
  String? closedByUserId;
  String? closedByUsername;

  String? openingComment;
  String? closingComment;

  String? branchId;
  String? brandId;

  String? openingDenominationsJson;
  String? closingDenominationsJson;

  int? createdAtUtcMs;

  EntityDaySession({
    this.id = 0,
    this.startTimestampMs,
    this.endTimestampMs,
    this.isOpen = true,
    this.openingCash = 0.0,
    this.closingCash = 0.0,
    this.startedByUserId,
    this.startedByUsername,
    this.closedByUserId,
    this.closedByUsername,
    this.openingComment,
    this.closingComment,
    this.branchId,
    this.brandId,
    this.openingDenominationsJson,
    this.closingDenominationsJson,
    this.createdAtUtcMs,
  });
}
