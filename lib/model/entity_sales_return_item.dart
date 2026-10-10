import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';
import 'entity_sales_return.dart';
import 'entity_item.dart';

@Entity()
class EntitySalesReturnItem {
  @Id()
  int id = 0;

  String? itemName;
  String? itemBarcode;
  String? hsnCode;
  String? unit;

  @Unique()
  String objectId = ObjectId().hexString;

  double? price;
  int? qty;
  double? tax;
  double? total;

  final salesReturn = ToOne<EntitySalesReturn>();
  final item = ToOne<EntityItem>();

  EntitySalesReturnItem({
    this.id = 0,
    this.itemName,
    this.itemBarcode,
    this.hsnCode,
    this.unit,
    this.price,
    this.qty,
    this.tax,
    this.total,
  });
}
