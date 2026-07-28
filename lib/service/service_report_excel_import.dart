import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lightweight parse result structure returned from background isolate.
class _ExcelParseResult {
  final bool success;
  final String? errorMessage;
  final List<String>? foundHeaders;
  final List<Map<String, dynamic>>? parsedRows;

  _ExcelParseResult({
    required this.success,
    this.errorMessage,
    this.foundHeaders,
    this.parsedRows,
  });
}

/// Params passed into the isolate worker function.
class _ExcelIsolateParams {
  final Uint8List bytes;
  final List<String> expectedHeaders;

  _ExcelIsolateParams({
    required this.bytes,
    required this.expectedHeaders,
  });
}

/// Development/Test Only helper to parse Excel files for testing report layouts and exports.
class ServiceReportExcelImport {
  /// Prompts the user to pick an `.xlsx` file, decodes the first worksheet in a background isolate,
  /// validates that the column headers match [expectedHeaders], and returns
  /// a list of maps representing data rows. Each map entry has the column header as key
  /// and the cell value as value.
  ///
  /// Returns `null` if selection is cancelled, file is empty, or header validation fails.
  static Future<List<Map<String, dynamic>>?> importAndValidate({
    required List<String> expectedHeaders,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.single.path == null) return null;

      final filePath = result.files.single.path!;

      // ── Show Loading Dialog ──
      _showLoadingDialog();

      try {
        // Read file bytes asynchronously
        final bytes = await File(filePath).readAsBytes();

        // Offload heavy decoding & parsing to a background isolate
        final parseResult = await Isolate.run(
          () => _parseExcelInIsolate(_ExcelIsolateParams(
            bytes: bytes,
            expectedHeaders: expectedHeaders,
          )),
        );

        // Dismiss loading dialog before showing UI feedback
        _dismissLoadingDialog();

        if (!parseResult.success) {
          if (parseResult.foundHeaders != null) {
            // Header validation failure
            final foundStr = parseResult.foundHeaders!.isEmpty
                ? 'None'
                : parseResult.foundHeaders!.join(', ');

            Get.snackbar(
              'Header Validation Failed',
              'Column headers do not match selected report type.\n'
              'Expected: ${expectedHeaders.join(", ")}\n'
              'Found: $foundStr',
              backgroundColor: Colors.red.shade700,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              snackPosition: SnackPosition.BOTTOM,
            );
          } else {
            // Other import error (empty sheet, etc.)
            Get.snackbar(
              'Import Failed',
              parseResult.errorMessage ?? 'Failed to parse Excel file.',
              backgroundColor: Colors.red.shade700,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
          return null;
        }

        final parsedRows = parseResult.parsedRows ?? [];

        Get.snackbar(
          'Test Data Loaded',
          'Successfully imported ${parsedRows.length} test rows (in-memory only).',
          backgroundColor: Colors.teal.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return parsedRows;
      } catch (e) {
        _dismissLoadingDialog();
        rethrow;
      }
    } catch (e) {
      debugPrint('Error importing report excel: $e');
      Get.snackbar(
        'Import Error',
        'Failed to parse Excel file: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  static bool _isLoadingDialogOpen = false;

  static void _showLoadingDialog() {
    _isLoadingDialogOpen = true;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing Excel File...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Parsing data in background...',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void _dismissLoadingDialog() {
    if (_isLoadingDialogOpen) {
      _isLoadingDialogOpen = false;
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  /// Runs in a background Isolate to prevent UI freezing on large Excel files.
  static _ExcelParseResult _parseExcelInIsolate(_ExcelIsolateParams params) {
    final workbook = excel_lib.Excel.decodeBytes(params.bytes);

    if (workbook.tables.isEmpty) {
      return _ExcelParseResult(
        success: false,
        errorMessage: 'The selected Excel file contains no worksheets.',
      );
    }

    final firstSheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[firstSheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      return _ExcelParseResult(
        success: false,
        errorMessage: 'The worksheet is empty.',
      );
    }

    // Pre-normalize expected headers once
    final expectedNormalized = params.expectedHeaders
        .map((s) => s.trim().toLowerCase())
        .toList();
    final expectedSet = expectedNormalized.toSet();

    int headerRowIdx = -1;
    final Map<int, String> colIndexToHeader = {};

    for (int i = 0; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      final rowStrings = <String>[];
      final rowLowerSet = <String>{};

      for (int c = 0; c < row.length; c++) {
        final cell = row[c];
        final rawVal = cell?.value;
        if (rawVal != null) {
          final str = rawVal.toString().trim();
          rowStrings.add(str);
          if (str.isNotEmpty) {
            rowLowerSet.add(str.toLowerCase());
          }
        } else {
          rowStrings.add('');
        }
      }

      // Check if all expected headers exist in this row
      bool matches = true;
      for (final exp in expectedSet) {
        if (!rowLowerSet.contains(exp)) {
          matches = false;
          break;
        }
      }

      if (matches) {
        headerRowIdx = i;
        for (int c = 0; c < rowStrings.length; c++) {
          final headerText = rowStrings[c];
          if (headerText.isNotEmpty) {
            colIndexToHeader[c] = headerText;
          }
        }
        break;
      }
    }

    if (headerRowIdx == -1) {
      // Find first non-empty row to list found headers for validation error
      final foundHeaderList = <String>[];
      for (final row in sheet.rows) {
        if (row.isEmpty) continue;
        for (final cell in row) {
          final v = cell?.value?.toString().trim();
          if (v != null && v.isNotEmpty) {
            foundHeaderList.add(v);
          }
        }
        if (foundHeaderList.isNotEmpty) break;
      }

      return _ExcelParseResult(
        success: false,
        foundHeaders: foundHeaderList,
      );
    }

    // ── Parse data rows efficiently ──
    final parsedRows = <Map<String, dynamic>>[];
    final colEntries = colIndexToHeader.entries.toList();

    for (int i = headerRowIdx + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      final rowMap = <String, dynamic>{};
      bool hasData = false;

      for (int k = 0; k < colEntries.length; k++) {
        final entry = colEntries[k];
        final colIndex = entry.key;
        if (colIndex >= row.length) continue;

        final cell = row[colIndex];
        final rawVal = cell?.value;
        if (rawVal == null) continue;

        final dynamic cleanVal = _extractPrimitiveValue(rawVal);
        if (cleanVal != null) {
          hasData = true;
          rowMap[entry.value] = cleanVal;
        }
      }

      if (hasData) {
        parsedRows.add(rowMap);
      }
    }

    return _ExcelParseResult(
      success: true,
      parsedRows: parsedRows,
    );
  }

  /// Converts Excel CellValue types to standard Dart primitives.
  static dynamic _extractPrimitiveValue(dynamic rawVal) {
    if (rawVal == null) return null;
    if (rawVal is num || rawVal is String || rawVal is bool || rawVal is DateTime) {
      if (rawVal is String) {
        final trimmed = rawVal.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      return rawVal;
    }
    final str = rawVal.toString().trim();
    if (str.isEmpty) return null;
    return str;
  }

  /// Helper utility to safely parse strings from imported cell values.
  static String parseString(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    final s = val.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  /// Helper utility to safely parse integers from imported cell values.
  static int parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    final s = val.toString().trim();
    return int.tryParse(s) ?? (double.tryParse(s)?.toInt() ?? fallback);
  }

  /// Helper utility to safely parse doubles from imported cell values.
  static double parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    final s = val.toString().trim();
    return double.tryParse(s) ?? fallback;
  }

  /// Helper utility to safely parse booleans from imported cell values.
  static bool parseBool(dynamic val, [bool fallback = false]) {
    if (val == null) return fallback;
    if (val is bool) return val;
    final s = val.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }
}
