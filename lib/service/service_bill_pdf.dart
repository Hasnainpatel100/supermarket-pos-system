import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:get/get.dart';
import '../model/entity_bill.dart';
import '../screens/home/fragment/controller_home_settings.dart';
import 'service_currency.dart';

class ServiceBillPdf {
  /// Generate a professional and modern PDF invoice and return the saved [File].
  static Future<File> generate(
    EntityBill bill,
    ControllerHomeSettings settings,
  ) async {
    // Load a Unicode-capable font so ₹ and other symbols render correctly
    final fontData = await rootBundle.load('assets/fonts/segoeui.ttf');
    final ttfFont = pw.Font.ttf(fontData.buffer.asByteData());

    final pdf = pw.Document();
    final String currencySymbol = Get.find<ServiceCurrency>().rxCurrency.value;
    final currencyFormat = NumberFormat.decimalPattern();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final date = bill.createdAtUtcMs != null
        ? DateTime.fromMillisecondsSinceEpoch(
            bill.createdAtUtcMs!,
            isUtc: true,
          ).toLocal()
        : DateTime.now();

    final storeName = settings.rxStoreName.value;
    final storeAddress = settings.rxStoreAddress.value;
    final storePhone = settings.rxStorePhone.value;
    final storeGstin = settings.rxStoreGstin.value;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: ttfFont,
          bold: ttfFont,
          italic: ttfFont,
          boldItalic: ttfFont,
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Header Section ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      storeName.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 24,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      storeAddress,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Phone: $storePhone',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    if (storeGstin.isNotEmpty)
                      pw.Text(
                        'GSTIN: $storeGstin',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey400,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '#${bill.billNo ?? "N/A"}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Divider(color: PdfColors.blue900, thickness: 2),
            pw.SizedBox(height: 20),

            // ── Bill Information ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL TO:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      bill.customerName ?? 'Walk-in Customer',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      bill.customerPhone ?? '',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _metaRow('Date:', dateFormat.format(date)),
                    _metaRow('Payment:', bill.paymentMode ?? 'CASH'),
                    _metaRow('Status:', bill.status ?? 'PAID'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // ── Items Table ──
            pw.Table(
              border: null,
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _tableHeader('Item Description'),
                    _tableHeader('Qty', align: pw.TextAlign.center),
                    _tableHeader('Rate', align: pw.TextAlign.right),
                    _tableHeader('Amount', align: pw.TextAlign.right),
                  ],
                ),
                // Table Body
                ...bill.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i.isEven ? PdfColors.white : PdfColors.grey100,
                    ),
                    children: [
                      _tableCell(item.itemName ?? '-'),
                      _tableCell(
                        '${item.qty ?? 0}',
                        align: pw.TextAlign.center,
                      ),
                      _tableCell(
                        '$currencySymbol${currencyFormat.format(item.price ?? 0)}',
                        align: pw.TextAlign.right,
                      ),
                      _tableCell(
                        '$currencySymbol${currencyFormat.format(item.total ?? 0)}',
                        align: pw.TextAlign.right,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey200),
            pw.SizedBox(height: 12),

            // ── Totals Section ──
            pw.Row(
              children: [
                pw.Spacer(flex: 2),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    children: [
                      _summaryRow(
                        'Subtotal',
                        '$currencySymbol${currencyFormat.format(bill.totalAmount ?? 0)}',
                      ),
                      if ((bill.tax ?? 0) > 0)
                        _summaryRow(
                          'Tax',
                          '$currencySymbol${currencyFormat.format(bill.tax ?? 0)}',
                        ),
                      if ((bill.discount ?? 0) > 0)
                        _summaryRow(
                          'Discount',
                          '- $currencySymbol${currencyFormat.format(bill.discount ?? 0)}',
                          color: PdfColors.red900,
                        ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            pw.Text(
                              '$currencySymbol${currencyFormat.format(bill.grandTotal ?? 0)}',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),

            // ── Footer ──
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'SuperMarket POS - System Generated Invoice',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final billDir = Directory('${dir.path}/SuperMarketBills');
    if (!await billDir.exists()) {
      await billDir.create(recursive: true);
    }
    final path =
        '${billDir.path}/Bill_${bill.billNo ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _metaRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
      ],
    ),
  );

  static pw.Widget _tableHeader(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
        color: PdfColors.white,
      ),
    ),
  );

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      textAlign: align,
      style: const pw.TextStyle(fontSize: 10),
    ),
  );

  static pw.Widget _summaryRow(String label, String value, {PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
}
