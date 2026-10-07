import 'package:objectbox/objectbox.dart';

@Entity()
class EntityStockTransaction {
  @Id()
  int? id;

  int? itemId;

  @Index()
  int? type; // StockTxnType.index

  int? quantity;

  String? referenceType;
  String? referenceId;
  String? remarks;

  int? performedByUserId;

  int? createdAtUtcMs;

  EntityStockTransaction({
    this.id,
    this.itemId,
    this.type,
    this.quantity,
    this.referenceType,
    this.referenceId,
    this.remarks,
    this.performedByUserId,
    this.createdAtUtcMs,
  });
}
