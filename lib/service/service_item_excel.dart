import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/entity_item.dart';

class ServiceItemExcel {
  // ── Export ───────────────────────────────────────────────────────────────

  /// Exports all [items] to an Excel file.
  ///
  /// On Windows / macOS / Linux  → opens a "Save As" dialog via FilePicker.
  /// On mobile / Web             → shares the file via share_plus.
  Future<bool> exportItems(List<EntityItem> items) async {
    try {
      // ── 1. Build the workbook ──────────────────────────────────────────────
      final excel = Excel.createExcel();
      final sheet = excel['Items'];
      excel.setDefaultSheet('Items');

      // ── 2. Header row ──────────────────────────────────────────────────────
      sheet.appendRow([
        'Name',
        'SKU',
        'Barcode',
        'Unit',
        'Category',
        'Cost Price',
        'Selling Price',
        'Stock Qty',
        'Tax Name',
        'Tax Rate (%)',
        'Tax Type',
        'Has Expiry',
        'Status',
      ]);

      // ── 3. Data rows ───────────────────────────────────────────────────────
      for (final item in items) {
        sheet.appendRow([
          item.name ?? '',
          item.sku ?? '',
          item.barcode ?? '',
          item.unit ?? '',
          item.category ?? '',
          item.costPrice ?? 0.0,
          item.sellingPrice ?? 0.0,
          item.totalQty ?? 0,
          item.taxName ?? '',
          item.taxRate ?? 0.0,
          item.taxType ?? '',
          item.hasExpiry == true ? 'Yes' : 'No',
          item.isActive == true ? 'Active' : 'Inactive',
        ]);
      }

      // ── 4. Save bytes ──────────────────────────────────────────────────────
      final bytes = excel.save();
      if (bytes == null) return false;

      final timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'items_export_$timestamp.xlsx';

      // ── 5a. Desktop – Save dialog ──────────────────────────────────────────
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Items Export',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        if (outputPath == null) return true; // user cancelled – not an error

        await File(outputPath).writeAsBytes(bytes);

        Get.snackbar(
          'Export Successful ✅',
          'File saved:\n$outputPath',
          backgroundColor: const Color(0xFF2E7D32),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.BOTTOM,
          isDismissible: true,
          icon: const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 22),
        );
        return true;
      }

      // ── 5b. Mobile / Web – Share ───────────────────────────────────────────
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Supermarket – Items Export ($timestamp)',
      );
      return true;
    } catch (e, st) {
      debugPrint('ServiceItemExcel.exportItems error: $e\n$st');
      return false;
    }
  }

  // ── Import ───────────────────────────────────────────────────────────────

  /// Imports items from an xlsx file chosen by the user.
  /// Returns the parsed list or null if the user cancelled / an error occurred.
  Future<List<EntityItem>?> importItems() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.single.path == null) return null;

      final bytes = File(result.files.single.path!).readAsBytesSync();
      final workbook = Excel.decodeBytes(bytes);
      final importedItems = <EntityItem>[];

      for (final tableName in workbook.tables.keys) {
        final table = workbook.tables[tableName]!;
        bool isHeader = true;
        for (final row in table.rows) {
          if (isHeader) {
            isHeader = false;
            continue;
          }
          if (row.isEmpty) continue;

          String str(int col) {
            if (col >= row.length) return '';
            return row[col]?.value?.toString() ?? '';
          }

          double? dbl(int col) => double.tryParse(str(col));

          final name = str(0);
          if (name.isEmpty) continue;

          importedItems.add(EntityItem(
            name: name,
            sku: str(1).isEmpty ? null : str(1),
            barcode: str(2).isEmpty ? null : str(2),
            unit: str(3).isEmpty ? null : str(3),
            category: str(4).isEmpty ? null : str(4),
            costPrice: dbl(5),
            sellingPrice: dbl(6) ?? 0.0,
            taxName: str(8).isEmpty ? null : str(8),
            taxRate: dbl(9),
            taxType: str(10).isEmpty ? null : str(10),
            hasExpiry: str(11).toLowerCase() == 'yes',
            isActive: str(12).toLowerCase() != 'inactive',
            totalQty: 0,
          ));
        }
      }
      return importedItems;
    } catch (e) {
      debugPrint('ServiceItemExcel.importItems error: $e');
      return null;
    }
  }
}
