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
import '../bills/controller_home_bills.dart';
import '../bills/dialog_bill_detail.dart';
import '../item/controller_home_item.dart';
import 'package:flutter/services.dart';
import '../../../customer/activity_customer_form.dart';

class BillSession {
  final String id;
  final rxCartItems = <EntityBillItem>[].obs;
  final rxSelectedCustomer = Rxn<EntityCustomer>();
  final rxSubTotal = 0.0.obs;
  final rxTaxRate = 0.0.obs;
  final rxTaxAmount = 0.0.obs;
  final rxDiscountAmount = 0.0.obs;
  final rxGrandTotal = 0.0.obs;
  final rxPaymentMode = 'Cash'.obs;
  final amountController = TextEditingController();
  final rxAmountReceived = 0.0.obs;
  final rxChangeReturned = 0.0.obs;
  final rxDueAmount = 0.0.obs;
  
  // Split payment fields
  final rxSplitCount = 2.obs;
  final rxSplitAmounts = <RxDouble>[].obs;
  final rxSplitModes = <RxString>[].obs;
  final splitControllers = <TextEditingController>[];
  
  void initSplitPayment(int count, double grandTotal) {
    rxSplitCount.value = count;
    // Clear existing
    for (var c in splitControllers) c.dispose();
    splitControllers.clear();
    rxSplitAmounts.clear();
    rxSplitModes.clear();
    
    // Initialize split amounts equally
    double splitAmount = grandTotal / count;
    for (int i = 0; i < count; i++) {
      rxSplitAmounts.add(splitAmount.obs);
      rxSplitModes.add('Cash'.obs);
      splitControllers.add(TextEditingController(text: splitAmount.toStringAsFixed(2)));
    }
  }
  
  void updateSplitAmount(int index, double amount) {
    if (index >= 0 && index < rxSplitAmounts.length) {
      rxSplitAmounts[index].value = amount;
    }
  }
  
  void updateSplitMode(int index, String mode) {
    if (index >= 0 && index < rxSplitModes.length) {
      rxSplitModes[index].value = mode;
    }
  }
  final rxSelectedCartIndex = (-1).obs;
  final rxRemark = ''.obs;

  // Quick Customer Entry
  final rxQuickCustomerName = ''.obs;
  final rxQuickCustomerPhone = ''.obs;

  BillSession({required this.id});

