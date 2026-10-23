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

  double? mrp;
  double? salePrice;
  double? costPrice;
  int? mfgDateUtcMs;
  double? discount;
  String? barcode;

  EntityItemBatch({
    this.id,
    this.itemId,
    this.batchNo,
    this.expiryDateUtcMs,
    this.quantity,
    this.receivedAtUtcMs,
    this.mrp,
    this.salePrice,
    this.costPrice,
    this.mfgDateUtcMs,
    this.discount,
    this.barcode,
  });
}
