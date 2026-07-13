import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityStockCount {
  @Id()
  int? id;

  int? itemId;

  int? systemQty;
  int? physicalQty;
  int? difference;

  int? countedByUserId;
  int? approvedByUserId;

  int? countedAtUtcMs;
  int? approvedAtUtcMs;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id


  EntityStockCount({
    this.id,
    this.itemId,
    this.systemQty,
    this.physicalQty,
    this.difference,
    this.countedByUserId,
    this.approvedByUserId,
    this.countedAtUtcMs,
    this.approvedAtUtcMs,
  });
}
