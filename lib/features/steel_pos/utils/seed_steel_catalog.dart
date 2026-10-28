import 'dart:io';
import 'package:excel/excel.dart';
import '../../../model/entity_item.dart';
import '../../../service/service_object_box.dart';
import '../models/steel_spec.dart';

class SeedSteelCatalog {
  /// Seeds standard Indian industrial steel products into the current active ObjectBox database.
  static Future<int> seedItemsIntoObjectBox(ServiceObjectBox ob) async {
    final box = ob.box<EntityItem>();
    final existingCount = box.count();
    if (existingCount > 0) {
      // Don't overwrite if items already present
      return existingCount;
    }

    final items = generateStandardSteelEntities();
    box.putMany(items);
    return items.length;
  }

  static List<EntityItem> generateStandardSteelEntities() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final entities = <EntityItem>[];

    // Primary Mills
    final mills = ['Tata Tiscon', 'JSW Neosteel', 'SAIL'];

    for (final spec in SteelCatalogData.standardCatalog) {
      if (spec.category == SteelCategory.tmtRebars) {
        for (final mill in mills) {
          final rateKg = mill == 'Tata Tiscon' ? 62.0 : (mill == 'JSW Neosteel' ? 60.5 : 58.0);
          final costKg = rateKg - 3.5;

          entities.add(EntityItem(
            name: '$mill ${spec.name}',
            sku: 'TMT-${spec.size.replaceAll(" ", "")}-${mill.substring(0, 4).toUpperCase()}',
            barcode: 'STEEL-${mill.substring(0, 3).toUpperCase()}-${spec.id.toUpperCase()}',
            category: spec.category.displayName,
            unit: 'Kg',
            costPrice: costKg,
            sellingPrice: rateKg,
            taxName: 'GST',
            taxRate: 18.0,
            taxType: 'inclusive',
            hsnCode: spec.hsnCode,
            totalQty: 25000, // 25 MT stock in yard
            hasExpiry: false,
            isActive: true,
            createdAtUtcMs: now,
            updatedAtUtcMs: now,
          ));
        }
      } else {
        // Structural, Pipes, Plates
        final rateKg = 54.0;
        final costKg = 49.5;

        entities.add(EntityItem(
          name: spec.name,
          sku: spec.id.toUpperCase(),
          barcode: 'STEEL-${spec.id.toUpperCase()}',
          category: spec.category.displayName,
          unit: 'Kg',
          costPrice: costKg,
          sellingPrice: rateKg,
          taxName: 'GST',
          taxRate: 18.0,
          taxType: 'inclusive',
          hsnCode: spec.hsnCode,
          totalQty: 15000, // 15 MT stock
          hasExpiry: false,
          isActive: true,
          createdAtUtcMs: now,
          updatedAtUtcMs: now,
        ));
      }
    }

    return entities;
  }

  /// Exports a clean Excel sheet of steel catalog
  static void generateSteelExcel(String outputPath) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    excel.setDefaultSheet('Sheet1');

    final headers = [
      'Name', 'SKU', 'Barcode', 'Unit', 'Category',
      'Cost Price', 'Selling Price', 'Tax Name',
      'Tax Rate (%)', 'Tax Type', 'Has Expiry', 'Status'
    ];

    sheet.appendRow(headers);

    final items = generateStandardSteelEntities();
    for (final it in items) {
      sheet.appendRow([
        it.name ?? '',
        it.sku ?? '',
        it.barcode ?? '',
        it.unit ?? '',
        it.category ?? '',
        it.costPrice ?? 0.0,
        it.sellingPrice ?? 0.0,
        it.taxName ?? 'GST',
        it.taxRate ?? 18.0,
        it.taxType ?? 'inclusive',
        it.hasExpiry == true ? 'Yes' : 'No',
        it.isActive == true ? 'Active' : 'Inactive',
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      File(outputPath).writeAsBytesSync(bytes);
    }
  }
}
