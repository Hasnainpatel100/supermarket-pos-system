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

  /// Category (e.g. "Beverages", "Snacks")
  String? category;

  double? costPrice;
  double? sellingPrice;

  /// Tax fields
  String? taxName;           // e.g. "SGST", "CGST"
  double? taxRate;           // e.g. 18.0
  String? taxType;           // "inclusive" or "exclusive"
  double? taxAmount;         // calculated tax amount
  double? priceBeforeTax;    // base price before tax
  double? priceAfterTax;     // final price after tax (mirrors sellingPrice)

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
    this.category,
    this.costPrice,
    this.sellingPrice,
    this.taxName,
    this.taxRate,
    this.taxType,
    this.taxAmount,
    this.priceBeforeTax,
    this.priceAfterTax,
    this.hasExpiry = false,
    this.isActive = true,
    this.totalQty,
    this.createdAtUtcMs,
    this.createdDate,
    this.updatedAtUtcMs,
    this.updatedDate,
  });
}
