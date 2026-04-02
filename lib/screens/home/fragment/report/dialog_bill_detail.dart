import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../service/service_bill_pdf.dart';
import '../setting/controller_home_settings.dart';

class DialogBillDetail extends StatelessWidget {
  final EntityBill bill;

  const DialogBillDetail({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<ControllerHomeSettings>();
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final date = bill.createdAtUtcMs != null
        ? DateTime.fromMillisecondsSinceEpoch(
            bill.createdAtUtcMs!,
            isUtc: true,
          ).toLocal()
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        constraints: const BoxConstraints(maxHeight: 740),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Gradient Header ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
              child: Obx(
                () => Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.rxStoreName.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Bill #${bill.billNo ?? "N/A"}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Scrollable body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Store sub-info
                    _StoreInfoRow(settings: settings),
                    const SizedBox(height: 16),

                    // Dotted separator
                    _DottedDivider(),
                    const SizedBox(height: 14),

                    // Bill meta
                    _MetaRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: date != null ? dateFormat.format(date) : '-',
                    ),
                    _MetaRow(
                      icon: Icons.person_rounded,
                      label: 'Customer',
                      value: bill.customerName ?? 'Walk-in',
                    ),
                    _MetaRow(
                      icon: Icons.payment_rounded,
                      label: 'Payment',
                      value: bill.paymentMode ?? '-',
                    ),
                    _MetaRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Status',
                      value: bill.status ?? '-',
                    ),

                    const SizedBox(height: 14),
                    _DottedDivider(),
                    const SizedBox(height: 12),

                    // Items header
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'ITEM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'QTY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'RATE',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'AMT',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(thickness: 1),
                    const SizedBox(height: 4),

                    // Items list
                    ...bill.items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Container(
                        color: i.isEven
                            ? colorScheme.surfaceContainerLowest
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 2,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                item.itemName ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${item.qty ?? 0}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                currencyFormat.format(item.price ?? 0),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                currencyFormat.format(item.total ?? 0),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    _DottedDivider(),
                    const SizedBox(height: 10),

                    // Totals
                    _TotalRow(
                      label: 'Subtotal',
                      value: currencyFormat.format(bill.totalAmount ?? 0),
                    ),
                    if ((bill.tax ?? 0) > 0)
                      _TotalRow(
                        label: 'Tax',
                        value: currencyFormat.format(bill.tax ?? 0),
                      ),
                    if ((bill.discount ?? 0) > 0)
                      _TotalRow(
                        label: 'Discount',
                        value: '- ${currencyFormat.format(bill.discount ?? 0)}',
                        isRed: true,
                      ),

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GRAND TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            currencyFormat.format(bill.grandTotal ?? 0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      '★  Thank you for shopping with us!  ★',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Action Buttons ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  // Preview PDF
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _previewPdf(context, settings),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Preview PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // WhatsApp
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _shareWhatsApp(context, settings),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send on WhatsApp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PDF Preview ──────────────────────────────────────────────
  Future<void> _previewPdf(
    BuildContext context,
    ControllerHomeSettings settings,
  ) async {
    try {
      final pdfFile = await ServiceBillPdf.generate(bill, settings);
      // Open PDF with the system default viewer
      await Process.run('cmd', ['/c', 'start', '', pdfFile.path]);
      Get.snackbar(
        'PDF Saved',
        'Bill PDF saved at:\n${pdfFile.path}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not generate PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── WhatsApp Share ──────────────────────────────────────────
  Future<void> _shareWhatsApp(
    BuildContext context,
    ControllerHomeSettings settings,
  ) async {
    final customerPhone = bill.customerPhone;

    if (customerPhone != null && customerPhone.length == 10) {
      // Already have a valid phone number
      _confirmAndSendWhatsApp(
        context,
        settings,
        customerPhone,
        isFromBill: true,
      );
    } else {
      // Ask for number
      _promptPhoneAndSend(context, settings);
    }
  }

  void _confirmAndSendWhatsApp(
    BuildContext context,
    ControllerHomeSettings settings,
    String phone, {
    bool isFromBill = false,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Bill on WhatsApp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isFromBill
                  ? 'Send bill to customer\'s number?'
                  : 'Send bill to this number?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '+91 $phone',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
            ),
            onPressed: () {
              Get.back();
              _launchWhatsApp(context, settings, phone);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _promptPhoneAndSend(
    BuildContext context,
    ControllerHomeSettings settings,
  ) {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Customer Number'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No phone number on file.\nEnter a 10-digit mobile number to send the bill.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().length != 10) {
                    return 'Please enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Get.back();
                _confirmAndSendWhatsApp(
                  context,
                  settings,
                  phoneController.text.trim(),
                );
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(
    BuildContext context,
    ControllerHomeSettings settings,
    String phone,
  ) async {
    try {
      // ── 1. Build formatted text receipt ──────────────────────
      final storeName = settings.rxStoreName.value;
      final storePhone = settings.rxStorePhone.value;
      final date = bill.createdAtUtcMs != null
          ? DateTime.fromMillisecondsSinceEpoch(
              bill.createdAtUtcMs!,
              isUtc: true,
            ).toLocal()
          : DateTime.now();
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      final buffer = StringBuffer();
      buffer.writeln('🏪 *$storeName*');
      if (storePhone.isNotEmpty) buffer.writeln('📞 $storePhone');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('🧾 *Bill #${bill.billNo ?? "N/A"}*');
      buffer.writeln('📅 $dateStr');
      buffer.writeln('👤 ${bill.customerName ?? "Walk-in"}');
      buffer.writeln(
        '💳 ${bill.paymentMode ?? "CASH"} | ${bill.status ?? "PAID"}',
      );
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');

      // Items
      for (final item in bill.items) {
        final name = item.itemName ?? '-';
        final qty = item.qty ?? 0;
        final price = (item.price ?? 0).toStringAsFixed(2);
        final total = (item.total ?? 0).toStringAsFixed(2);
        buffer.writeln('• $name');
        buffer.writeln('  $qty × ₹$price = ₹$total');
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln(
        '  Subtotal  : ₹${(bill.totalAmount ?? 0).toStringAsFixed(2)}',
      );
      if ((bill.tax ?? 0) > 0) {
        buffer.writeln('  Tax       : ₹${(bill.tax ?? 0).toStringAsFixed(2)}');
      }
      if ((bill.discount ?? 0) > 0) {
        buffer.writeln(
          '  Discount  : -₹${(bill.discount ?? 0).toStringAsFixed(2)}',
        );
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln(
        '*GRAND TOTAL : ₹${(bill.grandTotal ?? 0).toStringAsFixed(2)}*',
      );
      buffer.writeln();
      buffer.writeln('⭐ Thank you for shopping with us!');

      // ── 2. Launch WhatsApp with pre-filled text ───────────────
      final encoded = Uri.encodeComponent(buffer.toString());
      final whatsappUrl = Uri.parse('https://wa.me/91$phone?text=$encoded');

      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open WhatsApp. Is it installed?');
      }
    } catch (e) {
      Get.snackbar(
        '❌ Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }
} // end of DialogBillDetail
// ── Helper Widgets ────────────────────────────────────────────

class _StoreInfoRow extends StatelessWidget {
  final ControllerHomeSettings settings;
  const _StoreInfoRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Text(
            settings.rxStoreAddress.value,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (settings.rxStorePhone.value.isNotEmpty)
            Text(
              '📞 ${settings.rxStorePhone.value}'
              '${settings.rxStoreGstin.value.isNotEmpty ? "   |   GSTIN: ${settings.rxStoreGstin.value}" : ""}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _DotPainter(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final Color color;
  _DotPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const gapWidth = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isRed;
  const _TotalRow({
    required this.label,
    required this.value,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isRed ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
