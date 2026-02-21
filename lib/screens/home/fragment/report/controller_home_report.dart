import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

enum DateFilterType { today, yesterday, thisWeek, thisMonth, custom }

class ControllerHomeReport extends GetxController {
  late final Box<EntityBill> _boxBill;

  final RxList<EntityBill> rxListBill = <EntityBill>[].obs;

  // Stats
  final RxDouble filteredSales = 0.0.obs;
  final RxInt filteredOrders = 0.obs;
  final RxDouble averageBillValue = 0.0.obs;

  // Date filter
  final Rx<DateFilterType> rxDateFilter = DateFilterType.today.obs;
  final Rx<DateTime> rxStartDate = DateTime.now().obs;
  final Rx<DateTime> rxEndDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    _setDateFilter(DateFilterType.today);
  }

  void setDateFilter(DateFilterType type) {
    _setDateFilter(type);
  }

  void _setDateFilter(DateFilterType type) {
    rxDateFilter.value = type;
    final now = DateTime.now();

    switch (type) {
      case DateFilterType.today:
        rxStartDate.value = DateTime(now.year, now.month, now.day);
        rxEndDate.value = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        );
        break;
      case DateFilterType.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        rxStartDate.value = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
        );
        rxEndDate.value = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
          999,
        );
        break;
      case DateFilterType.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        rxStartDate.value = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );
        rxEndDate.value = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        );
        break;
      case DateFilterType.thisMonth:
        rxStartDate.value = DateTime(now.year, now.month, 1);
        rxEndDate.value = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        );
        break;
      case DateFilterType.custom:
        // Keep existing dates for custom
        break;
    }
    loadData();
  }

  void setCustomRange(DateTime start, DateTime end) {
    rxDateFilter.value = DateFilterType.custom;
    rxStartDate.value = DateTime(start.year, start.month, start.day);
    rxEndDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    loadData();
  }

  void loadData() {
    final startMs = rxStartDate.value.toUtc().millisecondsSinceEpoch;
    final endMs = rxEndDate.value.toUtc().millisecondsSinceEpoch;

    // Query bills in date range, ordered by newest first
    final query = _boxBill
        .query(EntityBill_.createdAtUtcMs.between(startMs, endMs))
        .order(EntityBill_.createdAtUtcMs, flags: Order.descending)
        .build();
    final bills = query.find();
    query.close();

    rxListBill.assignAll(bills);

    // Calculate stats
    double totalSales = 0;
    for (var bill in bills) {
      totalSales += (bill.grandTotal ?? 0);
    }

    filteredSales.value = totalSales;
    filteredOrders.value = bills.length;
    averageBillValue.value = bills.isNotEmpty ? totalSales / bills.length : 0;
  }

  String formatDateRange() {
    final fmt = DateFormat('dd MMM yyyy');
    final start = fmt.format(rxStartDate.value);
    final end = fmt.format(rxEndDate.value);
    if (start == end) return start;
    return '$start  →  $end';
  }
}
