import 'package:objectbox/objectbox.dart';

@Entity()
class EntitySaleItem {
@Id()
int? id;

int? saleId;
int? itemId;

int? quantity;

double? price;
double? total;

EntitySaleItem({
this.id,
this.saleId,
this.itemId,
this.quantity,
this.price,
this.total,
});
}
