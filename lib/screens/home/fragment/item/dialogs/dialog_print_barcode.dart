import 'dart:typed_data';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../model/entity_item.dart';
import '../../setting/controller_home_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class _PrintBarcodeController extends GetxController {
  final EntityItem item;

  _PrintBarcodeController(this.item) {
    // Set item-specific defaults first
    labelNameController.text = item.name ?? '';
    labelPriceController.text = item.sellingPrice != null
        ? item.sellingPrice!.toStringAsFixed(2)
        : '';

    // Pre-fill from global printer settings if the controller is registered
    if (Get.isRegistered<ControllerHomeSettings>()) {
      final settings = Get.find<ControllerHomeSettings>();
      rxIs1D.value       = settings.rxBarcodeType.value == '1D';
      rxPaperSize.value  = settings.rxPaperSize.value;
      rxShowName.value   = settings.rxShowName.value;
      rxShowPrice.value  = settings.rxShowPrice.value;
      rxExtraInfo.value  = settings.rxExtraInfo.value;
      extraInfoController.text = settings.rxExtraInfo.value;
      _defaultPrinterName = settings.rxDefaultPrinter.value;
    }
  }

  /// Printer name to use ('' = system default / let OS choose)
  String _defaultPrinterName = '';

  // Barcode type
  final rxIs1D = true.obs; // true = Code128 (1D), false = QR (2D)

  // Paper size: '58mm' | '80mm' | 'A4' | 'custom'
  final rxPaperSize = '58mm'.obs;
  final customWidthController = TextEditingController(text: '58');
  final customHeightController = TextEditingController(text: '30');

  // Optional label fields
  final labelNameController  = TextEditingController();
  final labelPriceController = TextEditingController();
  final rxShowName  = true.obs;
  final rxShowPrice = false.obs;

  // Extra info (global default or user override)
  final rxExtraInfo = ''.obs;
  final extraInfoController = TextEditingController();

  PdfPageFormat get pdfPageFormat {
    switch (rxPaperSize.value) {
      case '58mm':
        return PdfPageFormat(58 * PdfPageFormat.mm, 40 * PdfPageFormat.mm);
      case '80mm':
        return PdfPageFormat(80 * PdfPageFormat.mm, 50 * PdfPageFormat.mm);
      case 'A4':
        return PdfPageFormat.a4;
      case 'custom':
        final w = double.tryParse(customWidthController.text) ?? 58;
        final h = double.tryParse(customHeightController.text) ?? 30;
        return PdfPageFormat(w * PdfPageFormat.mm, h * PdfPageFormat.mm);
      default:
        return PdfPageFormat(58 * PdfPageFormat.mm, 40 * PdfPageFormat.mm);
    }
  }

  @override
  void onClose() {
    customWidthController.dispose();
    customHeightController.dispose();
    labelNameController.dispose();
    labelPriceController.dispose();
    extraInfoController.dispose();
    super.onClose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog Widget
// ─────────────────────────────────────────────────────────────────────────────

class DialogPrintBarcode extends StatelessWidget {
  final EntityItem item;
  const DialogPrintBarcode({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(_PrintBarcodeController(item));
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 700),
        child: Obx(() {
          final barcodeData = item.barcode?.isNotEmpty == true ? item.barcode! : (item.name ?? 'ITEM');

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.indigo.shade600]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Print Barcode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(item.name ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
                  ],
                ),
                const SizedBox(height: 20),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Two-column layout: options | preview ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT: Options
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Barcode type toggle
                                  _SectionLabel('Barcode Type'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _OptionChip(
                                          label: '1D Barcode',
                                          icon: Icons.view_week_rounded,
                                          selected: ctrl.rxIs1D.value,
                                          color: Colors.deepPurple.shade500,
                                          onTap: () => ctrl.rxIs1D.value = true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _OptionChip(
                                          label: '2D QR Code',
                                          icon: Icons.qr_code_2_rounded,
                                          selected: !ctrl.rxIs1D.value,
                                          color: Colors.indigo.shade500,
                                          onTap: () => ctrl.rxIs1D.value = false,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Paper size
                                  _SectionLabel('Paper Size'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: ['58mm', '80mm', 'A4', 'custom'].map((s) {
                                      return _SizeChip(
                                        label: s == 'custom' ? 'Custom' : s,
                                        selected: ctrl.rxPaperSize.value == s,
                                        onTap: () => ctrl.rxPaperSize.value = s,
                                      );
                                    }).toList(),
                                  ),

                                  // Custom size inputs
                                  if (ctrl.rxPaperSize.value == 'custom') ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: ctrl.customWidthController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Width (mm)',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                            onChanged: (_) => ctrl.rxPaperSize.refresh(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('×', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: ctrl.customHeightController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Height (mm)',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                            onChanged: (_) => ctrl.rxPaperSize.refresh(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 16),

                                  // Label options
                                  _SectionLabel('Label Details'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: ctrl.rxShowName.value,
                                        onChanged: (v) => ctrl.rxShowName.value = v ?? false,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Text('Show Name', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  if (ctrl.rxShowName.value) ...[
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: ctrl.labelNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Name on label',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        isDense: true,
                                      ),
                                      onChanged: (_) => ctrl.rxShowName.refresh(),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: ctrl.rxShowPrice.value,
                                        onChanged: (v) => ctrl.rxShowPrice.value = v ?? false,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Text('Show Price', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  if (ctrl.rxShowPrice.value) ...[
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: ctrl.labelPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Price on label',
                                        prefixText: '₹ ',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        isDense: true,
                                      ),
                                      onChanged: (_) => ctrl.rxShowPrice.refresh(),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  // Extra Info
                                  const Text('Extra Info',
                                      style: TextStyle(fontSize: 13)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: ctrl.extraInfoController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      hintText: 'Optional text on label',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      isDense: true,
                                    ),
                                    onChanged: (_) =>
                                        ctrl.rxExtraInfo.refresh(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            // RIGHT: Live Preview
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _SectionLabel('Preview'),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (ctrl.rxShowName.value && ctrl.labelNameController.text.isNotEmpty) ...[
                                          Text(
                                            ctrl.labelNameController.text,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                        ctrl.rxIs1D.value
                                            ? BarcodeWidget(
                                                barcode: Barcode.code128(),
                                                data: barcodeData,
                                                width: 160,
                                                height: 60,
                                                drawText: true,
                                                color: Colors.black,
                                              )
                                            : BarcodeWidget(
                                                barcode: Barcode.qrCode(),
                                                data: barcodeData,
                                                width: 120,
                                                height: 120,
                                                color: Colors.black,
                                              ),
                                        if (ctrl.rxShowPrice.value && ctrl.labelPriceController.text.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            '₹ ${ctrl.labelPriceController.text}',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ],
                                        if (ctrl.extraInfoController.text.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            ctrl.extraInfoController.text,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ctrl.rxPaperSize.value == 'custom'
                                        ? '${ctrl.customWidthController.text}mm × ${ctrl.customHeightController.text}mm'
                                        : ctrl.rxPaperSize.value,
                                    style: TextStyle(fontSize: 11, color: colorScheme.outline),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Action buttons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.indigo.shade600]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _printBarcode(ctrl, barcodeData),
                        icon: const Icon(Icons.print_rounded, size: 18, color: Colors.white),
                        label: const Text('Print', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _printBarcode(_PrintBarcodeController ctrl, String barcodeData) async {
    final is1D       = ctrl.rxIs1D.value;
    final format     = ctrl.pdfPageFormat;
    final showName   = ctrl.rxShowName.value;
    final showPrice  = ctrl.rxShowPrice.value;
    final labelName  = ctrl.labelNameController.text;
    final labelPrice = ctrl.labelPriceController.text;
    final extraInfo  = ctrl.extraInfoController.text.trim();
    final printerName = ctrl._defaultPrinterName;

    // Build the PDF bytes generator (shared between both print paths)
    Future<Uint8List> buildPdf(PdfPageFormat fmt) async {
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      final doc = pw.Document(
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
      );
      doc.addPage(
        pw.Page(
          pageFormat: fmt,
          margin: const pw.EdgeInsets.all(4 * PdfPageFormat.mm),
          build: (ctx) {
            final barcodeWidget = is1D
                ? pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: barcodeData,
                    width: fmt.availableWidth,
                    height: 20 * PdfPageFormat.mm,
                    drawText: true,
                  )
                : pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: barcodeData,
                    width: 25 * PdfPageFormat.mm,
                    height: 25 * PdfPageFormat.mm,
                  );

            return pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (showName && labelName.isNotEmpty)
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.only(bottom: 2 * PdfPageFormat.mm),
                    child: pw.Text(
                      labelName,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                pw.Center(child: barcodeWidget),
                if (showPrice && labelPrice.isNotEmpty)
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.only(top: 2 * PdfPageFormat.mm),
                    child: pw.Text(
                      '₹ $labelPrice',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ),
                if (extraInfo.isNotEmpty)
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.only(top: 1 * PdfPageFormat.mm),
                    child: pw.Text(
                      extraInfo,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
      );
      return doc.save();
    }

    // If a specific printer is configured, resolve it and print directly
    if (printerName.isNotEmpty) {
      try {
        final printers = await Printing.listPrinters();
        final target = printers
            .cast<Printer?>()
            .firstWhere((p) => p?.name == printerName, orElse: () => null);

        if (target != null) {
          await Printing.directPrintPdf(
            printer: target,
            onLayout: (fmt) => buildPdf(fmt),
            name: '${item.name ?? "barcode"}_barcode',
            format: format,
          );
          return;
        }
      } catch (_) {
        // fall through to layoutPdf dialog
      }
    }

    // Fall back to OS print dialog
    await Printing.layoutPdf(
      onLayout: (fmt) => buildPdf(fmt),
      name: '${item.name ?? "barcode"}_barcode',
      format: format,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.4),
      );
}

class _OptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _OptionChip({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.10) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? color : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SizeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Colors.deepPurple.shade400 : Colors.grey.shade300, width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? Colors.deepPurple.shade600 : Colors.grey.shade600),
        ),
      ),
    );
  }
}
