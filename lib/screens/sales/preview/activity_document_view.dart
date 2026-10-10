import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../screens/home/fragment/setting/controller_home_settings.dart';
import '../../../service/service_currency.dart';
import '../../../util/number_to_words.dart';
import 'service_gst_pdf.dart';

class DocumentViewModel {
  final DocumentType type;
  final String title;
  final String docNumber;
  final String docDate;
  final String? dueDate;
  final String? validityDate;
  final String status;
  final String partyName;
  final String? partyPhone;
  final String? partyAddress;
  final String? partyGstin;
  final List<GstPdfItem> items;
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? additionalCharges;
  final double? roundOff;
  final double grandTotal;
  final double? amountReceived;
  final double? balanceDue;
  final String? paymentMode;
  final String? notes;
  final String? termsConditions;

  DocumentViewModel({
    required this.type,
    required this.title,
    required this.docNumber,
    required this.docDate,
    this.dueDate,
    this.validityDate,
    required this.status,
    required this.partyName,
    this.partyPhone,
    this.partyAddress,
    this.partyGstin,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.taxAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.additionalCharges,
    this.roundOff,
    required this.grandTotal,
    this.amountReceived,
    this.balanceDue,
    this.paymentMode,
    this.notes,
    this.termsConditions,
  });
}

class ActivityDocumentView extends StatelessWidget {
  final DocumentViewModel model;

