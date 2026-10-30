import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'activity_split_bill.dart';
import 'dialog_select_batch.dart';
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

class PosSearchOption {
  final EntityItem item;
  final EntityItemBatch? batch;

  PosSearchOption({required this.item, this.batch});

  String get displayName => item.name ?? '';
  String? get batchNo => batch?.batchNo;
  int get availableQty => batch?.quantity ?? item.totalQty ?? 0;
  double get price => batch?.salePrice ?? item.sellingPrice ?? 0.0;
  double get mrp => batch?.mrp ?? item.sellingPrice ?? price;
  String? get expiryDate {
    if (batch?.expiryDateUtcMs == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(batch!.expiryDateUtcMs!, isUtc: true);
    return DateFormat('dd-MM-yyyy').format(dt);
  }
  bool get hasBatch => batch != null;
}

class BillSession {
  final String id;
  final rxCartItems = <EntityBillItem>[].obs;
  final rxSelectedCustomer = Rxn<EntityCustomer>();
  final rxSubTotal = 0.0.obs;
  final rxTaxRate = 0.0.obs;
  final rxTaxAmount = 0.0.obs;
  final rxInclusiveTaxAmount = 0.0.obs;
  final rxExclusiveTaxAmount = 0.0.obs;
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
    customUpiController.dispose();
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

