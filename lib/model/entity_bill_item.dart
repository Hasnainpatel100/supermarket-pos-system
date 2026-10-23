import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';
import 'entity_bill.dart';
import 'entity_item.dart';

@Entity()
class EntityBillItem {
  @Id()
  int id = 0;

  String? itemName;
  String? itemBarcode;
  String? unit;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id

  String? hsnCode;
  double? mrp;
  double? price;
  int? qty;
  double? taxRate;
  double? tax;
  double? discount;
  double? total;

  String? batchNo;
  int? batchId;

  final bill = ToOne<EntityBill>();
  final item = ToOne<EntityItem>();

  EntityBillItem({
    this.id = 0,
    this.itemName,
    this.itemBarcode,
    this.hsnCode,
    this.unit,
    this.mrp,
    this.price,
    this.qty,
    this.taxRate,
    this.tax,
    this.discount,
    this.total,
    this.batchNo,
    this.batchId,
  });
}
