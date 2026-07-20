import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'service_storage.dart';

class ServiceLocale {
  late ServiceStorage _storage;
  static const _key = 'lo';
  late Rx<Locale> rxLocale = Locale('en', 'US').obs;

  ServiceLocale onInit({required ServiceStorage storage}) {
    _storage = storage;
    _loadLocale();
    return this;
  }
  void _loadLocale() {
    final code = _storage.readString(_key);
    if (code != null) {
      final parts = code.split('_');
      rxLocale.value = Locale(parts[0], parts.length > 1 ? parts[1] : null);
    }
  }
  Future<void> update(Locale locale) async {
    rxLocale.value = locale;
    final code = locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    await _storage.writeString(_key, code);
    Get.updateLocale(locale);
  }
}
