import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../model/entity_finance_transaction.dart';
import '../../../../service/service_finance.dart';

class ControllerHomeExpenses extends GetxController {
  final ServiceFinance _service;

  ControllerHomeExpenses(this._service);

  final RxList<EntityFinanceTransaction> rxList =
      <EntityFinanceTransaction>[].obs;
  final rxFilter = 'all'.obs;

  // Summary totals
  final totalExpense = 0.0.obs;
  final totalBorrow = 0.0.obs;
  final totalLend = 0.0.obs;

  // Date range filter
  final Rx<DateTime?> rxFromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> rxToDate = Rx<DateTime?>(null);
  final rxDateRangeActive = false.obs;

  // ── Pagination ──
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      _applyFilter();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      _applyFilter();
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void setFilter(String filter) {
    rxFilter.value = filter;
    currentPage.value = 0;
    _applyFilter();
  }

  void loadData() {
    _computeTotals();
    _applyFilter();
  }

  void _computeTotals() {
    String? from;
    String? to;
    if (rxDateRangeActive.value &&
        rxFromDate.value != null &&
        rxToDate.value != null) {
      from = DateFormat('yyyy-MM-dd').format(rxFromDate.value!);
      to = DateFormat('yyyy-MM-dd').format(rxToDate.value!);
    }

    totalExpense.value = _service.getSumByType('expense', fromDate: from, toDate: to);
    totalBorrow.value = _service.getSumByType('borrow', fromDate: from, toDate: to);
    totalLend.value = _service.getSumByType('lend', fromDate: from, toDate: to);
  }

  void _applyFilter() {
    String? from;
    String? to;
    if (rxDateRangeActive.value &&
        rxFromDate.value != null &&
        rxToDate.value != null) {
      from = DateFormat('yyyy-MM-dd').format(rxFromDate.value!);
      to = DateFormat('yyyy-MM-dd').format(rxToDate.value!);
    }

    final result = _service.getPaginated(
      type: rxFilter.value,
      fromDate: from,
      toDate: to,
      offset: currentPage.value * _pageSize,
      limit: _pageSize,
    );

    totalCount.value = result.totalCount;
    rxList.assignAll(result.items);
  }

  /// Pick a date range and re-apply filter
  Future<void> pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange:
          rxDateRangeActive.value &&
              rxFromDate.value != null &&
              rxToDate.value != null
          ? DateTimeRange(start: rxFromDate.value!, end: rxToDate.value!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
    );
    if (result != null) {
      rxFromDate.value = result.start;
      rxToDate.value = result.end;
      rxDateRangeActive.value = true;
      currentPage.value = 0;
      loadData();
    }
  }

  /// Clear the date range filter
  void clearDateRange() {
    rxFromDate.value = null;
    rxToDate.value = null;
    rxDateRangeActive.value = false;
    currentPage.value = 0;
    loadData();
  }

  Future<void> delete(int id) async {
    if (id == 0) return;
    _service.delete(id);
    loadData();
  }
}
