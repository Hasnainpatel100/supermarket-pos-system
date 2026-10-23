import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:get/get.dart';
import '../model/entity_bill.dart';
import '../screens/home/fragment/setting/controller_home_settings.dart';
import 'service_currency.dart';

class ServiceBillPdf {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static Future<pw.Font> _loadRegularFont() async {
    if (_cachedRegularFont != null) return _cachedRegularFont!;
    final fontData = await rootBundle.load('assets/fonts/segoeui.ttf');
    _cachedRegularFont = pw.Font.ttf(fontData.buffer.asByteData());
    return _cachedRegularFont!;
  }

  static Future<pw.Font> _loadBoldFont() async {
    if (_cachedBoldFont != null) return _cachedBoldFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/segoeuib.ttf');
      _cachedBoldFont = pw.Font.ttf(fontData.buffer.asByteData());
      return _cachedBoldFont!;
    } catch (_) {
      return await _loadRegularFont();
    }
  }

  /// Builds a [pw.Document] for the given bill and paper size.
  /// Supported [paperSize] values: '80mm', '58mm', '56mm', 'A4'.
  static Future<pw.Document> buildPdfDocument(
    EntityBill bill,
    ControllerHomeSettings settings, {
    String? paperSize,
  }) async {
    final regularFont = await _loadRegularFont();
    final boldFont = await _loadBoldFont();

    final pdf = pw.Document();
    final String currencySymbol = Get.isRegistered<ServiceCurrency>()
        ? Get.find<ServiceCurrency>().rxCurrency.value
        : '₹';
    final currencyFormat = NumberFormat.decimalPattern();
    final dateFormat = DateFormat('dd/MM/yyyy, hh:mm a');
    final date = bill.createdAtUtcMs != null
        ? DateTime.fromMillisecondsSinceEpoch(
            bill.createdAtUtcMs!,
            isUtc: true,
          ).toLocal()
        : DateTime.now();

    final chosenSize = (paperSize ?? settings.rxPaperSize.value).toLowerCase();

    if (chosenSize == '80mm') {
      _buildThermalReceipt(
        pdf,
        bill,
        settings,
        regularFont,
        boldFont,
        currencySymbol,
        currencyFormat,
        dateFormat,
        date,
        is58mm: false,
      );
    } else if (chosenSize == '58mm' || chosenSize == '56mm' || chosenSize == '57mm') {
      _buildThermalReceipt(
        pdf,
        bill,
        settings,
        regularFont,
        boldFont,
        currencySymbol,
        currencyFormat,
        dateFormat,
        date,
        is58mm: true,
      );
    } else {
      _buildA4Invoice(
        pdf,
        bill,
        settings,
        regularFont,
        boldFont,
        currencySymbol,
        currencyFormat,
        dateFormat,
        date,
      );
    }

    return pdf;
  }

  /// Generate a PDF invoice and return the saved [File].
  static Future<File> generate(
    EntityBill bill,
    ControllerHomeSettings settings, {
    String? paperSize,
  }) async {
    final pdf = await buildPdfDocument(bill, settings, paperSize: paperSize);

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

  // ═══════════════════════════════════════════════════════════════════════════
  // THERMAL RECEIPT LAYOUT (80mm & 58mm / 56mm)
  // ═══════════════════════════════════════════════════════════════════════════

  static void _buildThermalReceipt(
    pw.Document pdf,
    EntityBill bill,
    ControllerHomeSettings settings,
    pw.Font regularFont,
    pw.Font boldFont,
    String currencySymbol,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    DateTime date, {
    required bool is58mm,
  }) {
    final storeName = settings.rxStoreName.value;
    final storeAddress = settings.rxStoreAddress.value;
    final storePhone = settings.rxStorePhone.value;
    final storeGstin = settings.rxStoreGstin.value;

    // Standard 80mm thermal printers have a 72mm (576 dots) physical printhead.
    // Using 70mm page width with 2mm margins guarantees zero text clipping on the right.
    // Standard 58mm thermal printers have a 48mm (384 dots) physical printhead.
    // Using 48mm page width with 1.5mm margins guarantees zero text clipping.
    final pageFormat = is58mm
        ? const PdfPageFormat(
            48 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 1.5 * PdfPageFormat.mm,
            marginRight: 1.5 * PdfPageFormat.mm,
            marginTop: 2 * PdfPageFormat.mm,
            marginBottom: 4 * PdfPageFormat.mm,
          )
        : const PdfPageFormat(
            70 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 2 * PdfPageFormat.mm,
            marginRight: 2 * PdfPageFormat.mm,
            marginTop: 2.5 * PdfPageFormat.mm,
            marginBottom: 4.5 * PdfPageFormat.mm,
          );

    final totalQty = bill.items.fold<int>(
      0,
      (sum, item) => sum + (item.qty ?? 0),
    );

    // Calculate customer total savings (discounts + MRP difference)
    double totalSavings = (bill.discount ?? 0);
    for (final it in bill.items) {
      totalSavings += (it.discount ?? 0);
      if (it.mrp != null && it.price != null && it.mrp! > it.price!) {
        totalSavings += (it.mrp! - it.price!) * (it.qty ?? 1);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          italic: regularFont,
          boldItalic: boldFont,
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Store Header ──
            pw.Center(
              child: pw.Text(
                storeName.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: is58mm ? 11.5 : 13.5,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 1.5),

            // Badge / Subtitle: RETAIL TAX INVOICE
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.6),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Text(
                  'RETAIL TAX INVOICE',
                  style: pw.TextStyle(
                    fontSize: is58mm ? 6.5 : 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ),

            if (storeAddress.isNotEmpty) ...[
              pw.SizedBox(height: 1.5),
              pw.Center(
                child: pw.Text(
                  storeAddress,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: is58mm ? 7 : 8,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
            if (storePhone.isNotEmpty) ...[
              pw.SizedBox(height: 1),
              pw.Center(
                child: pw.Text(
                  'Tel: $storePhone',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: is58mm ? 7 : 8,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
            if (storeGstin.isNotEmpty) ...[
              pw.SizedBox(height: 1),
              pw.Center(
                child: pw.Text(
                  'GSTIN: $storeGstin',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: is58mm ? 7 : 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],

            _doubleDivider(),

            // ── Bill Metadata (Structured Two-Column) ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Bill: ',
                        style: pw.TextStyle(
                          fontSize: is58mm ? 7.5 : 8.5,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.TextSpan(
                        text: '#${bill.billNo ?? "N/A"}',
                        style: pw.TextStyle(
                          fontSize: is58mm ? 8 : 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  dateFormat.format(date),
                  style: pw.TextStyle(
                    fontSize: is58mm ? 7 : 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 1.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Cust: ${bill.customerName?.isNotEmpty == true ? bill.customerName! : "Walk-in"}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      color: PdfColors.black,
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
                if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty)
                  pw.Text(
                    'Mob: ${bill.customerPhone!}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
              ],
            ),

            _divider(dashed: true),

            // ── Items Table Header ──
            pw.Row(
              children: [
                pw.Expanded(
                  flex: is58mm ? 4 : 5,
                  child: pw.Text(
                    'ITEM',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7.5 : 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'QTY x RATE',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'AMOUNT',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7.5 : 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ],
            ),

            _divider(dashed: true),

            // ── Item Rows ──
            ...bill.items.map((item) {
              final rateStr = '$currencySymbol${currencyFormat.format(item.price ?? 0)}';
              final amtStr = '$currencySymbol${currencyFormat.format(item.total ?? 0)}';
              final hasBatch = item.batchNo != null && item.batchNo!.isNotEmpty;
              final hasDisc = (item.discount ?? 0) > 0;
              final hasMrpSavings =
                  item.mrp != null && item.price != null && (item.mrp! > item.price!);

              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: is58mm ? 4 : 5,
                          child: pw.Text(
                            item.itemName ?? '-',
                            style: pw.TextStyle(
                              fontSize: is58mm ? 7.5 : 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            '${item.qty ?? 0} x $rateStr',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: is58mm ? 7 : 8,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            amtStr,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: is58mm ? 7.5 : 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Item Sub-info (Batch, MRP savings, discount)
                    if (hasBatch || hasDisc || hasMrpSavings)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 3, top: 0.5),
                        child: pw.Row(
                          children: [
                            if (hasBatch)
                              pw.Text(
                                '[B: ${item.batchNo}] ',
                                style: pw.TextStyle(
                                  fontSize: is58mm ? 6.5 : 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                            if (hasMrpSavings)
                              pw.Text(
                                'MRP: $currencySymbol${currencyFormat.format(item.mrp)} ',
                                style: pw.TextStyle(
                                  fontSize: is58mm ? 6.5 : 7.5,
                                  color: PdfColors.black,
                                ),
                              ),
                            if (hasDisc)
                              pw.Text(
                                'Disc: -$currencySymbol${currencyFormat.format(item.discount!)}',
                                style: pw.TextStyle(
                                  fontSize: is58mm ? 6.5 : 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),

            _divider(dashed: true),

            // ── Summary Totals ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Items: ${bill.items.length}   |   Qty: $totalQty',
                  style: pw.TextStyle(
                    fontSize: is58mm ? 7 : 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  'Subtotal: $currencySymbol${currencyFormat.format(bill.totalAmount ?? 0)}',
                  style: pw.TextStyle(
                    fontSize: is58mm ? 7.5 : 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            if ((bill.tax ?? 0) > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax / GST:',
                      style: pw.TextStyle(
                        fontSize: is58mm ? 7 : 8,
                        color: PdfColors.black,
                      )),
                  pw.Text(
                    '+ $currencySymbol${currencyFormat.format(bill.tax ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],
            if ((bill.discount ?? 0) > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill Discount:',
                      style: pw.TextStyle(
                        fontSize: is58mm ? 7 : 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      )),
                  pw.Text(
                    '- $currencySymbol${currencyFormat.format(bill.discount ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],
            if (bill.roundOff != null && bill.roundOff!.abs() > 0.001) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Round Off:',
                      style: pw.TextStyle(
                        fontSize: is58mm ? 7 : 8,
                        color: PdfColors.black,
                      )),
                  pw.Text(
                    '${bill.roundOff! >= 0 ? '+' : ''}$currencySymbol${currencyFormat.format(bill.roundOff!)}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],

            // ── Customer Total Savings Badge ──
            if (totalSavings > 0.5) ...[
              pw.SizedBox(height: 2),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '*** YOU SAVED: $currencySymbol${currencyFormat.format(totalSavings)} ***',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7.5 : 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 3),

            // ── Grand Total Highlight Box ──
            pw.Container(
              padding: pw.EdgeInsets.symmetric(
                vertical: is58mm ? 3.5 : 5,
                horizontal: is58mm ? 4 : 6,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1.4),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NET PAYABLE:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: is58mm ? 10 : 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    '$currencySymbol${currencyFormat.format(bill.grandTotal ?? 0)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: is58mm ? 11 : 13.5,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 3),

            // ── Payment Details ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Payment: ${bill.paymentMode?.toUpperCase() ?? "CASH"}',
                  style: pw.TextStyle(
                    fontSize: is58mm ? 7.5 : 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  'Status: ${bill.status ?? "PAID"}',
                  style: pw.TextStyle(
                    fontSize: is58mm ? 7.5 : 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),

            if (bill.paymentMode == 'UPI' &&
                bill.utrNumber != null &&
                bill.utrNumber!.isNotEmpty) ...[
              pw.SizedBox(height: 1),
              pw.Text(
                'UPI Ref / UTR: ${bill.utrNumber}',
                style: pw.TextStyle(
                  fontSize: is58mm ? 7 : 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ],

            if (bill.paymentMode == 'CASH' && (bill.amountReceived ?? 0) > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Tendered: $currencySymbol${currencyFormat.format(bill.amountReceived ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Change: $currencySymbol${currencyFormat.format(bill.changeReturned ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],

            if (bill.paymentMode == 'SPLIT') ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Cash: $currencySymbol${currencyFormat.format(bill.splitCash ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Online: $currencySymbol${currencyFormat.format(bill.splitOnline ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is58mm ? 7 : 8,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],

            _divider(dashed: true),

            // ── Barcode of Bill No ──
            if (bill.billNo != null && bill.billNo!.isNotEmpty) ...[
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: bill.billNo!,
                  width: is58mm ? 120 : 150,
                  height: is58mm ? 24 : 28,
                  drawText: true,
                  color: PdfColors.black,
                  textStyle: pw.TextStyle(
                    fontSize: is58mm ? 6.5 : 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
            ],

            // ── Footer ──
            pw.Center(
              child: pw.Text(
                '*** Thank You! Visit Again ***',
                style: pw.TextStyle(
                  fontSize: is58mm ? 7.5 : 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 1.5),
            pw.Center(
              child: pw.Text(
                'Goods once sold can be exchanged within 7 days with bill',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: is58mm ? 6.5 : 7.5,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Center(
              child: pw.Text(
                'Software: RH POS',
                style: pw.TextStyle(
                  fontSize: is58mm ? 5.5 : 6.5,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  static pw.Widget _divider({bool dashed = true, double thickness = 0.8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Divider(
        thickness: thickness,
        color: PdfColors.black,
        borderStyle: dashed ? pw.BorderStyle.dashed : pw.BorderStyle.solid,
      ),
    );
  }

  static pw.Widget _doubleDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Column(
        children: [
          pw.Divider(thickness: 0.8, color: PdfColors.black),
          pw.SizedBox(height: 1),
          pw.Divider(thickness: 0.8, color: PdfColors.black),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // A4 FULL INVOICE LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════

  static void _buildA4Invoice(
    pw.Document pdf,
    EntityBill bill,
    ControllerHomeSettings settings,
    pw.Font regularFont,
    pw.Font boldFont,
    String currencySymbol,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    DateTime date,
  ) {
    final storeName = settings.rxStoreName.value;
    final storeAddress = settings.rxStoreAddress.value;
    final storePhone = settings.rxStorePhone.value;
    final storeGstin = settings.rxStoreGstin.value;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          italic: regularFont,
          boldItalic: boldFont,
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
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.blue900, thickness: 2),
            pw.SizedBox(height: 16),

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
                    if (bill.customerPhone != null &&
                        bill.customerPhone!.isNotEmpty)
                      pw.Text(
                        bill.customerPhone!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _metaRow('Date:', dateFormat.format(date)),
                    _metaRow('Payment:', bill.paymentMode ?? 'CASH'),
                    if (bill.paymentMode == 'UPI' &&
                        bill.utrNumber != null &&
                        bill.utrNumber!.isNotEmpty)
                      _metaRow('Ref / UTR:', bill.utrNumber!),
                    _metaRow('Status:', bill.status ?? 'PAID'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

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
                      _tableDescCell(
                        itemName: item.itemName ?? '-',
                        sku: item.item.target?.sku,
                        unit: item.unit,
                      ),
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

            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey200),
            pw.SizedBox(height: 10),

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
                      if (bill.roundOff != null && bill.roundOff!.abs() > 0.001)
                        _summaryRow(
                          'Round Off',
                          '${bill.roundOff! >= 0 ? '+' : ''}$currencySymbol${currencyFormat.format(bill.roundOff!)}',
                          color: PdfColors.blueGrey700,
                        ),
                      pw.SizedBox(height: 6),
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
                                fontSize: 13,
                              ),
                            ),
                            pw.Text(
                              '$currencySymbol${currencyFormat.format(bill.grandTotal ?? 0)}',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
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
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'RH POS - System Generated Invoice',
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

  static pw.Widget _tableDescCell({
    required String itemName,
    String? sku,
    String? unit,
  }) {
    final subParts = <String>[];
    if (sku != null && sku.isNotEmpty) subParts.add('SKU: $sku');
    if (unit != null && unit.isNotEmpty) subParts.add(unit);
    final subLine = subParts.join('  |  ');
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            itemName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          if (subLine.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              subLine,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

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
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
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
