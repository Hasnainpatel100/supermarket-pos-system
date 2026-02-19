import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_item.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';
import '../../../../util/snackbar_util.dart';

class ControllerHomePos extends GetxController {
  late Box<EntityItem> _boxItem;
  late Box<EntityBill> _boxBill;
  late Box<EntityBillItem> _boxBillItem;
  late Box<EntityCustomer> _boxCustomer;

  // Search Items
  final searchController = TextEditingController();
  final rxSearchQuery = ''.obs;
  final rxListItems = <EntityItem>[].obs;

  // Search Customers
  final searchCustomerController = TextEditingController();
  final rxCustomerSearchQuery = ''.obs;
  final rxListCustomers = <EntityCustomer>[].obs;
  final rxSelectedCustomer = Rxn<EntityCustomer>();

  // Cart
  final rxCartItems = <EntityBillItem>[].obs;

  // Totals
  final rxSubTotal = 0.0.obs;
  final rxTaxRate = 0.0.obs; // In Percentage
  final rxTaxAmount = 0.0.obs; // Calculated
  final rxDiscountAmount = 0.0.obs; // In Amount
  final rxGrandTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxItem = ob.box<EntityItem>();
    _boxBill = ob.box<EntityBill>();
    _boxBillItem = ob.box<EntityBillItem>();
    _boxCustomer = ob.box<EntityCustomer>();

    loadItems();
    loadCustomers();

    // Debounce search
    debounce(
      rxSearchQuery,
      (_) => loadItems(),
      time: const Duration(milliseconds: 300),
    );

    debounce(
      rxCustomerSearchQuery,
      (_) => loadCustomers(),
      time: const Duration(milliseconds: 300),
    );
  }

  void loadItems() {
    final query = _boxItem
        .query(
          EntityItem_.name
              .contains(rxSearchQuery.value, caseSensitive: false)
              .or(EntityItem_.barcode.contains(rxSearchQuery.value))
              .or(EntityItem_.sku.contains(rxSearchQuery.value))
              .and(EntityItem_.isActive.equals(true)),
        )
        .order(EntityItem_.name)
        .build();

    rxListItems.assignAll(query.find());
  }

  void loadCustomers() {
    final query = _boxCustomer
        .query(
          EntityCustomer_.name
              .contains(rxCustomerSearchQuery.value, caseSensitive: false)
              .or(EntityCustomer_.phone.contains(rxCustomerSearchQuery.value)),
        )
        .order(EntityCustomer_.name)
        .build();

    rxListCustomers.assignAll(query.find());
  }

  void selectCustomer(EntityCustomer? customer) {
    rxSelectedCustomer.value = customer;
    // Clear search if selected
    if (customer != null) {
      searchCustomerController.clear();
      rxCustomerSearchQuery.value = '';
    }
  }

  void addToCart(EntityItem item) {
    // Check if item already in cart
    final index = rxCartItems.indexWhere(
      (element) => element.item.target?.id == item.id,
    );

    if (index >= 0) {
      // Update quantity
      final existing = rxCartItems[index];
      existing.qty = (existing.qty ?? 0) + 1;
      existing.total = (existing.qty! * (existing.price ?? 0));
      rxCartItems[index] = existing; // Refresh list item
    } else {
      // Add new
      final billItem = EntityBillItem(
        itemName: item.name,
        itemBarcode: item.barcode,
        unit: item.unit,
        price: item.sellingPrice,
        qty: 1,
        tax: 0,
        discount: 0,
        total: item.sellingPrice,
      );
      billItem.item.target = item;
      rxCartItems.add(billItem);
    }
    calculateTotals();
  }

  void updateQty(int index, int delta) {
    final item = rxCartItems[index];
    final newQty = (item.qty ?? 0) + delta;

    if (newQty <= 0) {
      rxCartItems.removeAt(index);
    } else {
      item.qty = newQty;
      item.total = newQty * (item.price ?? 0);
      rxCartItems[index] = item;
    }
    calculateTotals();
  }

  void removeFromCart(int index) {
    rxCartItems.removeAt(index);
    calculateTotals();
  }

  void setTaxRate(double rate) {
    rxTaxRate.value = rate;
    calculateTotals();
  }

  void setDiscount(double amount) {
    rxDiscountAmount.value = amount;
    calculateTotals();
  }

  void calculateTotals() {
    double subTotal = 0;
    for (var item in rxCartItems) {
      subTotal += item.total ?? 0;
    }

    rxSubTotal.value = subTotal;

    // Calculate Tax
    rxTaxAmount.value = (subTotal * (rxTaxRate.value / 100));

    // Grand Total
    double grand = subTotal + rxTaxAmount.value - rxDiscountAmount.value;
    if (grand < 0) grand = 0;

    rxGrandTotal.value = grand;
  }

  void clearCart() {
    rxCartItems.clear();
    rxDiscountAmount.value = 0;
    rxTaxRate.value = 0;
    rxTaxAmount.value = 0;
    rxGrandTotal.value = 0;
    rxSubTotal.value = 0;
    rxSelectedCustomer.value = null;
    calculateTotals();
  }

  void settleBill() {
    if (rxCartItems.isEmpty) {
      SnackbarUtil.showError("Cart is empty");
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final customer = rxSelectedCustomer.value;
    final customerName = customer != null ? "${customer.name}" : "Walk-in";
    final customerPhone = customer?.phone ?? "";

    final bill = EntityBill(
      billNo: "BIL-$now",
      customerName: customerName,
      customerPhone: customerPhone,
      totalAmount: rxSubTotal.value,
      discount: rxDiscountAmount.value,
      tax: rxTaxAmount.value,
      grandTotal: rxGrandTotal.value,
      status: "PAID",
      paymentMode: "CASH",
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );

    // Save Bill first to get ID
    final billId = _boxBill.put(bill);
    final savedBill = _boxBill.get(billId)!;

    // Save Bill Items
    for (var cartItem in rxCartItems) {
      // Create a new EntityBillItem to ensure clean state and persistence
      final billItem = EntityBillItem(
        itemName: cartItem.itemName,
        itemBarcode: cartItem.itemBarcode,
        unit: cartItem.unit,
        price: cartItem.price,
        qty: cartItem.qty,
        tax: cartItem.tax,
        discount: cartItem.discount,
        total: cartItem.total,
      );

      billItem.bill.target = savedBill;
      billItem.item.target = cartItem.item.target;

      _boxBillItem.put(billItem);
    }

    SnackbarUtil.showSuccess(
      "Bill Settled! \nAmount: ₹${rxGrandTotal.value.toStringAsFixed(2)}",
    );
    clearCart();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchCustomerController.dispose();
    super.onClose();
  }
}
