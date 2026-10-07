import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../model/entity_item.dart';
import '../../../../model/entity_stock_transaction.dart';
import '../../../../model/stock_txn_type.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

class ControllerHomeStock extends GetxController {
  late Box<EntityStockTransaction> _boxTxn;
  late Box<EntityItem> _boxItem;

  final RxList<EntityStockTransaction> rxListTxn =
      <EntityStockTransaction>[].obs;
  final RxString searchQuery = ''.obs;
  final searchController = TextEditingController();

  // Filter by type: null = all
  final Rxn<StockTxnType> rxFilterType = Rxn<StockTxnType>();

  // ── Pagination ──
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      loadTransactions();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      loadTransactions();
    }
  }

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxTxn = ob.box<EntityStockTransaction>();
    _boxItem = ob.box<EntityItem>();
    loadTransactions();

    // Debounce search — waits 300ms after last keystroke before querying
    debounce(
      searchQuery,
      (_) {
        currentPage.value = 0;
        loadTransactions();
      },
      time: const Duration(milliseconds: 300),
    );
  }

  void loadTransactions() {
    final query = _boxTxn
        .query()
        .order(EntityStockTransaction_.createdAtUtcMs, flags: Order.descending)
        .build();
    var all = query.find();
    query.close();

    // Filter by type
    final typeFilter = rxFilterType.value;
    if (typeFilter != null) {
      all = all.where((t) => t.type == typeFilter.index).toList();
    }

    // Filter by search (item name / remarks)
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      all = all.where((t) {
        final name = (t.referenceId ?? '').toLowerCase();
        final rem = (t.remarks ?? '').toLowerCase();
        return name.contains(q) || rem.contains(q);
      }).toList();
    }

    totalCount.value = all.length;
    final paged = all.skip(currentPage.value * _pageSize).take(_pageSize).toList();
    rxListTxn.assignAll(paged);
  }

  /// Called from TextField onChanged — only updates the observable,
  /// debounce handles calling loadTransactions after 300ms
  void updateSearch(String q) {
    searchQuery.value = q;
  }

  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    currentPage.value = 0;
    loadTransactions(); // immediate clear
  }

  void setTypeFilter(StockTxnType? type) {
    rxFilterType.value = type;
    currentPage.value = 0;
    loadTransactions();
  }

  String getItemName(int? itemId) {
    if (itemId == null || itemId == 0) return '-';
    final item = _boxItem.get(itemId);
    return item?.name ?? 'Item #$itemId';
  }

  String formatDate(int? ms) {
    if (ms == null) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return DateFormat('dd MMM yy  hh:mm a').format(dt);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
