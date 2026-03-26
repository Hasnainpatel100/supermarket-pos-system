import 'package:flutter/material.dart';
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

  // ── Pagination ──
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      _loadPage();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      _loadPage();
    }
  }

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
    currentPage.value = 0;

    _matchingDateStrings = _buildDateStrings(
      rxStartDate.value,
      rxEndDate.value,
    );

    _loadPage();
  }

  void _loadPage() {
    rxListBill.clear();

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

    // Count total for stats and pagination
    final allBillsCount = query.count();
    totalCount.value = allBillsCount;

    if (currentPage.value == 0) {
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
    query.offset = currentPage.value * _pageSize;
    query.limit = _pageSize;
    final page = query.find();
    query.close();

    rxListBill.assignAll(page);
  }

  String formatDateRange() {
    final fmt = DateFormat('dd MMM yyyy');
    final start = fmt.format(rxStartDate.value);
    final end = fmt.format(rxEndDate.value);
    if (start == end) return start;
    return '$start  →  $end';
  }

  void settleDuePayment(EntityBill bill) {
    if (bill.dueAmount == null || bill.dueAmount! <= 0) return;
    
    final tcAmount = TextEditingController(text: bill.dueAmount!.toStringAsFixed(2));
    final rxMode = 'CASH'.obs;
    
    Get.dialog(
      AlertDialog(
        title: const Text("Settle Due Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pending Due: \u20B9${bill.dueAmount!.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
              value: rxMode.value,
              decoration: const InputDecoration(labelText: "Payment Mode", border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('CASH')),
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'NETBANKING', child: Text('NETBANKING')),
              ],
              onChanged: (v) { if (v != null) rxMode.value = v; },
            )),
            const SizedBox(height: 12),
            TextField(
              controller: tcAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Amount Received", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final amt = double.tryParse(tcAmount.text) ?? 0.0;
              if (amt <= 0) {
                Get.snackbar("Error", "Enter valid amount");
                return;
              }
              
              if (rxMode.value == 'CASH') {
                bill.splitCash = (bill.splitCash ?? 0) + amt;
              } else {
                bill.splitOnline = (bill.splitOnline ?? 0) + amt;
              }
              
              bill.amountReceived = (bill.amountReceived ?? 0) + amt;
              bill.dueAmount = bill.dueAmount! - amt;
              
              if (bill.dueAmount! <= 0) {
                bill.dueAmount = 0;
                bill.status = "PAID";
              }
              
              _boxBill.put(bill);
              Get.back();
              Get.snackbar("Success", "Due payment settled successfully", backgroundColor: Colors.green, colorText: Colors.white);
              loadData();
            },
            child: const Text("Settle"),
          ),
        ],
      ),
    );
  }
}
