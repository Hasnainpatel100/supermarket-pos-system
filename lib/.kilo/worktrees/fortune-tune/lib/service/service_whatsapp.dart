import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

/// Sends a PDF document directly to a WhatsApp number using the
/// Meta WhatsApp Cloud API.
///
/// Setup (one-time):
///   1. Go to https://developers.facebook.com/
///   2. Create an App → Add WhatsApp product
///   3. Copy the "Temporary Access Token" and "Phone Number ID"
///   4. Paste them in Settings → WhatsApp API in this app
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
          filename: pdfFile.path.split(r'\').last,
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
  ///
  /// Throws an [Exception] if any step fails.
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
          'filename': pdfFile.path.split(r'\').last,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Message send failed (${response.statusCode}): ${response.body}',
      );
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
