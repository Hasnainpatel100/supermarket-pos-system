import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../objectbox.g.dart';
import '../../../../core/app_type/app_type_service.dart';
import '../../../../core/app_type/enum_app_type.dart';
import '../../../../service/service_brand_context.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_storage.dart';
import '../../../../util/snackbar_util.dart';

class ControllerHomeDashboard extends GetxController {
  late final Box<EntityBill> _boxBill;
  late final Box<EntityBillItem> _boxBillItem;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityCustomer> _boxCustomer;
  late final Box<EntityPurchase> _boxPurchase;
  late final Box<EntityItemBatch> _boxBatch;

  // ── 24-Hour Warning Dismissal Keys & State ──
  static const String keyDismissPlanExpiry = 'dashboard_dismiss_plan_expiry_until';
  static const String keyDismissItemExpiry = 'dashboard_dismiss_item_expiry_until';

  final RxBool isPlanExpiryDismissed = false.obs;
  final RxBool isItemExpiryDismissed = false.obs;

  // ── Today stats ──
  final RxDouble todaySales = 0.0.obs;
  final RxInt todayOrders = 0.obs;
  final RxDouble averageBill = 0.0.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalCustomers = 0.obs;

  // ── Expiry & Stock Alerts ──
  final RxInt expiringItemCount = 0.obs;   // items with batches expiring ≤ 30 days
  final RxInt expiredItemCount = 0.obs;    // items with batches already expired
  final RxInt lowStockItemCount = 0.obs;   // items with totalQty <= 0

  // ── Greeting ──
  final RxString greetingText = ''.obs;

  // ── Line chart: this week vs last week daily sales ──
  // Index 0 = Mon, index 6 = Sun (of current week)
  final RxList<double> thisWeekSales = List.filled(7, 0.0).obs;
  final RxList<double> lastWeekSales = List.filled(7, 0.0).obs;
  final RxList<String> weekLabels = <String>[].obs;

  // ── CashFlow bar chart: last 7 days inflow(sales) vs outflow(purchase cost) ──
  final RxList<double> cashInflow = List.filled(7, 0.0).obs;
  final RxList<double> cashOutflow = List.filled(7, 0.0).obs;
  final RxList<String> cashflowLabels = <String>[].obs;

  // ── Top Selling Items (today, all-time supported) ──
  // List of {name, qty}
  final RxList<Map<String, dynamic>> topSellingItems =
      <Map<String, dynamic>>[].obs;

  // ── Weekly overview bar chart (last 7 days grand totals) ──
  final RxList<double> weeklyOverview = List.filled(7, 0.0).obs;
  final RxList<String> overviewLabels = <String>[].obs;

  // ── Payment mode breakdown ──
  final RxMap<String, double> paymentBreakdown = <String, double>{}.obs;

  final RxBool isLoading = true.obs;

