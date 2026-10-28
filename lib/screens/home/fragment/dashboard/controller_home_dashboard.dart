import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../model/entity_supplier.dart';
import '../../../../objectbox.g.dart';
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
  late final Box<EntitySupplier> _boxSupplier;

  // ── Dreams POS Top 4 KPI Metrics ──
  final RxDouble totalPurchaseDue = 0.0.obs;
  final RxDouble totalSalesDue = 0.0.obs;
  final RxDouble totalSaleAmount = 0.0.obs;
  final RxDouble totalExpenseAmount = 0.0.obs;

  // ── Dreams POS Row 2 Solid Stat Counts ──
  final RxInt totalSuppliers = 0.obs;
  final RxInt totalPurchaseInvoices = 0.obs;
  final RxInt totalSalesInvoices = 0.obs;

  // ── Purchase & Sales Comparison Bar Chart (Monthly) ──
  final RxList<double> monthlySales = <double>[].obs;
  final RxList<double> monthlyPurchases = <double>[].obs;
  final RxList<String> monthLabels = <String>[].obs;

  // ── Recently Added Products & Low Stock / Expired ──
  final RxList<EntityItem> recentlyAddedProducts = <EntityItem>[].obs;
  final RxList<EntityItem> inventoryAlertProducts = <EntityItem>[].obs;

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
    _boxSupplier = ob.box<EntitySupplier>();
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
    totalSuppliers.value = _boxSupplier.count();
    totalPurchaseInvoices.value = _boxPurchase.count();
    totalSalesInvoices.value = _boxBill.count();

    // ── Aggregated KPI Values for Dreams POS Top Cards ──
    final allBills = _boxBill.getAll();
    totalSaleAmount.value = allBills.fold(0.0, (s, b) => s + (b.grandTotal ?? 0));
    totalSalesDue.value = allBills.fold(0.0, (s, b) => s + (b.dueAmount ?? 0));

    final allPurchases = _boxPurchase.getAll();
    double pDue = allPurchases.fold(0.0, (s, p) => s + (p.amountDue ?? 0));
    if (pDue == 0) {
      pDue = _boxSupplier.getAll().fold(0.0, (s, sup) => s + (sup.totalOutstanding ?? 0));
    }
    totalPurchaseDue.value = pDue;
    totalExpenseAmount.value = allPurchases.fold(0.0, (s, p) => s + (p.amountPaid ?? (p.totalAmount ?? 0)));

    // ── Monthly Purchase & Sales Comparison (Last 8 Months) ──
    final mLabels = <String>[];
    final mSales = <double>[];
    final mPurchases = <double>[];
    final monthFmt = DateFormat('MMM');
    for (int i = 7; i >= 0; i--) {
      final mDate = DateTime(now.year, now.month - i, 1);
      final nextMDate = DateTime(mDate.year, mDate.month + 1, 1);
      final mStartMs = mDate.millisecondsSinceEpoch;
      final mEndMs = nextMDate.millisecondsSinceEpoch;
      mLabels.add(monthFmt.format(mDate));

      final monthBills = allBills.where((b) {
        if (b.billDate == null) return false;
        try {
          final parsed = dateFmt.parse(b.billDate!);
          return parsed.isAfter(mDate.subtract(const Duration(seconds: 1))) &&
                 parsed.isBefore(nextMDate);
        } catch (_) {
          return false;
        }
      });
      mSales.add(monthBills.fold(0.0, (s, b) => s + (b.grandTotal ?? 0)));

      final monthPO = allPurchases.where((p) {
        final pDate = p.purchaseDateUtcMs ?? 0;
        return pDate >= mStartMs && pDate < mEndMs;
      });
      mPurchases.add(monthPO.fold(0.0, (s, p) => s + (p.totalAmount ?? 0)));
    }
    monthLabels.value = mLabels;
    monthlySales.value = mSales;
    monthlyPurchases.value = mPurchases;

    // ── Recently Added Products ──
    final recentItemsQuery = _boxItem.query().order(EntityItem_.id, flags: Order.descending).build();
    recentlyAddedProducts.value = recentItemsQuery.find().take(6).toList();
    recentItemsQuery.close();

    // ── Inventory Alerts: Low Stock or Expiring Materials ──
    final alertQuery = _boxItem.query(EntityItem_.isActive.equals(true)).order(EntityItem_.totalQty).build();
    inventoryAlertProducts.value = alertQuery.find().take(6).toList();
    alertQuery.close();

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
  }

  /// Returns the Monday of the week containing [date]
  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday; // Mon=1, Sun=7
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }
}
