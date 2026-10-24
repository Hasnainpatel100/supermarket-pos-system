import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/home/fragment/setting/controller_home_settings.dart';
import '../util/snackbar_util.dart';

/// Service for sending PDF invoices and receipts via WhatsApp:
/// 1. Meta WhatsApp Cloud API (automated background PDF delivery)
/// 2. WhatsApp Desktop / Web launcher with receipt image copy on clipboard for instant Ctrl+V
/// 3. Windows Native Share Sheet (attaches .pdf file directly to WhatsApp app / Mail)
/// 4. Windows Explorer highlight for easy drag-and-drop
class ServiceWhatsApp {
  static const String _baseUrl = 'https://graph.facebook.com/v19.0';

  /// Normalizes phone number to digits-only with country code (defaults to 91 for 10-digit numbers).
  static String normalizePhoneNumber(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }
    if (digits.length == 10) {
      return '91$digits';
    }
    if (digits.startsWith('91') && digits.length == 12) {
      return digits;
    }
    return digits;
  }

  /// Formats phone number for display (e.g. +91 98765 43210).
  static String formatPhoneDisplay(String phone) {
    final norm = normalizePhoneNumber(phone);
    if (norm.startsWith('91') && norm.length == 12) {
      final p1 = norm.substring(2, 7);
      final p2 = norm.substring(7);
      return '+91 $p1 $p2';
    }
    if (norm.length == 10) {
      return '+91 ${norm.substring(0, 5)} ${norm.substring(5)}';
    }
    return norm.isNotEmpty ? '+$norm' : 'Not set';
  }

  /// Tests connection with Meta WhatsApp Cloud API credentials.
  static Future<Map<String, dynamic>> testConnection({
    required String accessToken,
    required String phoneNumberId,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/$phoneNumberId?fields=verified_name,display_phone_number,quality_rating,code_verification_status',
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      String errMsg = 'Connection check failed (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error']?['message'] != null) {
          errMsg = '${errJson['error']['message']} (Code: ${errJson['error']['code']})';
        }
      } catch (_) {
        errMsg = response.body;
      }
      throw Exception(errMsg);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Uploads [pdfFile] as a WhatsApp media object and returns the media ID.
  static Future<String> _uploadMedia({
    required File pdfFile,
    required String accessToken,
    required String phoneNumberId,
  }) async {
    final uri = Uri.parse('$_baseUrl/$phoneNumberId/media');
    final filename = pdfFile.path.split(Platform.isWindows ? r'\' : '/').last;

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['messaging_product'] = 'whatsapp'
      ..fields['type'] = 'application/pdf'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          pdfFile.path,
          filename: filename,
          contentType: MediaType('application', 'pdf'),
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      String errMsg = 'Media upload failed (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error']?['message'] != null) {
          errMsg = '${errJson['error']['message']} (Code: ${errJson['error']['code']})';
        }
      } catch (_) {
        errMsg = response.body;
      }
      throw Exception(errMsg);
    }

    final data = jsonDecode(response.body);
    final mediaId = data['id'] as String?;
    if (mediaId == null) {
      throw Exception('No media ID in response: ${response.body}');
    }
    return mediaId;
  }

  /// Sends [pdfFile] as a document to [toPhone] (with country code, e.g. 919876543210)
  /// with an optional [caption] via Meta WhatsApp Cloud API.
  static Future<void> sendDocument({
    required File pdfFile,
    required String toPhone,
    required String accessToken,
    required String phoneNumberId,
    String caption = '',
  }) async {
    final cleanPhone = normalizePhoneNumber(toPhone);
    if (cleanPhone.length < 10) {
      throw Exception('Invalid phone number: $toPhone');
    }

    // Step 1 — Upload media and get ID
    final mediaId = await _uploadMedia(
      pdfFile: pdfFile,
      accessToken: accessToken,
      phoneNumberId: phoneNumberId,
    );

    // Step 2 — Send the document message
    final uri = Uri.parse('$_baseUrl/$phoneNumberId/messages');
    final filename = pdfFile.path.split(Platform.isWindows ? r'\' : '/').last;

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messaging_product': 'whatsapp',
        'recipient_type': 'individual',
        'to': cleanPhone,
        'type': 'document',
        'document': {
          'id': mediaId,
          'caption': caption,
          'filename': filename,
        },
      }),
    );

    if (response.statusCode != 200) {
      String errMsg = 'Message send failed (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error']?['message'] != null) {
          errMsg = '${errJson['error']['message']} (Code: ${errJson['error']['code']})';
        }
      } catch (_) {
        errMsg = response.body;
      }
      throw Exception(errMsg);
    }
  }

  /// Renders page 0 of [pdfFile] as a PNG image for instant pasting into WhatsApp chat.
  static Future<File?> renderReceiptImage(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      await for (final page in Printing.raster(bytes, pages: [0], dpi: 180)) {
        final pngBytes = await page.toPng();
        final tempDir = Directory.systemTemp;
        final baseName = pdfFile.path.split(Platform.isWindows ? r'\' : '/').last.replaceAll('.pdf', '');
        final imgFile = File('${tempDir.path}/${baseName}_preview.png');
        await imgFile.writeAsBytes(pngBytes, flush: true);
        return imgFile;
      }
    } catch (e) {
      debugPrint('Failed to render receipt image: $e');
    }
    return null;
  }

  /// Copies the rendered receipt image (and PDF path) to Windows clipboard.
  /// Web browsers (Chrome/Edge) allow pasting images via Ctrl+V into WhatsApp Web!
  static Future<void> copyReceiptToWindowsClipboard({
    required File pdfFile,
    File? imageFile,
  }) async {
    if (!Platform.isWindows) return;
    try {
      if (imageFile != null && await imageFile.exists()) {
        final escapedImgPath = imageFile.path.replaceAll("'", "''");
        await Process.run('powershell', [
          '-STA',
          '-NoProfile',
          '-Command',
          "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; \$img = [System.Drawing.Image]::FromFile('$escapedImgPath'); [System.Windows.Forms.Clipboard]::SetImage(\$img); \$img.Dispose();",
        ]);
      } else {
        await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Set-Clipboard -LiteralPath "${pdfFile.path}"',
        ]);
      }
    } catch (e) {
      debugPrint('Failed to copy to clipboard: $e');
    }
  }

  /// Launches WhatsApp Desktop or WhatsApp Web directly to customer's chat with prefilled caption.
  static Future<bool> openWhatsAppChat({
    required String phone,
    required String caption,
  }) async {
    final cleanPhone = normalizePhoneNumber(phone);
    final encodedText = Uri.encodeComponent(caption);

    // 1. Try native WhatsApp desktop protocol first
    try {
      final nativeDesktopUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
      if (await canLaunchUrl(nativeDesktopUri)) {
        final success = await launchUrl(nativeDesktopUri, mode: LaunchMode.externalApplication);
        if (success) return true;
      }
    } catch (_) {}

    // 2. Try WhatsApp Web directly (skips wa.me landing page)
    try {
      final webUri = Uri.parse('https://web.whatsapp.com/send?phone=$cleanPhone&text=$encodedText');
      final success = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (success) return true;
    } catch (_) {}

    // 3. Fallback to wa.me
    try {
      final waUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');
      return await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch WhatsApp URL: $e');
      return false;
    }
  }

  /// Shares PDF file via native system share sheet (Windows 10/11 Share UI).
  static Future<void> sharePdfNative({
    required File pdfFile,
    required String invoiceNumber,
    required String caption,
    required String storeName,
  }) async {
    try {
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [
          XFile(
            pdfFile.path,
            mimeType: 'application/pdf',
            name: 'Invoice_$invoiceNumber.pdf',
          ),
        ],
        text: caption,
        subject: 'Invoice #$invoiceNumber from $storeName',
      );
    } catch (e) {
      debugPrint('Share.shareXFiles error: $e');
      SnackbarUtil.showError('Could not open share menu: $e');
    }
  }

  /// Highlights [pdfFile] in Windows Explorer.
  static Future<void> highlightInFolder(File pdfFile) async {
    if (Platform.isWindows) {
      try {
        await Process.run('explorer.exe', ['/select,', pdfFile.path]);
      } catch (e) {
        debugPrint('Failed to open explorer: $e');
      }
    }
  }

  /// Opens the PDF file with the default PDF reader.
  static Future<void> openPdfFile(File pdfFile) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', pdfFile.path]);
      } else {
        await launchUrl(Uri.file(pdfFile.path));
      }
    } catch (e) {
      debugPrint('Failed to open PDF file: $e');
      SnackbarUtil.showError('Could not open PDF file: $e');
    }
  }

  /// Builds a friendly text caption for the bill.
  static String buildInvoiceCaption({
    required String invoiceNumber,
    required String storeName,
    required double total,
    String? customerName,
  }) {
    final resolvedCustomer = customerName?.isNotEmpty == true ? customerName! : 'Valued Customer';
    return '🧾 *Tax Invoice / Bill #$invoiceNumber*\n'
        '🏪 *$storeName*\n'
        '👤 *Customer:* $resolvedCustomer\n'
        '💰 *Net Amount:* ₹${total.toStringAsFixed(2)}\n\n'
        '⭐ *Thank you for shopping with us!* Please find your invoice receipt attached.';
  }

  /// Main entry point that displays the comprehensive WhatsApp Dispatch Dialog.
  static void showDispatchDialog({
    required BuildContext context,
    required File pdfFile,
    required String phone,
    required String invoiceNumber,
    required String storeName,
    required double total,
    String? customerName,
    ControllerHomeSettings? settings,
  }) {
    final ControllerHomeSettings resolvedSettings = settings ??
        (Get.isRegistered<ControllerHomeSettings>()
            ? Get.find<ControllerHomeSettings>()
            : Get.put(ControllerHomeSettings()));

    final resolvedStore = storeName.isNotEmpty
        ? storeName
        : (resolvedSettings.rxStoreName.value.isNotEmpty
            ? resolvedSettings.rxStoreName.value
            : 'SUPER MARKET');

    Get.dialog(
      DialogWhatsAppDispatch(
        pdfFile: pdfFile,
        initialPhone: phone,
        invoiceNumber: invoiceNumber,
        storeName: resolvedStore,
        total: total,
        customerName: customerName,
        settings: resolvedSettings,
      ),
      barrierDismissible: true,
    );
  }

  /// Dispatches the invoice PDF by showing the WhatsApp Dispatch dialog.
  static Future<void> dispatchInvoicePdf({
    required File pdfFile,
    required String phone,
    required String invoiceNumber,
    required String storeName,
    required double total,
    String? customerName,
    ControllerHomeSettings? settings,
    BuildContext? context,
  }) async {
    showDispatchDialog(
      context: context ?? (Get.context ?? Get.overlayContext!),
      pdfFile: pdfFile,
      phone: phone,
      invoiceNumber: invoiceNumber,
      storeName: storeName,
      total: total,
      customerName: customerName,
      settings: settings,
    );
  }

  /// Shows a snackbar error with a helpful message.
  static void showError(String message) {
    Get.snackbar(
      'WhatsApp Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG: WhatsApp Invoice Dispatch
// ─────────────────────────────────────────────────────────────────────────────

class DialogWhatsAppDispatch extends StatefulWidget {
  final File pdfFile;
  final String initialPhone;
  final String invoiceNumber;
  final String storeName;
  final double total;
  final String? customerName;
  final ControllerHomeSettings settings;

  const DialogWhatsAppDispatch({
    super.key,
    required this.pdfFile,
    required this.initialPhone,
    required this.invoiceNumber,
    required this.storeName,
    required this.total,
    this.customerName,
    required this.settings,
  });

  @override
  State<DialogWhatsAppDispatch> createState() => _DialogWhatsAppDispatchState();
}

class _DialogWhatsAppDispatchState extends State<DialogWhatsAppDispatch> {
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  bool _isSendingCloudApi = false;
  String? _cloudApiSuccessMsg;
  String? _cloudApiErrorMsg;

  bool _chatOpened = false;
  bool _isCopyingReceipt = false;

  @override
  void initState() {
    super.initState();
    final digits = widget.initialPhone.replaceAll(RegExp(r'\D'), '');
    final clean = digits.startsWith('91') && digits.length == 12
        ? digits.substring(2)
        : (digits.startsWith('0') && digits.length == 11 ? digits.substring(1) : digits);
    _phoneController = TextEditingController(text: clean);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _currentCaption => ServiceWhatsApp.buildInvoiceCaption(
        invoiceNumber: widget.invoiceNumber,
        storeName: widget.storeName,
        total: widget.total,
        customerName: widget.customerName,
      );

  Future<void> _sendViaCloudApi() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();

    setState(() {
      _isSendingCloudApi = true;
      _cloudApiSuccessMsg = null;
      _cloudApiErrorMsg = null;
    });

    try {
      await ServiceWhatsApp.sendDocument(
        pdfFile: widget.pdfFile,
        toPhone: phone,
        accessToken: widget.settings.rxWhatsAppToken.value,
        phoneNumberId: widget.settings.rxWhatsAppPhoneId.value,
        caption: _currentCaption,
      );

      setState(() {
        _isSendingCloudApi = false;
        _cloudApiSuccessMsg = 'Invoice PDF delivered to WhatsApp successfully!';
      });
      SnackbarUtil.showSuccess('Invoice PDF sent to WhatsApp successfully!');
    } catch (e) {
      setState(() {
        _isSendingCloudApi = false;
        _cloudApiErrorMsg = e.toString().replaceAll('Exception: ', '');
      });
      SnackbarUtil.showError('Cloud API error: $_cloudApiErrorMsg');
    }
  }

  Future<void> _openWhatsAppChatAndCopy() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();

    setState(() {
      _isCopyingReceipt = true;
    });

    try {
      // 1. Render receipt image and copy to Windows clipboard
      final imgFile = await ServiceWhatsApp.renderReceiptImage(widget.pdfFile);
      await ServiceWhatsApp.copyReceiptToWindowsClipboard(
        pdfFile: widget.pdfFile,
        imageFile: imgFile,
      );

      // 2. Open WhatsApp Desktop or Web
      final success = await ServiceWhatsApp.openWhatsAppChat(
        phone: phone,
        caption: _currentCaption,
      );

      setState(() {
        _isCopyingReceipt = false;
        _chatOpened = true;
      });

      if (success) {
        SnackbarUtil.showSuccess('WhatsApp chat opened! Press Ctrl+V to paste receipt image.');
      }
    } catch (e) {
      setState(() {
        _isCopyingReceipt = false;
      });
      SnackbarUtil.showError('Failed to open WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCloudApi = widget.settings.hasWhatsAppCredentials;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Header ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1EBE5D), Color(0xFF128C7E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send Bill on WhatsApp',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bill #${widget.invoiceNumber}  •  ₹${widget.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Get.back(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Recipient Phone Input
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'CUSTOMER MOBILE NUMBER',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              if (widget.customerName != null && widget.customerName!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.customerName!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            decoration: InputDecoration(
                              counterText: '',
                              prefixText: '+91 ',
                              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              prefixIcon: const Icon(Icons.phone_rounded),
                              hintText: '9876543210',
                              filled: true,
                              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length != 10) {
                                return 'Please enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── METHOD 1: Cloud API (Automated) ──────────────────
                    if (hasCloudApi) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF25D366),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Direct Automated PDF Delivery',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Cloud API Active',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF128C7E)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Directly delivers the official PDF document message to the customer WhatsApp in the background.',
                              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF128C7E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isSendingCloudApi ? null : _sendViaCloudApi,
                              icon: _isSendingCloudApi
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.bolt_rounded, size: 18),
                              label: Text(
                                _isSendingCloudApi ? 'Sending PDF to WhatsApp...' : 'Send PDF Directly (Automated)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_cloudApiSuccessMsg != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _cloudApiSuccessMsg!,
                                      style: const TextStyle(color: Colors.green, fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_cloudApiErrorMsg != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Error: $_cloudApiErrorMsg',
                                  style: const TextStyle(color: Colors.red, fontSize: 11),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── METHOD 2: WhatsApp Web / Desktop ─────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.desktop_windows_rounded, size: 18, color: Color(0xFF1EBE5D)),
                              const SizedBox(width: 8),
                              const Text(
                                'Send via WhatsApp Web / App',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Opens customer chat, prefills invoice text, and copies receipt image to clipboard for instant Ctrl+V paste.',
                            style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isCopyingReceipt ? null : _openWhatsAppChatAndCopy,
                            icon: _isCopyingReceipt
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                              _isCopyingReceipt ? 'Preparing Receipt...' : 'Open Chat & Copy Receipt',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_chatOpened) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.tips_and_updates_rounded, color: Colors.green.shade800, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'WhatsApp Chat Opened!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '1. Click Send in chat to send the bill summary text.\n'
                                    '2. Press Ctrl+V in the chat to paste the bill receipt image!\n'
                                    '3. Or drag the PDF file from the button below.',
                                    style: TextStyle(fontSize: 11, color: Colors.green.shade900, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Alternative Actions Row ──────────────────────────
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        // Windows Share
                        OutlinedButton.icon(
                          onPressed: () => ServiceWhatsApp.sharePdfNative(
                            pdfFile: widget.pdfFile,
                            invoiceNumber: widget.invoiceNumber,
                            caption: _currentCaption,
                            storeName: widget.storeName,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 15),
                          label: const Text('Share PDF (Windows)', style: TextStyle(fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        // Highlight in folder
                        OutlinedButton.icon(
                          onPressed: () => ServiceWhatsApp.highlightInFolder(widget.pdfFile),
                          icon: const Icon(Icons.folder_open_rounded, size: 15),
                          label: const Text('PDF in Folder', style: TextStyle(fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        // View PDF
                        OutlinedButton.icon(
                          onPressed: () => ServiceWhatsApp.openPdfFile(widget.pdfFile),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                          label: const Text('View PDF', style: TextStyle(fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),

                    // Info note if Cloud API not set
                    if (!hasCloudApi) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Want 1-click automatic background PDF delivery? Configure WhatsApp Cloud API in Settings -> WhatsApp.',
                                style: TextStyle(fontSize: 11, color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
