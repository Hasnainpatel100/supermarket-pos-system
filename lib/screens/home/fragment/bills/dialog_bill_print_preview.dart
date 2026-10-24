import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../model/entity_bill.dart';
import '../../../../service/service_bill_pdf.dart';
import '../../../../service/service_whatsapp.dart';
import '../../../../util/snackbar_util.dart';
import '../setting/controller_home_settings.dart';

class DialogBillPrintPreview extends StatefulWidget {
  final EntityBill bill;
  final String? initialPaperSize;

  const DialogBillPrintPreview({
    super.key,
    required this.bill,
    this.initialPaperSize,
  });

  @override
  State<DialogBillPrintPreview> createState() => _DialogBillPrintPreviewState();
}

class _DialogBillPrintPreviewState extends State<DialogBillPrintPreview> {
  late final ControllerHomeSettings _settings;
  late final RxString _rxPaperSize;
  final Map<String, Uint8List> _pdfBytesCache = {};

  @override
  void initState() {
    super.initState();
    _settings = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>()
        : Get.put(ControllerHomeSettings());

    final initial = widget.initialPaperSize ??
        (_settings.rxThermalPaperSize.value.isNotEmpty ? _settings.rxThermalPaperSize.value : '80mm');
    _rxPaperSize = initial.obs;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 650,
        height: 780,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 36,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Modern Gradient Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Receipt & Print Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bill #${widget.bill.billNo ?? "N/A"}  •  ${widget.bill.customerName ?? "Walk-in"}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // ── Paper Format Selector Bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.print_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Paper Size:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      final currentSize = _rxPaperSize.value.toLowerCase();
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSizeChip(
                              label: '80mm Thermal (3")',
                              sizeKey: '80mm',
                              isSelected: currentSize == '80mm',
                              icon: Icons.receipt_long_rounded,
                              cs: cs,
                            ),
                            const SizedBox(width: 8),
                            _buildSizeChip(
                              label: '58mm Thermal (2.25")',
                              sizeKey: '58mm',
                              isSelected: currentSize == '58mm',
                              icon: Icons.receipt_outlined,
                              cs: cs,
                            ),
                            const SizedBox(width: 8),
                            _buildSizeChip(
                              label: '56mm Thermal (2")',
                              sizeKey: '56mm',
                              isSelected: currentSize == '56mm',
                              icon: Icons.receipt_outlined,
                              cs: cs,
                            ),
                            const SizedBox(width: 8),
                            _buildSizeChip(
                              label: 'A4 Full Invoice',
                              sizeKey: 'A4',
                              isSelected: currentSize == 'a4',
                              icon: Icons.article_outlined,
                              cs: cs,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  // Save as Default Pill
                  Obx(() {
                    final current = _rxPaperSize.value;
                    final isDefault = _settings.rxThermalPaperSize.value.toLowerCase() == current.toLowerCase();
                    return Tooltip(
                      message: isDefault ? 'Current Default Paper Size' : 'Save as Default Thermal Size in Settings',
                      child: InkWell(
                        onTap: isDefault
                            ? null
                            : () async {
                                _settings.rxThermalPaperSize.value = current;
                                await _settings.savePrinterSettings();
                                SnackbarUtil.showSuccess('Default thermal paper size set to $current');
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDefault
                                ? cs.primary.withValues(alpha: 0.12)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDefault ? cs.primary : cs.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDefault ? Icons.check_circle_rounded : Icons.star_border_rounded,
                                size: 14,
                                color: isDefault ? cs.primary : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isDefault ? 'Default' : 'Set Default',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDefault ? cs.primary : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Live PDF Interactive Preview (Sharp & High DPI) ──
            Expanded(
              child: Obx(() {
                final paperSize = _rxPaperSize.value.toLowerCase();
                final is56 = paperSize == '56mm' || paperSize.contains('56');
                final is58 = !is56 && (paperSize == '58mm' || paperSize == '57mm' || paperSize.contains('58'));
                final isA4 = paperSize == 'a4';
                final format = isA4
                    ? PdfPageFormat.a4
                    : (is56
                        ? const PdfPageFormat(56 * PdfPageFormat.mm, double.infinity, marginAll: 1.5 * PdfPageFormat.mm)
                        : (is58
                            ? const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm)
                            : const PdfPageFormat(72 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm)));

                return PdfPreview(
                  key: ValueKey('preview_${widget.bill.billNo}_$paperSize'),
                  dpi: isA4 ? 180 : 140, // Fast crisp rasterization for instant preview
                  initialPageFormat: format,
                  dynamicLayout: false,
                  build: (f) async {
                    if (_pdfBytesCache.containsKey(paperSize)) {
                      return _pdfBytesCache[paperSize]!;
                    }
                    final doc = await ServiceBillPdf.buildPdfDocument(
                      widget.bill,
                      _settings,
                      paperSize: paperSize,
                    );
                    final bytes = await doc.save();
                    _pdfBytesCache[paperSize] = bytes;
                    return bytes;
                  },
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  maxPageWidth: isA4 ? 560 : (is58 ? 320 : 380),
                  pdfFileName: 'Bill_${widget.bill.billNo ?? "receipt"}.pdf',
                  actions: [
                    PdfPreviewAction(
                      icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                      onPressed: (ctx, build, pageFormat) async {
                        _sharePdfToWhatsApp(ctx);
                      },
                    ),
                  ],
                  loadingWidget: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: cs.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Generating receipt preview...',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeChip({
    required String label,
    required String sizeKey,
    required bool isSelected,
    required IconData icon,
    required ColorScheme cs,
  }) {
    return InkWell(
      onTap: () {
        _rxPaperSize.value = sizeKey;
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePdfToWhatsApp(BuildContext context) async {
    await _dispatchWhatsAppPdf(widget.bill.customerPhone ?? '');
  }

  Future<void> _dispatchWhatsAppPdf(String phone) async {
    try {
      SnackbarUtil.showSuccess('Preparing Bill PDF for WhatsApp...');
      final file = await ServiceBillPdf.generate(
        widget.bill,
        _settings,
        paperSize: _rxPaperSize.value,
      );

      final billNo = widget.bill.billNo ?? '${widget.bill.id}';

      if (!mounted) return;
      ServiceWhatsApp.showDispatchDialog(
        context: context,
        pdfFile: file,
        phone: phone,
        invoiceNumber: billNo,
        storeName: _settings.rxStoreName.value,
        total: widget.bill.grandTotal ?? 0.0,
        customerName: widget.bill.customerName,
        settings: _settings,
      );
    } catch (e) {
      SnackbarUtil.showError('Failed to prepare PDF for WhatsApp: $e');
    }
  }
}
