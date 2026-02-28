import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../model/entity_finance_transaction.dart';
import '../../service/service_finance.dart';
import '../../service/service_object_box.dart';

enum TransactionType { expense, borrow, lend }

class ControllerExpensesFrom extends GetxController {
  late final ServiceFinance _service;

  // ── Form state ──────────────────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();

  final amountController = TextEditingController();
  final personNameController = TextEditingController();
  final noteController = TextEditingController();

  // Rx observables
  final rxType = TransactionType.expense.obs;
  final rxCategory = 'Transportation'.obs;
  final rxIsDebit = true.obs;
  final rxDate = DateTime.now().obs;

  // ── Category options ─────────────────────────────────────────────────────────
  static const List<String> expenseCategories = [
    'Transportation',
    'Petrol',
    'Bike Servicing',
    'Vehicle Repair',
    'Electricity',
    'Water Bill',
    'Rent',
    'Salary',
    'Food & Groceries',
    'Medical',
    'Office Supplies',
    'Miscellaneous',
  ];

  static const List<String> borrowLendCategories = [
    'Personal Loan',
    'Business Loan',
    'Emergency',
    'Miscellaneous',
  ];

  List<String> get currentCategories => rxType.value == TransactionType.expense
      ? expenseCategories
      : borrowLendCategories;

  @override
  void onInit() {
    super.onInit();
    _service = ServiceFinance(
      Get.find<ServiceObjectBox>().box<EntityFinanceTransaction>(),
    );
    // Auto-set debit/credit when type changes
    ever(rxType, _onTypeChanged);
  }

  void _onTypeChanged(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
      case TransactionType.borrow:
        rxIsDebit.value = true;
        break;
      case TransactionType.lend:
        rxIsDebit.value = false;
        break;
    }
    // Reset category to first item of new list
    rxCategory.value = currentCategories.first;
  }

  String get typeName {
    switch (rxType.value) {
      case TransactionType.expense:
        return 'expense';
      case TransactionType.borrow:
        return 'borrow';
      case TransactionType.lend:
        return 'lend';
    }
  }

  /// Displayed in the form field as dd MMM yyyy
  String get formattedDate => DateFormat('dd MMM yyyy').format(rxDate.value);

  /// Stored in entity as yyyy-MM-dd (date only, no time)
  String get _storedDate => DateFormat('yyyy-MM-dd').format(rxDate.value);

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: rxDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) rxDate.value = picked;
  }

  void saveTransaction() {
    if (!formKey.currentState!.validate()) return;

    // dateUtcMs: midnight of the selected date (date only, no time)
    final dateOnly = DateTime(
      rxDate.value.year,
      rxDate.value.month,
      rxDate.value.day,
    );

    final tx = EntityFinanceTransaction()
      ..type = typeName
      ..category = rxCategory.value
      ..personName = personNameController.text.trim().isEmpty
          ? null
          : personNameController.text.trim()
      ..amount = double.tryParse(amountController.text)
      ..isDebit = rxIsDebit.value
      ..note = noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim()
      ..dateUtcMs = dateOnly.millisecondsSinceEpoch
      ..createdDate = _storedDate;

    _service.save(tx);

    Get.back(result: true);

    Get.snackbar(
      'Saved',
      '${_capitalize(typeName)} recorded successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 2),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  void onClose() {
    amountController.dispose();
    personNameController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