  const ActivityDocumentView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currencySymbol = Get.isRegistered<ServiceCurrency>()
        ? Get.find<ServiceCurrency>().rxCurrency.value
        : '₹';
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol);

    final settings = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>()
        : Get.put(ControllerHomeSettings());

    final storeName = settings.rxStoreName.value.isEmpty ? 'SUPER MARKET' : settings.rxStoreName.value;
    final storeAddress = settings.rxStoreAddress.value;
    final storePhone = settings.rxStorePhone.value;
    final storeEmail = settings.rxStoreEmail.value;
    final storeGstin = settings.rxStoreGstin.value;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surfaceContainerLowest : const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Text(
              '${model.title} #${model.docNumber}',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(model.status),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _downloadPdf(context),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text('Download PDF'.tr),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _printPdf(context),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: Text('Print PDF'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Share'.tr,
            icon: Icon(Icons.share_rounded, color: colorScheme.onSurfaceVariant),
            onPressed: () => _sharePdf(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Container(
            width: 820,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? colorScheme.outline.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
              ),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Header ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF4F46E5),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (storeAddress.isNotEmpty)
                            Text(
                              storeAddress,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          if (storeGstin.isNotEmpty)
                            Text(
                              'GSTIN: $storeGstin',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                            ),
                          if (storePhone.isNotEmpty)
                            Text(
                              'Phone: $storePhone | Email: $storeEmail',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          model.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No: ${model.docNumber}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Date: ${model.docDate}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        if (model.dueDate != null && model.dueDate!.isNotEmpty)
                          Text(
                            'Due Date: ${model.dueDate}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                          ),
                        if (model.validityDate != null && model.validityDate!.isNotEmpty)
                          Text(
                            'Valid Until: ${model.validityDate}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),

                // ── Bill To ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BILL TO:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              model.partyName.isEmpty ? 'Cash Sale' : model.partyName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            if (model.partyAddress != null && model.partyAddress!.isNotEmpty)
                              Text(
                                'Address: ${model.partyAddress}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                              ),
                            if (model.partyPhone != null && model.partyPhone!.isNotEmpty)
                              Text(
                                'Phone: ${model.partyPhone}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                              ),
                            if (model.partyGstin != null && model.partyGstin!.isNotEmpty)
                              Text(
                                'GSTIN: ${model.partyGstin}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Items Table ──
                Table(
                  border: TableBorder.all(color: const Color(0xFFE5E7EB), width: 1),
                  columnWidths: const {
                    0: FixedColumnWidth(40),
                    1: FlexColumnWidth(4),
                    2: FixedColumnWidth(80),
                    3: FixedColumnWidth(65),
                    4: FixedColumnWidth(90),
                    5: FixedColumnWidth(75),
                    6: FixedColumnWidth(75),
                    7: FixedColumnWidth(100),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
                      children: [
                        _th('S.N', align: TextAlign.center),
                        _th('ITEMS / SERVICES'),
                        _th('HSN', align: TextAlign.center),
                        _th('QTY', align: TextAlign.center),
                        _th('RATE', align: TextAlign.right),
                        _th('DISC', align: TextAlign.right),
                        _th('TAX', align: TextAlign.right),
                        _th('AMOUNT', align: TextAlign.right),
                      ],
                    ),
                    ...model.items.map(
                      (item) => TableRow(
                        children: [
                          _td('${item.sNo}', align: TextAlign.center),
                          _td(item.name, isBold: true),
                          _td(item.hsn.isEmpty ? '-' : item.hsn, align: TextAlign.center),
                          _td('${item.qty} ${item.unit}', align: TextAlign.center),
                          _td(currencyFmt.format(item.rate), align: TextAlign.right),
                          _td(item.discount > 0 ? currencyFmt.format(item.discount) : '-', align: TextAlign.right),
                          _td(item.taxPercent > 0 ? '${item.taxPercent}%' : '-', align: TextAlign.right),
                          _td(currencyFmt.format(item.total), align: TextAlign.right, isBold: true),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Summary & Calculations ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Notes
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Amount in Words:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                          ),
                          Text(
                            NumberToWords.convert(model.grandTotal),
                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 16),
                          if (model.notes != null && model.notes!.isNotEmpty) ...[
                            const Text('Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(model.notes!, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                            const SizedBox(height: 8),
                          ],
                          if (model.termsConditions != null && model.termsConditions!.isNotEmpty) ...[
                            const Text('Terms & Conditions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(model.termsConditions!, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Right Breakdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            _calcLine('Subtotal', currencyFmt.format(model.subtotal)),
                            if (model.discount > 0)
                              _calcLine('Discount (-)', currencyFmt.format(model.discount)),
                            if (model.taxAmount > 0) ...[
                              if (model.cgstAmount != null && model.cgstAmount! > 0)
                                _calcLine('CGST', currencyFmt.format(model.cgstAmount)),
                              if (model.sgstAmount != null && model.sgstAmount! > 0)
                                _calcLine('SGST', currencyFmt.format(model.sgstAmount)),
                              if (model.igstAmount != null && model.igstAmount! > 0)
                                _calcLine('IGST', currencyFmt.format(model.igstAmount)),
                              if ((model.cgstAmount == null || model.cgstAmount == 0) && (model.sgstAmount == null || model.sgstAmount == 0))
                                _calcLine('Tax (+)', currencyFmt.format(model.taxAmount)),
                            ],
                            if (model.additionalCharges != null && model.additionalCharges! > 0)
                              _calcLine('Additional Charges (+)', currencyFmt.format(model.additionalCharges)),
                            if (model.roundOff != null && model.roundOff! != 0)
                              _calcLine('Round Off', currencyFmt.format(model.roundOff)),
                            const Divider(height: 16),
                            _calcLine('Grand Total', currencyFmt.format(model.grandTotal), isGrand: true),
                            if (model.amountReceived != null && model.amountReceived! > 0)
                              _calcLine('Amount Received', currencyFmt.format(model.amountReceived)),
                            if (model.balanceDue != null && model.balanceDue! > 0)
                              _calcLine('Balance Due', currencyFmt.format(model.balanceDue), isDue: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),

                // ── Footer ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thank you for your business!',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'For $storeName',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),
                        const Text('Authorized Signatory', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'converted':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'unpaid':
      case 'overdue':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'partially paid':
      case 'open':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _th(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _td(String text, {TextAlign align = TextAlign.left, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _calcLine(String label, String value, {bool isGrand = false, bool isDue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrand ? 14 : 12,
              fontWeight: isGrand ? FontWeight.bold : FontWeight.normal,
              color: isDue ? Colors.red.shade700 : const Color(0xFF374151),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isGrand ? 15 : 12,
              fontWeight: isGrand || isDue ? FontWeight.bold : FontWeight.w600,
              color: isDue
                  ? Colors.red.shade700
                  : (isGrand ? const Color(0xFF4F46E5) : const Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final doc = await ServiceGstPdf.generateDocument(
        type: model.type,
        docNumber: model.docNumber,
        docDate: model.docDate,
        dueDate: model.dueDate,
        validityDate: model.validityDate,
        partyName: model.partyName,
        partyPhone: model.partyPhone,
        partyAddress: model.partyAddress,
        partyGstin: model.partyGstin,
        items: model.items,
        subtotal: model.subtotal,
        discount: model.discount,
        taxAmount: model.taxAmount,
        cgstAmount: model.cgstAmount,
        sgstAmount: model.sgstAmount,
        igstAmount: model.igstAmount,
        additionalCharges: model.additionalCharges,
        roundOff: model.roundOff,
        grandTotal: model.grandTotal,
        amountReceived: model.amountReceived,
        balanceDue: model.balanceDue,
        notes: model.notes,
        termsConditions: model.termsConditions,
      );
      final file = await ServiceGstPdf.saveAndGetFile(doc, '${model.title}_${model.docNumber}');
      Get.snackbar(
        'Downloaded',
        'File saved at ${file.path}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate PDF: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    try {
      final doc = await ServiceGstPdf.generateDocument(
        type: model.type,
        docNumber: model.docNumber,
        docDate: model.docDate,
        dueDate: model.dueDate,
        validityDate: model.validityDate,
        partyName: model.partyName,
        partyPhone: model.partyPhone,
        partyAddress: model.partyAddress,
        partyGstin: model.partyGstin,
        items: model.items,
        subtotal: model.subtotal,
        discount: model.discount,
        taxAmount: model.taxAmount,
        cgstAmount: model.cgstAmount,
        sgstAmount: model.sgstAmount,
        igstAmount: model.igstAmount,
        additionalCharges: model.additionalCharges,
        roundOff: model.roundOff,
        grandTotal: model.grandTotal,
        amountReceived: model.amountReceived,
        balanceDue: model.balanceDue,
        notes: model.notes,
        termsConditions: model.termsConditions,
      );
      await ServiceGstPdf.printDocument(doc);
    } catch (e) {
      Get.snackbar('Error', 'Failed to print document: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final doc = await ServiceGstPdf.generateDocument(
        type: model.type,
        docNumber: model.docNumber,
        docDate: model.docDate,
        dueDate: model.dueDate,
        validityDate: model.validityDate,
        partyName: model.partyName,
        partyPhone: model.partyPhone,
        partyAddress: model.partyAddress,
        partyGstin: model.partyGstin,
        items: model.items,
        subtotal: model.subtotal,
        discount: model.discount,
        taxAmount: model.taxAmount,
        cgstAmount: model.cgstAmount,
        sgstAmount: model.sgstAmount,
        igstAmount: model.igstAmount,
        additionalCharges: model.additionalCharges,
        roundOff: model.roundOff,
        grandTotal: model.grandTotal,
        amountReceived: model.amountReceived,
        balanceDue: model.balanceDue,
        notes: model.notes,
        termsConditions: model.termsConditions,
      );
      final file = await ServiceGstPdf.saveAndGetFile(doc, '${model.title}_${model.docNumber}');
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: '${model.title} #${model.docNumber}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to share document: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
