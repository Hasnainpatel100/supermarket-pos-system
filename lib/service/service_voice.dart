import 'dart:io';
import 'package:flutter/foundation.dart';

class ServiceVoice {
  /// Announces payment receipt aloud like a commercial soundbox.
  /// Runs asynchronously in background without delaying UI thread.
  static Future<void> announcePayment({
    required double amount,
    required String paymentMode,
    String storeName = '',
  }) async {
    try {
      final formattedAmount = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
      final text = 'Payment of $formattedAmount rupees received via $paymentMode.';

      await speak(text);
    } catch (e) {
      debugPrint('Voice announcement error: $e');
    }
  }

  /// Speaks arbitrary text using native OS text-to-speech.
  static Future<void> speak(String text) async {
    try {
      // Clean speech text for command line safety
      final cleanText = text.replaceAll("'", " ").replaceAll('"', ' ').replaceAll('`', ' ');

      if (Platform.isWindows) {
        await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-WindowStyle',
            'Hidden',
            '-Command',
            "(New-Object -ComObject SAPI.SpVoice).Speak('$cleanText')",
          ],
          runInShell: true,
        );
      } else if (Platform.isMacOS) {
        await Process.run('say', [cleanText]);
      } else if (Platform.isLinux) {
        await Process.run('spd-say', [cleanText]);
      }
    } catch (e) {
      debugPrint('Voice TTS error: $e');
    }
  }
}
