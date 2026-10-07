import 'package:objectbox/objectbox.dart';

@Entity()
class EntityItemBatch {
  @Id()
  int? id;

  int? itemId;

  String? batchNo;

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
