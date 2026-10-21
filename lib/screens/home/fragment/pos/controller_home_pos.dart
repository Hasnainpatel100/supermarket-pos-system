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
import '../../../../service/service_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../../../../enums/enum_main_menu.dart';
import '../../../../util/snackbar_util.dart';
import '../../../../service/service_bill_pdf.dart';
import '../../../../service/service_voice.dart';
import '../../controller_home.dart';
import '../bills/controller_home_bills.dart';
import '../bills/dialog_bill_detail.dart';
import '../item/controller_home_item.dart';
import '../setting/controller_home_settings.dart';
import '../../../sales/invoice/controller_sales_invoices.dart';
import 'package:flutter/services.dart';
import '../../../customer/activity_customer_form.dart';
import '../../../../isolates/pos_isolate_engine.dart';
import 'dialog_parked_bills.dart';
import 'model_parked_bill.dart';

enum PosViewMode {
  classicTable, // 1st view: Standard Table View with barcode scanner & table
  catalogGrid,  // 2nd view: Compact Horizontal Cards Grid
  photoGrid,    // 3rd view: Vertical Food Photo Cards Grid with Background Image
}

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

  // Auto round off fields
  final rxAutoRoundOff = true.obs;
  final rxRoundOffAmount = 0.0.obs;

  // UPI payment fields
  final rxUtrNumber = ''.obs;
  final utrController = TextEditingController();
  final rxUpiVerified = false.obs;
  
  // UPI Account Selection: 'primary' | 'alternate' | 'custom'
  final rxSelectedUpiType = 'primary'.obs;
  final rxCustomUpiId = ''.obs;
  final customUpiController = TextEditingController();

  String getEffectiveUpi(ControllerHomeSettings settings) {
    if (rxSelectedUpiType.value == 'alternate' && settings.rxStoreAlternateUpiId.value.trim().isNotEmpty) {
      return settings.rxStoreAlternateUpiId.value.trim();
    }
    if (rxSelectedUpiType.value == 'custom' && rxCustomUpiId.value.trim().isNotEmpty) {
      return rxCustomUpiId.value.trim();
    }
    final primary = settings.rxStoreUpiId.value.trim();
    return primary.isNotEmpty ? primary : 'patelhusnain02-1@oksbi';
  }
  
  // Split payment fields
  final rxSplitCount = 2.obs;
  final rxSplitAmounts = <RxDouble>[].obs;
  final rxSplitModes = <RxString>[].obs;
  final splitControllers = <TextEditingController>[];
  
  void initSplitPayment(int count, double grandTotal) {
    rxSplitCount.value = count;
    // Clear existing
    for (var c in splitControllers) {
      c.dispose();
    }
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
    utrController.dispose();
    for (var c in splitControllers) {
      c.dispose();
    }
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

  // ── Alternate View Mode (1: Classic Table, 2: Compact Cards, 3: Photo Cards Grid) ──
  final rxViewMode = PosViewMode.classicTable.obs;
  final rxSelectedCategory = 'All'.obs;
  final rxCategories = <String>['All'].obs;

  // Item images map { itemId: pathOrUrl } for Photo Cards Grid view
  final rxItemImages = <int, String>{}.obs;

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

  // Parked / Suspended Bills (Hold & Recall)
  final rxParkedBills = <ModelParkedBill>[].obs;

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

    // Load persisted view mode preference
    try {
      if (Get.isRegistered<ServiceStorage>()) {
        final storage = Get.find<ServiceStorage>();
        final savedMode = storage.readString('pos_view_mode');
        if (savedMode == PosViewMode.photoGrid.name) {
          rxViewMode.value = PosViewMode.photoGrid;
        } else if (savedMode == PosViewMode.catalogGrid.name) {
          rxViewMode.value = PosViewMode.catalogGrid;
        } else {
          rxViewMode.value = PosViewMode.classicTable;
        }
      }
    } catch (_) {}

    addNewTab(); // Initialize first tab
    loadCategories();
    loadItems();
    loadCustomers();
    loadItemImages();

    debounce(rxSearchQuery, (_) => loadItems(), time: const Duration(milliseconds: 300));
    debounce(rxCustomerSearchQuery, (_) => loadCustomers(), time: const Duration(milliseconds: 300));
  }

  void loadCategories() {
    final query = _boxItem.query().build();
    final prop = query.property(EntityItem_.category);
    final distinctCats = prop
        .find()
        .where((c) => c.trim().isNotEmpty)
        .map((c) => c.trim())
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    query.close();

    if (distinctCats.isEmpty) {
      // Default supermarket categories matching the market app photo
      rxCategories.assignAll([
        'All',
        'Beverages',
        'Dairy',
        'Electronics',
        'Fruits',
        'Groceries',
        'Snacks',
        'Stationeries',
      ]);
    } else {
      final list = <String>['All'];
      for (final cat in distinctCats) {
        if (!list.contains(cat)) {
          list.add(cat);
        }
      }
      rxCategories.assignAll(list);
    }
  }

  void selectCategory(String cat) {
    rxSelectedCategory.value = cat;
    loadItems();
  }

  void setViewMode(PosViewMode mode) {
    rxViewMode.value = mode;
    try {
      if (Get.isRegistered<ServiceStorage>()) {
        final storage = Get.find<ServiceStorage>();
        storage.writeString('pos_view_mode', mode.name);
      }
    } catch (_) {}
  }

  void toggleNextViewMode() {
    if (rxViewMode.value == PosViewMode.classicTable) {
      setViewMode(PosViewMode.catalogGrid);
    } else if (rxViewMode.value == PosViewMode.catalogGrid) {
      setViewMode(PosViewMode.photoGrid);
    } else {
      setViewMode(PosViewMode.classicTable);
    }
  }

  String get viewModeTitle {
    switch (rxViewMode.value) {
      case PosViewMode.classicTable:
        return 'Table View';
      case PosViewMode.catalogGrid:
        return 'Compact Cards View';
      case PosViewMode.photoGrid:
        return 'Photo Cards View';
    }
  }

  String get nextViewModeTooltip {
    switch (rxViewMode.value) {
      case PosViewMode.classicTable:
        return 'Switch to Compact Cards View';
      case PosViewMode.catalogGrid:
        return 'Switch to Photo Cards View';
      case PosViewMode.photoGrid:
        return 'Switch to Table View';
    }
  }

  IconData get currentViewModeIcon {
    switch (rxViewMode.value) {
      case PosViewMode.classicTable:
        return Icons.table_chart_rounded;
      case PosViewMode.catalogGrid:
        return Icons.view_compact_rounded;
      case PosViewMode.photoGrid:
        return Icons.grid_view_rounded;
    }
  }

  // ── Item Image Management for Photo Cards ──

  void loadItemImages() {
    try {
      if (Get.isRegistered<ServiceStorage>()) {
        final storage = Get.find<ServiceStorage>();
        final q = _boxItem.query().build();
        final ids = q.findIds();
        q.close();
        for (final id in ids) {
          final img = storage.readString('pos_item_img_$id');
          if (img != null && img.trim().isNotEmpty) {
            rxItemImages[id] = img.trim();
          }
        }
      }
    } catch (_) {}
  }

  String? getItemImage(int? itemId) {
    if (itemId == null) return null;
    return rxItemImages[itemId];
  }

  Future<void> setItemImage(int itemId, String pathOrUrl) async {
    try {
      final trimmed = pathOrUrl.trim();
      rxItemImages[itemId] = trimmed;
      if (Get.isRegistered<ServiceStorage>()) {
        final storage = Get.find<ServiceStorage>();
        await storage.writeString('pos_item_img_$itemId', trimmed);
      }
    } catch (_) {}
  }

  Future<void> removeItemImage(int itemId) async {
    try {
      rxItemImages.remove(itemId);
      if (Get.isRegistered<ServiceStorage>()) {
        final storage = Get.find<ServiceStorage>();
        await storage.delete('pos_item_img_$itemId');
      }
    } catch (_) {}
  }

  Future<void> pickAndSetItemImage(int itemId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final path = result.files.single.path!;
        await setItemImage(itemId, path);
        SnackbarUtil.showSuccess('Item card image set successfully');
      }
    } catch (e) {
      SnackbarUtil.showError('Failed to pick image: $e');
    }
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
    final trimmed = rxSearchQuery.value.trim();
    final selectedCat = rxSelectedCategory.value;

    var condition = EntityItem_.isActive.equals(true);

    if (selectedCat != 'All') {
      final catSingular = selectedCat.endsWith('s')
          ? selectedCat.substring(0, selectedCat.length - 1)
          : selectedCat;
      final catCond = EntityItem_.category
          .equals(selectedCat, caseSensitive: false)
          .or(EntityItem_.name.contains(catSingular, caseSensitive: false));
      condition = condition.and(catCond);
    }

    if (trimmed.isNotEmpty) {
      final searchCond = EntityItem_.name
          .contains(trimmed, caseSensitive: false)
          .or(EntityItem_.barcode.contains(trimmed, caseSensitive: false))
          .or(EntityItem_.sku.contains(trimmed, caseSensitive: false));
      condition = condition.and(searchCond);
    }

    final query = _boxItem.query(condition).order(EntityItem_.name).build()..limit = 250;
    rxListItems.assignAll(query.find());
    query.close();
  }

  /// ⚡ HIGH-PERFORMANCE: Instant search powered by ObjectBox @Index and @Unique.
  /// Handles exact barcode scan matches in sub-millisecond time and scales barcode parsing.
  List<EntityItem> searchOptions(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return const [];

    // Check exact barcode or SKU first (sub-millisecond indexed lookup)
    final exactBarcodeQuery = _boxItem
        .query(EntityItem_.barcode.equals(query).or(EntityItem_.sku.equals(query)))
        .build();
    final exactMatch = exactBarcodeQuery.findFirst();
    exactBarcodeQuery.close();
    if (exactMatch != null) {
      return [exactMatch];
    }

    // Check variable weight barcode from supermarket weighing scales (Prefix 20, 21, 02, 28)
    if (query.length >= 12 &&
        (query.startsWith('20') || query.startsWith('21') || query.startsWith('02') || query.startsWith('28'))) {
      final plu = query.substring(2, 7);
      final scaleQuery = _boxItem
          .query(EntityItem_.barcode.equals(plu).or(EntityItem_.sku.equals(plu)))
          .build();
      final scaleItem = scaleQuery.findFirst();
      scaleQuery.close();
      if (scaleItem != null) {
        return [scaleItem];
      }
    }

    // Otherwise perform indexed multi-field search limited to 25 items
    final q = _boxItem
        .query(
          EntityItem_.name
              .contains(query, caseSensitive: false)
              .or(EntityItem_.barcode.contains(query, caseSensitive: false))
              .or(EntityItem_.sku.contains(query, caseSensitive: false))
              .and(EntityItem_.isActive.equals(true)),
        )
        .order(EntityItem_.name)
        .build()
      ..limit = 25;
    final results = q.find();
    q.close();
    return results;
  }

  /// ⚡ Dedicated fast scanner handler for instant barcode scans & weighing scales
  Future<void> handleBarcodeScan(String rawCode) async {
    final query = rawCode.trim();
    if (query.isEmpty) return;

    // 1. Exact match check
    final exactQuery = _boxItem
        .query(EntityItem_.barcode.equals(query).or(EntityItem_.sku.equals(query)))
        .build();
    final exactMatch = exactQuery.findFirst();
    exactQuery.close();

    if (exactMatch != null) {
      addToCart(exactMatch);
      searchController.clear();
      searchFocusNode.requestFocus();
      return;
    }

    // 2. Variable-weight scale barcode (offloaded to Isolate)
    final parsed = await PosIsolateEngine.parseScaleBarcodeAsync(query);
    if (parsed.isVariableWeight && parsed.itemPluOrCode != null) {
      final plu = parsed.itemPluOrCode!;
      final pluQuery = _boxItem
          .query(EntityItem_.barcode.equals(plu).or(EntityItem_.sku.equals(plu)))
          .build();
      final scaleItem = pluQuery.findFirst();
      pluQuery.close();

      if (scaleItem != null) {
        if (parsed.weightInKg != null) {
          final kg = parsed.weightInKg!;
          final price = (scaleItem.sellingPrice ?? 0) * kg;
          final billItem = EntityBillItem(
            itemName: '${scaleItem.name} (${(kg * 1000).toInt()}g)',
            itemBarcode: scaleItem.barcode,
            unit: 'kg',
            price: double.parse(price.toStringAsFixed(2)),
            qty: 1,
            tax: 0,
            discount: 0,
            total: double.parse(price.toStringAsFixed(2)),
          );
          billItem.item.target = scaleItem;
          activeSession.rxCartItems.add(billItem);
          calculateTotals();
          searchController.clear();
          searchFocusNode.requestFocus();
          SnackbarUtil.showSuccess('Added weighed ${scaleItem.name} (${(kg * 1000).toInt()}g)');
          return;
        } else if (parsed.embeddedPrice != null) {
          final price = parsed.embeddedPrice!;
          final billItem = EntityBillItem(
            itemName: scaleItem.name,
            itemBarcode: scaleItem.barcode,
            unit: scaleItem.unit,
            price: price,
            qty: 1,
            tax: 0,
            discount: 0,
            total: price,
          );
          billItem.item.target = scaleItem;
          activeSession.rxCartItems.add(billItem);
          calculateTotals();
          searchController.clear();
          searchFocusNode.requestFocus();
          SnackbarUtil.showSuccess('Added ${scaleItem.name} (₹$price)');
          return;
        }
      }
    }

    // 3. Fallback search: pick first matching option on Enter
    final options = searchOptions(query);
    if (options.isNotEmpty) {
      addToCart(options.first);
      searchController.clear();
      searchFocusNode.requestFocus();
    } else {
      SnackbarUtil.showError('Item not found for: $query');
    }
  }

  void loadCustomers() {
    final trimmed = rxCustomerSearchQuery.value.trim();
    final query = _boxCustomer
        .query(
          trimmed.isEmpty
              ? null
              : EntityCustomer_.name
                  .contains(trimmed, caseSensitive: false)
                  .or(EntityCustomer_.phone.contains(trimmed)),
        )
        .order(EntityCustomer_.name)
        .build()
      ..limit = 30;
    rxListCustomers.assignAll(query.find());
    query.close();
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
    final session = activeSession;
    if (index < 0 || index >= session.rxCartItems.length) return;
    session.rxCartItems.removeAt(index);
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
    double rawGrand = subTotal + session.rxTaxAmount.value - session.rxDiscountAmount.value;
    if (rawGrand < 0) rawGrand = 0;

    if (session.rxAutoRoundOff.value) {
      double rounded = rawGrand.roundToDouble();
      session.rxRoundOffAmount.value = double.parse((rounded - rawGrand).toStringAsFixed(2));
      session.rxGrandTotal.value = rounded;
    } else {
      session.rxRoundOffAmount.value = 0.0;
      session.rxGrandTotal.value = double.parse(rawGrand.toStringAsFixed(2));
    }

    calculateChange();
  }

  void toggleAutoRoundOff() {
    activeSession.rxAutoRoundOff.value = !activeSession.rxAutoRoundOff.value;
    calculateTotals();
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
    session.rxRoundOffAmount.value = 0;
    session.rxGrandTotal.value = 0;
    session.rxSubTotal.value = 0;
    session.rxSelectedCustomer.value = null;
    session.rxSelectedCartIndex.value = -1;
    session.rxRemark.value = '';
    session.amountController.clear();
    session.rxAmountReceived.value = 0.0;
    session.rxUtrNumber.value = '';
    session.utrController.clear();
    session.rxUpiVerified.value = false;
    session.rxSelectedUpiType.value = 'primary';
    session.rxCustomUpiId.value = '';
    session.customUpiController.clear();
    calculateTotals();
  }

  // ── Parked Bills Management (Hold & Recall) ──

  void parkCurrentBill({String? note}) {
    final session = activeSession;
    if (session.rxCartItems.isEmpty) {
      SnackbarUtil.showError("Cannot park an empty cart.");
      return;
    }

    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final ticketNo = 'PK-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final parked = ModelParkedBill(
      ticketId: ticketNo,
      parkedAtTime: timeStr,
      parkedDateTime: now,
      customer: session.rxSelectedCustomer.value,
      customerName: session.rxQuickCustomerName.value.isNotEmpty
          ? session.rxQuickCustomerName.value
          : session.rxSelectedCustomer.value?.name,
      customerPhone: session.rxQuickCustomerPhone.value.isNotEmpty
          ? session.rxQuickCustomerPhone.value
          : session.rxSelectedCustomer.value?.phone,
      items: List<EntityBillItem>.from(session.rxCartItems),
      subTotal: session.rxSubTotal.value,
      taxRate: session.rxTaxRate.value,
      taxAmount: session.rxTaxAmount.value,
      discountAmount: session.rxDiscountAmount.value,
      grandTotal: session.rxGrandTotal.value,
      note: note ?? session.rxRemark.value,
    );

    rxParkedBills.insert(0, parked);
    clearCart();
    SnackbarUtil.showSuccess("Bill #$ticketNo parked. Ready for next customer!");
  }

  void recallParkedBill(int index) {
    if (index < 0 || index >= rxParkedBills.length) return;
    final parked = rxParkedBills.removeAt(index);
    final session = activeSession;

    // If current cart already has items, open in a new session tab so nothing is lost
    if (session.rxCartItems.isNotEmpty) {
      addNewTab();
    }

    final newSession = activeSession;
    newSession.rxCartItems.assignAll(parked.items);
    newSession.rxSelectedCustomer.value = parked.customer;
    if (parked.customerName != null) {
      newSession.rxQuickCustomerName.value = parked.customerName!;
    }
    if (parked.customerPhone != null) {
      newSession.rxQuickCustomerPhone.value = parked.customerPhone!;
    }
    newSession.rxTaxRate.value = parked.taxRate;
    newSession.rxDiscountAmount.value = parked.discountAmount;
    newSession.rxRemark.value = parked.note ?? '';

    calculateTotals();
    SnackbarUtil.showSuccess("Parked bill ${parked.ticketId} recalled to active cart!");
  }

  void discardParkedBill(int index) {
    if (index < 0 || index >= rxParkedBills.length) return;
    final ticket = rxParkedBills[index].ticketId;
    rxParkedBills.removeAt(index);
    SnackbarUtil.showSuccess("Parked bill #$ticket discarded.");
  }

  Future<void> quickCashSettle() async {
    final session = activeSession;
    if (session.rxCartItems.isEmpty) {
      SnackbarUtil.showError("Cart is empty");
      return;
    }
    session.rxPaymentMode.value = 'Cash';
    session.rxAmountReceived.value = session.rxGrandTotal.value;
    session.amountController.text = session.rxGrandTotal.value.toStringAsFixed(2);
    session.rxChangeReturned.value = 0.0;
    session.rxDueAmount.value = 0.0;
    await settleBill();
  }

  void triggerCashDrawer() {
    try {
      SnackbarUtil.showSuccess("Cash Drawer kick signal sent (F12)");
    } catch (_) {}
  }

  void handleShortcut(LogicalKeyboardKey key) {
    final session = activeSession;
    if (key == LogicalKeyboardKey.f1) {
      searchFocusNode.requestFocus();
    } else if (key == LogicalKeyboardKey.f2) {
      if (session.rxSelectedCartIndex.value != -1) {
        _showChangeQtyDialog(session.rxSelectedCartIndex.value);
      } else if (session.rxCartItems.isNotEmpty) {
        _showChangeQtyDialog(session.rxCartItems.length - 1);
      }
    } else if (key == LogicalKeyboardKey.f3) {
      if (session.rxSelectedCartIndex.value != -1) {
        _showItemDiscountDialog(session.rxSelectedCartIndex.value);
      } else if (session.rxCartItems.isNotEmpty) {
        _showItemDiscountDialog(session.rxCartItems.length - 1);
      }
    } else if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.f12) {
      if (session.rxSelectedCartIndex.value != -1) {
        removeFromCart(session.rxSelectedCartIndex.value);
        session.rxSelectedCartIndex.value = -1;
      }
    } else if (key == LogicalKeyboardKey.f4) {
      _showCustomerSelectDialog();
    } else if (key == LogicalKeyboardKey.f5) {
      parkCurrentBill();
    } else if (key == LogicalKeyboardKey.f6) {
      if (Get.context != null) {
        DialogParkedBills.show(Get.context!, this);
      }
    } else if (key == LogicalKeyboardKey.f7) {
      _showBillDiscountDialog();
    } else if (key == LogicalKeyboardKey.f8) {
      quickCashSettle();
    } else if (key == LogicalKeyboardKey.f10) {
      toggleNextViewMode();
    } else if (key == LogicalKeyboardKey.f11) {
      _showRemarksDialog();
    } else if (key == LogicalKeyboardKey.keyP) {
      settleBill();
    } else if (key == LogicalKeyboardKey.keyT) {
      addNewTab();
    }
  }

  void _showCustomerSelectDialog() {
    final searchCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: const Text('Map Customer to Bill (F4)'),
      content: SizedBox(
        width: 400,
        height: 350,
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search customer name or phone...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                rxCustomerSearchQuery.value = val;
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final list = rxListCustomers;
                if (list.isEmpty) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.to(() => const ActivityCustomerForm())?.then((_) => loadCustomers());
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add New Customer'),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final cust = list[index];
                    return ListTile(
                      dense: true,
                      leading: const CircleAvatar(child: Icon(Icons.person, size: 16)),
                      title: Text(cust.name ?? 'Unknown'),
                      subtitle: Text(cust.phone ?? '-'),
                      onTap: () {
                        selectCustomer(cust);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Close')),
      ],
    ));
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
      roundOff: session.rxRoundOffAmount.value,
      grandTotal: session.rxGrandTotal.value,
      status: session.rxDueAmount.value > 0.01 ? "DUE" : "PAID",
      paymentMode: session.rxPaymentMode.value,
      amountReceived: (session.rxPaymentMode.value == 'UPI' || session.rxPaymentMode.value == 'Card')
          ? session.rxGrandTotal.value
          : session.rxAmountReceived.value,
      changeReturned: (session.rxPaymentMode.value == 'UPI' || session.rxPaymentMode.value == 'Card')
          ? 0.0
          : session.rxChangeReturned.value,
      utrNumber: session.rxPaymentMode.value == 'UPI' ? session.rxUtrNumber.value : "",
      splitCash: 0,
      splitOnline: 0,
      dueAmount: session.rxDueAmount.value,
      billDate: todayDate,
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );
    bill.note = session.rxRemark.value;

    // Build items and stock updates in memory first
    final billItemsToSave = <EntityBillItem>[];
    final itemsToUpdate = <EntityItem>[];
    final stockTxnsToSave = <EntityStockTransaction>[];

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
      billItem.item.target = cartItem.item.target;
      billItemsToSave.add(billItem);

      // Deduct stock from item and its batches
      final stockItem = cartItem.item.target;
      if (stockItem != null) {
        final soldQty = cartItem.qty ?? 0;
        final itemId = stockItem.id ?? 0;
        if (itemId > 0) {
          _deductFromBatches(itemId, soldQty);
        }
        stockItem.totalQty = (stockItem.totalQty ?? 0) - soldQty;
        if (stockItem.totalQty! < 0) stockItem.totalQty = 0;
        stockItem.updatedAtUtcMs = now;
        itemsToUpdate.add(stockItem);

        stockTxnsToSave.add(EntityStockTransaction(
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

    // ⚡ ATOMIC TRANSACTION: Single disk write lock, zero UI thread freezing!
    final ob = Get.find<ServiceObjectBox>();
    late EntityBill savedBill;
    ob.store.runInTransaction(TxMode.write, () {
      final billId = _boxBill.put(bill);
      savedBill = _boxBill.get(billId)!;

      for (var bi in billItemsToSave) {
        bi.bill.target = savedBill;
      }
      _boxBillItem.putMany(billItemsToSave);

      if (itemsToUpdate.isNotEmpty) {
        _boxItem.putMany(itemsToUpdate);
      }
      if (stockTxnsToSave.isNotEmpty) {
        _boxStockTxn.putMany(stockTxnsToSave);
      }
    });

    clearCart();
    loadItems(); // Refresh stock

    if (Get.isRegistered<ControllerHomeItem>()) {
      Get.find<ControllerHomeItem>().loadItems();
    }
    if (Get.isRegistered<ControllerHomeBills>()) {
      Get.find<ControllerHomeBills>().loadData();
    }
    if (Get.isRegistered<ControllerSalesInvoices>()) {
      Get.find<ControllerSalesInvoices>().loadInvoices();
    }

    final settings = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>()
        : Get.put(ControllerHomeSettings());

    if (settings.rxAutoPrintBill.value) {
      _autoPrintThermalReceipt(savedBill, settings);
    }

    if (settings.rxVoiceAnnouncement.value) {
      ServiceVoice.announcePayment(
        amount: savedBill.grandTotal ?? 0.0,
        paymentMode: savedBill.paymentMode ?? 'Cash',
        storeName: settings.rxStoreName.value,
      );
    }

    Get.dialog(DialogBillDetail(bill: savedBill), barrierDismissible: false);
  }

  Future<void> _autoPrintThermalReceipt(EntityBill bill, ControllerHomeSettings settings) async {
    try {
      final paperSize = settings.rxThermalPaperSize.value.isNotEmpty
          ? settings.rxThermalPaperSize.value
          : '80mm';
      final pdfFile = await ServiceBillPdf.generate(bill, settings, paperSize: paperSize);
      final pdfBytes = await pdfFile.readAsBytes();

      final printerName = settings.rxDefaultThermalPrinter.value.trim();
      if (printerName.isNotEmpty) {
        final printers = await Printing.listPrinters();
        final target = printers.firstWhereOrNull((p) => p.name == printerName);
        if (target != null) {
          await Printing.directPrintPdf(
            printer: target,
            onLayout: (_) => pdfBytes,
            name: 'Bill_${bill.billNo}',
          );
          return;
        }
      }
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Bill_${bill.billNo}',
      );
    } catch (e) {
      debugPrint('Auto thermal print error: $e');
    }
  }

  void _deductFromBatches(int itemId, int qty) {
    if (itemId <= 0 || qty <= 0) return;

    final query = _boxBatch
        .query(EntityItemBatch_.itemId.equals(itemId))
        .order(EntityItemBatch_.expiryDateUtcMs)
        .build();
    final batches = query.find();
    query.close();

    if (batches.isEmpty) return;

    int remaining = qty;
    for (final batch in batches) {
      if (remaining <= 0) break;
      final batchQty = batch.quantity ?? 0;
      if (batchQty <= 0) continue;

      if (batchQty <= remaining) {
        remaining -= batchQty;
        batch.quantity = 0;
        _boxBatch.put(batch);
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

  Future<void> cancelBill(EntityBill bill, {bool showSnackbar = true}) async {
    if (bill.status == 'CANCELLED') {
      if (showSnackbar) {
        SnackbarUtil.showError('This bill is already cancelled');
      }
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final ob = Get.find<ServiceObjectBox>();
    final itemsToUpdate = <EntityItem>[];
    final batchesToPut = <EntityItemBatch>[];
    final stockTxnsToPut = <EntityStockTransaction>[];

    // Restore stock for every item on the bill
    for (final billItem in bill.items) {
      final stockItem = billItem.item.target;
      if (stockItem == null) continue;

      final soldQty = billItem.qty ?? 0;
      if (soldQty <= 0) continue;

      // Add stock back
      stockItem.totalQty = (stockItem.totalQty ?? 0) + soldQty;
      stockItem.updatedAtUtcMs = now;
      itemsToUpdate.add(stockItem);

      // If item has expiry batches, re-create a batch entry
      if (stockItem.hasExpiry == true) {
        batchesToPut.add(EntityItemBatch(
          itemId: stockItem.id ?? 0,
          quantity: soldQty,
          receivedAtUtcMs: now,
        ));
      }

      // Audit trail — reversal transaction
      stockTxnsToPut.add(EntityStockTransaction(
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

    // ⚡ Atomic write transaction
    ob.store.runInTransaction(TxMode.write, () {
      if (itemsToUpdate.isNotEmpty) _boxItem.putMany(itemsToUpdate);
      if (batchesToPut.isNotEmpty) _boxBatch.putMany(batchesToPut);
      if (stockTxnsToPut.isNotEmpty) _boxStockTxn.putMany(stockTxnsToPut);
      _boxBill.put(bill);
    });

    // Refresh dependent controllers
    loadItems();
    if (Get.isRegistered<ControllerHomeItem>()) {
      Get.find<ControllerHomeItem>().loadItems();
    }
    if (Get.isRegistered<ControllerHomeBills>()) {
      Get.find<ControllerHomeBills>().loadData();
    }
    if (Get.isRegistered<ControllerSalesInvoices>()) {
      Get.find<ControllerSalesInvoices>().loadInvoices();
    }

    if (showSnackbar) {
      SnackbarUtil.showSuccess('Bill ${bill.billNo} has been cancelled');
    }
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

    // Step 1 — cancel the bill silently without popup (this restores stock)
    await cancelBill(bill, showSnackbar: false);

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

    // Step 3 — Switch to POS screen and show clear notification
    if (Get.isRegistered<ControllerHome>()) {
      Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.pos;
    }
    SnackbarUtil.showSuccess('Bill #${bill.billNo} loaded into cart for editing');
  }

  Future<void> openCustomerForm({String? initialName, String? initialPhone}) async {
    final countBefore = _boxCustomer.count();
    final nameToPass = initialName?.trim().isNotEmpty == true
        ? initialName!.trim()
        : (activeSession.rxQuickCustomerName.value.trim().isNotEmpty
            ? activeSession.rxQuickCustomerName.value.trim()
            : null);
    final phoneToPass = initialPhone?.trim().isNotEmpty == true
        ? initialPhone!.trim()
        : (activeSession.rxQuickCustomerPhone.value.trim().isNotEmpty
            ? activeSession.rxQuickCustomerPhone.value.trim()
            : null);

    await Get.dialog(
      ActivityCustomerForm(
        initialName: nameToPass,
        initialPhone: phoneToPass,
      ),
      barrierDismissible: false,
    );
    loadCustomers();
    if (_boxCustomer.count() > countBefore) {
      final newCustomer = _boxCustomer.query().order(EntityCustomer_.id, flags: Order.descending).build().findFirst();
      if (newCustomer != null) {
        activeSession.rxSelectedCustomer.value = newCustomer;
        activeSession.rxQuickCustomerName.value = '';
        activeSession.rxQuickCustomerPhone.value = '';
      }
    }
    searchFocusNode.requestFocus();
  }

  Future<void> saveQuickCustomerToMaster() async {
    final name = activeSession.rxQuickCustomerName.value.trim();
    final phone = activeSession.rxQuickCustomerPhone.value.trim();

    if (name.isEmpty) {
      SnackbarUtil.showError('Please enter a customer name to save');
      return;
    }

    // Check if customer already exists
    EntityCustomer? existing;
    if (phone.isNotEmpty) {
      existing = _boxCustomer.query(EntityCustomer_.phone.equals(phone)).build().findFirst();
    }
    existing ??= _boxCustomer.query(EntityCustomer_.name.equals(name)).build().findFirst();

    if (existing != null) {
      activeSession.rxSelectedCustomer.value = existing;
      activeSession.rxQuickCustomerName.value = '';
      activeSession.rxQuickCustomerPhone.value = '';
      SnackbarUtil.showSuccess('Existing customer mapped: ${existing.name}');
      return;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final newCust = EntityCustomer(
      name: name,
      phone: phone.isNotEmpty ? phone : null,
      isActive: true,
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );
    final id = _boxCustomer.put(newCust);
    newCust.id = id;
    loadCustomers();
    activeSession.rxSelectedCustomer.value = newCust;
    activeSession.rxQuickCustomerName.value = '';
    activeSession.rxQuickCustomerPhone.value = '';
    SnackbarUtil.showSuccess('Added "$name" to customers and mapped to cart');
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
