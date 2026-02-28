import 'package:get/get.dart' hide Condition;
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

  // Pagination
  static const int _pageSize = 20;
  final RxInt _currentOffset = 0.obs;
  final RxBool rxHasMore = true.obs;
  final RxBool rxIsLoadingMore = false.obs;

  /// All matching date strings for the current filter
  List<String> _matchingDateStrings = [];

  // Search
  final RxString rxSearchQuery = ''.obs;
  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    _setDateFilter(DateFilterType.today);

    // Debounce search
    _searchWorker = debounce(
      rxSearchQuery,
      (_) => loadData(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  void setSearchQuery(String query) {
    rxSearchQuery.value = query;
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
        rxEndDate.value = DateTime(now.year, now.month, now.day);
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
        );
        break;
      case DateFilterType.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        rxStartDate.value = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );
        rxEndDate.value = DateTime(now.year, now.month, now.day);
        break;
      case DateFilterType.thisMonth:
        rxStartDate.value = DateTime(now.year, now.month, 1);
        rxEndDate.value = DateTime(now.year, now.month, now.day);
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
    rxEndDate.value = DateTime(end.year, end.month, end.day);
    loadData();
  }

  /// Build a list of all date strings (d/MM/yyyy) from start to end inclusive
  List<String> _buildDateStrings(DateTime start, DateTime end) {
    final fmt = DateFormat('d/MM/yyyy');
    final dates = <String>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDay)) {
      dates.add(fmt.format(current));
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  /// Reset pagination and load first page
  void loadData() {
    _currentOffset.value = 0;
    rxHasMore.value = true;
    rxListBill.clear();

    _matchingDateStrings = _buildDateStrings(
      rxStartDate.value,
      rxEndDate.value,
    );

    _loadPage();
  }

  /// Load the next page of bills
  void loadMore() {
    if (!rxHasMore.value || rxIsLoadingMore.value) return;
    _loadPage();
  }

  void _loadPage() {
    rxIsLoadingMore.value = true;

    // Query bills that match any of the date strings, newest first
    Condition<EntityBill>? dateCondition;
    if (_matchingDateStrings.length == 1) {
      dateCondition = EntityBill_.billDate.equals(_matchingDateStrings.first);
    } else if (_matchingDateStrings.length > 1) {
      dateCondition = EntityBill_.billDate.oneOf(_matchingDateStrings);
    }

    Condition<EntityBill>? searchCondition;
    final queryText = rxSearchQuery.value.trim().toLowerCase();
    if (queryText.isNotEmpty) {
      searchCondition = EntityBill_.customerName
          .contains(queryText, caseSensitive: false)
          .or(EntityBill_.customerPhone.contains(queryText, caseSensitive: false))
          .or(EntityBill_.billNo.contains(queryText, caseSensitive: false));
    }

    Condition<EntityBill>? finalCondition;
    if (dateCondition != null && searchCondition != null) {
      finalCondition = dateCondition.and(searchCondition);
    } else if (dateCondition != null) {
      finalCondition = dateCondition;
    } else if (searchCondition != null) {
      finalCondition = searchCondition;
    }

    final queryBuilder = finalCondition != null
        ? _boxBill.query(finalCondition)
        : _boxBill.query();
    queryBuilder.order(EntityBill_.id, flags: Order.descending);
    final query = queryBuilder.build();

    // Count total for stats (only on first page)
    if (_currentOffset.value == 0) {
      final allBills = query.find();
      double totalSales = 0;
      for (var bill in allBills) {
        totalSales += (bill.grandTotal ?? 0);
      }
      filteredSales.value = totalSales;
      filteredOrders.value = allBills.length;
      averageBillValue.value = allBills.isNotEmpty
          ? totalSales / allBills.length
          : 0;
    }

    // Paginate
    query.offset = _currentOffset.value;
    query.limit = _pageSize;
    final page = query.find();
    query.close();

    rxListBill.addAll(page);
    _currentOffset.value += page.length;
    rxHasMore.value = page.length >= _pageSize;
    rxIsLoadingMore.value = false;
  }

  String formatDateRange() {
    final fmt = DateFormat('dd MMM yyyy');
    final start = fmt.format(rxStartDate.value);
    final end = fmt.format(rxEndDate.value);
    if (start == end) return start;
    return '$start  →  $end';
  }
}
