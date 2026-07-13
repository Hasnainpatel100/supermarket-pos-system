import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityItemBatch {
  @Id()
  int? id;

  int? itemId;

  String? batchNo;

  @Unique()
  String objectId = ObjectId().hexString;  //mongo id

  @Index()
  int? expiryDateUtcMs;

  int? quantity;

  int? receivedAtUtcMs;

  EntityItemBatch({
    this.id,
    this.itemId,
    this.batchNo,
    this.expiryDateUtcMs,
    this.quantity,
    this.receivedAtUtcMs,
  });
}
