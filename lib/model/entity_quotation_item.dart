import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';
import 'entity_quotation.dart';
import 'entity_item.dart';

@Entity()
class EntityQuotationItem {
  @Id()
  int id = 0;

  String? itemName;
  String? itemBarcode;
  String? hsnCode;
  String? unit;

  @Unique()
  String objectId = ObjectId().hexString;

  double? mrp;
  double? price;
  int? qty;
  double? discount;
  double? taxRate;
  double? tax;
  double? total;

  final quotation = ToOne<EntityQuotation>();
  final item = ToOne<EntityItem>();

  EntityQuotationItem({
    this.id = 0,
    this.itemName,
    this.itemBarcode,
    this.hsnCode,
    this.unit,
    this.mrp,
    this.price,
    this.qty,
    this.discount,
    this.taxRate,
    this.tax,
    this.total,
  });
}
