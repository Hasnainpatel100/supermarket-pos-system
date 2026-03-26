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
    final all = _service.getAll();
    _computeTotals(all);
    _applyFilter();
  }

  void _computeTotals(List<EntityFinanceTransaction> all) {
    totalExpense.value = all
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
    totalBorrow.value = all
        .where((t) => t.type == 'borrow')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
    totalLend.value = all
        .where((t) => t.type == 'lend')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
  }

  void _applyFilter() {
    List<EntityFinanceTransaction> list;

    if (rxDateRangeActive.value &&
        rxFromDate.value != null &&
        rxToDate.value != null) {
      final from = DateFormat('yyyy-MM-dd').format(rxFromDate.value!);
      final to = DateFormat('yyyy-MM-dd').format(rxToDate.value!);
      if (rxFilter.value == 'all') {
        list = _service.getByDateRange(from, to);
      } else {
        list = _service.getByTypeAndDateRange(rxFilter.value, from, to);
      }
    } else {
      if (rxFilter.value == 'all') {
        list = _service.getAll();
      } else {
        list = _service.getByType(rxFilter.value);
      }
    }

    totalCount.value = list.length;
    final paged = list.skip(currentPage.value * _pageSize).take(_pageSize).toList();
    rxList.assignAll(paged);
  }

  /// Pick a date range and re-apply filter
  Future<void> pickDateRange(context) async {
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
      _applyFilter();
    }
  }

  /// Clear the date range filter
  void clearDateRange() {
    rxFromDate.value = null;
    rxToDate.value = null;
    rxDateRangeActive.value = false;
    currentPage.value = 0;
    _applyFilter();
  }

  Future<void> delete(int id) async {
    if (id == 0) return;
    _service.delete(id);
    loadData();
  }
}
