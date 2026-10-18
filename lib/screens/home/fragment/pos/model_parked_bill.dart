import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';

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
}
