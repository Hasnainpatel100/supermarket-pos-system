import 'package:objectbox/objectbox.dart';
import 'entity_bill.dart';
import 'entity_item.dart';

@Entity()
class EntityBillItem {
  @Id()
  int id = 0;

  String? itemName;
  String? itemBarcode;
  String? unit;

  double? price;
  int? qty;
  double? tax;
  double? discount;
  double? total;

  final bill = ToOne<EntityBill>();
  final item = ToOne<EntityItem>();

  EntityBillItem({
    this.id = 0,
    this.itemName,
    this.itemBarcode,
    this.unit,
    this.price,
    this.qty,
    this.tax,
    this.discount,
    this.total,
  });
}
