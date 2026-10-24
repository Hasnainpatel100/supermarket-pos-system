import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:get/get.dart';
import '../model/entity_bill.dart';
import '../model/entity_bill_item.dart';
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

  /// Formats CGST / SGST and GST breakup tax amounts with strictly 1 decimal digit (e.g. 24.5).
  static String formatGstOneDecimal(double val) {
    return NumberFormat('#,##0.0').format(val);
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
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy, hh:mm a');
    final date = bill.createdAtUtcMs != null
        ? DateTime.fromMillisecondsSinceEpoch(
            bill.createdAtUtcMs!,
            isUtc: true,
          ).toLocal()
        : DateTime.now();

    final defaultPaperSize = settings.rxThermalPaperSize.value.isNotEmpty
        ? settings.rxThermalPaperSize.value
        : '80mm';
    final chosenSize = (paperSize ?? defaultPaperSize).toLowerCase();

    if (chosenSize == 'a4') {
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
    } else {
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
        paperSize: chosenSize,
      );
    }

    return pdf;
  }

  /// Build and return the raw PDF bytes without writing to disk.
  static Future<Uint8List> generateBytes(
    EntityBill bill,
    ControllerHomeSettings settings, {
    String? paperSize,
  }) async {
    final pdf = await buildPdfDocument(bill, settings, paperSize: paperSize);
    return await pdf.save();
  }

  /// Generate a PDF invoice and return the saved [File].
  static Future<File> generate(
    EntityBill bill,
    ControllerHomeSettings settings, {
    String? paperSize,
  }) async {
    final bytes = await generateBytes(bill, settings, paperSize: paperSize);

    final dir = await getApplicationDocumentsDirectory();
    final billDir = Directory('${dir.path}/SuperMarketBills');
    if (!await billDir.exists()) {
      await billDir.create(recursive: true);
    }
    final rawNo = bill.billNo?.trim();
    final safeNo = (rawNo != null && rawNo.isNotEmpty)
        ? rawNo.replaceAll(RegExp(r'[\\/:*?"<>|\s]'), '_')
        : '${DateTime.now().millisecondsSinceEpoch}';
    final path = '${billDir.path}/Bill_$safeNo.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
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
    String paperSize = '80mm',
    bool? is58mm,
  }) {
    final storeName = settings.rxStoreName.value;
    final storeAddress = settings.rxStoreAddress.value;
    final storeGstin = settings.rxStoreGstin.value;

    final sizeKey = paperSize.toLowerCase();
    final bool is56mm = sizeKey == '56mm' || sizeKey.contains('56');
    final bool is58mmEffective = !is56mm && (sizeKey == '58mm' || sizeKey == '57mm' || sizeKey.contains('58') || (is58mm ?? false));
    final bool isCompact = is56mm || is58mmEffective;
    final bool showTaxInItemList = settings.rxShowTaxInItemList.value;
    final bool showGstBreakup = settings.rxShowGstBreakup.value;
    final bool showBillBarcode = settings.rxShowBillBarcode.value;
    final String billTerms = settings.rxBillTerms.value.trim();
    final String billFooterTagline = settings.rxBillFooterTagline.value.trim();

    // Precise pageFormat for each thermal roll width:
    // 56mm paper roll: 56.0mm physical width (~158.7pt), with 1.5mm margins => 53mm (~150.2pt) printable width.
    // 58mm paper roll: 58.0mm physical width (~164.4pt), with 2.0mm margins => 54mm (~153.1pt) printable width.
    // 80mm paper roll: 72.0mm standard printhead width (~204.1pt), with 2.0mm margins => 68mm (~192.8pt) printable width.
    final pageFormat = is56mm
        ? const PdfPageFormat(
            56.0 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 1.5 * PdfPageFormat.mm,
            marginRight: 1.5 * PdfPageFormat.mm,
            marginTop: 2.0 * PdfPageFormat.mm,
            marginBottom: 4.0 * PdfPageFormat.mm,
          )
        : (is58mmEffective
            ? const PdfPageFormat(
                58.0 * PdfPageFormat.mm,
                double.infinity,
                marginLeft: 2.0 * PdfPageFormat.mm,
                marginRight: 2.0 * PdfPageFormat.mm,
                marginTop: 2.0 * PdfPageFormat.mm,
                marginBottom: 4.0 * PdfPageFormat.mm,
              )
            : const PdfPageFormat(
                72.0 * PdfPageFormat.mm,
                double.infinity,
                marginLeft: 2.0 * PdfPageFormat.mm,
                marginRight: 2.0 * PdfPageFormat.mm,
                marginTop: 2.5 * PdfPageFormat.mm,
                marginBottom: 4.5 * PdfPageFormat.mm,
              ));

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
                  fontSize: is56mm ? 10.5 : (is58mmEffective ? 11.5 : 13.5),
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
                    fontSize: is56mm ? 6.2 : (is58mmEffective ? 6.5 : 7.5),
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
                    fontSize: is56mm ? 6.5 : (is58mmEffective ? 7.0 : 8.0),
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
                    fontSize: is56mm ? 6.5 : (is58mmEffective ? 7.0 : 8.0),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],

            _doubleDivider(),

            // ── Bill Metadata (Structured to display Date & Time in front of Customer Name) ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Bill: ',
                          style: pw.TextStyle(
                            fontSize: is56mm ? 7.2 : (is58mmEffective ? 7.5 : 8.5),
                            color: PdfColors.black,
                          ),
                        ),
                        pw.TextSpan(
                          text: '#${bill.billNo ?? "N/A"}',
                          style: pw.TextStyle(
                            fontSize: is56mm ? 7.5 : (is58mmEffective ? 8.0 : 9.0),
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 1.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Cust: ${bill.customerName?.isNotEmpty == true ? bill.customerName! : "Walk-in"}',
                    style: pw.TextStyle(
                      fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                      color: PdfColors.black,
                    ),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  isCompact
                      ? DateFormat('dd/MM/yy, hh:mm a').format(date)
                      : dateFormat.format(date),
                  style: pw.TextStyle(
                    fontSize: is56mm ? 6.5 : (is58mmEffective ? 7.0 : 8.0),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),

            _divider(dashed: true),

            if (isCompact) ...[
              // ── 56mm / 58mm Compact Table Header ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ITEM / DETAILS',
                    style: pw.TextStyle(
                      fontSize: is56mm ? 7.0 : 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'AMOUNT',
                    style: pw.TextStyle(
                      fontSize: is56mm ? 7.0 : 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
              _divider(dashed: true),

              // ── 56mm / 58mm Clean Compact Item Rows (Line 1: Name, Line 2: Qty x Rate + Tax & Amt) ──
              ...bill.items.map((item) {
                final rateStr = '$currencySymbol${currencyFormat.format(item.price ?? 0)}';
                final amtStr = '$currencySymbol${currencyFormat.format(item.total ?? 0)}';
                final itemName = item.itemName ?? '-';
                // Prevent duplicate batch display if already embedded in itemName
                final alreadyHasBatch = itemName.contains('[B:') || itemName.contains('(Batch:');
                final showBatchTag = !alreadyHasBatch && item.batchNo != null && item.batchNo!.trim().isNotEmpty;
                // Only show tax tag in item list if enabled in settings (standard restaurant bills omit it)
                final hasTaxTag = showTaxInItemList && (item.taxRate ?? 0) > 0;
                final hasDisc = (item.discount ?? 0) > 0;
                final hasMrpSavings =
                    item.mrp != null && item.price != null && (item.mrp! > item.price!);

                return pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: is56mm ? 1.5 : 2.0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Item Name (bold, full-width)
                      pw.Text(
                        itemName,
                        style: pw.TextStyle(
                          fontSize: is56mm ? 7.5 : 8.0,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        maxLines: 2,
                      ),
                      pw.SizedBox(height: 1),
                      // Line 2: Qty x Rate [B: batch] [GST %] (Left) and Amount (Right)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${item.qty ?? 0} x $rateStr'
                              '${showBatchTag ? " [B: ${item.batchNo}]" : ""}'
                              '${hasTaxTag ? " [GST ${(item.taxRate! % 1 == 0 ? item.taxRate!.toInt() : item.taxRate)}%]" : ""}',
                              style: pw.TextStyle(
                                fontSize: is56mm ? 6.5 : 7.0,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Text(
                            amtStr,
                            style: pw.TextStyle(
                              fontSize: is56mm ? 7.5 : 8.0,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                      if (hasDisc || hasMrpSavings)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 0.5),
                          child: pw.Text(
                            '${hasMrpSavings ? "MRP: $currencySymbol${currencyFormat.format(item.mrp)} " : ""}'
                            '${hasDisc ? "Disc: -$currencySymbol${currencyFormat.format(item.discount!)}" : ""}',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.0 : 6.5,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // ── 80mm Standard Items Table Header ──
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      'ITEM',
                      style: pw.TextStyle(
                        fontSize: 8.5,
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
                        fontSize: 8,
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
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              _divider(dashed: true),

              // ── 80mm Item Rows ──
              ...bill.items.map((item) {
                final rateStr = '$currencySymbol${currencyFormat.format(item.price ?? 0)}';
                final amtStr = '$currencySymbol${currencyFormat.format(item.total ?? 0)}';
                final itemName = item.itemName ?? '-';
                final alreadyHasBatch = itemName.contains('[B:') || itemName.contains('(Batch:');
                final showBatchTag = !alreadyHasBatch && item.batchNo != null && item.batchNo!.trim().isNotEmpty;
                final hasTaxTag = showTaxInItemList && (item.taxRate ?? 0) > 0;
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
                            flex: 5,
                            child: pw.Text(
                              itemName,
                              style: pw.TextStyle(
                                fontSize: 8.5,
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
                              style: const pw.TextStyle(
                                fontSize: 8,
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
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (showBatchTag || hasTaxTag || hasDisc || hasMrpSavings)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 3, top: 0.5),
                          child: pw.Row(
                            children: [
                              if (showBatchTag)
                                pw.Text(
                                  '[B: ${item.batchNo}] ',
                                  style: pw.TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                              if (hasTaxTag)
                                pw.Text(
                                  '[GST ${(item.taxRate! % 1 == 0 ? item.taxRate!.toInt() : item.taxRate)}%] ',
                                  style: pw.TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                              if (hasMrpSavings)
                                pw.Text(
                                  'MRP: $currencySymbol${currencyFormat.format(item.mrp)} ',
                                  style: const pw.TextStyle(
                                    fontSize: 7.5,
                                    color: PdfColors.black,
                                  ),
                                ),
                              if (hasDisc)
                                pw.Text(
                                  'Disc: -$currencySymbol${currencyFormat.format(item.discount!)}',
                                  style: pw.TextStyle(
                                    fontSize: 7.5,
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
            ],

            _divider(dashed: true),

            // ── Items & Qty Summary Row ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Items: ${bill.items.length}',
                  style: pw.TextStyle(
                    fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  'Total Qty: $totalQty',
                  style: pw.TextStyle(
                    fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 1.5),

            // ── Subtotal Row (Separated onto its own line to prevent collision on 56mm) ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Subtotal:',
                  style: pw.TextStyle(
                    fontSize: is56mm ? 7.5 : (is58mmEffective ? 8.0 : 8.5),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  '$currencySymbol${currencyFormat.format(bill.totalAmount ?? 0)}',
                  style: pw.TextStyle(
                    fontSize: is56mm ? 7.5 : (is58mmEffective ? 8.0 : 8.5),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),

            // ── Standard Restaurant Tax Breakdown (CGST & SGST) ──
            () {
              final gstRows = _calculateGstBreakup(bill);
              final double totalCgst = double.parse(
                gstRows.fold<double>(0, (sum, r) => sum + r.cgst).toStringAsFixed(2),
              );
              final double totalSgst = double.parse(
                gstRows.fold<double>(0, (sum, r) => sum + r.sgst).toStringAsFixed(2),
              );
              final double totalTax = totalCgst + totalSgst;

              if (totalTax > 0) {
                if (gstRows.length == 1 && gstRows.first.rate > 0) {
                  final halfRate = gstRows.first.rate / 2;
                  final rateStr = halfRate % 1 == 0 ? '${halfRate.toInt()}%' : '$halfRate%';
                  return pw.Column(
                    children: [
                      pw.SizedBox(height: 1),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'CGST ($rateStr):',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            '$currencySymbol${formatGstOneDecimal(totalCgst)}',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 0.5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'SGST ($rateStr):',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            '$currencySymbol${formatGstOneDecimal(totalSgst)}',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return pw.Column(
                    children: [
                      pw.SizedBox(height: 1),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'CGST:',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            '$currencySymbol${formatGstOneDecimal(totalCgst)}',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 0.5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'SGST:',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            '$currencySymbol${formatGstOneDecimal(totalSgst)}',
                            style: pw.TextStyle(
                              fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              } else {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'GST / Tax (0%):',
                        style: pw.TextStyle(
                          fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        '$currencySymbol 0.00',
                        style: pw.TextStyle(
                          fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }
            }(),

            if ((bill.discount ?? 0) > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill Discount:',
                      style: pw.TextStyle(
                        fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      )),
                  pw.Text(
                    '- $currencySymbol${currencyFormat.format(bill.discount ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
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
                        fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
                        color: PdfColors.black,
                      )),
                  pw.Text(
                    '${bill.roundOff! >= 0 ? '+' : ''}$currencySymbol${currencyFormat.format(bill.roundOff!)}',
                    style: pw.TextStyle(
                      fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.0 : 8.0),
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
                      fontSize: is56mm ? 6.8 : (is58mmEffective ? 7.5 : 8.5),
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 2.5),

            // ── Grand Total Highlight Box ──
            pw.Container(
              padding: pw.EdgeInsets.symmetric(
                vertical: is56mm ? 3.0 : (is58mmEffective ? 3.5 : 5.0),
                horizontal: is56mm ? 3.0 : (is58mmEffective ? 4.0 : 6.0),
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1.2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NET PAYABLE:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: is56mm ? 9.0 : (is58mmEffective ? 10.0 : 12.0),
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    '$currencySymbol${currencyFormat.format(bill.grandTotal ?? 0)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: is56mm ? 10.0 : (is58mmEffective ? 11.0 : 13.5),
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),

            // ── GST Breakup Details Table (Configurable via Settings) ──
            if (showGstBreakup) ...[
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  isCompact ? '<--- GST Breakup (INR) --->' : '<------- GST Breakup Details -------> (Amount INR)',
                  style: pw.TextStyle(
                    fontSize: is56mm ? 6.2 : (is58mmEffective ? 6.5 : 7.5),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              _divider(dashed: true),

              if (isCompact) ...[
                // 56mm / 58mm compact GST header
                pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text('GST', style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 3, child: pw.Text('Taxable', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 2, child: pw.Text('CGST', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 2, child: pw.Text('SGST', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 3, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                  ],
                ),
                _divider(dashed: true),
                ..._calculateGstBreakup(bill).map((r) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 2, child: pw.Text('${r.rate % 1 == 0 ? r.rate.toInt() : r.rate}%', style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, color: PdfColors.black))),
                      pw.Expanded(flex: 3, child: pw.Text(currencyFormat.format(r.taxableAmount), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, color: PdfColors.black))),
                      pw.Expanded(flex: 2, child: pw.Text(formatGstOneDecimal(r.cgst), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, color: PdfColors.black))),
                      pw.Expanded(flex: 2, child: pw.Text(formatGstOneDecimal(r.sgst), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, color: PdfColors.black))),
                      pw.Expanded(flex: 3, child: pw.Text(currencyFormat.format(r.total), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: is56mm ? 6.0 : 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    ],
                  ),
                )),
              ] else ...[
                // 80mm GST header
                pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text('GST IND', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 3, child: pw.Text('Taxable Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 2, child: pw.Text('CGST', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 2, child: pw.Text('SGST', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 2, child: pw.Text('CESS', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.Expanded(flex: 3, child: pw.Text('Total Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                  ],
                ),
                _divider(dashed: true),
                ..._calculateGstBreakup(bill).map((r) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 2, child: pw.Text('${r.index} (${r.rate % 1 == 0 ? r.rate.toInt() : r.rate}%)', style: const pw.TextStyle(fontSize: 7, color: PdfColors.black))),
                      pw.Expanded(flex: 3, child: pw.Text(currencyFormat.format(r.taxableAmount), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7, color: PdfColors.black))),
                      pw.Expanded(flex: 2, child: pw.Text(formatGstOneDecimal(r.cgst), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7, color: PdfColors.black))),
                      pw.Expanded(flex: 2, child: pw.Text(formatGstOneDecimal(r.sgst), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7, color: PdfColors.black))),
                      pw.Expanded(flex: 2, child: pw.Text(r.cess > 0 ? currencyFormat.format(r.cess) : '...', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7, color: PdfColors.black))),
                      pw.Expanded(flex: 3, child: pw.Text(currencyFormat.format(r.total), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    ],
                  ),
                )),
              ],

              _divider(dashed: true),
            ],

            // ── Amount Received / Payment Details ──
            pw.Center(
              child: pw.Text(
                '<----- Payment Details ----->',
                style: pw.TextStyle(
                  fontSize: is56mm ? 6.2 : (is58mmEffective ? 6.5 : 7.5),
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 1.5),
            pw.Center(
              child: pw.Text(
                '${(bill.paymentMode?.isNotEmpty == true ? bill.paymentMode! : "CASH").toUpperCase()} Payment : $currencySymbol${currencyFormat.format(bill.grandTotal ?? 0)} /-',
                style: pw.TextStyle(
                  fontSize: is56mm ? 7.0 : (is58mmEffective ? 7.5 : 8.5),
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),

            if (bill.paymentMode == 'UPI' &&
                bill.utrNumber != null &&
                bill.utrNumber!.isNotEmpty) ...[
              pw.SizedBox(height: 1),
              pw.Center(
                child: pw.Text(
                  'UPI Ref / UTR: ${bill.utrNumber}',
                  style: pw.TextStyle(
                    fontSize: is56mm ? 6.0 : (is58mmEffective ? 6.5 : 7.5),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
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
                      fontSize: is56mm ? 6.5 : (is58mmEffective ? 7.0 : 8.0),
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Change: $currencySymbol${currencyFormat.format(bill.changeReturned ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is56mm ? 6.5 : (is58mmEffective ? 7.0 : 8.0),
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
                      fontSize: is56mm ? 6.5 : (is58mmEffective ? 7.0 : 8.0),
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    'Online: $currencySymbol${currencyFormat.format(bill.splitOnline ?? 0)}',
                    style: pw.TextStyle(
                      fontSize: is56mm ? 6.5 : (is58mmEffective ? 7.0 : 8.0),
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],

            _divider(dashed: true),

            // ── Barcode of Bill No (Configurable via Settings) ──
            if (showBillBarcode && bill.billNo != null && bill.billNo!.isNotEmpty) ...[
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: bill.billNo!,
                  width: is56mm ? 105 : (is58mmEffective ? 120 : 150),
                  height: is56mm ? 20 : (is58mmEffective ? 24 : 28),
                  drawText: true,
                  color: PdfColors.black,
                  textStyle: pw.TextStyle(
                    fontSize: is56mm ? 6.0 : (is58mmEffective ? 6.5 : 7.5),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 2.5),
            ],

            // ── Footer ──
            pw.Center(
              child: pw.Text(
                billFooterTagline.isNotEmpty ? '*** $billFooterTagline ***' : '*** Thank You! Visit Again ***',
                style: pw.TextStyle(
                  fontSize: is56mm ? 7.0 : (is58mmEffective ? 7.5 : 8.5),
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 1.0),
            pw.Center(
              child: pw.Text(
                billTerms.isNotEmpty ? billTerms : 'Goods once sold can be exchanged within 7 days with bill',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: is56mm ? 6.0 : (is58mmEffective ? 6.5 : 7.5),
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 1.0),
            pw.Center(
              child: pw.Text(
                'Software: RH POS',
                style: pw.TextStyle(
                  fontSize: is56mm ? 5.2 : (is58mmEffective ? 5.5 : 6.5),
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
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
  static List<_GstBreakupRow> _calculateGstBreakup(EntityBill bill) {
    final Map<double, List<EntityBillItem>> grouped = {};
    for (final item in bill.items) {
      final rate = item.taxRate ?? item.item.target?.taxRate ?? ((bill.tax != null && bill.tax! > 0) ? 18.0 : 0.0);
      grouped.putIfAbsent(rate, () => []).add(item);
    }

    final rows = <_GstBreakupRow>[];
    int idx = 1;

    if (grouped.isEmpty) {
      final total = bill.grandTotal ?? bill.totalAmount ?? 0.0;
      final tax = bill.tax ?? 0.0;
      final taxable = (total - tax) > 0 ? (total - tax) : total;
      final halfTax = double.parse((tax / 2.0).toStringAsFixed(2));
      rows.add(_GstBreakupRow(
        index: 1,
        rate: 0.0,
        taxableAmount: double.parse(taxable.toStringAsFixed(2)),
        cgst: halfTax,
        sgst: halfTax,
        cess: 0.0,
        total: double.parse(total.toStringAsFixed(2)),
      ));
      return rows;
    }

    final sortedRates = grouped.keys.toList()..sort();
    for (final rate in sortedRates) {
      final items = grouped[rate]!;
      double slabTaxable = 0;
      double slabTax = 0;
      double slabTotal = 0;

      for (final it in items) {
        final isInclusive = (it.item.target?.taxType ?? '').toLowerCase().trim() == 'inclusive';
        final lineAmt = it.total ?? ((it.price ?? 0) * (it.qty ?? 1) - (it.discount ?? 0));

        if (rate > 0) {
          if (isInclusive) {
            final t = it.tax ?? (lineAmt * (rate / (100.0 + rate)));
            slabTax += t;
            slabTaxable += (lineAmt - t);
            slabTotal += lineAmt;
          } else {
            final t = it.tax ?? (lineAmt * (rate / 100.0));
            slabTax += t;
            slabTaxable += lineAmt;
            slabTotal += (lineAmt + t);
          }
        } else {
          slabTaxable += lineAmt;
          slabTotal += lineAmt;
        }
      }

      final cgst = double.parse((slabTax / 2.0).toStringAsFixed(2));
      final sgst = double.parse((slabTax / 2.0).toStringAsFixed(2));

      rows.add(_GstBreakupRow(
        index: idx++,
        rate: rate,
        taxableAmount: double.parse(slabTaxable.toStringAsFixed(2)),
        cgst: cgst,
        sgst: sgst,
        cess: 0.0,
        total: double.parse(slabTotal.toStringAsFixed(2)),
      ));
    }

    return rows;
  }
}

class _GstBreakupRow {
  final int index;
  final double rate;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double cess;
  final double total;

  _GstBreakupRow({
    required this.index,
    required this.rate,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    this.cess = 0.0,
    required this.total,
  });
}
