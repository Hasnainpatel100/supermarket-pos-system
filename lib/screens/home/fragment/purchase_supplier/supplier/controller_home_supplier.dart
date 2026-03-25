import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../model/entity_supplier.dart';
import '../../../../../objectbox.g.dart';
import '../../../../../service/service_object_box.dart';

class ControllerHomeSupplier extends GetxController {
  late final Box<EntitySupplier> _box;

  final RxList<EntitySupplier> rxListSupplier = <EntitySupplier>[].obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // ── Pagination ──
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext =>
      (currentPage.value + 1) * _pageSize < totalCount.value;

  @override
  void onInit() {
    super.onInit();
    _box = Get.find<ServiceObjectBox>().box<EntitySupplier>();
    loadSuppliers();

    debounce(
      searchQuery,
          (_) {
        currentPage.value = 0;
        loadSuppliers();
      },
      time: const Duration(milliseconds: 300),
    );
  }

  // ─────────────────────────────────────────────
  //  LOAD
  // ─────────────────────────────────────────────

  void loadSuppliers() {
    final q = searchQuery.value.trim();

    QueryBuilder<EntitySupplier> builder;
    if (q.isEmpty) {
      builder = _box.query()..order(EntitySupplier_.name);
    } else {
      builder = _box.query(
        EntitySupplier_.name
            .contains(q, caseSensitive: false)
            .or(EntitySupplier_.phone.contains(q, caseSensitive: false))
            .or(EntitySupplier_.supplierCode.contains(q, caseSensitive: false)),
      )..order(EntitySupplier_.name);
    }

    final query = builder.build();
    totalCount.value = query.count();

    query
      ..offset = currentPage.value * _pageSize
      ..limit = _pageSize;

    rxListSupplier.assignAll(query.find());
    query.close();
  }

  // ─────────────────────────────────────────────
  //  SEARCH
  // ─────────────────────────────────────────────

  void updateSearch(String val) => searchQuery.value = val;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 0;
    loadSuppliers();
  }

  // ─────────────────────────────────────────────
  //  PAGINATION
  // ─────────────────────────────────────────────

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      loadSuppliers();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      loadSuppliers();
    }
  }

  // ─────────────────────────────────────────────
  //  SAVE (Create / Update)
  // ─────────────────────────────────────────────

  /// Returns error string or null on success
  String? saveSupplier(EntitySupplier supplier) {
    final name = supplier.name?.trim() ?? '';
    if (name.isEmpty) return 'Supplier name is required';

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (supplier.id == 0) {
      // ── CREATE ──
      supplier.supplierCode = _generateSupplierCode();
      supplier.isActive = true;
      supplier.createdAtUtcMs = now;
      supplier.updatedAtUtcMs = now;
    } else {
      // ── UPDATE ──
      supplier.updatedAtUtcMs = now;
    }

    _box.put(supplier);
    loadSuppliers();
    return null;
  }

  /// Auto-create supplier by name (used during purchase creation)
  EntitySupplier findOrCreateByName(String name) {
    final existing = _box
        .query(EntitySupplier_.name.equals(name, caseSensitive: false))
        .build()
        .findFirst();
    if (existing != null) return existing;

    final supplier = EntitySupplier(name: name.trim());
    saveSupplier(supplier);
    return _box
        .query(EntitySupplier_.name.equals(name, caseSensitive: false))
        .build()
        .findFirst()!;
  }

  // ─────────────────────────────────────────────
  //  TOGGLE ACTIVE
  // ─────────────────────────────────────────────

  void toggleActive(EntitySupplier supplier) {
    supplier.isActive = !(supplier.isActive ?? true);
    supplier.updatedAtUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    _box.put(supplier);
    loadSuppliers();
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────

  String _generateSupplierCode() {
    final count = _box.count();
    final seq = (count + 1).toString().padLeft(3, '0');
    return 'SUP$seq';
  }

  List<EntitySupplier> getAllActive() {
    return _box
        .query(EntitySupplier_.isActive.equals(true))
        .order(EntitySupplier_.name)
        .build()
        .find();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
