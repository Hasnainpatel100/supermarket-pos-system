import 'package:flutter/services.dart';

/// Utility and input formatter that normalizes barcode scanner output for invoice numbers.
///
/// Scanner machines often translate hyphen '-' to slash '/' depending on keyboard layout
/// or regional scanner firmware settings (e.g. BIL/1792849558790 instead of BIL-1792849558790).
/// This formatter ensures that all inputs, pastes, and keystrokes automatically convert
/// forward slashes to hyphens across the entire system.
class InvoicePatternFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll('\r', '').replaceAll('\n', '');
    if (!raw.contains('/')) {
      if (raw == newValue.text) return newValue;
      return newValue.copyWith(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
    }
    final sanitized = raw.replaceAll('/', '-');
    return newValue.copyWith(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }
}

/// Helper function to normalize invoice queries across database lookups and searches.
String sanitizeInvoiceBarcode(String? raw) {
  if (raw == null) return '';
  return raw
      .replaceAll('\r', '')
      .replaceAll('\n', '')
      .replaceAll('/', '-')
      .trim();
}
