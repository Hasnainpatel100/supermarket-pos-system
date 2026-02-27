import 'package:get/get.dart';

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

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void setFilter(String filter) {
    rxFilter.value = filter;
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
    final filter = rxFilter.value;
    if (filter == 'all') {
      rxList.assignAll(_service.getAll());
    } else {
      rxList.assignAll(_service.getByType(filter));
    }
  }

  void delete(int id) {
    if (id == 0) return;
    _service.delete(id);
    loadData();
  }
}
