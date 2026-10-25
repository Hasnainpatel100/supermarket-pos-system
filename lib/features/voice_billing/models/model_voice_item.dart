import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';

class ModelVoiceItem {
  String itemName;
  String spokenName;
  double quantity;
  String unit;
  double price;
  double mrp;
  double taxRate;
  double taxAmount;
  double discount;
  double total;
  
  // Inventory matching
  int? matchedItemId;
  String? matchedBarcode;
  String? matchedSku;
  String? hsnCode;
  bool isMatched;
  EntityItem? entityItem;
  EntityItemBatch? entityBatch;

  ModelVoiceItem({
    required this.itemName,
    this.spokenName = '',
    this.quantity = 1.0,
    this.unit = 'pcs',
    this.price = 0.0,
    this.mrp = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.matchedItemId,
    this.matchedBarcode,
    this.matchedSku,
    this.hsnCode,
    this.isMatched = false,
    this.entityItem,
    this.entityBatch,
  }) {
    recalculate();
  }

  void recalculate() {
    final sub = quantity * price;
    final discountedSub = (sub - discount).clamp(0.0, 99999999.0);
    if (taxRate > 0) {
      taxAmount = (discountedSub * taxRate) / 100.0;
    } else {
      taxAmount = 0.0;
    }
    total = discountedSub;
  }

  Map<String, dynamic> toJson() => {
    'item_name': itemName,
    'spoken_name': spokenName,
    'quantity': quantity,
    'unit': unit,
    'price': price,
    'mrp': mrp,
    'tax_rate': taxRate,
    'tax_amount': taxAmount,
    'discount': discount,
    'total': total,
    'matched_item_id': matchedItemId,
    'is_matched': isMatched,
  };

  factory ModelVoiceItem.fromJson(Map<String, dynamic> json) {
    final name = (json['item_name'] ?? json['name'] ?? 'Item').toString();
    final spoken = (json['spoken_name'] ?? '').toString();
    final qty = (json['quantity'] is num) ? (json['quantity'] as num).toDouble() : (double.tryParse('${json['quantity']}') ?? 1.0);
    final unit = (json['unit'] ?? 'pcs').toString();
    final p = (json['price'] is num) ? (json['price'] as num).toDouble() : (double.tryParse('${json['price']}') ?? 0.0);
    final tax = (json['tax_rate'] is num) ? (json['tax_rate'] as num).toDouble() : (double.tryParse('${json['tax_rate']}') ?? 0.0);
    final disc = (json['discount'] is num) ? (json['discount'] as num).toDouble() : (double.tryParse('${json['discount']}') ?? 0.0);

    return ModelVoiceItem(
      itemName: name,
      spokenName: spoken,
      quantity: qty <= 0 ? 1.0 : qty,
      unit: unit,
      price: p,
      mrp: p,
      taxRate: tax,
      discount: disc,
    );
  }
}
