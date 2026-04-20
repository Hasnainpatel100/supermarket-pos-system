import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

class ControllerHomeDashboard extends GetxController {
  late final Box<EntityBill> _boxBill;
  late final Box<EntityBillItem> _boxBillItem;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityCustomer> _boxCustomer;
  late final Box<EntityPurchase> _boxPurchase;

  // ── Today stats ──
  final RxDouble todaySales = 0.0.obs;
  final RxInt todayOrders = 0.obs;
  final RxDouble averageBill = 0.0.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalCustomers = 0.obs;

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
    loadData();
  }

  void loadData() {
    isLoading.value = true;

    final now = DateTime.now();
    final dateFmt = DateFormat('d/MM/yyyy');
    final labelFmt = DateFormat('EEE'); // Mon, Tue …

    // ── Total counts ──
    totalItems.value = _boxItem.count();
    totalCustomers.value = _boxCustomer.count();

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

    // ── Top Selling Items from all bill items ──
    final allBillItems = _boxBillItem.getAll();
    final qtyMap = <String, int>{};
    for (final bi in allBillItems) {
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
