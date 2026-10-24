import 'package:get/get.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_item.dart';
import '../../../../service/service_object_box.dart';

/// Represents a held/parked customer cart session in the POS.
/// Allows cashiers to temporarily suspend a customer's order and recall it later.
class ModelParkedBill {
  final String ticketId;
  final String parkedAtTime;
  final DateTime parkedDateTime;
  final EntityCustomer? customer;
  final String? customerName;
  final String? customerPhone;
  final List<EntityBillItem> items;
  final double subTotal;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double grandTotal;
  final String? note;

  ModelParkedBill({
    required this.ticketId,
    required this.parkedAtTime,
    required this.parkedDateTime,
    this.customer,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subTotal,
    required this.taxRate,
    required this.taxAmount,
    required this.discountAmount,
    required this.grandTotal,
    this.note,
  });

  int get totalItemCount => items.fold(0, (sum, i) => sum + (i.qty ?? 0));

  String get timeAgo {
    final diff = DateTime.now().difference(parkedDateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'parkedAtTime': parkedAtTime,
      'parkedDateTime': parkedDateTime.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'subTotal': subTotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'grandTotal': grandTotal,
      'note': note,
      'items': items.map((item) => {
        'itemName': item.itemName,
        'itemBarcode': item.itemBarcode,
        'unit': item.unit,
        'hsnCode': item.hsnCode,
        'mrp': item.mrp,
        'price': item.price,
        'qty': item.qty,
        'taxRate': item.taxRate,
        'tax': item.tax,
        'discount': item.discount,
        'total': item.total,
        'targetItemId': item.item.target?.id,
      }).toList(),
    };
  }

  factory ModelParkedBill.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems.map((raw) {
      final m = raw as Map<String, dynamic>;
      final entity = EntityBillItem(
        itemName: m['itemName'] as String?,
        itemBarcode: m['itemBarcode'] as String?,
        unit: m['unit'] as String?,
        hsnCode: m['hsnCode'] as String?,
        mrp: (m['mrp'] as num?)?.toDouble(),
        price: (m['price'] as num?)?.toDouble(),
        qty: m['qty'] as int?,
        taxRate: (m['taxRate'] as num?)?.toDouble(),
        tax: (m['tax'] as num?)?.toDouble(),
        discount: (m['discount'] as num?)?.toDouble(),
        total: (m['total'] as num?)?.toDouble(),
      );
      final targetId = m['targetItemId'] as int?;
      if (targetId != null && targetId > 0 && Get.isRegistered<ServiceObjectBox>()) {
        try {
          final box = Get.find<ServiceObjectBox>().box<EntityItem>();
          entity.item.target = box.get(targetId);
        } catch (_) {}
      }
      return entity;
    }).toList();

    return ModelParkedBill(
      ticketId: json['ticketId'] as String? ?? 'HOLD-0',
      parkedAtTime: json['parkedAtTime'] as String? ?? '',
      parkedDateTime: json['parkedDateTime'] != null
          ? DateTime.tryParse(json['parkedDateTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      items: itemsList,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
    );
  }
}
