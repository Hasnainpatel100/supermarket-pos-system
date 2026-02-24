import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../model/entity_bill.dart';
import '../screens/home/fragment/controller_home_settings.dart';

class ServiceBillPdf {
  /// Generate a thermal-receipt styled PDF and return the saved [File].
  static Future<File> generate(
    EntityBill bill,
    ControllerHomeSettings settings,
  ) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');
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
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Store Header ──
            pw.Center(
              child: pw.Text(
                storeName.toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                storeAddress,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Ph: $storePhone',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            if (storeGstin.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'GSTIN: $storeGstin',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // ── Bill Info ──
            _infoRow('Bill #', bill.billNo?.toString() ?? 'N/A'),
            _infoRow('Date', dateFormat.format(date)),
            _infoRow('Customer', bill.customerName ?? 'Walk-in'),
            if ((bill.paymentMode ?? '').isNotEmpty)
              _infoRow('Payment', bill.paymentMode!),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // ── Items Table ──
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headers: ['Item', 'Qty', 'Rate', 'Amount'],
              data: bill.items
                  .map(
                    (item) => [
                      item.itemName ?? '-',
                      '${item.qty ?? 0}',
                      currencyFormat.format(item.price ?? 0),
                      currencyFormat.format(item.total ?? 0),
                    ],
                  )
                  .toList(),
            ),

            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // ── Totals ──
            _totalRow('Subtotal', currencyFormat.format(bill.totalAmount ?? 0)),
            if ((bill.tax ?? 0) > 0)
              _totalRow('Tax', currencyFormat.format(bill.tax ?? 0)),
            if ((bill.discount ?? 0) > 0)
              _totalRow(
                'Discount',
                '- ${currencyFormat.format(bill.discount ?? 0)}',
              ),

            pw.SizedBox(height: 8),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 8),

            // ── Grand Total ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'GRAND TOTAL',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  currencyFormat.format(bill.grandTotal ?? 0),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for your purchase!',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            if (settings.rxStoreEmail.value.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  settings.rxStoreEmail.value,
                  style: const pw.TextStyle(fontSize: 9),
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

  static pw.Widget _infoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
      ],
    ),
  );

  static pw.Widget _totalRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    ),
  );
}
