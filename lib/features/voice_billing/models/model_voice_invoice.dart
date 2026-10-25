import 'model_voice_item.dart';

class ModelVoiceInvoice {
  String? customerName;
  String? customerPhone;
  String paymentMode;
  String? notes;
  List<ModelVoiceItem> items;
  double subTotal;
  double taxTotal;
  double discountTotal;
  double grandTotal;

  ModelVoiceInvoice({
    this.customerName,
    this.customerPhone,
    this.paymentMode = 'Cash',
    this.notes,
    List<ModelVoiceItem>? items,
    this.subTotal = 0.0,
    this.taxTotal = 0.0,
    this.discountTotal = 0.0,
    this.grandTotal = 0.0,
  }) : items = items ?? [] {
    recalculate();
  }

  void recalculate() {
    double sub = 0.0;
    double tax = 0.0;
    double disc = 0.0;

    for (final item in items) {
      item.recalculate();
      sub += item.quantity * item.price;
      tax += item.taxAmount;
      disc += item.discount;
    }

    subTotal = sub;
    taxTotal = tax;
    discountTotal = disc;
    // Grand total: if prices are inclusive or exclusive, standard total is sum of item totals + tax
    grandTotal = (sub - disc).clamp(0.0, 99999999.0);
  }

  Map<String, dynamic> toJson() => {
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'payment_mode': paymentMode,
    'notes': notes,
    'items': items.map((e) => e.toJson()).toList(),
    'sub_total': subTotal,
    'tax_total': taxTotal,
    'discount_total': discountTotal,
    'grand_total': grandTotal,
  };

  factory ModelVoiceInvoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems.map((e) => ModelVoiceItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    final invoice = ModelVoiceInvoice(
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      paymentMode: (json['payment_mode'] ?? 'Cash').toString(),
      notes: json['notes']?.toString(),
      items: parsedItems,
    );
    invoice.recalculate();
    return invoice;
  }
}
