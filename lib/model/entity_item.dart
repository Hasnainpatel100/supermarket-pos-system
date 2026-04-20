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

  // ── Tax fields ──

  /// GST regime: 'GST' or 'IGST' or null (no tax)
  /// Used in purchase form as taxType (GST/IGST dropdown)
  String? taxName;

  /// Tax rate e.g. 5.0, 12.0, 18.0, 28.0
  /// Auto-fills in purchase form, overridable by staff
  double? taxRate;

  /// 'inclusive' = price already includes tax (With Tax)
  /// 'exclusive' = tax added on top (Without Tax)
  /// Maps to isTaxInclusive in purchase:
  ///   'inclusive' → isTaxInclusive = true
  ///   'exclusive' → isTaxInclusive = false
  String? taxType;

  /// Calculated tax amount (on item master, for reference)
  double? taxAmount;

  /// Base price before tax applied
  double? priceBeforeTax;

  /// Final price after tax (mirrors sellingPrice)
  double? priceAfterTax;

  /// ⭐ NEW — HSN code for GST compliance
  /// e.g. '0402' for milk, '1006' for rice
  /// Optional — used on purchase invoice for GST audit trail
  String? hsnCode;

  bool? hasExpiry;
  bool? isActive;

  /// ⭐ STOCK CACHE — derived from StockTransactions
  /// Never edit directly — always via StockTransaction
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
    this.hsnCode,           // ← only new field added
    this.hasExpiry = false,
    this.isActive = true,
    this.totalQty,
    this.createdAtUtcMs,
    this.createdDate,
    this.updatedAtUtcMs,
    this.updatedDate,
  });

  // ── Convenience getters for purchase form ──

  /// Maps taxType string → bool for purchase isTaxInclusive
  bool get isTaxInclusive => taxType == 'inclusive';

  /// Maps taxName → purchase taxType field (GST/IGST)
  String? get gstType => taxName; // 'GST', 'IGST', or null
}
