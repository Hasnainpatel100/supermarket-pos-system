import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import '../../../screens/home/fragment/setting/controller_home_settings.dart';
import '../../../service/service_currency.dart';
import '../../../util/number_to_words.dart';

enum DocumentType {
  salesInvoice,
  quotation,
  salesReturn,
}

class GstPdfItem {
  final int sNo;
  final String name;
  final String hsn;
  final int qty;
  final String unit;
  final double mrp;
  final double rate;
  final double discount;
  final double taxPercent;
  final double taxAmount;
  final double total;

  GstPdfItem({
    required this.sNo,
    required this.name,
    required this.hsn,
    required this.qty,
    required this.unit,
    required this.mrp,
    required this.rate,
    required this.discount,
    required this.taxPercent,
    required this.taxAmount,
    required this.total,
  });
}

class ServiceGstPdf {
  static Future<pw.Document> generateDocument({
    required DocumentType type,
    required String docNumber,
    required String docDate,
    String? docTime,
    String? dueDate,
    String? validityDate,
    required String partyName,
    String? partyPhone,
    String? partyAddress,
    String? partyGstin,
    required List<GstPdfItem> items,
    required double subtotal,
    required double discount,
    required double taxAmount,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? additionalCharges,
    double? roundOff,
    required double grandTotal,
    double? amountReceived,
    double? balanceDue,
    String? paymentMode,
    String? termsConditions,
    String? notes,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/segoeui.ttf');
    final ttfFont = pw.Font.ttf(fontData.buffer.asByteData());

    final ControllerHomeSettings settings = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>()
        : Get.put(ControllerHomeSettings());

    final storeName = settings.rxStoreName.value.isEmpty ? 'SUPER MARKET' : settings.rxStoreName.value;
    final storeAddress = settings.rxStoreAddress.value;
    final storePhone = settings.rxStorePhone.value;
    final storeEmail = settings.rxStoreEmail.value;
    final storeGstin = settings.rxStoreGstin.value;

    final String currencySymbol = Get.isRegistered<ServiceCurrency>()
        ? Get.find<ServiceCurrency>().rxCurrency.value
        : '₹';
    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

    final title = switch (type) {
      DocumentType.salesInvoice => 'TAX INVOICE',
      DocumentType.quotation => 'QUOTATION / ESTIMATE',
      DocumentType.salesReturn => 'CREDIT NOTE / SALES RETURN',
    };

    final docNumLabel = switch (type) {
      DocumentType.salesInvoice => 'Invoice No.',
      DocumentType.quotation => 'Quotation No.',
      DocumentType.salesReturn => 'Return No.',
    };

    final docDateLabel = switch (type) {
      DocumentType.salesInvoice => 'Invoice Date',
      DocumentType.quotation => 'Quotation Date',
      DocumentType.salesReturn => 'Return Date',
    };

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: ttfFont,
          bold: ttfFont,
        ),
        build: (pw.Context context) {
          return [
            // ── Top Header / Company Details ──
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                storeName.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.indigo900,
                                ),
                              ),
                              if (storeAddress.isNotEmpty)
                                pw.Text(
                                  storeAddress,
                                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                                ),
                              pw.SizedBox(height: 3),
                              if (storeGstin.isNotEmpty)
                                pw.Text(
                                  'GSTIN: $storeGstin',
                                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                                ),
                              if (storePhone.isNotEmpty)
                                pw.Text(
                                  'Mobile: $storePhone | Email: $storeEmail',
                                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                                ),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                title,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.indigo800,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text('$docNumLabel: $docNumber', style: const pw.TextStyle(fontSize: 9)),
                              pw.Text('$docDateLabel: $docDate', style: const pw.TextStyle(fontSize: 9)),
                              if (docTime != null && docTime.isNotEmpty)
                                pw.Text('Time: $docTime', style: const pw.TextStyle(fontSize: 9)),
                              if (dueDate != null && dueDate.isNotEmpty)
                                pw.Text('Due Date: $dueDate', style: const pw.TextStyle(fontSize: 9)),
                              if (validityDate != null && validityDate.isNotEmpty)
                                pw.Text('Valid Until: $validityDate', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.Divider(height: 1, color: PdfColors.grey400),

                  // ── Bill To / Party Details ──
                  pw.Container(
                    color: PdfColors.grey50,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'BILL TO / PARTY DETAILS:',
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                partyName.isEmpty ? 'Cash Sale' : partyName,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (partyAddress != null && partyAddress.isNotEmpty)
                                pw.Text('Address: $partyAddress', style: const pw.TextStyle(fontSize: 8.5)),
                              if (partyPhone != null && partyPhone.isNotEmpty)
                                pw.Text('Phone: $partyPhone', style: const pw.TextStyle(fontSize: 8.5)),
                              if (partyGstin != null && partyGstin.isNotEmpty)
                                pw.Text('GSTIN: $partyGstin', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Items Table ──
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(28),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FixedColumnWidth(55),
                      3: const pw.FixedColumnWidth(40),
                      4: const pw.FixedColumnWidth(55),
                      5: const pw.FixedColumnWidth(45),
                      6: const pw.FixedColumnWidth(45),
                      7: const pw.FixedColumnWidth(65),
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _tableCell('S.N', isHeader: true, align: pw.TextAlign.center),
                          _tableCell('ITEMS / DESCRIPTION', isHeader: true),
                          _tableCell('HSN/SAC', isHeader: true, align: pw.TextAlign.center),
                          _tableCell('QTY', isHeader: true, align: pw.TextAlign.center),
                          _tableCell('RATE ($currencySymbol)', isHeader: true, align: pw.TextAlign.right),
                          _tableCell('DISC ($currencySymbol)', isHeader: true, align: pw.TextAlign.right),
                          _tableCell('TAX (%)', isHeader: true, align: pw.TextAlign.right),
                          _tableCell('AMOUNT ($currencySymbol)', isHeader: true, align: pw.TextAlign.right),
                        ],
                      ),
                      ...items.map(
                        (item) => pw.TableRow(
                          children: [
                            _tableCell('${item.sNo}', align: pw.TextAlign.center),
                            _tableCell(item.name),
                            _tableCell(item.hsn.isEmpty ? '-' : item.hsn, align: pw.TextAlign.center),
                            _tableCell('${item.qty} ${item.unit}', align: pw.TextAlign.center),
                            _tableCell(currencyFormat.format(item.rate), align: pw.TextAlign.right),
                            _tableCell(item.discount > 0 ? currencyFormat.format(item.discount) : '-', align: pw.TextAlign.right),
                            _tableCell(item.taxPercent > 0 ? '${item.taxPercent.toStringAsFixed(1)}%' : '-', align: pw.TextAlign.right),
                            _tableCell(currencyFormat.format(item.total), align: pw.TextAlign.right, isBold: true),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Tax & Totals Summary ──
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left: Amount in words + Bank info + Notes
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Total Amount in Words:',
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                              ),
                              pw.Text(
                                NumberToWords.convert(grandTotal),
                                style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                              ),
                              pw.SizedBox(height: 10),
                              if (notes != null && notes.isNotEmpty) ...[
                                pw.Text('Notes: $notes', style: const pw.TextStyle(fontSize: 8)),
                                pw.SizedBox(height: 4),
                              ],
                              if (termsConditions != null && termsConditions.isNotEmpty) ...[
                                pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                pw.Text(termsConditions, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                              ],
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        // Right: Calculation Breakdown
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            children: [
                              _calcRow('Subtotal', '$currencySymbol ${currencyFormat.format(subtotal)}'),
                              if (discount > 0)
                                _calcRow('Discount (-)', '$currencySymbol ${currencyFormat.format(discount)}'),
                              if (taxAmount > 0) ...[
                                if (cgstAmount != null && cgstAmount > 0)
                                  _calcRow('CGST', '$currencySymbol ${NumberFormat('#,##0.0').format(cgstAmount)}'),
                                if (sgstAmount != null && sgstAmount > 0)
                                  _calcRow('SGST', '$currencySymbol ${NumberFormat('#,##0.0').format(sgstAmount)}'),
                                if (igstAmount != null && igstAmount > 0)
                                  _calcRow('IGST', '$currencySymbol ${currencyFormat.format(igstAmount)}'),
                                if ((cgstAmount == null || cgstAmount == 0) && (sgstAmount == null || sgstAmount == 0))
                                  _calcRow('Tax (+)', '$currencySymbol ${currencyFormat.format(taxAmount)}'),
                              ],
                              if (additionalCharges != null && additionalCharges > 0)
                                _calcRow('Additional Charges (+)', '$currencySymbol ${currencyFormat.format(additionalCharges)}'),
                              if (roundOff != null && roundOff != 0)
                                _calcRow('Round Off', '$currencySymbol ${currencyFormat.format(roundOff)}'),
                              pw.Divider(height: 6, color: PdfColors.grey400),
                              _calcRow(
                                'Grand Total',
                                '$currencySymbol ${currencyFormat.format(grandTotal)}',
                                isGrand: true,
                              ),
                              if (amountReceived != null && amountReceived > 0)
                                _calcRow('Amount Received', '$currencySymbol ${currencyFormat.format(amountReceived)}'),
                              if (balanceDue != null && balanceDue > 0)
                                _calcRow(
                                  'Balance Due',
                                  '$currencySymbol ${currencyFormat.format(balanceDue)}',
                                  isDue: true,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.Divider(height: 1, color: PdfColors.grey400),

                  // ── Footer / Signature ──
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Thank you for your business!',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'For $storeName',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 24),
                            pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.indigo900 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _calcRow(String label, String value, {bool isGrand = false, bool isDue = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isGrand ? 10 : 8.5,
              fontWeight: isGrand ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDue ? PdfColors.red700 : PdfColors.black,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isGrand ? 11 : 8.5,
              fontWeight: isGrand || isDue ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDue ? PdfColors.red700 : (isGrand ? PdfColors.indigo900 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> saveAndGetFile(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> printDocument(pw.Document pdf) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
