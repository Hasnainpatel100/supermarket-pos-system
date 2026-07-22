import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show Colors, Color, Icon, Icons;
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// A reusable PDF report export service.
///
/// Call [exportReport] with the same arguments used for
/// [ServiceItemExcel.exportReport]. The service generates a professional,
/// print-ready A4 PDF and either opens a "Save As" dialog (desktop),
/// shows a print-preview sheet (mobile), or shares the file (web).
class ServiceReportPdf {
  // ── Brand colours ─────────────────────────────────────────────────────────
  static const PdfColor _clrStoreBg   = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor _clrTitleBg   = PdfColor.fromInt(0xFF283593);
  static const PdfColor _clrSectionBg = PdfColor.fromInt(0xFFE8EAF6);
  static const PdfColor _clrSectionFg = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor _clrHeaderBg  = PdfColor.fromInt(0xFF3949AB);
  static const PdfColor _clrRowEven   = PdfColor.fromInt(0xFFF3F4FB);
  static const PdfColor _clrBorder    = PdfColor.fromInt(0xFFBDBDBD);
  static const PdfColor _clrLabelFg   = PdfColor.fromInt(0xFF424242);
  static const PdfColor _clrValueFg   = PdfColor.fromInt(0xFF212121);
  static const PdfColor _clrWhite     = PdfColors.white;
  static const PdfColor _clrLabelCellBg = PdfColor.fromInt(0xFFEEF0FB);
  static const PdfColor _clrTimestampBg = PdfColor.fromInt(0xFFF5F5F5);

  // ── Layout constants ───────────────────────────────────────────────────────
  static const double _sectionGap = 10;
  static const double _smallGap   = 4;

  // ─────────────────────────────────────────────────────────────────────────
  /// Load the bundled Segoe UI font (supports ₹ and other Unicode symbols).
  static Future<pw.Font> _loadFont() async {
    final data = await rootBundle.load('assets/fonts/segoeui.ttf');
    return pw.Font.ttf(data.buffer.asByteData());
  }

  /// Format a value for display. Null → '-'.
  static String _fmt(dynamic v) => v == null ? '-' : v.toString();

  /// Right-align only genuine numeric types; strings go left.
  static pw.TextAlign _numAlign(dynamic v) =>
      (v is double || v is int) ? pw.TextAlign.right : pw.TextAlign.left;

  // ─────────────────────────────────────────────────────────────────────────
  // Widget builders (static so they are cheap to call inside pw.MultiPage)
  // ─────────────────────────────────────────────────────────────────────────

