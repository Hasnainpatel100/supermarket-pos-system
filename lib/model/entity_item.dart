import 'package:objectbox/objectbox.dart';

@Entity()
class EntityItem {
  @Id()
  int? id;

  @Unique()
  String? sku;

  @Unique()
  String? barcode;

  @Unique()
  String? mongoId;

  String? name;
  String? unit;

  double? costPrice;
  double? sellingPrice;

  bool? hasExpiry;
  bool? isActive;

  /// ⭐ STOCK CACHE
  int? totalQty;

  int? createdAtUtcMs;
  int? createdDate;

  int? updatedAtUtcMs;
  int? updatedDate;

  EntityItem({
    this.id,
    this.sku,
    this.barcode,
    this.name,
    this.unit,
    this.costPrice,
    this.sellingPrice,
    this.hasExpiry = false,
    this.isActive = true,
    this.totalQty,
    this.createdAtUtcMs,
    this.createdDate,
    this.updatedAtUtcMs,
    this.updatedDate
  });
}
