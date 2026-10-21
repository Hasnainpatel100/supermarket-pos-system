import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/home/fragment/setting/controller_home_settings.dart';
import '../util/snackbar_util.dart';

/// Sends a PDF document directly to a WhatsApp number using either:
/// 1. Meta WhatsApp Cloud API (automated direct PDF delivery if configured)
/// 2. WhatsApp Desktop / Web launcher with prefilled message, Explorer highlight & clipboard
class ServiceWhatsApp {
  static const String _baseUrl = 'https://graph.facebook.com/v19.0';

  /// Uploads [pdfFile] as a WhatsApp media object and returns the media ID.
  static Future<String> _uploadMedia({
    required File pdfFile,
    required String accessToken,
    required String phoneNumberId,
  }) async {
    final uri = Uri.parse('$_baseUrl/$phoneNumberId/media');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['messaging_product'] = 'whatsapp'
      ..fields['type'] = 'application/pdf'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          pdfFile.path,
          filename: pdfFile.path.split(Platform.isWindows ? r'\' : '/').last,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Media upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final mediaId = data['id'] as String?;
    if (mediaId == null) {
      throw Exception('No media ID in response: ${response.body}');
    }
    return mediaId;
  }

  /// Sends [pdfFile] as a document to [toPhone] (with country code, e.g. 919876543210)
  /// with an optional [caption].
  static Future<void> sendDocument({
    required File pdfFile,
    required String toPhone,
    required String accessToken,
    required String phoneNumberId,
    String caption = '',
  }) async {
    // Step 1 — Upload media and get ID
    final mediaId = await _uploadMedia(
      pdfFile: pdfFile,
      accessToken: accessToken,
      phoneNumberId: phoneNumberId,
    );

    // Step 2 — Send the document message
    final uri = Uri.parse('$_baseUrl/$phoneNumberId/messages');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messaging_product': 'whatsapp',
        'to': toPhone,
        'type': 'document',
        'document': {
          'id': mediaId,
          'caption': caption,
          'filename': pdfFile.path.split(Platform.isWindows ? r'\' : '/').last,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Message send failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Complete dispatch method that handles Cloud API direct sending or Desktop/Web fallback.
  static Future<void> dispatchInvoicePdf({
    required File pdfFile,
    required String phone,
    required String invoiceNumber,
    required String storeName,
    required double total,
    String? customerName,
    ControllerHomeSettings? settings,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final targetPhone = cleanPhone.startsWith('91') && cleanPhone.length == 12
        ? cleanPhone
        : (cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone);

    final ControllerHomeSettings resolvedSettings = settings ??
        (Get.isRegistered<ControllerHomeSettings>()
            ? Get.find<ControllerHomeSettings>()
            : Get.put(ControllerHomeSettings()));

    final resolvedStore = storeName.isNotEmpty
        ? storeName
        : (resolvedSettings.rxStoreName.value.isNotEmpty
            ? resolvedSettings.rxStoreName.value
            : 'SUPER MARKET');

    final resolvedCustomer = customerName?.isNotEmpty == true
        ? customerName!
        : 'Valued Customer';

    final caption = '🧾 *Tax Invoice / Bill #$invoiceNumber*\n'
        '🏪 *$resolvedStore*\n'
        '👤 *Customer:* $resolvedCustomer\n'
        '💰 *Net Amount:* ₹${total.toStringAsFixed(2)}\n\n'
        '⭐ *Thank you for shopping with us!* Please find your invoice PDF attached.';

    // 1. Try WhatsApp Cloud API if credentials are configured
    if (resolvedSettings.hasWhatsAppCredentials) {
      try {
        SnackbarUtil.showSuccess('Sending PDF via WhatsApp Cloud API...');
        await sendDocument(
          pdfFile: pdfFile,
          toPhone: targetPhone,
          accessToken: resolvedSettings.rxWhatsAppToken.value,
          phoneNumberId: resolvedSettings.rxWhatsAppPhoneId.value,
          caption: caption,
        );
        SnackbarUtil.showSuccess('Invoice PDF sent to WhatsApp successfully!');
        return;
      } catch (e) {
        debugPrint('WhatsApp Cloud API failed, falling back to desktop/web: $e');
        SnackbarUtil.showError('Cloud API error: $e. Opening WhatsApp...');
      }
    }

    // 2. Fallback: Launch WhatsApp Web / App & copy file to clipboard
    try {
      SnackbarUtil.showSuccess('Opening WhatsApp...');

      // Copy PDF directly to Windows clipboard
      if (Platform.isWindows) {
        try {
          await Process.run('powershell', [
            '-NoProfile',
            '-Command',
            'Set-Clipboard -LiteralPath "${pdfFile.path}"',
          ]);
        } catch (_) {}

        // Highlight in Windows Explorer for drag-and-drop
        try {
          await Process.run('explorer.exe', ['/select,', pdfFile.path]);
        } catch (_) {}
      }

      // Open WhatsApp chat with prefilled message
      final encodedText = Uri.encodeComponent(caption);
      final waUrl = Uri.parse('https://wa.me/$targetPhone?text=$encodedText');
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);

      // System share sheet (works on mobile/desktop share targets)
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
          subject: 'Invoice #$invoiceNumber from $resolvedStore',
        );
      } catch (_) {}

      SnackbarUtil.showSuccess('PDF ready! Press Ctrl+V in WhatsApp chat or drag the file from folder.');
    } catch (e) {
      SnackbarUtil.showError('Failed to launch WhatsApp: $e');
    }
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
