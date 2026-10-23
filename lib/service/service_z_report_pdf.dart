import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import 'service_currency.dart';

/// Generates and prints professional End-of-Day Register Z-Reports and Shift Closing X-Reports.
/// Designed specifically for standard 80mm/58mm POS thermal receipt printers and A4 audit archives.
class ServiceZReportPdf {
  static pw.Font? _cachedFont;

  static Future<pw.Font> _loadFont() async {
    if (_cachedFont != null) return _cachedFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/segoeui.ttf');
      _cachedFont = pw.Font.ttf(fontData.buffer.asByteData());
    } catch (_) {
      _cachedFont = pw.Font.helvetica();
    }
    return _cachedFont!;
  }

  /// Print or show print preview dialog for the Z-Report
  static Future<void> printZReport({
    required String reportType, // 'DAILY Z-REPORT' or 'SHIFT X-REPORT'
    required String storeName,
    String? branchName,
    String? terminalId,
    required String cashierName,
    required DateTime startTime,
    required DateTime endTime,
    required double openingCash,
    required double salesCash,
    required Map<String, double> paymentModes,
    required double cashIn,
    required double cashOut,
    required double expensesCash,
    required double expectedClosingCash,
    required double physicalCountedCash,
    Map<int, int>? denominations,
    int fulfilledOrders = 0,
    int cancelledOrders = 0,
    int complimentaryOrders = 0,
    String? comments,
  }) async {
    final ttfFont = await _loadFont();
    final pdf = pw.Document();

    final currencySymbol = Get.isRegistered<ServiceCurrency>()
        ? Get.find<ServiceCurrency>().rxCurrency.value
        : '₹';
    final fmtNum = NumberFormat('#,##0.00');
    final fmtDate = DateFormat('dd/MM/yyyy hh:mm a');

    final variance = physicalCountedCash - expectedClosingCash;
    final totalSales = paymentModes.values.fold(0.0, (sum, val) => sum + val);

    // Standard 80mm thermal printers have 72mm printable width.
    const pageFormat = PdfPageFormat(
      70 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 2 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(font: ttfFont, fontSize: 9),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                pw.Center(
                  child: pw.Text(
                    storeName.toUpperCase(),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                if (branchName != null && branchName.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Center(
                    child: pw.Text(
                      'Branch: $branchName',
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  ),
                ],
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Text(
                      reportType,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                _divider(),

                // ── Session Meta ──
                _row('Terminal / Register:', terminalId ?? 'POS-01'),
                _row('Cashier / User:', cashierName),
                _row('Session Opened:', fmtDate.format(startTime)),
                _row('Session Closed:', fmtDate.format(endTime)),
                _divider(),

                // ── Sales Summary ──
                pw.Text(
                  'SALES BREAKDOWN',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                ),
                pw.SizedBox(height: 3),
                ...paymentModes.entries.map((e) => _row(
                      '  ${e.key} Sales:',
                      '$currencySymbol ${fmtNum.format(e.value)}',
                    )),
                _divider(dotted: true),
                _row(
                  'TOTAL GROSS SALES:',
                  '$currencySymbol ${fmtNum.format(totalSales)}',
                  bold: true,
                ),
                _divider(),

                // ── Cash Flow & Drawer Audit ──
                pw.Text(
                  'CASH DRAWER RECONCILIATION',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                ),
                pw.SizedBox(height: 3),
                _row('(+) Opening Cash Float:', '$currencySymbol ${fmtNum.format(openingCash)}'),
                _row('(+) Cash Sales Received:', '$currencySymbol ${fmtNum.format(salesCash)}'),
                _row('(+) Cash In (Paid In):', '$currencySymbol ${fmtNum.format(cashIn)}'),
                _row('(-) Cash Out (Paid Out):', '$currencySymbol ${fmtNum.format(cashOut)}'),
                _row('(-) Shift Expenses:', '$currencySymbol ${fmtNum.format(expensesCash)}'),
                _divider(dotted: true),
                _row(
                  'EXPECTED DRAWER CASH:',
                  '$currencySymbol ${fmtNum.format(expectedClosingCash)}',
                  bold: true,
                ),
                _row(
                  'ACTUAL COUNTED CASH:',
                  '$currencySymbol ${fmtNum.format(physicalCountedCash)}',
                  bold: true,
                ),
                _divider(dotted: true),

                // ── Variance Alert ──
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: pw.BoxDecoration(
                    color: variance == 0
                        ? PdfColors.grey200
                        : (variance > 0 ? PdfColors.blue50 : PdfColors.red50),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        variance == 0
                            ? 'STATUS: BALANCED'
                            : (variance > 0 ? 'CASH OVERAGE (+):' : 'CASH SHORTAGE (-):'),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: variance < 0 ? PdfColors.red900 : PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        '$currencySymbol ${fmtNum.format(variance.abs())}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: variance < 0 ? PdfColors.red900 : PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                _divider(),

                // ── Denominations breakdown (if counted) ──
                if (denominations != null && denominations.values.any((c) => c > 0)) ...[
                  pw.Text(
                    'PHYSICAL CASH COUNT DETAILS',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                  ),
                  pw.SizedBox(height: 3),
                  ...denominations.entries.where((e) => e.value > 0).map((e) => _row(
                        '  $currencySymbol${e.key} x ${e.value}:',
                        '$currencySymbol ${fmtNum.format(e.key * e.value)}',
                      )),
                  _divider(),
                ],

                // ── Transaction counts ──
                pw.Text(
                  'ORDER STATISTICS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                ),
                pw.SizedBox(height: 3),
                _row('Fulfilled Orders:', '$fulfilledOrders'),
                _row('Cancelled Orders:', '$cancelledOrders'),
                _row('Complimentary Orders:', '$complimentaryOrders'),
                if (comments != null && comments.isNotEmpty) ...[
                  _divider(dotted: true),
                  pw.Text(
                    'Notes / Remarks:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
                  ),
                  pw.Text(comments, style: const pw.TextStyle(fontSize: 8)),
                ],
                _divider(),

                // ── Signatures ──
                pw.SizedBox(height: 14),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 80, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 2),
                        pw.Text('Cashier Signature', style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 80, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 2),
                        pw.Text('Manager Signature', style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    '-- END OF REGISTER AUDIT REPORT --',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${reportType.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: bold ? 9.5 : 8.5,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: bold ? 9.5 : 8.5,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _divider({bool dotted = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Container(
        height: 0.8,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(
              color: PdfColors.grey500,
              width: 0.8,
              style: dotted ? pw.BorderStyle.dashed : pw.BorderStyle.solid,
            ),
          ),
        ),
      ),
    );
  }
}