  void dispose() {
    amountController.dispose();
    for (var c in splitControllers) c.dispose();
  }
}

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
  final searchFocusNode = FocusNode();
  final rxSearchQuery = ''.obs;
  final rxListItems = <EntityItem>[].obs;

  // Search Customers
  final searchCustomerController = TextEditingController();
  final rxCustomerSearchQuery = ''.obs;
  final rxListCustomers = <EntityCustomer>[].obs;

  // Multi-Session
  final rxBillTabs = <BillSession>[].obs;
  final rxActiveTabIndex = 0.obs;
  int _tabCounter = 1;

  BillSession get activeSession => rxBillTabs[rxActiveTabIndex.value];

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

    addNewTab(); // Initialize first tab
    loadItems();
    loadCustomers();

    debounce(rxSearchQuery, (_) => loadItems(), time: const Duration(milliseconds: 300));
    debounce(rxCustomerSearchQuery, (_) => loadCustomers(), time: const Duration(milliseconds: 300));
  }

  void addNewTab() {
    final session = BillSession(id: "Bill #$_tabCounter");
    _tabCounter++;
    rxBillTabs.add(session);
    rxActiveTabIndex.value = rxBillTabs.length - 1;
  }

  void switchTab(int index) {
    if (index >= 0 && index < rxBillTabs.length) {
      rxActiveTabIndex.value = index;
    }
  }

  void closeTab(int index) {
    if (rxBillTabs.length <= 1) {
      clearCart(); // Just clear if it's the last one
      return;
    }
    final wasActive = rxActiveTabIndex.value;
    rxBillTabs[index].dispose();
    rxBillTabs.removeAt(index);

    if (index < wasActive) {
      // Closed a tab before the active one — shift left
      rxActiveTabIndex.value = wasActive - 1;
    } else if (index == wasActive) {
      // Closed the active tab — pick the nearest valid tab
      final newIndex = index >= rxBillTabs.length ? rxBillTabs.length - 1 : index;
      // Force reactive update even if value is same
      rxActiveTabIndex.value = -1;
      rxActiveTabIndex.value = newIndex;
    }
    // If closed a tab after active, no index change needed
  }

  void loadItems() {
    final query = _boxItem
        .query(EntityItem_.name.contains(rxSearchQuery.value, caseSensitive: false)
            .or(EntityItem_.barcode.contains(rxSearchQuery.value))
            .or(EntityItem_.sku.contains(rxSearchQuery.value))
            .and(EntityItem_.isActive.equals(true)))
        .order(EntityItem_.name)
        .build();
    rxListItems.assignAll(query.find());
  }

  void loadCustomers() {
    final query = _boxCustomer
        .query(EntityCustomer_.name.contains(rxCustomerSearchQuery.value, caseSensitive: false)
            .or(EntityCustomer_.phone.contains(rxCustomerSearchQuery.value)))
        .order(EntityCustomer_.name)
        .build();
    rxListCustomers.assignAll(query.find());
  }

  void selectCustomer(EntityCustomer? customer) {
    activeSession.rxSelectedCustomer.value = customer;
    if (customer != null) {
      searchCustomerController.clear();
      rxCustomerSearchQuery.value = '';
    }
  }

  void addToCart(EntityItem item) {
    final availableStock = item.totalQty ?? 0;
    final session = activeSession;
    final index = session.rxCartItems.indexWhere((element) => element.item.target?.id == item.id);

    if (index >= 0) {
      final existing = session.rxCartItems[index];
      final currentCartQty = existing.qty ?? 0;
      if (currentCartQty + 1 > availableStock) {
        SnackbarUtil.showError("Insufficient stock! Available: $availableStock");
        return;
      }
      existing.qty = currentCartQty + 1;
      existing.total = (existing.qty! * (existing.price ?? 0));
      session.rxCartItems[index] = existing;
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
      session.rxCartItems.add(billItem);
    }
    
    // Attempt Auto-focus back
    searchController.clear();
    rxSearchQuery.value = '';
    searchFocusNode.requestFocus();
    
    calculateTotals();
  }

  void updateQty(int index, int delta) {
    final session = activeSession;
    final cartItem = session.rxCartItems[index];
    final newQty = (cartItem.qty ?? 0) + delta;

    if (newQty <= 0) {
      session.rxCartItems.removeAt(index);
    } else {
      if (delta > 0) {
        final stockItem = cartItem.item.target;
        final availableStock = stockItem?.totalQty ?? 0;
        if (newQty > availableStock) {
          SnackbarUtil.showError("Insufficient stock! Available: $availableStock");
          return;
        }
      }
      cartItem.qty = newQty;
      cartItem.total = newQty * (cartItem.price ?? 0);
      session.rxCartItems[index] = cartItem;
    }
    calculateTotals();
  }

  void removeFromCart(int index) {
    activeSession.rxCartItems.removeAt(index);
    calculateTotals();
  }

  void setTaxRate(double rate) {
    activeSession.rxTaxRate.value = rate;
    calculateTotals();
  }

  void setBillDiscount(double amount) {
    activeSession.rxDiscountAmount.value = amount;
    calculateTotals();
  }

  void calculateTotals() {
    final session = activeSession;
    double subTotal = 0;
    for (var item in session.rxCartItems) {
      double itemPrice = item.price ?? 0;
      double itemQty = (item.qty ?? 0).toDouble();
      double itemDiscount = item.discount ?? 0;
      item.total = (itemPrice * itemQty) - itemDiscount;
      subTotal += item.total ?? 0;
    }

    session.rxSubTotal.value = subTotal;
    session.rxTaxAmount.value = (subTotal * (session.rxTaxRate.value / 100));
    double grand = subTotal + session.rxTaxAmount.value - session.rxDiscountAmount.value;
    if (grand < 0) grand = 0;
    session.rxGrandTotal.value = grand;

    calculateChange();
  }

  void onAmountChanged(String val) {
    activeSession.rxAmountReceived.value = double.tryParse(val) ?? 0.0;
    calculateChange();
  }

  void calculateChange() {
    final session = activeSession;
    double received = session.rxAmountReceived.value;
    double grand = session.rxGrandTotal.value;
    if (received >= grand) {
      session.rxChangeReturned.value = received - grand;
      session.rxDueAmount.value = 0.0;
    } else {
      session.rxChangeReturned.value = 0.0;
      session.rxDueAmount.value = grand - received;
    }
  }

  void setQty(int index, int newQty) {
    final session = activeSession;
    if (index < 0 || index >= session.rxCartItems.length) return;
    final cartItem = session.rxCartItems[index];

    if (newQty <= 0) {
      session.rxCartItems.removeAt(index);
    } else {
      final stockItem = cartItem.item.target;
      final availableStock = stockItem?.totalQty ?? 0;
      if (newQty > availableStock) {
        SnackbarUtil.showError("Insufficient stock! Available: $availableStock");
        return;
      }
      cartItem.qty = newQty;
      session.rxCartItems[index] = cartItem;
    }
    calculateTotals();
  }

  void setItemDiscount(int index, double discountAmount) {
    final session = activeSession;
    if (index < 0 || index >= session.rxCartItems.length) return;
    final cartItem = session.rxCartItems[index];
    cartItem.discount = discountAmount;
    session.rxCartItems[index] = cartItem;
    calculateTotals();
  }

  void clearCart() {
    final session = activeSession;
    session.rxCartItems.clear();
    session.rxDiscountAmount.value = 0;
    session.rxTaxRate.value = 0;
    session.rxTaxAmount.value = 0;
    session.rxGrandTotal.value = 0;
    session.rxSubTotal.value = 0;
    session.rxSelectedCustomer.value = null;
    session.rxSelectedCartIndex.value = -1;
    session.rxRemark.value = '';
    session.amountController.clear();
    session.rxAmountReceived.value = 0.0;
    calculateTotals();
  }

  void handleShortcut(LogicalKeyboardKey key) {
    final session = activeSession;
    if (key == LogicalKeyboardKey.f2) {
      if (session.rxSelectedCartIndex.value != -1) {
         _showChangeQtyDialog(session.rxSelectedCartIndex.value);
      }
    } else if (key == LogicalKeyboardKey.f3) {
      if (session.rxSelectedCartIndex.value != -1) {
         _showItemDiscountDialog(session.rxSelectedCartIndex.value);
      }
    } else if (key == LogicalKeyboardKey.delete) {
      if (session.rxSelectedCartIndex.value != -1) {
        removeFromCart(session.rxSelectedCartIndex.value);
        session.rxSelectedCartIndex.value = -1;
      }
    } else if (key == LogicalKeyboardKey.f4) {
      _showBillDiscountDialog();
    } else if (key == LogicalKeyboardKey.f5) {
      _showRemarksDialog();
    } else if (key == LogicalKeyboardKey.keyP) {
      settleBill();
    } else if (key == LogicalKeyboardKey.keyT) {
      addNewTab();
    }
  }

  void _showChangeQtyDialog(int index) {
      final session = activeSession;
      final cartItem = session.rxCartItems[index];
      final ctrl = TextEditingController(text: "${cartItem.qty}");
      Get.dialog(AlertDialog(
         title: Text('change_qty'.trParams({'itemName': '${cartItem.itemName}'})),
         content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: "New Quantity"),
            onSubmitted: (val) {
               Get.back();
               int? q = int.tryParse(val);
               if (q != null) setQty(index, q);
               searchFocusNode.requestFocus();
            },
         ),
         actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () {
               Get.back();
               int? q = int.tryParse(ctrl.text);
               if (q != null) setQty(index, q);
               searchFocusNode.requestFocus();
            }, child: Text('save'.tr)),
         ],
      ));
  }

  void _showItemDiscountDialog(int index) {
      final session = activeSession;
      final cartItem = session.rxCartItems[index];
      final ctrl = TextEditingController(text: "${cartItem.discount ?? 0}");
      Get.dialog(AlertDialog(
         title: Text('set_item_discount'.trParams({'itemName': '${cartItem.itemName}'})),
         content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(labelText: "Discount Amount (${serviceCurrency.rxCurrency.value})"),
            onSubmitted: (val) {
               Get.back();
               double? d = double.tryParse(val);
               if (d != null) setItemDiscount(index, d);
               searchFocusNode.requestFocus();
            },
         ),
         actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () {
               Get.back();
               double? d = double.tryParse(ctrl.text);
               if (d != null) setItemDiscount(index, d);
               searchFocusNode.requestFocus();
            }, child: Text('save'.tr)),
         ],
      ));
  }

  void _showBillDiscountDialog() {
      final session = activeSession;
      final ctrl = TextEditingController(text: "${session.rxDiscountAmount.value}");
      Get.dialog(AlertDialog(
         title: Text('set_bill_discount'.tr),
         content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(labelText: "Discount Amount (${serviceCurrency.rxCurrency.value})"),
            onSubmitted: (val) {
               Get.back();
               double? d = double.tryParse(val);
               if (d != null) setBillDiscount(d);
               searchFocusNode.requestFocus();
            },
         ),
         actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () {
               Get.back();
               double? d = double.tryParse(ctrl.text);
               if (d != null) setBillDiscount(d);
               searchFocusNode.requestFocus();
            }, child: Text('save'.tr)),
         ],
      ));
  }

  void _showRemarksDialog() {
      final session = activeSession;
      final ctrl = TextEditingController(text: session.rxRemark.value);
      Get.dialog(AlertDialog(
         title: Text('bill_remarks'.tr),
         content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(labelText: "Enter note..."),
            onSubmitted: (val) {
               Get.back();
               session.rxRemark.value = val;
               searchFocusNode.requestFocus();
            },
         ),
         actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () {
               Get.back();
               session.rxRemark.value = ctrl.text;
               searchFocusNode.requestFocus();
            }, child: Text('save'.tr)),
         ],
      ));
  }

  Future<void> settleBill() async {
    final session = activeSession;
    if (session.rxCartItems.isEmpty) {
      SnackbarUtil.showError("Cart is empty");
      return;
    }

    if (session.rxDueAmount.value > 0.01) {
      if (session.rxSelectedCustomer.value == null) {
        SnackbarUtil.showError("Please map a customer for the pending due amount (₹${session.rxDueAmount.value.toStringAsFixed(2)}).");
        return;
      }
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final todayDate = DateFormat('d/MM/yyyy').format(DateTime.now());

    EntityCustomer? customer = session.rxSelectedCustomer.value;
    
    // If no customer selected but quick name/phone entered
    if (customer == null && 
        (session.rxQuickCustomerName.value.isNotEmpty || session.rxQuickCustomerPhone.value.isNotEmpty)) {
      final newCust = EntityCustomer(
        name: session.rxQuickCustomerName.value,
        phone: session.rxQuickCustomerPhone.value,
        isActive: true,
        createdAtUtcMs: now,
        updatedAtUtcMs: now,
      );
      final cid = _boxCustomer.put(newCust);
      customer = _boxCustomer.get(cid);
      loadCustomers(); // Refresh list
    }

    final customerName = customer != null ? "${customer.name}" : "Walk-in";
    final customerPhone = customer?.phone ?? "";

    final bill = EntityBill(
      billNo: "BIL-$now",
      customerName: customerName,
      customerPhone: customerPhone,
      totalAmount: session.rxSubTotal.value,
      discount: session.rxDiscountAmount.value,
      tax: session.rxTaxAmount.value,
      grandTotal: session.rxGrandTotal.value,
      status: session.rxDueAmount.value > 0.01 ? "DUE" : "PAID",
      paymentMode: session.rxPaymentMode.value,
      amountReceived: session.rxAmountReceived.value,
      changeReturned: session.rxChangeReturned.value,
      utrNumber: "",
      splitCash: 0,
      splitOnline: 0,
      dueAmount: session.rxDueAmount.value,
      billDate: todayDate,
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );
    bill.note = session.rxRemark.value;

    // Save Bill first to get ID
    final billId = _boxBill.put(bill);
    final savedBill = _boxBill.get(billId)!;

    // Save Bill Items & Deduct Stock
    for (var cartItem in session.rxCartItems) {
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

      // Deduct stock from item
      final stockItem = cartItem.item.target;
      if (stockItem != null) {
        final soldQty = cartItem.qty ?? 0;
        if (stockItem.hasExpiry == true) {
          _deductFromBatches(stockItem.id ?? 0, soldQty);
        }
        stockItem.totalQty = (stockItem.totalQty ?? 0) - soldQty;
        if (stockItem.totalQty! < 0) stockItem.totalQty = 0;
        stockItem.updatedAtUtcMs = now;
        _boxItem.put(stockItem);

        _boxStockTxn.put(EntityStockTransaction(
          itemId: stockItem.id ?? 0,
          type: StockTxnType.sell.index,
          quantity: -soldQty,
          referenceType: 'sell',
          referenceId: stockItem.name ?? '',
          remarks: 'Sold via POS',
          createdAtUtcMs: now,
        ));
      }
    }

    clearCart();
    loadItems(); // Refresh stock

    if (Get.isRegistered<ControllerHomeItem>()) {
      Get.find<ControllerHomeItem>().loadItems();
    }
    if (Get.isRegistered<ControllerHomeBills>()) {
      Get.find<ControllerHomeBills>().loadData();
    }

    Get.dialog(DialogBillDetail(bill: savedBill), barrierDismissible: false);
  }

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
        remaining -= batchQty;
        _boxBatch.remove(batch.id!);
      } else {
        batch.quantity = batchQty - remaining;
        _boxBatch.put(batch);
        remaining = 0;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CANCEL BILL — reverse stock & mark CANCELLED
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> cancelBill(EntityBill bill) async {
    if (bill.status == 'CANCELLED') {
      SnackbarUtil.showError('This bill is already cancelled');
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Restore stock for every item on the bill
    for (final billItem in bill.items) {
      final stockItem = billItem.item.target;
      if (stockItem == null) continue;

      final soldQty = billItem.qty ?? 0;
      if (soldQty <= 0) continue;

      // Add stock back
      stockItem.totalQty = (stockItem.totalQty ?? 0) + soldQty;
      stockItem.updatedAtUtcMs = now;
      _boxItem.put(stockItem);

      // If item has expiry batches, re-create a batch entry
      if (stockItem.hasExpiry == true) {
        final batch = EntityItemBatch(
          itemId: stockItem.id ?? 0,
          quantity: soldQty,
          receivedAtUtcMs: now,
        );
        _boxBatch.put(batch);
      }

      // Audit trail — reversal transaction
      _boxStockTxn.put(EntityStockTransaction(
        itemId: stockItem.id ?? 0,
        type: StockTxnType.returnStock.index,
        quantity: soldQty,
        referenceType: 'bill_cancel',
        referenceId: bill.billNo ?? '',
        remarks: 'Stock returned — bill cancelled',
        createdAtUtcMs: now,
      ));
    }

    // Mark bill cancelled
    bill.status = 'CANCELLED';
    bill.updatedAtUtcMs = now;
    _boxBill.put(bill);

    // Refresh dependent controllers
    loadItems();
    if (Get.isRegistered<ControllerHomeItem>()) {
      Get.find<ControllerHomeItem>().loadItems();
    }
    if (Get.isRegistered<ControllerHomeBills>()) {
      Get.find<ControllerHomeBills>().loadData();
    }

    SnackbarUtil.showSuccess('Bill ${bill.billNo} has been cancelled');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT BILL — cancel old bill & reload items into POS cart
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> editBill(EntityBill bill) async {
    if (bill.status == 'CANCELLED') {
      SnackbarUtil.showError('Cannot edit a cancelled bill');
      return;
    }

    // Snapshot the bill data before cancelling
    final billItems = bill.items.toList();
    final customerName = bill.customerName;
    final customerPhone = bill.customerPhone;
    final discount = bill.discount ?? 0;
    final taxAmount = bill.tax ?? 0;
    final paymentMode = bill.paymentMode ?? 'Cash';
    final note = bill.note ?? '';

    // Step 1 — cancel the bill (this restores stock)
    await cancelBill(bill);

    // Step 2 — open a new tab and load items into it
    addNewTab();
    final session = activeSession;

    // Restore customer if available
    if (customerName != null && customerName != 'Walk-in') {
      // Try to find existing customer by phone first, then by name
      EntityCustomer? customer;
      if (customerPhone != null && customerPhone.isNotEmpty) {
        customer = _boxCustomer
            .query(EntityCustomer_.phone.equals(customerPhone))
            .build()
            .findFirst();
      }
      customer ??= _boxCustomer
          .query(EntityCustomer_.name.equals(customerName))
          .build()
          .findFirst();
      if (customer != null) {
        session.rxSelectedCustomer.value = customer;
      } else {
        session.rxQuickCustomerName.value = customerName;
        session.rxQuickCustomerPhone.value = customerPhone ?? '';
      }
    }

    // Restore cart items
    for (final oldItem in billItems) {
      final newCartItem = EntityBillItem(
        itemName: oldItem.itemName,
        itemBarcode: oldItem.itemBarcode,
        unit: oldItem.unit,
        price: oldItem.price,
        qty: oldItem.qty,
        tax: oldItem.tax,
        discount: oldItem.discount,
        total: oldItem.total,
      );
      newCartItem.item.target = oldItem.item.target;
      session.rxCartItems.add(newCartItem);
    }

    // Restore bill-level settings
    session.rxDiscountAmount.value = discount;
    if (taxAmount > 0) {
      // Approximate the tax rate from the saved amounts
      final subTotal = bill.totalAmount ?? 0;
      if (subTotal > 0) {
        session.rxTaxRate.value = (taxAmount / subTotal) * 100;
      }
    }
    session.rxPaymentMode.value = paymentMode;
    session.rxRemark.value = note;

    calculateTotals();
  }

  Future<void> openCustomerForm() async {
    final countBefore = _boxCustomer.count();
    await Get.to(() => const ActivityCustomerForm());
    loadCustomers();
    if (_boxCustomer.count() > countBefore) {
      final newCustomer = _boxCustomer.query().order(EntityCustomer_.id, flags: Order.descending).build().findFirst();
      activeSession.rxSelectedCustomer.value = newCustomer;
    }
    searchFocusNode.requestFocus();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchCustomerController.dispose();
    searchFocusNode.dispose();
    for (var session in rxBillTabs) {
      session.dispose();
    }
    super.onClose();
  }
}