  void requestSearchFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!searchFocusNode.hasFocus) {
        searchFocusNode.requestFocus();
      }
    });
  }

  // Cart Items Keyboard Navigation & Scrolling
  final ScrollController cartScrollController = ScrollController();

  void navigateCartItem(int delta) {
    final session = activeSession;
    if (session.rxCartItems.isEmpty) return;

    final current = session.rxSelectedCartIndex.value;
    int next;
    if (current == -1) {
      next = delta > 0 ? 0 : session.rxCartItems.length - 1;
    } else {
      next = (current + delta).clamp(0, session.rxCartItems.length - 1);
    }

    session.rxSelectedCartIndex.value = next;
    scrollToCartItem(next);
  }

  void scrollToCartItem(int index) {
    if (!cartScrollController.hasClients) return;
    try {
      const double rowHeight = 52.0;
      final target = (index * rowHeight).clamp(
        0.0,
        cartScrollController.position.maxScrollExtent,
      );
      cartScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

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
    _loadParkedBills();
    loadCategories();
    loadItems();
    loadCustomers();
    loadItemImages();

    debounce(rxSearchQuery, (_) => loadItems(), time: const Duration(milliseconds: 200));
    debounce(rxCustomerSearchQuery, (_) => loadCustomers(), time: const Duration(milliseconds: 300));

    // Auto-normalize any barcode scanner forward slashes in search field
    searchController.addListener(() {
      final t = searchController.text;
      if (t.contains('/')) {
        final sanitized = t.replaceAll('/', '-');
        searchController.value = searchController.value.copyWith(
          text: sanitized,
          selection: TextSelection.collapsed(offset: sanitized.length),
        );
      }
    });
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
      clearCart(restoreStock: true); // Just clear if it's the last one
      return;
    }
    final tabToClose = rxBillTabs[index];
    for (final cartItem in tabToClose.rxCartItems) {
      final qty = cartItem.qty ?? 0;
      if (qty > 0) {
        if (cartItem.batchId != null && cartItem.batchId! > 0) {
          final batch = _boxBatch.get(cartItem.batchId!);
          if (batch != null) {
            batch.quantity = (batch.quantity ?? 0) + qty;
            _boxBatch.put(batch);
          }
        }
        final stockItem = cartItem.item.target;
        if (stockItem != null) {
          stockItem.totalQty = (stockItem.totalQty ?? 0) + qty;
          _boxItem.put(stockItem);
        }
      }
    }
    loadItems();

    final wasActive = rxActiveTabIndex.value;
    tabToClose.dispose();
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

    // ── Fast path: when the user is actively typing, offload the filtering to a
    // background isolate so the UI never drops below 60 FPS even with 10k+ SKUs.
    if (trimmed.isNotEmpty) {
      _loadItemsViaIsolate(trimmed, selectedCat);
      return;
    }

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

    final query = _boxItem.query(condition).order(EntityItem_.name).build()..limit = 250;
    rxListItems.assignAll(query.find());
    query.close();
  }

  /// Snapshots the full catalogue to plain maps and runs the fuzzy filter in a
  /// background isolate. The search box stays responsive while the heavy work
  /// runs off the Flutter UI thread.
  Future<void> _loadItemsViaIsolate(String query, String selectedCat) async {
    try {
      final allQuery = _boxItem.query(EntityItem_.isActive.equals(true)).build()..limit = 10000;
      final allItems = allQuery.find();
      allQuery.close();

      final snapshot = allItems
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'barcode': e.barcode,
                'sku': e.sku,
                'category': e.category,
                'isActive': e.isActive,
              })
          .toList();

      final filtered = await PosIsolateEngine.filterItemsAsync(
        allItems: snapshot,
        query: query,
        selectedCategory: selectedCat,
      );

      final idSet = filtered.map((m) => m['id'] as int).toSet();
      final results = allItems.where((e) => idSet.contains(e.id)).toList()
        ..sort((a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));

      rxListItems.assignAll(results);
    } catch (_) {
      // Fallback to synchronous DB query if isolate fails
      final q = _boxItem
          .query(
            EntityItem_.name.contains(query, caseSensitive: false)
                .or(EntityItem_.barcode.contains(query, caseSensitive: false))
                .or(EntityItem_.sku.contains(query, caseSensitive: false)),
          )
          .order(EntityItem_.name)
          .build()
        ..limit = 250;
      rxListItems.assignAll(q.find());
      q.close();
    }
  }

  /// ⚡ HIGH-PERFORMANCE: Instant search returning items and their specific batches.
  /// If an item has batches, each batch is returned so the user can select the exact batch.
  List<PosSearchOption> searchOptions(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return const [];

    final List<PosSearchOption> results = [];
    final Set<String> seenKeys = {}; // key: "${item.id}_${batch?.id ?? 'null'}"

    // 1. Search batches directly by batchNo or barcode (only batches with available stock)
    final batchQuery = _boxBatch
        .query(
          (EntityItemBatch_.batchNo
                  .contains(query, caseSensitive: false)
                  .or(EntityItemBatch_.barcode.contains(query, caseSensitive: false)))
              .and(EntityItemBatch_.quantity.greaterThan(0)),
        )
        .build()
      ..limit = 25;
    final matchingBatches = batchQuery.find();
    batchQuery.close();

    for (final b in matchingBatches) {
      if ((b.quantity ?? 0) <= 0) continue;
      if (b.itemId != null && b.itemId! > 0) {
        final item = _boxItem.get(b.itemId!);
        if (item != null) {
          final key = '${item.id}_${b.id}';
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            results.add(PosSearchOption(item: item, batch: b));
          }
        }
      }
    }

    // 2. Exact barcode or SKU check
    final exactBarcodeQuery = _boxItem
        .query(EntityItem_.barcode.equals(query).or(EntityItem_.sku.equals(query)))
        .build();
    final exactMatch = exactBarcodeQuery.findFirst();
    exactBarcodeQuery.close();

    if (exactMatch != null) {
      final batches = _boxBatch
          .query(EntityItemBatch_.itemId
              .equals(exactMatch.id ?? 0)
              .and(EntityItemBatch_.quantity.greaterThan(0)))
          .order(EntityItemBatch_.id)
          .build()
          .find();
      if (batches.isNotEmpty) {
        for (final b in batches) {
          if ((b.quantity ?? 0) <= 0) continue;
          final key = '${exactMatch.id}_${b.id}';
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            results.add(PosSearchOption(item: exactMatch, batch: b));
          }
        }
      } else {
        final key = '${exactMatch.id}_null';
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          results.add(PosSearchOption(item: exactMatch, batch: null));
        }
      }
    }

    // 3. Variable weight barcode from supermarket weighing scales (Prefix 20, 21, 02, 28)
    if (query.length >= 12 &&
        (query.startsWith('20') || query.startsWith('21') || query.startsWith('02') || query.startsWith('28'))) {
      final plu = query.substring(2, 7);
      final scaleQuery = _boxItem
          .query(EntityItem_.barcode.equals(plu).or(EntityItem_.sku.equals(plu)))
          .build();
      final scaleItem = scaleQuery.findFirst();
      scaleQuery.close();
      if (scaleItem != null) {
        final key = '${scaleItem.id}_null';
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          results.add(PosSearchOption(item: scaleItem, batch: null));
        }
      }
    }

    // 4. Multi-field search across item name, barcode, and sku
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
      ..limit = 30;
    final matchingItems = q.find();
    q.close();

    for (final item in matchingItems) {
      final batches = _boxBatch
          .query(EntityItemBatch_.itemId
              .equals(item.id ?? 0)
              .and(EntityItemBatch_.quantity.greaterThan(0)))
          .order(EntityItemBatch_.id)
          .build()
          .find();

      if (batches.isNotEmpty) {
        for (final b in batches) {
          if ((b.quantity ?? 0) <= 0) continue;
          final key = '${item.id}_${b.id}';
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            results.add(PosSearchOption(item: item, batch: b));
          }
        }
      } else {
        final key = '${item.id}_null';
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          results.add(PosSearchOption(item: item, batch: null));
        }
      }
    }

    return results;
  }

  /// Returns all active batches with quantity > 0 for a given item.
  List<EntityItemBatch> getAvailableBatches(EntityItem item) {
    if (item.id == null || item.id == 0) return const [];
    final q = _boxBatch
        .query(EntityItemBatch_.itemId
            .equals(item.id!)
            .and(EntityItemBatch_.quantity.greaterThan(0)))
        .order(EntityItemBatch_.id)
        .build();
    final batches = q.find();
    q.close();
    return batches;
  }

  /// ⚡ Dedicated fast scanner handler for instant barcode scans & weighing scales
  Future<void> handleBarcodeScan(String rawCode) async {
    final query = rawCode.trim();
    if (query.isEmpty) return;

    // 0. Handle scanned invoice/bill barcode (e.g. BIL-1792849558790 or scanner error BIL/1792849558790)
    final sanitizedBillNo = query.replaceAll('/', '-');
    if (sanitizedBillNo.toUpperCase().startsWith('BIL-') || query.toUpperCase().startsWith('BIL/')) {
      final bill = _boxBill.query(EntityBill_.billNo.equals(sanitizedBillNo, caseSensitive: false)).build().findFirst();
      if (bill != null) {
        searchController.clear();
        rxSearchQuery.value = '';
        Get.dialog(
          DialogBillDetail(bill: bill),
          barrierDismissible: true,
        );
        return;
      }
    }

    // 1. Exact match check on item barcode or SKU
    final exactQuery = _boxItem
        .query(EntityItem_.barcode.equals(query).or(EntityItem_.sku.equals(query)))
        .build();
    final exactMatch = exactQuery.findFirst();
    exactQuery.close();

    if (exactMatch != null) {
      final batches = getAvailableBatches(exactMatch);
      if (batches.length > 1) {
        // Multiple batches available: prompt user to select, DO NOT add direct
        searchController.clear();
        rxSearchQuery.value = '';
        Get.dialog(
          DialogSelectBatch(
            item: exactMatch,
            batches: batches,
            onBatchSelected: (batch) => addBatchToCart(exactMatch, batch),
          ),
          barrierDismissible: true,
        );
        return;
      } else if (batches.length == 1) {
        addBatchToCart(exactMatch, batches.first);
        searchController.clear();
        rxSearchQuery.value = '';
        requestSearchFocus();
        return;
      } else {
        addToCart(exactMatch, skipBatchCheck: true);
        searchController.clear();
        rxSearchQuery.value = '';
        requestSearchFocus();
        return;
      }
    }

    // 1b. Check if scanned code matches a batch directly (by batch barcode or batchNo)
    final batchQuery = _boxBatch
        .query(
          (EntityItemBatch_.barcode.equals(query).or(EntityItemBatch_.batchNo.equals(query)))
              .and(EntityItemBatch_.quantity.greaterThan(0)),
        )
        .build();
    final matchingBatches = batchQuery.find();
    batchQuery.close();

    if (matchingBatches.isNotEmpty) {
      final firstBatch = matchingBatches.first;
      if (firstBatch.itemId != null && firstBatch.itemId! > 0) {
        final parentItem = _boxItem.get(firstBatch.itemId!);
        if (parentItem != null) {
          final allBatches = getAvailableBatches(parentItem);
          if (allBatches.length > 1) {
            // Multiple batches exist for this item: give user option to select batch
            searchController.clear();
            rxSearchQuery.value = '';
            Get.dialog(
              DialogSelectBatch(
                item: parentItem,
                batches: allBatches,
                onBatchSelected: (batch) => addBatchToCart(parentItem, batch),
              ),
              barrierDismissible: true,
            );
            return;
          } else if (allBatches.length == 1) {
            addBatchToCart(parentItem, allBatches.first);
            searchController.clear();
            rxSearchQuery.value = '';
            requestSearchFocus();
            return;
          } else {
            addBatchToCart(parentItem, firstBatch);
            searchController.clear();
            rxSearchQuery.value = '';
            requestSearchFocus();
            return;
          }
        }
      }
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
          requestSearchFocus();
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
          requestSearchFocus();
          SnackbarUtil.showSuccess('Added ${scaleItem.name} (₹$price)');
          return;
        }
      }
    }

    // 3. Fallback search: pick matching item
    final options = searchOptions(query);
    if (options.isNotEmpty) {
      final first = options.first;
      final targetItem = first.item;
      final allBatches = getAvailableBatches(targetItem);
      if (allBatches.length > 1) {
        searchController.clear();
        rxSearchQuery.value = '';
        Get.dialog(
          DialogSelectBatch(
            item: targetItem,
            batches: allBatches,
            onBatchSelected: (batch) => addBatchToCart(targetItem, batch),
          ),
          barrierDismissible: true,
        );
      } else if (allBatches.length == 1) {
        addBatchToCart(targetItem, allBatches.first);
        searchController.clear();
        rxSearchQuery.value = '';
        requestSearchFocus();
      } else if (first.hasBatch) {
        addBatchToCart(first.item, first.batch!);
        searchController.clear();
        rxSearchQuery.value = '';
        requestSearchFocus();
      } else {
        addToCart(first.item, skipBatchCheck: true);
        searchController.clear();
        rxSearchQuery.value = '';
        requestSearchFocus();
      }
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

  void addToCart(EntityItem item, {bool skipBatchCheck = false}) {
    // ⚡ Always fetch fresh item details from database to ensure updated tax, price, and stock
    final freshItem = (item.id != null && item.id! > 0 ? _boxItem.get(item.id!) : null) ?? item;

    if (!skipBatchCheck) {
      final batches = getAvailableBatches(freshItem);
      if (batches.length > 1) {
        // Multiple batches available: give user option for selecting batch, do NOT add direct
        Get.dialog(
          DialogSelectBatch(
            item: freshItem,
            batches: batches,
            onBatchSelected: (batch) => addBatchToCart(freshItem, batch),
          ),
          barrierDismissible: true,
        );
        return;
      } else if (batches.length == 1) {
        // Exactly 1 batch available: add it directly
        addBatchToCart(freshItem, batches.first);
        return;
      }
    }

    final availableStock = freshItem.totalQty ?? 0;
    if (availableStock < 1) {
      SnackbarUtil.showError("${freshItem.name} is out of stock!");
      return;
    }

    // Deduct stock from item immediately
    freshItem.totalQty = availableStock - 1;
    _boxItem.put(freshItem);

    final session = activeSession;
    final index = session.rxCartItems.indexWhere(
      (element) => element.item.target?.id == freshItem.id && element.batchNo == null,
    );

    if (index >= 0) {
      final existing = session.rxCartItems[index];
      final currentCartQty = existing.qty ?? 0;
      existing.qty = currentCartQty + 1;
      existing.price = freshItem.sellingPrice;
      existing.mrp = freshItem.sellingPrice;
      existing.taxRate = freshItem.taxRate;
      existing.hsnCode = freshItem.hsnCode;
      existing.total = (existing.qty! * (existing.price ?? freshItem.sellingPrice ?? 0));
      existing.item.target = freshItem;
      session.rxCartItems[index] = existing;
    } else {
      final billItem = EntityBillItem(
        itemName: freshItem.name,
        itemBarcode: freshItem.barcode,
        hsnCode: freshItem.hsnCode,
        unit: freshItem.unit,
        price: freshItem.sellingPrice,
        mrp: freshItem.sellingPrice,
        qty: 1,
        taxRate: freshItem.taxRate,
        tax: 0,
        discount: 0,
        total: freshItem.sellingPrice,
      );
      billItem.item.target = freshItem;
      session.rxCartItems.add(billItem);
    }
    
    loadItems();
    calculateTotals();

    // Auto-focus back to search
    searchController.clear();
    rxSearchQuery.value = '';
    requestSearchFocus();
  }

  void addBatchToCart(EntityItem item, EntityItemBatch batch) {
    // ⚡ Always fetch fresh item & batch from database so updated price, tax and stock are used
    final freshItem = (item.id != null && item.id! > 0 ? _boxItem.get(item.id!) : null) ?? item;
    final freshBatch = (batch.id != null && batch.id! > 0 ? _boxBatch.get(batch.id!) : null) ?? batch;

    final availableStock = freshBatch.quantity ?? 0;
    if (availableStock < 1) {
      SnackbarUtil.showError("Batch ${freshBatch.batchNo} is out of stock! Available: $availableStock");
      return;
    }

    // 1. Minus stock in THAT batch only
    freshBatch.quantity = availableStock - 1;
    _boxBatch.put(freshBatch);

    // 2. Minus stock in the item total quantity
    freshItem.totalQty = ((freshItem.totalQty ?? 0) - 1).clamp(0, 99999999);
    _boxItem.put(freshItem);

    final session = activeSession;
    final effectivePrice = freshBatch.salePrice ?? freshItem.sellingPrice ?? 0.0;
    final effectiveMrp = freshBatch.mrp ?? freshItem.sellingPrice ?? effectivePrice;

    final index = session.rxCartItems.indexWhere(
      (element) => element.item.target?.id == freshItem.id && element.batchNo == freshBatch.batchNo,
    );

    if (index >= 0) {
      final existing = session.rxCartItems[index];
      final currentCartQty = existing.qty ?? 0;
      existing.qty = currentCartQty + 1;
      existing.price = effectivePrice;
      existing.mrp = effectiveMrp;
      existing.taxRate = freshItem.taxRate;
      existing.hsnCode = freshItem.hsnCode;
      existing.total = (existing.qty! * (existing.price ?? effectivePrice));
      existing.item.target = freshItem;
      session.rxCartItems[index] = existing;
    } else {
      final displayName = freshBatch.batchNo != null && freshBatch.batchNo!.isNotEmpty
          ? '${freshItem.name} [B: ${freshBatch.batchNo}]'
          : (freshItem.name ?? '');

      final billItem = EntityBillItem(
        itemName: displayName,
        itemBarcode: freshItem.barcode,
        hsnCode: freshItem.hsnCode,
        unit: freshItem.unit,
        price: effectivePrice,
        mrp: effectiveMrp,
        batchNo: freshBatch.batchNo,
        batchId: freshBatch.id,
        qty: 1,
        taxRate: freshItem.taxRate,
        tax: 0,
        discount: freshBatch.discount ?? 0,
        total: effectivePrice,
      );
      billItem.item.target = freshItem;
      session.rxCartItems.add(billItem);
    }

    loadItems();
    calculateTotals();

    searchController.clear();
    rxSearchQuery.value = '';
    requestSearchFocus();
  }

  void updateQty(int index, int delta) {
    final session = activeSession;
    if (index < 0 || index >= session.rxCartItems.length) return;
    final cartItem = session.rxCartItems[index];
    final newQty = (cartItem.qty ?? 0) + delta;

    if (delta > 0) {
      // Cashier added +: deduct from batch or item
      if (cartItem.batchId != null && cartItem.batchId! > 0) {
        final batch = _boxBatch.get(cartItem.batchId!);
        if (batch == null || (batch.quantity ?? 0) < delta) {
          final avail = batch?.quantity ?? 0;
          SnackbarUtil.showError("Insufficient batch stock! Available: $avail (Batch ${cartItem.batchNo ?? ''})");
          return;
        }
        batch.quantity = (batch.quantity ?? 0) - delta;
        _boxBatch.put(batch);

        final stockItem = cartItem.item.target;
        if (stockItem != null) {
          stockItem.totalQty = ((stockItem.totalQty ?? 0) - delta).clamp(0, 99999999);
          _boxItem.put(stockItem);
        }
      } else {
        final stockItem = cartItem.item.target;
        final availableStock = stockItem?.totalQty ?? 0;
        if (availableStock < delta) {
          SnackbarUtil.showError("Insufficient stock! Available: $availableStock");
          return;
        }
        if (stockItem != null) {
          stockItem.totalQty = availableStock - delta;
          _boxItem.put(stockItem);
        }
      }

      cartItem.qty = newQty;
      cartItem.total = newQty * (cartItem.price ?? 0);
      session.rxCartItems[index] = cartItem;
    } else if (delta < 0) {
      // Cashier decreased -: restore stock to batch or item
      final restoreQty = -delta;
      if (cartItem.batchId != null && cartItem.batchId! > 0) {
        final batch = _boxBatch.get(cartItem.batchId!);
        if (batch != null) {
          batch.quantity = (batch.quantity ?? 0) + restoreQty;
          _boxBatch.put(batch);
        }
        final stockItem = cartItem.item.target;
        if (stockItem != null) {
          stockItem.totalQty = (stockItem.totalQty ?? 0) + restoreQty;
          _boxItem.put(stockItem);
        }
      } else {
        final stockItem = cartItem.item.target;
        if (stockItem != null) {
          stockItem.totalQty = (stockItem.totalQty ?? 0) + restoreQty;
          _boxItem.put(stockItem);
        }
      }

      if (newQty <= 0) {
        session.rxCartItems.removeAt(index);
      } else {
        cartItem.qty = newQty;
        cartItem.total = newQty * (cartItem.price ?? 0);
        session.rxCartItems[index] = cartItem;
      }
    }

    loadItems();
    calculateTotals();
  }

  void removeFromCart(int index) {
    final session = activeSession;
    if (index < 0 || index >= session.rxCartItems.length) return;
    final cartItem = session.rxCartItems[index];
    final restoreQty = cartItem.qty ?? 0;

    if (restoreQty > 0) {
      if (cartItem.batchId != null && cartItem.batchId! > 0) {
        final batch = _boxBatch.get(cartItem.batchId!);
        if (batch != null) {
          batch.quantity = (batch.quantity ?? 0) + restoreQty;
          _boxBatch.put(batch);
        }
        final stockItem = cartItem.item.target;
        if (stockItem != null) {
          stockItem.totalQty = (stockItem.totalQty ?? 0) + restoreQty;
          _boxItem.put(stockItem);
        }
      } else {
        final stockItem = cartItem.item.target;
        if (stockItem != null) {
          stockItem.totalQty = (stockItem.totalQty ?? 0) + restoreQty;
          _boxItem.put(stockItem);
        }
      }
    }

    session.rxCartItems.removeAt(index);
    loadItems();
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
    double inclusiveTaxTotal = 0;
    double exclusiveTaxTotal = 0;

    for (var item in session.rxCartItems) {
      // ⚡ Dynamically sync target item from database so changes in tax/price immediately reflect on cart
      int? targetId;
      try {
        targetId = item.item.target?.id;
      } catch (_) {}

      if (targetId != null && targetId > 0) {
        final freshTarget = _boxItem.get(targetId);
        if (freshTarget != null) {
          item.item.target = freshTarget;
          item.taxRate = freshTarget.taxRate;
          item.hsnCode = freshTarget.hsnCode;
          if (item.batchId == null || item.batchId == 0) {
            item.itemName = freshTarget.name;
            item.price = freshTarget.sellingPrice;
            item.mrp = freshTarget.sellingPrice;
          }
        }
      }

      double itemPrice = item.price ?? 0;
      double itemQty = (item.qty ?? 0).toDouble();
      double itemDiscount = item.discount ?? 0;
      double lineGross = (itemPrice * itemQty) - itemDiscount;
      item.total = lineGross;
      subTotal += lineGross;

      final rate = item.taxRate ?? item.item.target?.taxRate ?? 0;
      final isInclusive = (item.item.target?.taxType ?? '').toLowerCase().trim() == 'inclusive';

      if (rate > 0) {
        if (isInclusive) {
          // Inclusive: Tax is already added inside the item price
          final taxVal = lineGross * (rate / (100.0 + rate));
          item.tax = double.parse(taxVal.toStringAsFixed(2));
          inclusiveTaxTotal += item.tax!;
        } else {
          // Exclusive: Tax is added on top of the item price
          final taxVal = lineGross * (rate / 100.0);
          item.tax = double.parse(taxVal.toStringAsFixed(2));
          exclusiveTaxTotal += item.tax!;
        }
      } else {
        item.tax = 0.0;
      }
    }

    session.rxSubTotal.value = subTotal;
    session.rxInclusiveTaxAmount.value = double.parse(inclusiveTaxTotal.toStringAsFixed(2));
    session.rxExclusiveTaxAmount.value = double.parse(exclusiveTaxTotal.toStringAsFixed(2));
    session.rxTaxAmount.value = double.parse((inclusiveTaxTotal + exclusiveTaxTotal).toStringAsFixed(2));

    // Notice: subTotal already contains inclusive tax. Exclusive tax is added on top.
    double rawGrand = subTotal + session.rxExclusiveTaxAmount.value - session.rxDiscountAmount.value;
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

  void clearCart({bool restoreStock = true}) {
    final session = activeSession;
    if (restoreStock && session.rxCartItems.isNotEmpty) {
      for (final cartItem in session.rxCartItems) {
        final qty = cartItem.qty ?? 0;
        if (qty > 0) {
          if (cartItem.batchId != null && cartItem.batchId! > 0) {
            final batch = _boxBatch.get(cartItem.batchId!);
            if (batch != null) {
              batch.quantity = (batch.quantity ?? 0) + qty;
              _boxBatch.put(batch);
            }
          }
          final stockItem = cartItem.item.target;
          if (stockItem != null) {
            stockItem.totalQty = (stockItem.totalQty ?? 0) + qty;
            _boxItem.put(stockItem);
          }
        }
      }
      loadItems();
    }

    session.rxCartItems.clear();
    session.rxDiscountAmount.value = 0;
    session.rxTaxRate.value = 0;
    session.rxTaxAmount.value = 0;
    session.rxInclusiveTaxAmount.value = 0;
    session.rxExclusiveTaxAmount.value = 0;
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
    _saveParkedBills();
    clearCart(restoreStock: false); // Hold items in parked bill without restoring yet
    SnackbarUtil.showSuccess("Bill #$ticketNo parked. Ready for next customer!");
  }

  void recallParkedBill(int index) {
    if (index < 0 || index >= rxParkedBills.length) return;
    final parked = rxParkedBills.removeAt(index);
    _saveParkedBills();
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
    final parked = rxParkedBills[index];
    for (final cartItem in parked.items) {
      final qty = cartItem.qty ?? 0;
      if (qty > 0) {
        if (cartItem.batchId != null && cartItem.batchId! > 0) {
          final batch = _boxBatch.get(cartItem.batchId!);
          if (batch != null) {
            batch.quantity = (batch.quantity ?? 0) + qty;
            _boxBatch.put(batch);
          }
        }
        final stockItem = cartItem.item.target;
        if (stockItem != null) {
          stockItem.totalQty = (stockItem.totalQty ?? 0) + qty;
          _boxItem.put(stockItem);
        }
      }
    }
    loadItems();
    final ticket = parked.ticketId;
    rxParkedBills.removeAt(index);
    _saveParkedBills();
    SnackbarUtil.showSuccess("Parked bill #$ticket discarded.");
  }

  void _saveParkedBills() {
    try {
      if (Get.isRegistered<ServiceStorage>()) {
        final storage = Get.find<ServiceStorage>();
        final jsonList = rxParkedBills.map((b) => b.toJson()).toList();
        storage.writeString('pos_held_parked_bills', jsonEncode(jsonList));
      }
    } catch (_) {}
  }

  void _loadParkedBills() {
    try {
      if (Get.isRegistered<ServiceStorage>()) {
        final storage = Get.find<ServiceStorage>();
        final raw = storage.readString('pos_held_parked_bills');
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List<dynamic>;
          final list = decoded
              .map((e) => ModelParkedBill.fromJson(e as Map<String, dynamic>))
              .toList();
          rxParkedBills.assignAll(list);
        }
      }
    } catch (_) {}
  }

  void openSplitBill() {
    final session = activeSession;
    if (session.rxCartItems.isEmpty) {
      SnackbarUtil.showError("Cart is empty");
      return;
    }
    Get.to(() => const ActivitySplitBill());
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
      SnackbarUtil.showSuccess("Cash Drawer kick signal sent (Delete)");
    } catch (_) {}
  }

  void handleShortcut(LogicalKeyboardKey key) {
    final session = activeSession;
    if (key == LogicalKeyboardKey.pageUp) {
      navigateCartItem(-1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      navigateCartItem(1);
    } else if (key == LogicalKeyboardKey.arrowUp && searchController.text.isEmpty && !searchFocusNode.hasFocus) {
      navigateCartItem(-1);
    } else if (key == LogicalKeyboardKey.arrowDown && searchController.text.isEmpty && !searchFocusNode.hasFocus) {
      navigateCartItem(1);
    } else if (key == LogicalKeyboardKey.f1) {
      requestSearchFocus();
    } else if (key == LogicalKeyboardKey.f2) {
      addNewTab();
    } else if (key == LogicalKeyboardKey.f8) {
      parkCurrentBill();
    } else if (key == LogicalKeyboardKey.f9) {
      quickCashSettle();
    } else if (key == LogicalKeyboardKey.f10) {
      settleBill();
    } else if (key == LogicalKeyboardKey.f3) {
      if (session.rxSelectedCartIndex.value != -1) {
        _showChangeQtyDialog(session.rxSelectedCartIndex.value);
      } else if (session.rxCartItems.isNotEmpty) {
        _showChangeQtyDialog(session.rxCartItems.length - 1);
      }
    } else if (key == LogicalKeyboardKey.f7) {
      if (session.rxSelectedCartIndex.value != -1) {
        _showItemDiscountDialog(session.rxSelectedCartIndex.value);
      } else if (session.rxCartItems.isNotEmpty) {
        _showItemDiscountDialog(session.rxCartItems.length - 1);
      }
    } else if (key == LogicalKeyboardKey.delete) {
      if (session.rxSelectedCartIndex.value != -1) {
        removeFromCart(session.rxSelectedCartIndex.value);
        session.rxSelectedCartIndex.value = -1;
      }
    } else if (key == LogicalKeyboardKey.f4) {
      _showCustomerSelectDialog();
    } else if (key == LogicalKeyboardKey.f5) {
       if (Get.context != null) {
        DialogParkedBills.show(Get.context!, this);
      }
    } else if (key == LogicalKeyboardKey.f7) {
      _showBillDiscountDialog();
    } else if (key == LogicalKeyboardKey.f11) {
      _showRemarksDialog();
    } else if (key == LogicalKeyboardKey.keyP && HardwareKeyboard.instance.isControlPressed) {
      settleBill();
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
    )).then((_) => searchCtrl.dispose());
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
               requestSearchFocus();
            },
         ),
         actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () {
               Get.back();
               int? q = int.tryParse(ctrl.text);
               if (q != null) setQty(index, q);
               requestSearchFocus();
            }, child: Text('save'.tr)),
         ],
      )).then((_) => ctrl.dispose());
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
               requestSearchFocus();
            },
         ),
         actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () {
               Get.back();
               double? d = double.tryParse(ctrl.text);
               if (d != null) setItemDiscount(index, d);
               requestSearchFocus();
            }, child: Text('save'.tr)),
         ],
      )).then((_) => ctrl.dispose());
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
               requestSearchFocus();
            },
         ),
         actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () {
               Get.back();
               double? d = double.tryParse(ctrl.text);
               if (d != null) setBillDiscount(d);
               requestSearchFocus();
            }, child: Text('save'.tr)),
         ],
      )).then((_) => ctrl.dispose());
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
               requestSearchFocus();
            },
         ),
         actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () {
               Get.back();
               session.rxRemark.value = ctrl.text;
               requestSearchFocus();
            }, child: Text('save'.tr)),
         ],
      )).then((_) => ctrl.dispose());
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
    final stockTxnsToSave = <EntityStockTransaction>[];

    for (var cartItem in session.rxCartItems) {
      int? targetId;
      try {
        targetId = cartItem.item.target?.id;
      } catch (_) {}
      final freshItem = (targetId != null && targetId > 0) ? _boxItem.get(targetId) : cartItem.item.target;
      final finalTaxRate = freshItem?.taxRate ?? cartItem.taxRate;
      final finalHsn = freshItem?.hsnCode ?? cartItem.hsnCode;

      final billItem = EntityBillItem(
        itemName: cartItem.itemName,
        itemBarcode: cartItem.itemBarcode,
        hsnCode: finalHsn,
        unit: cartItem.unit,
        price: cartItem.price,
        mrp: cartItem.mrp,
        batchNo: cartItem.batchNo,
        batchId: cartItem.batchId,
        qty: cartItem.qty,
        taxRate: finalTaxRate,
        tax: cartItem.tax,
        discount: cartItem.discount,
        total: cartItem.total,
      );
      billItem.item.target = freshItem ?? cartItem.item.target;
      billItemsToSave.add(billItem);

      // Record stock transaction for sale audit
      final stockItem = cartItem.item.target;
      if (stockItem != null) {
        final soldQty = cartItem.qty ?? 0;
        stockTxnsToSave.add(EntityStockTransaction(
          itemId: stockItem.id ?? 0,
          type: StockTxnType.sell.index,
          quantity: -soldQty,
          referenceType: 'sell',
          referenceId: stockItem.name ?? '',
          remarks: 'Sold via POS${cartItem.batchNo != null ? ' (Batch ${cartItem.batchNo})' : ''}',
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

      if (stockTxnsToSave.isNotEmpty) {
        _boxStockTxn.putMany(stockTxnsToSave);
      }

      // If any batch was sold and reached 0 stock, remove it from the database permanently
      for (var bi in billItemsToSave) {
        if (bi.batchId != null && bi.batchId! > 0) {
          final b = _boxBatch.get(bi.batchId!);
          if (b != null && (b.quantity ?? 0) <= 0 && b.id != null) {
            _boxBatch.remove(b.id!);
          }
        } else if (bi.batchNo != null && bi.batchNo!.isNotEmpty && bi.item.target != null) {
          final q = _boxBatch
              .query(EntityItemBatch_.itemId
                  .equals(bi.item.target!.id ?? 0)
                  .and(EntityItemBatch_.batchNo.equals(bi.batchNo!)))
              .build();
          final b = q.findFirst();
          q.close();
          if (b != null && (b.quantity ?? 0) <= 0 && b.id != null) {
            _boxBatch.remove(b.id!);
          }
        }
      }
    });

    clearCart(restoreStock: false);
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

    // NOTE: When user taps "Save & Print", do NOT auto print directly here.
    // As per user specification, we open the exact bill preview dialog (DialogBillDetail).
    // The user prints on-demand by tapping "Print" inside the dialog without a printer prompt!

    if (settings.rxVoiceAnnouncement.value) {
      ServiceVoice.announcePayment(
        amount: savedBill.grandTotal ?? 0.0,
        paymentMode: savedBill.paymentMode ?? 'Cash',
        storeName: settings.rxStoreName.value,
      );
    }

    Get.dialog(DialogBillDetail(bill: savedBill), barrierDismissible: false);
  }

  Future<void> autoPrintThermalReceipt(EntityBill bill, ControllerHomeSettings settings) async {
    try {
      final paperSize = settings.rxThermalPaperSize.value.isNotEmpty
          ? settings.rxThermalPaperSize.value
          : '80mm';
      final pdfBytes = await ServiceBillPdf.generateBytes(bill, settings, paperSize: paperSize);

      final printers = await Printing.listPrinters();
      if (printers.isEmpty) return;

      final printerName = settings.rxDefaultThermalPrinter.value.trim();
      Printer? target;
      if (printerName.isNotEmpty) {
        target = printers.firstWhereOrNull(
          (p) => p.name.toLowerCase() == printerName.toLowerCase(),
        );
      }
      target ??= printers.firstWhereOrNull((p) => p.isDefault) ?? printers.first;

      await Printing.directPrintPdf(
        printer: target,
        onLayout: (_) => pdfBytes,
        name: 'Bill_${bill.billNo}',
      );
    } catch (e) {
      debugPrint('Auto thermal print error: $e');
    }
  }

  void deductFromBatches(int itemId, int qty, {String? batchNo, int? batchId}) {
    if (itemId <= 0 || qty <= 0) return;

    // 1. If specific batchId is provided, deduct directly from that batch
    if (batchId != null && batchId > 0) {
      final batch = _boxBatch.get(batchId);
      if (batch != null) {
        final currentQty = batch.quantity ?? 0;
        final newQty = (currentQty - qty).clamp(0, 99999999);
        if (newQty <= 0) {
          if (batch.id != null) _boxBatch.remove(batch.id!);
        } else {
          batch.quantity = newQty;
          _boxBatch.put(batch);
        }
        return;
      }
    }

    // 2. If batchNo is provided, find that batch for the item
    if (batchNo != null && batchNo.isNotEmpty) {
      final query = _boxBatch
          .query(EntityItemBatch_.itemId.equals(itemId).and(EntityItemBatch_.batchNo.equals(batchNo)))
          .build();
      final batch = query.findFirst();
      query.close();
      if (batch != null) {
        final currentQty = batch.quantity ?? 0;
        final newQty = (currentQty - qty).clamp(0, 99999999);
        if (newQty <= 0) {
          if (batch.id != null) _boxBatch.remove(batch.id!);
        } else {
          batch.quantity = newQty;
          _boxBatch.put(batch);
        }
        return;
      }
    }

    // 3. Fallback: FEFO (First Expiring First Out)
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
      if (batchQty <= 0) {
        if (batch.id != null) _boxBatch.remove(batch.id!);
        continue;
      }

      if (batchQty <= remaining) {
        remaining -= batchQty;
        if (batch.id != null) _boxBatch.remove(batch.id!);
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
    requestSearchFocus();
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

  void resetSearch() {
    if (searchController.text.isNotEmpty || rxSearchQuery.value.isNotEmpty) {
      searchController.clear();
      rxSearchQuery.value = '';
      loadItems();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    searchCustomerController.dispose();
    searchFocusNode.dispose();
    cartScrollController.dispose();
    for (var session in rxBillTabs) {
      for (final cartItem in session.rxCartItems) {
        final qty = cartItem.qty ?? 0;
        if (qty > 0) {
          if (cartItem.batchId != null && cartItem.batchId! > 0) {
            final batch = _boxBatch.get(cartItem.batchId!);
            if (batch != null) {
              batch.quantity = (batch.quantity ?? 0) + qty;
              _boxBatch.put(batch);
            }
          }
          final stockItem = cartItem.item.target;
          if (stockItem != null) {
            stockItem.totalQty = (stockItem.totalQty ?? 0) + qty;
            _boxItem.put(stockItem);
          }
        }
      }
      session.dispose();
    }
    super.onClose();
  }
}
