import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../enums/enum_payement_mode.dart';
import '../../../../../model/entity_payment.dart';
import '../../../../../model/entity_purchase.dart';

/// Generates and shares/prints a professional payment voucher PDF.
///
/// Dependencies to add in pubspec.yaml:
///   pdf: ^3.11.0
///   printing: ^5.13.0
///   path_provider: ^2.1.0
class ServicePaymentReceipt {
  // ── Branding — update these for your shop ──────────────────────────
  static const String _shopName = 'RH POS Supermarket';
  static const String _shopAddress =
      '14, Market Road, Latur – 411001, Maharashtra';
  static const String _shopPhone = '+91 98765 43210';
  static const String _shopGstin = '27AAAAA0000A1Z5';
  static const String _shopEmail = 'rhpos@example.com';
  // ────────────────────────────────────────────────────────────────────

  /// Generate a PDF voucher for one or more payments against a purchase.
  /// [payments] should be the payments recorded in this session (1 for single,
  /// 2+ for split). [isSplit] controls whether to show the split breakdown table.
  static Future<void> generateAndShare({
    required EntityPurchase purchase,
    required List<EntityPayment> payments,
    bool isSplit = false,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
        italic: await PdfGoogleFonts.notoSansItalic(),
      ),
    );

    final double totalPaid =
    payments.fold(0, (sum, p) => sum + (p.amount ?? 0));
    final String voucherNo =
        'VCH-${purchase.purchaseNo}-${DateFormat('yyyyMMddHHmm').format(DateTime.now())}';
    final String printedAt =
    DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // ── Brand colors ──
    const PdfColor green = PdfColor.fromInt(0xFF2E7D32);
    const PdfColor greenLight = PdfColor.fromInt(0xFFE8F5E9);
    const PdfColor grey = PdfColor.fromInt(0xFF616161);
    const PdfColor greyLight = PdfColor.fromInt(0xFFF5F5F5);
    const PdfColor red = PdfColor.fromInt(0xFFC62828);
    const PdfColor black = PdfColor.fromInt(0xFF212121);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: green,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _shopName,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _shopAddress,
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 8),
                      ),
                      pw.Text(
                        'Ph: $_shopPhone  |  $_shopEmail',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 8),
                      ),
                      pw.Text(
                        'GSTIN: $_shopGstin',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 8),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'PAYMENT VOUCHER',
                          style: pw.TextStyle(
                            color: green,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── Voucher meta row ───────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: greyLight,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _metaCell('Voucher No', voucherNo, black),
                  _metaCell('PO Number', purchase.purchaseNo ?? '-', black),
                  _metaCell('Date', printedAt, black),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── Supplier Info ──────────────────────────────────────
            pw.Text('Supplier Details',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: green)),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(purchase.supplierName ?? '-',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  // if (purchase.supplierPhone != null)
                  //   pw.Text('Ph: ${purchase.supplierPhone}',
                  //       style: const pw.TextStyle(fontSize: 9, color: grey)),
                  // if (purchase.supplierGstin != null)
                  //   pw.Text('GSTIN: ${purchase.supplierGstin}',
                  //       style: const pw.TextStyle(fontSize: 9, color: grey)),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── Purchase Summary ───────────────────────────────────
            pw.Text('Payment Summary',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: green)),
            pw.SizedBox(height: 6),

            _buildSummaryTable(
              purchase: purchase,
              totalPaid: totalPaid,
              green: green,
              greenLight: greenLight,
              grey: grey,
            ),

            pw.SizedBox(height: 12),

            // ── Payment Breakdown (always shown; split label if needed) ──
            pw.Text(
              isSplit ? 'Split Payment Breakdown' : 'Payment Details',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: green),
            ),
            pw.SizedBox(height: 6),

            _buildPaymentBreakdownTable(
              payments: payments,
              green: green,
              greenLight: greenLight,
              grey: grey,
            ),

            pw.SizedBox(height: 14),

            // ── Outstanding after this payment ────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: purchase.outstandingAmount <= 0
                    ? greenLight
                    : PdfColor.fromInt(0xFFFFEBEE),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: purchase.outstandingAmount <= 0 ? green : red,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    pw.Text(
                      purchase.outstandingAmount <= 0
                          ? '✓  Fully Settled'
                          : '⚠  Balance Due',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: purchase.outstandingAmount <= 0 ? green : red,
                      ),
                    ),
                  ]),
                  pw.Text(
                    purchase.outstandingAmount <= 0
                        ? 'NIL'
                        : 'Rs. ${purchase.outstandingAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: purchase.outstandingAmount <= 0 ? green : red,
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // ── Footer ────────────────────────────────────────────
            pw.Divider(color: PdfColor.fromInt(0xFFBDBDBD)),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Authorised Signatory',
                        style:
                        const pw.TextStyle(fontSize: 8, color: grey)),
                    pw.SizedBox(height: 20),
                    pw.Container(
                        width: 80,
                        height: 1,
                        color: PdfColor.fromInt(0xFF9E9E9E)),
                    pw.SizedBox(height: 4),
                    pw.Text(_shopName,
                        style: const pw.TextStyle(fontSize: 8, color: grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('This is a computer-generated voucher.',
                        style:
                        const pw.TextStyle(fontSize: 7, color: grey)),
                    pw.Text('No signature required.',
                        style:
                        const pw.TextStyle(fontSize: 7, color: grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // ── Share / Print ──
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '$voucherNo.pdf',
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  WIDGET HELPERS
  // ─────────────────────────────────────────────────────────────────────

  static pw.Widget _metaCell(String label, String value, PdfColor valueColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E))),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: valueColor)),
      ],
    );
  }

  static pw.Widget _buildSummaryTable({
    required EntityPurchase purchase,
    required double totalPaid,
    required PdfColor green,
    required PdfColor greenLight,
    required PdfColor grey,
  }) {
    final rows = [
      ['Total Invoice Amount', 'Rs. ${(purchase.totalAmount ?? 0).toStringAsFixed(2)}'],
      ['Previously Paid', 'Rs. ${((purchase.amountPaid ?? 0) - totalPaid).clamp(0, double.infinity).toStringAsFixed(2)}'],
      ['This Payment', 'Rs. ${totalPaid.toStringAsFixed(2)}'],
    ];

    return pw.Table(
      border: pw.TableBorder.all(
          color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        ...rows.map((row) => pw.TableRow(children: [
          _tableCell(row[0], isLabel: true, grey: grey),
          _tableCell(row[1], isLabel: false, grey: grey,
              align: pw.Alignment.centerRight),
        ])),
        // Total row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: greenLight),
          children: [
            _tableCell('Total Paid (This Session)',
                isLabel: true, grey: green, bold: true),
            _tableCell('Rs. ${totalPaid.toStringAsFixed(2)}',
                isLabel: false,
                grey: green,
                bold: true,
                align: pw.Alignment.centerRight),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentBreakdownTable({
    required List<EntityPayment> payments,
    required PdfColor green,
    required PdfColor greenLight,
    required PdfColor grey,
  }) {
    final modeNames = {
      PaymentMode.cash: 'Cash',
      PaymentMode.cheque: 'Cheque',
      PaymentMode.bankTransfer: 'Bank Transfer',
      PaymentMode.upi: 'UPI',
    };

    return pw.Table(
      border: pw.TableBorder.all(
          color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: green),
          children: [
            _tableCell('Mode', isLabel: true, grey: PdfColors.white, bold: true),
            _tableCell('Reference / Note',
                isLabel: true, grey: PdfColors.white, bold: true),
            _tableCell('Amount',
                isLabel: true,
                grey: PdfColors.white,
                bold: true,
                align: pw.Alignment.centerRight),
          ],
        ),
        // Data rows
        ...payments.map((p) {
          final mode = PaymentMode.values[p.paymentMode ?? 0];
          final modeName = modeNames[mode] ?? 'Cash';
          final ref = p.referenceNo?.isNotEmpty == true
              ? p.referenceNo!
              : (p.note?.isNotEmpty == true ? p.note! : '-');
          return pw.TableRow(children: [
            _tableCell(modeName, isLabel: false, grey: grey),
            _tableCell(ref, isLabel: false, grey: grey),
            _tableCell('Rs. ${(p.amount ?? 0).toStringAsFixed(2)}',
                isLabel: false,
                grey: grey,
                align: pw.Alignment.centerRight),
          ]);
        }),
      ],
    );
  }

  static pw.Widget _tableCell(
      String text, {
        required bool isLabel,
        required PdfColor grey,
        bool bold = false,
        pw.Alignment align = pw.Alignment.centerLeft,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: grey,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
