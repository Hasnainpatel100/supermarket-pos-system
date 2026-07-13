import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntitySaleItem {
@Id()
int? id;

int? saleId;
int? itemId;

int? quantity;

double? price;
double? total;


@Unique()
String objectId = ObjectId().hexString;  //mongo id


EntitySaleItem({
this.id,
this.saleId,
this.itemId,
this.quantity,
this.price,
this.total,
});
}