  /// Full-width coloured banner.
  static pw.Widget _banner(
    String text,
    pw.Font font, {
    PdfColor bg        = _clrStoreBg,
    PdfColor fg        = _clrWhite,
    double   fontSize  = 14,
    pw.TextAlign align = pw.TextAlign.center,
    bool bold          = true,
  }) =>
      pw.Container(
        width:   double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(color: bg),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
              font:       font,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize:   fontSize,
              color:      fg),
        ),
      );

  /// Section header banner (light-indigo, left-aligned bold text).
  static pw.Widget _sectionHeader(String text, pw.Font font) => _banner(
        text, font,
        bg: _clrSectionBg, fg: _clrSectionFg,
        fontSize: 9, align: pw.TextAlign.left);

  /// One key-value pair cell with a tinted label background.
  static pw.Widget _kvCell(
    String label,
    String value,
    pw.Font font, {
    bool         valueBold  = false,
    pw.TextAlign valueAlign = pw.TextAlign.left,
  }) =>
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _clrBorder, width: 0.5),
        ),
        child: pw.Row(children: [
          pw.Container(
            width:   80,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color:   _clrLabelCellBg,
            child:   pw.Text(label,
                style: pw.TextStyle(
                    font:       font,
                    fontSize:   8,
                    fontWeight: pw.FontWeight.bold,
                    color:      _clrLabelFg)),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(value,
                  textAlign: valueAlign,
                  style: pw.TextStyle(
                      font:       font,
                      fontSize:   8,
                      fontWeight: valueBold
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: _clrValueFg)),
            ),
          ),
        ]),
      );

  /// Table header cell (indigo bg, white bold text).
  static pw.Widget _thCell(String text, pw.Font font) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: const pw.BoxDecoration(
          color: _clrHeaderBg,
          border: pw.Border(
            right: pw.BorderSide(color: _clrWhite, width: 0.5),
          ),
        ),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                font:       font,
                fontSize:   8,
                fontWeight: pw.FontWeight.bold,
                color:      _clrWhite)),
      );

  /// Table data cell with alternating background and thin border.
  static pw.Widget _tdCell(
    String       text,
    pw.Font      font,
    PdfColor     bgColor, {
    pw.TextAlign align = pw.TextAlign.left,
  }) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: pw.BoxDecoration(
          color:  bgColor,
          border: pw.Border.all(color: _clrBorder, width: 0.3),
        ),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(
                font: font, fontSize: 8, color: _clrValueFg)),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Exports a generic report to a professionally styled, print-ready A4 PDF.
  ///
  /// Parameters are identical to [ServiceItemExcel.exportReport], so every
  /// report controller can call this with the same assembled data.
  Future<bool> exportReport({
    required String                title,
    required List<String>          headers,
    required List<List<dynamic>>   rows,
    Map<String, String>?           appliedFilters,
    Map<String, dynamic>?          summaryData,
  }) async {
    if (rows.isEmpty && (summaryData == null || summaryData.isEmpty)) {
      Get.snackbar(
        'No Data',
        'No data available to export for $title',
        backgroundColor: Colors.orange,
        colorText:       Colors.white,
        snackPosition:   SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      final font   = await _loadFont();
      final now    = DateTime.now();
      final tsLong = DateFormat('dd-MMM-yyyy   HH:mm:ss').format(now);
      final tsDate = DateFormat('dd-MMM-yyyy').format(now);
      final tsFile = DateFormat('yyyyMMdd_HHmmss').format(now);

      final colCount = headers.length;

      // ── Column flex widths ──────────────────────────────────────────────
      // Give the first column slightly more space; remaining share equally.
      final colWidths = <int, pw.TableColumnWidth>{};
      if (colCount > 0) {
        colWidths[0] = const pw.FlexColumnWidth(2.0);
        for (int c = 1; c < colCount; c++) {
          colWidths[c] = const pw.FlexColumnWidth(1.0);
        }
      }

      // ── Table header row (reused on every page via MultiPage) ───────────
      pw.TableRow buildTableHeaderRow() => pw.TableRow(
            children: List.generate(
                colCount, (c) => _thCell(headers[c], font)),
          );

      // ── Data rows ───────────────────────────────────────────────────────
      final tableRows = rows.asMap().entries.map((entry) {
        final idx = entry.key;
        final row = entry.value;
        final bg  = idx.isEven ? _clrRowEven : _clrWhite;
        return pw.TableRow(
          children: List.generate(colCount, (c) {
            final raw = c < row.length ? row[c] : null;
            return _tdCell(_fmt(raw), font, bg, align: _numAlign(raw));
          }),
        );
      }).toList();

      // ── Filters block ───────────────────────────────────────────────────
      List<pw.Widget> buildFilterRows() {
        if (appliedFilters == null || appliedFilters.isEmpty) return [];
        final fList = appliedFilters.entries.toList();
        final out   = <pw.Widget>[
          _sectionHeader('  APPLIED FILTERS', font),
          pw.SizedBox(height: _smallGap),
        ];
        for (int i = 0; i < fList.length; i += 2) {
          out.add(pw.Row(children: [
            pw.Expanded(
                child: _kvCell(fList[i].key, fList[i].value, font)),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: i + 1 < fList.length
                  ? _kvCell(fList[i + 1].key, fList[i + 1].value, font)
                  : pw.SizedBox(),
            ),
          ]));
          out.add(pw.SizedBox(height: 2));
        }
        out.add(pw.SizedBox(height: _sectionGap));
        return out;
      }

      // ── Summary block ───────────────────────────────────────────────────
      List<pw.Widget> buildSummaryRows() {
        if (summaryData == null || summaryData.isEmpty) return [];
        final sList = summaryData.entries.toList();
        final out   = <pw.Widget>[
          _sectionHeader('  REPORT SUMMARY', font),
          pw.SizedBox(height: _smallGap),
        ];
        for (int i = 0; i < sList.length; i += 2) {
          out.add(pw.Row(children: [
            pw.Expanded(
              child: _kvCell(sList[i].key, _fmt(sList[i].value), font,
                  valueBold: true, valueAlign: pw.TextAlign.right),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: i + 1 < sList.length
                  ? _kvCell(sList[i + 1].key,
                        _fmt(sList[i + 1].value), font,
                        valueBold: true, valueAlign: pw.TextAlign.right)
                  : pw.SizedBox(),
            ),
          ]));
          out.add(pw.SizedBox(height: 2));
        }
        out.add(pw.SizedBox(height: _sectionGap));
        return out;
      }

      // ── Build document ──────────────────────────────────────────────────
      final pdf = pw.Document(
        title:    title,
        creator:  'RH Supermarket POS',
        producer: 'pdf package',
      );

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        theme: pw.ThemeData.withFont(
          base:       font,
          bold:       font,
          italic:     font,
          boldItalic: font,
        ),

        // ── Page header (repeated on every page) ─────────────────────────
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _banner('RH Supermarket', font,
                bg: _clrStoreBg, fg: _clrWhite, fontSize: 14),
            _banner(title, font,
                bg: _clrTitleBg, fg: _clrWhite, fontSize: 11),
            pw.Container(
              width:   double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color:   _clrTimestampBg,
              child:   pw.Text('Generated: $tsLong',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      font:      font,
                      fontSize:  7,
                      fontStyle: pw.FontStyle.italic,
                      color:     _clrLabelFg)),
            ),
            pw.SizedBox(height: _smallGap),
          ],
        ),

        // ── Page footer (branding + page number) ─────────────────────────
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: _clrBorder, thickness: 0.5),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by RH Supermarket POS  •  $tsDate  •  Confidential',
                  style: pw.TextStyle(
                      font:      font,
                      fontSize:  7,
                      fontStyle: pw.FontStyle.italic,
                      color:     _clrLabelFg),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: pw.TextStyle(
                      font: font, fontSize: 7, color: _clrLabelFg),
                ),
              ],
            ),
          ],
        ),

        // ── Page body ────────────────────────────────────────────────────
        build: (_) => [
          ...buildFilterRows(),
          ...buildSummaryRows(),

          // Data table — pw.Table inside MultiPage splits across pages
          // automatically; repeating the header row manually at the top of
          // each split is handled by MultiPage's built-in table support.
          if (rows.isNotEmpty)
            pw.Table(
              columnWidths: colWidths,
              border:       null,
              children: [
                buildTableHeaderRow(),
                ...tableRows,
              ],
            ),

          if (rows.isEmpty && summaryData != null)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Text('No detail rows — see summary above.',
                    style: pw.TextStyle(
                        font: font, fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                        color: _clrLabelFg)),
              ),
            ),
        ],
      ));

      // ── Save ────────────────────────────────────────────────────────────
      final pdfBytes = await pdf.save();

      final safeTitle  = title
          .replaceAll(RegExp(r'[\\/*?:\[\]"<>|]'), '_')
          .replaceAll(' ', '_');
      final fileName = '${safeTitle}_$tsFile.pdf';

      // Desktop → FilePicker save dialog
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle:       'Save Report PDF – $title',
          fileName:          fileName,
          type:              FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (outputPath == null) return true; // user cancelled

        await File(outputPath).writeAsBytes(pdfBytes);
        Get.snackbar(
          'PDF Exported ✅',
          'File saved:\n$outputPath',
          backgroundColor: const Color(0xFF2E7D32),
          colorText:       const Color(0xFFFFFFFF),
          duration:        const Duration(seconds: 6),
          snackPosition:   SnackPosition.BOTTOM,
          isDismissible:   true,
          icon: const Icon(Icons.picture_as_pdf_rounded,
              color: Colors.white, size: 22),
        );
        return true;
      }

      // Mobile → print preview (user can save / share natively from there)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name:     fileName,
        );
        return true;
      }

      // Web / other → share via share_plus
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      // ignore: deprecated_member_use
      await Share.shareXFiles(
          [XFile(file.path)], text: 'RH Supermarket – $title ($tsFile)');
      Get.snackbar(
        'PDF Exported ✅',
        'Report shared successfully.',
        backgroundColor: const Color(0xFF2E7D32),
        colorText:       const Color(0xFFFFFFFF),
        duration:        const Duration(seconds: 4),
        snackPosition:   SnackPosition.BOTTOM,
      );
      return true;
    } catch (e, st) {
      debugPrint('ServiceReportPdf.exportReport error: $e\n$st');
      Get.snackbar(
        'PDF Export Failed ❌',
        'An error occurred: $e',
        backgroundColor: Colors.red.shade700,
        colorText:       Colors.white,
        duration:        const Duration(seconds: 5),
        snackPosition:   SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
