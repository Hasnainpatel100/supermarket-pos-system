import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Dynamically loads translations from JSON assets instead of modular Dart files.
class AppTranslation extends Translations {
  static final Map<String, Map<String, String>> _keys = {};

  static Future<void> loadTranslations() async {
    final locales = ['en_US', 'hi_IN', 'mr_IN', 'ur_PK'];
    for (var locale in locales) {
      try {
        final jsonString = await rootBundle.loadString('assets/translations/$locale.json');
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _keys[locale] = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        // Fallback or log if loading fails
        print('Error loading translation asset for $locale: $e');
      }
    }
  }

  @override
  Map<String, Map<String, String>> get keys => _keys;
}
