import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityShiftSession {
  @Id()
  int id = 0;

  @Unique()
  String objectId = ObjectId().hexString;

  int daySessionId = 0;

  int? startTimestampMs;
  int? endTimestampMs;
  bool isOpen = true;

  double openingCash = 0.0;
  double closingCash = 0.0;

  double cashIn = 0.0;
  double cashOut = 0.0;
  double salesCash = 0.0;
  double expensesCash = 0.0;

  String? startedByUserId;
  String? startedByUsername;
  String? closedByUserId;
  String? closedByUsername;

  String? comments;

  String? openingDenominationsJson;
  String? closingDenominationsJson;
  String? paymentModesJson;

  int fulfilledOrders = 0;
  int cancelledOrders = 0;
  int complimentaryOrders = 0;

  String? branchId;
  String? brandId;

  int? createdAtUtcMs;

  EntityShiftSession({
    this.id = 0,
    this.daySessionId = 0,
    this.startTimestampMs,
    this.endTimestampMs,
    this.isOpen = true,
    this.openingCash = 0.0,
    this.closingCash = 0.0,
    this.cashIn = 0.0,
    this.cashOut = 0.0,
    this.salesCash = 0.0,
    this.expensesCash = 0.0,
    this.startedByUserId,
    this.startedByUsername,
    this.closedByUserId,
    this.closedByUsername,
    this.comments,
    this.openingDenominationsJson,
    this.closingDenominationsJson,
    this.paymentModesJson,
    this.fulfilledOrders = 0,
    this.cancelledOrders = 0,
    this.complimentaryOrders = 0,
    this.branchId,
    this.brandId,
    this.createdAtUtcMs,
  });
}
