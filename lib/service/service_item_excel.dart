import 'dart:io';

import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/entity_item.dart';

class ServiceItemExcel {
  // ── Generic Report Export ──────────────────────────────────────────────────

  // ─── Colour palette (ARGB hex strings for excel 3.0.0) ───────────────────
  static const String _clrStoreBg   = 'FF1A237E'; // deep indigo  – store banner
  static const String _clrStoreText = 'FFFFFFFF'; // white
  static const String _clrTitleBg   = 'FF283593'; // indigo       – report title
  static const String _clrSectionBg = 'FFE8EAF6'; // light indigo – section headers
  static const String _clrSectionFg = 'FF1A237E'; // deep indigo
  static const String _clrHeaderBg  = 'FF3949AB'; // indigo       – table col headers
  static const String _clrHeaderFg  = 'FFFFFFFF'; // white
  static const String _clrRowEven   = 'FFF3F4FB'; // very light indigo – alternating
  static const String _clrRowOdd    = 'FFFFFFFF'; // white
  static const String _clrBorder    = 'FFBDBDBD'; // grey border
  static const String _clrFooterBg  = 'FF1A237E'; // same as store banner
  static const String _clrLabelFg   = 'FF424242'; // dark grey – filter/summary labels
  static const String _clrValueFg   = 'FF212121'; // near-black – filter/summary values

  // ─── Helper: create a styled CellStyle (excel 3.0.0 API) ─────────────────
  excel_lib.CellStyle _style({
    String? bgColor,
    String? fontColor,
    bool bold      = false,
    bool italic    = false,
    int  fontSize  = 10,
    excel_lib.HorizontalAlign hAlign = excel_lib.HorizontalAlign.Left,
    excel_lib.VerticalAlign   vAlign = excel_lib.VerticalAlign.Center,
    bool borderAll    = false,
    bool borderBottom = false,
    bool borderTop    = false,
  }) {
    final thinBorder = excel_lib.Border(
      borderStyle:    excel_lib.BorderStyle.Thin,
      borderColorHex: _clrBorder,
    );
    final noBorder = excel_lib.Border();

    return excel_lib.CellStyle(
      backgroundColorHex: bgColor   ?? 'none',
      fontColorHex:       fontColor ?? 'FF000000',
      bold:               bold,
      italic:             italic,
      fontSize:           fontSize,
      horizontalAlign:    hAlign,
      verticalAlign:      vAlign,
      leftBorder:   borderAll ? thinBorder : noBorder,
      rightBorder:  borderAll ? thinBorder : noBorder,
      topBorder:    (borderAll || borderTop)    ? thinBorder : noBorder,
      bottomBorder: (borderAll || borderBottom) ? thinBorder : noBorder,
    );
  }

  // ─── Helper: write a cell at (col, row) with optional style ───────────────
  void _writeCell(
      excel_lib.Sheet sheet, int colIdx, int rowIdx, dynamic value,
      {excel_lib.CellStyle? style}) {
    final cell = sheet.cell(
        excel_lib.CellIndex.indexByColumnRow(
            columnIndex: colIdx, rowIndex: rowIdx));
    cell.value = value?.toString() ?? '';
    if (style != null) cell.cellStyle = style;
  }

  // ─── Helper: write + merge a full-width banner row ────────────────────────
  // Cell is written BEFORE merging to avoid xlsx repair warnings in Excel.
  void _writeBanner(
      excel_lib.Sheet sheet, int rowIdx, String text, int colSpan,
      excel_lib.CellStyle style) {
    final startIdx = excel_lib.CellIndex.indexByColumnRow(
        columnIndex: 0, rowIndex: rowIdx);
    final cell = sheet.cell(startIdx);
    cell.value     = text;
    cell.cellStyle = style;
    if (colSpan > 1) {
      sheet.merge(
        startIdx,
        excel_lib.CellIndex.indexByColumnRow(
            columnIndex: colSpan - 1, rowIndex: rowIdx),
      );
    }
  }

