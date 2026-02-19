import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/entity_item.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item.dart';
import '../../../../service/service_object_box.dart';

class ControllerHomeItem extends GetxController {
  late final ItemService _itemService;
  late final Box<EntityItem> _boxItem;

  final RxList<EntityItem> rxListItem = <EntityItem>[].obs;
  final RxString searchQuery = ''.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    final ob = Get.find<ServiceObjectBox>();
    _boxItem = ob.box<EntityItem>();
    _itemService = ItemService(_boxItem);
    loadItems();
    super.onInit();
  }

  /// Load all items
  void loadItems() {
    if (searchQuery.value.trim().isEmpty) {
      rxListItem.value = _itemService.getAllItems();
    } else {
      rxListItem.value = _itemService.searchItems(searchQuery.value);
    }
    debugPrint("loadItems size: ${rxListItem.length}");
  }

  /// Update search and refresh list
  void updateSearch(String query) {
    searchQuery.value = query;
    loadItems();
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    loadItems();
  }

  /// Adjust stock quantity (positive = increment, negative = decrement)
  bool adjustStock(EntityItem item, int delta) {
    final success = _itemService.adjustStock(item, delta);
    if (success) {
      loadItems();
    }
    return success;
  }

  /// Auto-generate barcode for an item
  void generateBarcode(EntityItem item) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    item.barcode = 'ITM-${item.id}-$timestamp';
    _itemService.updateItem(item);
    loadItems();
  }

  /// Toggle active/inactive
  void toggleActive(EntityItem item) {
    item.isActive = !(item.isActive ?? true);
    _itemService.updateItem(item);
    loadItems();
  }

  /// Delete item
  void deleteItem(EntityItem item) {
    if (item.id != null) {
      _itemService.deleteItem(item.id!);
      loadItems();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
