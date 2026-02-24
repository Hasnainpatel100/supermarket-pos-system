import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:super_market/service/service_currency.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../model/entity_stock_transaction.dart';
import '../../../../model/stock_txn_type.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';
import '../../../../util/snackbar_util.dart';
import '../item/controller_home_item.dart';
import '../report/controller_home_report.dart';
import '../report/dialog_bill_detail.dart';

class ControllerHomePos extends GetxController {
  late Box<EntityItem> _boxItem;
  late Box<EntityItemBatch> _boxBatch;
  late Box<EntityBill> _boxBill;
  late Box<EntityBillItem> _boxBillItem;
  late Box<EntityCustomer> _boxCustomer;
  late Box<EntityStockTransaction> _boxStockTxn;

  final ServiceCurrency serviceCurrency = Get.find();

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
    _boxBatch = ob.box<EntityItemBatch>();
    _boxBill = ob.box<EntityBill>();
    _boxBillItem = ob.box<EntityBillItem>();
    _boxCustomer = ob.box<EntityCustomer>();
    _boxStockTxn = ob.box<EntityStockTransaction>();

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
    final availableStock = item.totalQty ?? 0;

    // Check if item already in cart
    final index = rxCartItems.indexWhere(
      (element) => element.item.target?.id == item.id,
    );

    if (index >= 0) {
      final existing = rxCartItems[index];
      final currentCartQty = existing.qty ?? 0;

      if (currentCartQty + 1 > availableStock) {
        SnackbarUtil.showError(
          "Insufficient stock! Available: $availableStock",
        );
        return;
      }

      existing.qty = currentCartQty + 1;
      existing.total = (existing.qty! * (existing.price ?? 0));
      rxCartItems[index] = existing;
    } else {
      if (availableStock < 1) {
        SnackbarUtil.showError("${item.name} is out of stock!");
        return;
      }

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
    final cartItem = rxCartItems[index];
    final newQty = (cartItem.qty ?? 0) + delta;

    if (newQty <= 0) {
      rxCartItems.removeAt(index);
    } else {
      // Check stock when incrementing
      if (delta > 0) {
        final stockItem = cartItem.item.target;
        final availableStock = stockItem?.totalQty ?? 0;
        if (newQty > availableStock) {
          SnackbarUtil.showError(
            "Insufficient stock! Available: $availableStock",
          );
          return;
        }
      }
      cartItem.qty = newQty;
      cartItem.total = newQty * (cartItem.price ?? 0);
      rxCartItems[index] = cartItem;
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
    final todayDate = DateFormat('d/MM/yyyy').format(DateTime.now());

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
      billDate: todayDate,
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );

    // Save Bill first to get ID
    final billId = _boxBill.put(bill);
    final savedBill = _boxBill.get(billId)!;

    // Save Bill Items & Deduct Stock
    for (var cartItem in rxCartItems) {
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

      // Deduct stock from item (hasExpiry-aware)
      final stockItem = cartItem.item.target;
      if (stockItem != null) {
        final soldQty = cartItem.qty ?? 0;

        if (stockItem.hasExpiry == true) {
          // ── Batch-tracked: FIFO deduction from oldest batches ──
          _deductFromBatches(stockItem.id ?? 0, soldQty);
        }

        // Always update totalQty on the item
        stockItem.totalQty = (stockItem.totalQty ?? 0) - soldQty;
        if (stockItem.totalQty! < 0) stockItem.totalQty = 0;
        stockItem.updatedAtUtcMs = now;
        _boxItem.put(stockItem);

        // Log SELL transaction
        _boxStockTxn.put(
          EntityStockTransaction(
            itemId: stockItem.id ?? 0,
            type: StockTxnType.sell.index,
            quantity: -soldQty,
            referenceType: 'sell',
            referenceId: stockItem.name ?? '',
            remarks: 'Sold via POS',
            createdAtUtcMs: now,
          ),
        );
      }
    }

    clearCart();
    loadItems(); // Refresh POS grid with updated stock

    // Also refresh the Items tab controller if it exists
    if (Get.isRegistered<ControllerHomeItem>()) {
      Get.find<ControllerHomeItem>().loadItems();
    }

    // Refresh Report controller if it exists
    if (Get.isRegistered<ControllerHomeReport>()) {
      Get.find<ControllerHomeReport>().loadData();
    }

    // Show beautiful bill preview to user
    Get.dialog(DialogBillDetail(bill: savedBill), barrierDismissible: false);
  }

  /// FIFO batch deduction — walks oldest batches first
  void _deductFromBatches(int itemId, int qty) {
    final query = _boxBatch
        .query(EntityItemBatch_.itemId.equals(itemId))
        .order(EntityItemBatch_.receivedAtUtcMs)
        .build();
    final batches = query.find();
    query.close();

    int remaining = qty;

    for (final batch in batches) {
      if (remaining <= 0) break;

      final batchQty = batch.quantity ?? 0;
      if (batchQty <= remaining) {
        // Fully consumed → remove batch
        remaining -= batchQty;
        _boxBatch.remove(batch.id!);
      } else {
        // Partially deduct
        batch.quantity = batchQty - remaining;
        _boxBatch.put(batch);
        remaining = 0;
      }
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    searchCustomerController.dispose();
    super.onClose();
  }
}