  // ─── Helper: write a two-column key/value row (preserved for API compatibility)
  // ignore: unused_element
  void _writeKV(
      excel_lib.Sheet sheet, int rowIdx, String key, String value,
      {excel_lib.CellStyle? keyStyle, excel_lib.CellStyle? valStyle}) {
    _writeCell(sheet, 0, rowIdx, key,   style: keyStyle);
    _writeCell(sheet, 1, rowIdx, value, style: valStyle);
  }

  // ─── Helper: set row height ────────────────────────────────────────────────
  void _setRowHeight(excel_lib.Sheet sheet, int rowIdx, double height) {
    sheet.setRowHeight(rowIdx, height);
  }

  // ─── Helper: format value for display ─────────────────────────────────────
  // Values are displayed exactly as provided by the calling controller.
  // Only null → '-'. No currency heuristics applied here.
  String _formatValue(dynamic v) {
    if (v == null) return '-';
    return v.toString();
  }

  // ─── Helper: compute a heuristic column width from content samples ─────────
  double _autoWidth(List<String> samples,
      {double min = 10, double max = 35}) {
    double w = min;
    for (final s in samples) {
      // 1.15 is a rough char-width fudge factor for proportional fonts
      final len = s.length * 1.15;
      if (len > w) w = len;
    }
    return w.clamp(min, max);
  }

