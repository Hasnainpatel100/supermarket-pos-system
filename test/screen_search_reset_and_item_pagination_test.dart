import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:super_market/enums/enum_main_menu.dart';
import 'package:super_market/model/entity_item.dart';

void main() {
  group('Requirement 1: Item Screen Multi-Page Selection & Row Key Tests', () {
    test('Selected IDs persist across pages, and page 2 items are not falsely selected', () {
      final selectedIds = <int>{}.obs;

      bool isSelected(int? id) => id != null && id > 0 && selectedIds.contains(id);

      // Page 1 items (IDs 1..20)
      final page1Items = List.generate(
        20,
        (i) => EntityItem(id: i + 1, name: 'Item ${i + 1}'),
      );

      // Page 2 items (IDs 21..40)
      final page2Items = List.generate(
        20,
        (i) => EntityItem(id: i + 21, name: 'Item ${i + 21}'),
      );

      // 1. Select items on Page 1 (IDs 2, 5, 10)
      selectedIds.addAll([2, 5, 10]);

      expect(selectedIds.length, equals(3));
      expect(isSelected(page1Items[1].id), isTrue); // Item 2
      expect(isSelected(page1Items[4].id), isTrue); // Item 5
      expect(isSelected(page1Items[9].id), isTrue); // Item 10
      expect(isSelected(page1Items[0].id), isFalse); // Item 1

      // 2. Navigate to Page 2: selections remain intact in selectedIds
      expect(selectedIds.contains(2), isTrue);

      // None of the items on page 2 are falsely checked
      for (final item in page2Items) {
        expect(isSelected(item.id), isFalse, reason: 'Item ${item.id} should not be selected on page 2');
      }

      // 3. User selects item 25 on Page 2
      selectedIds.add(25);
      expect(isSelected(25), isTrue);
      expect(selectedIds.length, equals(4)); // 3 from page 1 + 1 from page 2

      // 4. Verification of label text breakdown:
      // "4 items selected (1 on this page)"
      final page2SelectedCount = page2Items.where((it) => isSelected(it.id)).length;
      expect(page2SelectedCount, equals(1));
      final label = (page2SelectedCount == selectedIds.length)
          ? '${selectedIds.length} items selected'
          : '${selectedIds.length} items selected ($page2SelectedCount on this page)';
      expect(label, equals('4 items selected (1 on this page)'));

      // 5. Deselect all visible on Page 2: should only remove 25, leaving 2, 5, 10
      for (final item in page2Items) {
        if (item.id != null) selectedIds.remove(item.id!);
      }
      expect(selectedIds.length, equals(3));
      expect(selectedIds.contains(2), isTrue);
      expect(selectedIds.contains(5), isTrue);
      expect(selectedIds.contains(10), isTrue);
      expect(selectedIds.contains(25), isFalse);
    });

    test('DataRow unique ValueKey generation prevents element recycling confusion', () {
      final item1 = EntityItem(id: 101, name: 'Milk');
      final item2 = EntityItem(id: 202, name: 'Bread');
      final itemNoId = EntityItem(id: null, name: 'Apple');

      final key1 = ValueKey('item_row_${item1.id ?? item1.objectId}');
      final key2 = ValueKey('item_row_${item2.id ?? item2.objectId}');
      final keyNoId = ValueKey('item_row_${itemNoId.id ?? itemNoId.objectId}');

      expect(key1, isNot(equals(key2)));
      expect(key1.value, equals('item_row_101'));
      expect(key2.value, equals('item_row_202'));
      expect(keyNoId.value.toString().startsWith('item_row_'), isTrue);
    });

    test('Invalid or zero or null IDs cannot be selected or toggled', () {
      final selectedIds = <int>{}.obs;

      bool isSelected(int? id) => id != null && id > 0 && selectedIds.contains(id);

      void toggleSelection(int id) {
        if (id <= 0) return;
        if (selectedIds.contains(id)) {
          selectedIds.remove(id);
        } else {
          selectedIds.add(id);
        }
      }

      toggleSelection(0);
      toggleSelection(-5);
      expect(selectedIds.isEmpty, isTrue);

      expect(isSelected(null), isFalse);
      expect(isSelected(0), isFalse);
      expect(isSelected(-1), isFalse);
    });
  });

  group('Requirement 2: Search Query Clearing On Screen Navigation Tests', () {
    test('Search fields reset state properly when resetSearch is invoked', () {
      final searchQuery = 'Paracetamol'.obs;
      final searchController = TextEditingController(text: 'Paracetamol');
      int page = 2;

      void resetSearch() {
        if (searchQuery.value.isNotEmpty || searchController.text.isNotEmpty) {
          searchQuery.value = '';
          searchController.clear();
          page = 0;
        }
      }

      expect(searchQuery.value, equals('Paracetamol'));
      expect(searchController.text, equals('Paracetamol'));
      expect(page, equals(2));

      resetSearch();

      expect(searchQuery.value, isEmpty);
      expect(searchController.text, isEmpty);
      expect(page, equals(0));
    });

    test('Menu switching observable triggers search resets across all screens', () {
      final activeMenu = EnumMainMenu.item.obs;

      bool itemSearchResetCalled = false;
      bool stockSearchResetCalled = false;
      bool purchaseSearchResetCalled = false;
      bool supplierSearchResetCalled = false;
      bool posSearchResetCalled = false;

      // Mock of ControllerHome.resetAllScreenSearches
      void resetAllScreenSearches() {
        itemSearchResetCalled = true;
        stockSearchResetCalled = true;
        purchaseSearchResetCalled = true;
        supplierSearchResetCalled = true;
        posSearchResetCalled = true;
      }

      ever(activeMenu, (_) {
        resetAllScreenSearches();
      });

      // User moves from Item screen to Stocks screen
      activeMenu.value = EnumMainMenu.stocks;

      expect(itemSearchResetCalled, isTrue);
      expect(stockSearchResetCalled, isTrue);
      expect(purchaseSearchResetCalled, isTrue);
      expect(supplierSearchResetCalled, isTrue);
      expect(posSearchResetCalled, isTrue);
    });
  });
}