  // ── Vertical-Specific KPIs (driven by AppTypeService.currentProfile) ──
  final RxInt verticalFootfallToday = 0.obs;
  final RxInt verticalPendingOrders = 0.obs;
  final RxDouble verticalDispatchTonnage = 0.0.obs;
  final RxDouble verticalKhataDue = 0.0.obs;
  final RxInt verticalActiveVehicles = 0.obs;
  final RxDouble verticalGoldGrams = 0.0.obs;
  final RxInt verticalImeiInStock = 0.obs;
  final RxDouble verticalExchangePercent = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    _boxBillItem = ob.box<EntityBillItem>();
    _boxItem = ob.box<EntityItem>();
    _boxCustomer = ob.box<EntityCustomer>();
    _boxPurchase = ob.box<EntityPurchase>();
    _boxBatch = ob.box<EntityItemBatch>();
    _updateGreeting();
    checkDismissStatus();
    loadData();
  }

  /// Checks if warnings were snoozed for 24 hours
  void checkDismissStatus() {
    if (!Get.isRegistered<ServiceStorage>()) return;
    final storage = Get.find<ServiceStorage>();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final planUntil = storage.readInt(keyDismissPlanExpiry) ?? 0;
    isPlanExpiryDismissed.value = nowMs < planUntil;

    final itemUntil = storage.readInt(keyDismissItemExpiry) ?? 0;
    isItemExpiryDismissed.value = nowMs < itemUntil;
  }

  /// Snoozes plan expiry warning banner for 24 hours
  Future<void> dismissPlanExpiryBanner() async {
    final until = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
    if (Get.isRegistered<ServiceStorage>()) {
      await Get.find<ServiceStorage>().writeInt(keyDismissPlanExpiry, until);
    }
    isPlanExpiryDismissed.value = true;
    SnackbarUtil.showSuccess('Plan expiry warning dismissed for 24 hours');
  }

  /// Snoozes item expiry warning banner for 24 hours
  Future<void> dismissItemExpiryBanner() async {
    final until = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
    if (Get.isRegistered<ServiceStorage>()) {
      await Get.find<ServiceStorage>().writeInt(keyDismissItemExpiry, until);
    }
    isItemExpiryDismissed.value = true;
    SnackbarUtil.showSuccess('Item expiry warning dismissed for 24 hours');
  }

  /// Updates the greeting based on current time (Hindi + English mix popular in India)
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = '🌅 सुप्रभात • Good Morning!';
    } else if (hour < 17) {
      greeting = '☀️ शुभ दोपहर • Good Afternoon!';
    } else if (hour < 20) {
      greeting = '🌆 शुभ संध्या • Good Evening!';
    } else {
      greeting = '🌙 शुभ रात्रि • Good Night!';
    }

    if (Get.isRegistered<ServiceBrandContext>()) {
      final branch = Get.find<ServiceBrandContext>().rxSelectedBranch.value;
      if (branch != null && branch.name.en.isNotEmpty) {
        greeting += '  |  🏪 ${branch.name.en}';
      }
    }
    greetingText.value = greeting;
  }

  void loadData() {
    isLoading.value = true;
    _updateGreeting();
    checkDismissStatus();

    final now = DateTime.now();
    final dateFmt = DateFormat('d/MM/yyyy');
    final labelFmt = DateFormat('EEE'); // Mon, Tue …

    // ── Total counts ──
    totalItems.value = _boxItem.count();
    totalCustomers.value = _boxCustomer.count();

    // ── Expiry alerts: count items whose nearest batch expires within 30 days (with stock > 0) ──
    final nowMs = now.millisecondsSinceEpoch;
    final in30daysMs = now.add(const Duration(days: 30)).millisecondsSinceEpoch;
    final expiringBatches = _boxBatch
        .query(EntityItemBatch_.expiryDateUtcMs
            .greaterOrEqual(nowMs)
            .and(EntityItemBatch_.expiryDateUtcMs.lessOrEqual(in30daysMs)))
        .build()
        .find()
        .where((b) => (b.quantity ?? 0) > 0)
        .toList();
    // Unique item IDs expiring soon
    final expiringIds = expiringBatches.map((b) => b.itemId).toSet();
    expiringItemCount.value = expiringIds.length;

    final expiredBatches = _boxBatch
        .query(EntityItemBatch_.expiryDateUtcMs.lessOrEqual(nowMs))
        .build()
        .find()
        .where((b) => (b.quantity ?? 0) > 0)
        .toList();
    final expiredIds = expiredBatches.map((b) => b.itemId).toSet();
    expiredItemCount.value = expiredIds.length;

    // ── Low stock: items with totalQty <= 0 ──
    final lowStockQuery = _boxItem
        .query(EntityItem_.totalQty.lessThan(1).and(EntityItem_.isActive.equals(true)))
        .build();
    lowStockItemCount.value = lowStockQuery.count();
    lowStockQuery.close();

    // ── Today ──
    final todayStr = dateFmt.format(now);
    final todayQuery =
        _boxBill.query(EntityBill_.billDate.equals(todayStr)).build();
    final todayBills = todayQuery.find();
    todayQuery.close();

    double tSales = 0;
    final modeMap = <String, double>{};
    for (final b in todayBills) {
      tSales += (b.grandTotal ?? 0);
      final mode = (b.paymentMode ?? 'CASH').toUpperCase();
      modeMap[mode] = (modeMap[mode] ?? 0) + (b.grandTotal ?? 0);
    }
    todaySales.value = tSales;
    todayOrders.value = todayBills.length;
    averageBill.value =
        todayBills.isNotEmpty ? tSales / todayBills.length : 0;
    paymentBreakdown.value = modeMap;

    // ── This week vs last week (Mon–Sun based on current week) ──
    final thisWeekStart = _startOfWeek(now);
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final labels = <String>[];
    final thisW = List.filled(7, 0.0);
    final lastW = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final thisDay = thisWeekStart.add(Duration(days: i));
      final lastDay = lastWeekStart.add(Duration(days: i));
      labels.add(labelFmt.format(thisDay));

      // This week
      final q1 = _boxBill
          .query(EntityBill_.billDate.equals(dateFmt.format(thisDay)))
          .build();
      final bills1 = q1.find();
      q1.close();
      thisW[i] = bills1.fold(0.0, (s, b) => s + (b.grandTotal ?? 0));

      // Last week
      final q2 = _boxBill
          .query(EntityBill_.billDate.equals(dateFmt.format(lastDay)))
          .build();
      final bills2 = q2.find();
      q2.close();
      lastW[i] = bills2.fold(0.0, (s, b) => s + (b.grandTotal ?? 0));
    }

    weekLabels.value = labels;
    thisWeekSales.value = thisW;
    lastWeekSales.value = lastW;

    // ── Cash flow: last 7 days (inflow = sales, outflow = purchase cost) ──
    final cfLabels = <String>[];
    final inflow = List.filled(7, 0.0);
    final outflow = List.filled(7, 0.0);

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      cfLabels.add(labelFmt.format(day));
      final idx = 6 - i;

      // Inflow = sales grandTotal
      final sq = _boxBill
          .query(EntityBill_.billDate.equals(dateFmt.format(day)))
          .build();
      final sBills = sq.find();
      sq.close();
      inflow[idx] = sBills.fold(0.0, (s, b) => s + (b.grandTotal ?? 0));

      // Outflow = purchases on that day (using purchaseDateUtcMs range)
      final dayStart =
          DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      final dayEnd = dayStart + 86400000;
      final pq = _boxPurchase
          .query(EntityPurchase_.purchaseDateUtcMs
              .greaterOrEqual(dayStart)
              .and(EntityPurchase_.purchaseDateUtcMs.lessOrEqual(dayEnd)))
          .build();
      final purchases = pq.find();
      pq.close();
      outflow[idx] =
          purchases.fold(0.0, (s, p) => s + (p.totalAmount ?? 0));
    }

    cashflowLabels.value = cfLabels;
    cashInflow.value = inflow;
    cashOutflow.value = outflow;

    // Reuse inflow as weekly overview
    weeklyOverview.value = List.from(inflow);
    overviewLabels.value = List.from(cfLabels);

    // ── Top Selling Items from recent bill items ──
    final biQuery = _boxBillItem
        .query()
        .order(EntityBillItem_.id, flags: Order.descending)
        .build()
      ..limit = 1000;
    final recentBillItems = biQuery.find();
    biQuery.close();

    final qtyMap = <String, int>{};
    for (final bi in recentBillItems) {
      final name = bi.itemName ?? 'Unknown';
      qtyMap[name] = (qtyMap[name] ?? 0) + (bi.qty ?? 0);
    }
    // Sort descending, take top 5
    final sorted = qtyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topSellingItems.value = sorted
        .take(5)
        .map((e) => {'name': e.key, 'qty': e.value})
        .toList();

    isLoading.value = false;
    _loadVerticalKpis();
  }

  /// Computes vertical-specific KPIs driven by AppTypeService.currentProfile.
  /// Each vertical highlights its own primary business metric.
  void _loadVerticalKpis() {
    final type = AppTypeService.to.currentType;

    switch (type) {
      case AppType.market:
        verticalFootfallToday.value = todayOrders.value;
        verticalPendingOrders.value = 0;
        verticalDispatchTonnage.value = 0.0;
        verticalKhataDue.value = 0.0;
        verticalActiveVehicles.value = 0;
        verticalGoldGrams.value = 0.0;
        verticalImeiInStock.value = 0;
        verticalExchangePercent.value = 0.0;
        break;

      case AppType.steel:
        verticalFootfallToday.value = todayOrders.value;
        verticalPendingOrders.value = _boxPurchase.count();
        verticalDispatchTonnage.value = _sumDispatchTonnageToday();
        verticalKhataDue.value = _sumCustomerKhataDue();
        verticalActiveVehicles.value = 0;
        verticalGoldGrams.value = 0.0;
        verticalImeiInStock.value = 0;
        verticalExchangePercent.value = 0.0;
        break;

      case AppType.jewellery:
        verticalFootfallToday.value = todayOrders.value;
        verticalPendingOrders.value = 0;
        verticalDispatchTonnage.value = 0.0;
        verticalKhataDue.value = _sumCustomerKhataDue();
        verticalActiveVehicles.value = 0;
        verticalGoldGrams.value = _sumGoldStockGrams();
        verticalImeiInStock.value = 0;
        verticalExchangePercent.value = 0.0;
        break;

      case AppType.electronics:
        verticalFootfallToday.value = todayOrders.value;
        verticalPendingOrders.value = 0;
        verticalDispatchTonnage.value = 0.0;
        verticalKhataDue.value = _sumCustomerKhataDue();
        verticalActiveVehicles.value = 0;
        verticalGoldGrams.value = 0.0;
        verticalImeiInStock.value = _countImeiInStock();
        verticalExchangePercent.value = 0.0;
        break;

      case AppType.apparel:
        verticalFootfallToday.value = todayOrders.value;
        verticalPendingOrders.value = 0;
        verticalDispatchTonnage.value = 0.0;
        verticalKhataDue.value = _sumCustomerKhataDue();
        verticalActiveVehicles.value = 0;
        verticalGoldGrams.value = 0.0;
        verticalImeiInStock.value = 0;
        verticalExchangePercent.value = todayOrders.value > 0
            ? (paymentBreakdown['CASH'] ?? 0.0) / todaySales.value * 100
            : 0.0;
        break;

      case AppType.optical:
      case AppType.footwear:
        verticalFootfallToday.value = todayOrders.value;
        verticalPendingOrders.value = 0;
        verticalDispatchTonnage.value = 0.0;
        verticalKhataDue.value = _sumCustomerKhataDue();
        verticalActiveVehicles.value = 0;
        verticalGoldGrams.value = 0.0;
        verticalImeiInStock.value = 0;
        verticalExchangePercent.value = 0.0;
        break;
    }
  }

  double _sumDispatchTonnageToday() {
    try {
      final q = _boxBillItem
          .query(
            EntityBillItem_.unit
                .equals('MT', caseSensitive: false)
                .or(EntityBillItem_.unit.equals('kg', caseSensitive: false)),
          )
          .build();
      final items = q.find();
      q.close();
      double total = 0.0;
      for (final bi in items) {
        final unit = (bi.unit ?? '').toLowerCase();
        final qty = (bi.qty ?? 1).toDouble();
        final lineTotal = (bi.total ?? 0.0);
        if (unit == 'mt') {
          total += lineTotal > 0 ? lineTotal : qty;
        } else if (unit == 'kg') {
          total += qty / 1000.0;
        }
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  double _sumCustomerKhataDue() {
    try {
      final q = _boxCustomer.query().build();
      final customers = q.find();
      q.close();
      double total = 0.0;
      for (final c in customers) {
        if (c.dueAmount != null && c.dueAmount! > 0) {
          total += c.dueAmount!;
        }
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  double _sumGoldStockGrams() {
    try {
      final q = _boxItem
          .query(EntityItem_.unit.equals('Gram', caseSensitive: false))
          .build();
      final items = q.find();
      q.close();
      double total = 0.0;
      for (final it in items) {
        total += (it.totalQty ?? 0).toDouble();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  int _countImeiInStock() {
    try {
      final q = _boxItem
          .query(EntityItem_.sku.notEquals(''))
          .build();
      return q.count();
    } catch (_) {
      return 0;
    }
  }

  /// Returns the Monday of the week containing [date]
  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday; // Mon=1, Sun=7
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }
}