  /// Exports generic report data to a professionally styled Excel workbook.
  ///
  /// Layout (row order):
  ///   [0]   Store banner         – deep-indigo bg, white bold 14pt, merged
  ///   [1]   Report title         – indigo bg, white bold 12pt, merged
  ///   [2]   Generated timestamp  – light-grey bg, right-aligned italic, merged
  ///   [3]   narrow spacer
  ///   [4…]  APPLIED FILTERS      – section header + 2-pair-per-row grid
  ///         narrow spacer
  ///   […]   REPORT SUMMARY       – section header + 2-pair-per-row grid
  ///         narrow spacer
  ///   […]   Data table header    – indigo bg, white bold, full borders
  ///   […]   Data rows            – alternating bg, full borders
  ///         narrow spacer
  ///   […]   Footer               – deep-indigo bg, white italic, merged
  Future<bool> exportReport({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    Map<String, String>? appliedFilters,
    Map<String, dynamic>? summaryData,
  }) async {
    if (rows.isEmpty && (summaryData == null || summaryData.isEmpty)) {
      Get.snackbar(
        'No Data',
        'No data available to export for $title',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      final excelFile = excel_lib.Excel.createExcel();

      // ── Sheet setup ──────────────────────────────────────────────────────
      String sheetName = title.replaceAll(RegExp(r'[\\/*?:\[\]]'), ' ').trim();
      if (sheetName.length > 31) sheetName = sheetName.substring(0, 31).trim();
      if (sheetName.isEmpty) sheetName = 'Report';

      final sheet = excelFile[sheetName];
      excelFile.setDefaultSheet(sheetName);
      if (sheetName != 'Sheet1' && excelFile.tables.containsKey('Sheet1')) {
        try { excelFile.delete('Sheet1'); } catch (_) {}
      }

      // colSpan ≥ 6 ensures info sections look balanced and span the sheet
      final int colSpan = headers.length.clamp(6, 26);
      final now = DateTime.now();
      int r = 0; // current row pointer

      // ════════════════════════════════════════════════════════════════════
      // ROW 0 – Store banner
      // ════════════════════════════════════════════════════════════════════
      _setRowHeight(sheet, r, 30);
      _writeBanner(sheet, r, 'RH Supermarket', colSpan,
          _style(bgColor: _clrStoreBg, fontColor: _clrStoreText,
              bold: true, fontSize: 14,
              hAlign: excel_lib.HorizontalAlign.Center));
      r++;

      // ════════════════════════════════════════════════════════════════════
      // ROW 1 – Report title
      // ════════════════════════════════════════════════════════════════════
      _setRowHeight(sheet, r, 26);
      _writeBanner(sheet, r, title, colSpan,
          _style(bgColor: _clrTitleBg, fontColor: _clrStoreText,
              bold: true, fontSize: 12,
              hAlign: excel_lib.HorizontalAlign.Center));
      r++;

      // ════════════════════════════════════════════════════════════════════
      // ROW 2 – Generated timestamp (light-grey bg, right-aligned)
      // ════════════════════════════════════════════════════════════════════
      _setRowHeight(sheet, r, 18);
      _writeBanner(sheet, r,
          'Generated: ${DateFormat('dd-MMM-yyyy   HH:mm:ss').format(now)}',
          colSpan,
          _style(bgColor: 'FFF5F5F5', fontColor: _clrLabelFg,
              italic: true, fontSize: 9,
              hAlign: excel_lib.HorizontalAlign.Right));
      r++;

      // ROW 3 – narrow spacer
      _setRowHeight(sheet, r, 8);
      r++;

      // ════════════════════════════════════════════════════════════════════
      // APPLIED FILTERS section
      // Renders 2 key-value pairs side-by-side per row to use full width.
      //   Col 0 = label,   Col 1 = value   (pair 1)
      //   Col 2 = narrow gap (3 chars wide)
      //   Col 3 = label,   Col 4 = value   (pair 2)
      // ════════════════════════════════════════════════════════════════════
      if (appliedFilters != null && appliedFilters.isNotEmpty) {
        _setRowHeight(sheet, r, 20);
        _writeBanner(sheet, r, '  APPLIED FILTERS', colSpan,
            _style(bgColor: _clrSectionBg, fontColor: _clrSectionFg,
                bold: true, fontSize: 10,
                hAlign: excel_lib.HorizontalAlign.Left));
        r++;

        final fLabelStyle = _style(
            bgColor: 'FFEEF0FB',
            fontColor: _clrLabelFg, bold: true, fontSize: 9,
            hAlign: excel_lib.HorizontalAlign.Left, borderAll: true);
        final fValueStyle = _style(
            fontColor: _clrValueFg, fontSize: 9,
            hAlign: excel_lib.HorizontalAlign.Left, borderAll: true);

        final fEntries = appliedFilters.entries.toList();
        for (int i = 0; i < fEntries.length; i += 2) {
          _setRowHeight(sheet, r, 16);
          _writeCell(sheet, 0, r, '  ${fEntries[i].key}',   style: fLabelStyle);
          _writeCell(sheet, 1, r, '  ${fEntries[i].value}', style: fValueStyle);
          if (i + 1 < fEntries.length) {
            _writeCell(sheet, 3, r, '  ${fEntries[i + 1].key}',   style: fLabelStyle);
            _writeCell(sheet, 4, r, '  ${fEntries[i + 1].value}', style: fValueStyle);
          }
          r++;
        }
        // narrow spacer
        _setRowHeight(sheet, r, 8);
        r++;
      }

      // ════════════════════════════════════════════════════════════════════
      // REPORT SUMMARY section – same 2-pair-per-row grid as filters
      // ════════════════════════════════════════════════════════════════════
      if (summaryData != null && summaryData.isNotEmpty) {
        _setRowHeight(sheet, r, 20);
        _writeBanner(sheet, r, '  REPORT SUMMARY', colSpan,
            _style(bgColor: _clrSectionBg, fontColor: _clrSectionFg,
                bold: true, fontSize: 10,
                hAlign: excel_lib.HorizontalAlign.Left));
        r++;

        final sLabelStyle = _style(
            bgColor: 'FFEEF0FB',
            fontColor: _clrLabelFg, bold: true, fontSize: 9,
            hAlign: excel_lib.HorizontalAlign.Left, borderAll: true);
        final sValueStyle = _style(
            fontColor: _clrValueFg, bold: true, fontSize: 10,
            hAlign: excel_lib.HorizontalAlign.Right, borderAll: true);

        final sEntries = summaryData.entries.toList();
        for (int i = 0; i < sEntries.length; i += 2) {
          _setRowHeight(sheet, r, 18);
          _writeCell(sheet, 0, r, '  ${sEntries[i].key}',
              style: sLabelStyle);
          _writeCell(sheet, 1, r, '  ${_formatValue(sEntries[i].value)}',
              style: sValueStyle);
          if (i + 1 < sEntries.length) {
            _writeCell(sheet, 3, r, '  ${sEntries[i + 1].key}',
                style: sLabelStyle);
            _writeCell(sheet, 4, r, '  ${_formatValue(sEntries[i + 1].value)}',
                style: sValueStyle);
          }
          r++;
        }
        // narrow spacer
        _setRowHeight(sheet, r, 8);
        r++;
      }

      // ════════════════════════════════════════════════════════════════════
      // DATA TABLE – column headers
      // ════════════════════════════════════════════════════════════════════
      _setRowHeight(sheet, r, 22);
      final hdrStyle = _style(
          bgColor: _clrHeaderBg, fontColor: _clrHeaderFg,
          bold: true, fontSize: 10,
          hAlign: excel_lib.HorizontalAlign.Center,
          vAlign: excel_lib.VerticalAlign.Center,
          borderAll: true);
      for (int c = 0; c < headers.length; c++) {
        _writeCell(sheet, c, r, headers[c], style: hdrStyle);
      }
      r++;

      // ════════════════════════════════════════════════════════════════════
      // DATA TABLE – data rows (alternating row colours)
      // ════════════════════════════════════════════════════════════════════
      int dataRowIdx = 0;
      for (final row in rows) {
        _setRowHeight(sheet, r, 15);
        final rowBg = dataRowIdx.isEven ? _clrRowEven : _clrRowOdd;

        for (int c = 0; c < row.length; c++) {
          final raw       = row[c];
          final formatted = _formatValue(raw);

          // Right-align only true numeric values; strings go left
          final isNumeric = raw is double || raw is int;

          final cellStyle = _style(
              bgColor:   rowBg,
              fontColor: _clrValueFg,
              fontSize:  9,
              hAlign: isNumeric
                  ? excel_lib.HorizontalAlign.Right
                  : excel_lib.HorizontalAlign.Left,
              borderAll: true);

          _writeCell(sheet, c, r, formatted, style: cellStyle);
        }
        r++;
        dataRowIdx++;
      }

      // ════════════════════════════════════════════════════════════════════
      // FOOTER
      // ════════════════════════════════════════════════════════════════════
      _setRowHeight(sheet, r, 8); // spacer before footer
      r++;
      _setRowHeight(sheet, r, 20);
      _writeBanner(sheet, r,
          'Generated by RH Supermarket POS  •  '
          '${DateFormat('dd-MMM-yyyy').format(now)}  •  Confidential',
          colSpan,
          _style(bgColor: _clrFooterBg, fontColor: _clrStoreText,
              italic: true, fontSize: 8,
              hAlign: excel_lib.HorizontalAlign.Center));

      // ════════════════════════════════════════════════════════════════════
      // Column widths
      // ════════════════════════════════════════════════════════════════════
      // Helper: gather all samples (including headers, data table, and filters/summaries) for a specific column c
      List<String> colSamples(int c) {
        final s = <String>[];
        // 1. Add headers and data table content
        if (c < headers.length) s.add(headers[c]);
        for (int ri = 0; ri < rows.length && ri < 80; ri++) {
          if (c < rows[ri].length) s.add(_formatValue(rows[ri][c]));
        }

        // 2. Add filter & summary text if it's placed in this column
        if (c == 0) {
          s.add('  APPLIED FILTERS');
          s.add('  REPORT SUMMARY');
          if (appliedFilters != null) {
            s.addAll(appliedFilters.keys.map((k) => '  $k'));
          }
          if (summaryData != null) {
            s.addAll(summaryData.keys.map((k) => '  $k'));
          }
        } else if (c == 1) {
          if (appliedFilters != null) {
            s.addAll(appliedFilters.values.map((v) => '  $v'));
          }
          if (summaryData != null) {
            s.addAll(summaryData.values.map((v) => '  ${_formatValue(v)}'));
          }
        } else if (c == 3) {
          if (appliedFilters != null) {
            final keys = appliedFilters.keys.toList();
            for (int i = 1; i < keys.length; i += 2) {
              s.add('  ${keys[i]}');
            }
          }
          if (summaryData != null) {
            final keys = summaryData.keys.toList();
            for (int i = 1; i < keys.length; i += 2) {
              s.add('  ${keys[i]}');
            }
          }
        } else if (c == 4) {
          if (appliedFilters != null) {
            final values = appliedFilters.values.toList();
            for (int i = 1; i < values.length; i += 2) {
              s.add('  ${values[i]}');
            }
          }
          if (summaryData != null) {
            final values = summaryData.values.toList();
            for (int i = 1; i < values.length; i += 2) {
              s.add('  ${_formatValue(values[i])}');
            }
          }
        }
        return s;
      }

      // Apply dynamic widths to all columns
      for (int c = 0; c < colSpan; c++) {
        // Col 2 is a narrow spacer ONLY if there is no data in column 2 (meaning headers.length <= 2)
        if (c == 2 && headers.length <= 2) {
          sheet.setColumnWidth(2, 2.5);
          continue;
        }

        // Determine column min and max widths
        double minW = 10;
        double maxW = 28;

        // Auto-detect category column
        bool isCategory = false;
        if (c < headers.length) {
          final h = headers[c].toLowerCase();
          if (h.contains('category')) {
            isCategory = true;
          }
        }

        if (isCategory) {
          minW = 22;
          maxW = 38;
        } else if (c == 0) {
          minW = 22;
          maxW = 38;
        } else if (c == 1) {
          minW = 16;
          maxW = 30; // Name column is usually col 1, can be wider
        } else if (c == 3 || c == 4) {
          minW = 14;
          maxW = 28;
        }

        sheet.setColumnWidth(c, _autoWidth(colSamples(c), min: minW, max: maxW));
      }

      // ════════════════════════════════════════════════════════════════════
      // Encode & save
      // ════════════════════════════════════════════════════════════════════
      final bytes = excelFile.save();
      if (bytes == null) {
        Get.snackbar(
          'Export Failed ❌',
          'Failed to generate Excel file bytes.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final safeTitle = title
          .replaceAll(RegExp(r'[\\/*?:\[\]"<>|]'), '_')
          .replaceAll(' ', '_');
      final fileName = '${safeTitle}_$timestamp.xlsx';

      // Desktop: FilePicker Save Dialog
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Report – $title',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        if (outputPath == null) return true; // user cancelled

        await File(outputPath).writeAsBytes(bytes);
        Get.snackbar(
          'Export Successful ✅',
          'File saved:\n$outputPath',
          backgroundColor: const Color(0xFF2E7D32),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.BOTTOM,
          isDismissible: true,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
        );
        return true;
      }

      // Mobile / Web: Share
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      // ignore: deprecated_member_use
      await Share.shareXFiles(
          [XFile(file.path)], text: 'RH Supermarket – $title ($timestamp)');
      Get.snackbar(
        'Export Successful ✅',
        'Report shared successfully.',
        backgroundColor: const Color(0xFF2E7D32),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e, st) {
      debugPrint('ServiceItemExcel.exportReport error: $e\n$st');
      Get.snackbar(
        'Export Failed ❌',
        'An error occurred while exporting: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // ── Export Items ─────────────────────────────────────────────────────────

  /// Exports all [items] to an Excel file.
  ///
  /// On Windows / macOS / Linux  → opens a "Save As" dialog via FilePicker.
  /// On mobile / Web             → shares the file via share_plus.
  Future<bool> exportItems(List<EntityItem> items) async {
    try {
      final excelFile = excel_lib.Excel.createExcel();
      final sheet     = excelFile['Items'];
      excelFile.setDefaultSheet('Items');

      sheet.appendRow([
        'Name', 'SKU', 'Barcode', 'Unit', 'Category',
        'Cost Price', 'Selling Price', 'Stock Qty',
        'Tax Name', 'Tax Rate (%)', 'Tax Type', 'Has Expiry', 'Status',
      ]);

      for (final item in items) {
        sheet.appendRow([
          item.name          ?? '',
          item.sku           ?? '',
          item.barcode       ?? '',
          item.unit          ?? '',
          item.category      ?? '',
          item.costPrice     ?? 0.0,
          item.sellingPrice  ?? 0.0,
          item.totalQty      ?? 0,
          item.taxName       ?? '',
          item.taxRate       ?? 0.0,
          item.taxType       ?? '',
          item.hasExpiry == true ? 'Yes' : 'No',
          item.isActive  == true ? 'Active' : 'Inactive',
        ]);
      }

      final bytes = excelFile.save();
      if (bytes == null) return false;

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName  = 'items_export_$timestamp.xlsx';

      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Items Export',
          fileName:    fileName,
          type:        FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        if (outputPath == null) return true;

        await File(outputPath).writeAsBytes(bytes);
        Get.snackbar(
          'Export Successful ✅',
          'File saved:\n$outputPath',
          backgroundColor: const Color(0xFF2E7D32),
          colorText:       const Color(0xFFFFFFFF),
          duration:        const Duration(seconds: 6),
          snackPosition:   SnackPosition.BOTTOM,
          isDismissible:   true,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
        );
        return true;
      }

      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      // ignore: deprecated_member_use
      await Share.shareXFiles(
          [XFile(file.path)], text: 'Supermarket – Items Export ($timestamp)');
      return true;
    } catch (e, st) {
      debugPrint('ServiceItemExcel.exportItems error: $e\n$st');
      return false;
    }
  }

  // ── Import Items ─────────────────────────────────────────────────────────

  /// Imports items from an xlsx file chosen by the user.
  /// Returns the parsed list or null if the user cancelled / an error occurred.
  Future<List<EntityItem>?> importItems() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.single.path == null) return null;

      final bytes    = File(result.files.single.path!).readAsBytesSync();
      final workbook = excel_lib.Excel.decodeBytes(bytes);
      final importedItems = <EntityItem>[];

      for (final tableName in workbook.tables.keys) {
        final table   = workbook.tables[tableName]!;
        bool isHeader = true;
        for (final row in table.rows) {
          if (isHeader) { isHeader = false; continue; }
          if (row.isEmpty) continue;

          String str(int col) {
            if (col >= row.length) return '';
            return row[col]?.value?.toString() ?? '';
          }
          double? dbl(int col) => double.tryParse(str(col));

          final name = str(0);
          if (name.isEmpty) continue;

          importedItems.add(EntityItem(
            name:         name,
            sku:          str(1).isEmpty  ? null : str(1),
            barcode:      str(2).isEmpty  ? null : str(2),
            unit:         str(3).isEmpty  ? null : str(3),
            category:     str(4).isEmpty  ? null : str(4),
            costPrice:    dbl(5),
            sellingPrice: dbl(6) ?? 0.0,
            taxName:      str(8).isEmpty  ? null : str(8),
            taxRate:      dbl(9),
            taxType:      str(10).isEmpty ? null : str(10),
            hasExpiry:    str(11).toLowerCase() == 'yes',
            isActive:     str(12).toLowerCase() != 'inactive',
            totalQty:     0,
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
