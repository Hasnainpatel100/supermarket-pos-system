import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'service_storage.dart';

class ServiceTheme {
  late ServiceStorage _storage;
  static const _key = 'tm';

  // Use Rx to make it reactive
  final RxBool rxIsDarkMode = false.obs;

  ServiceTheme onInit({required ServiceStorage storage}) {
    _storage = storage;
    rxIsDarkMode.value = _loadTheme();
    return this;
  }

  bool _loadTheme() {
    // Default to light mode (false)
    final savedTheme = _storage.readString(_key);
    debugPrint("Loaded theme: $savedTheme");
    return savedTheme == 'dark';
  }

  ThemeMode getThemeMode() {
    return rxIsDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> switchTheme() async {
    rxIsDarkMode.value = !rxIsDarkMode.value;
    await _storage.writeString(_key, rxIsDarkMode.value ? 'dark' : 'light');
    var themeMode = getThemeMode();
    Get.changeThemeMode(themeMode);
    debugPrint("Theme changed to: ${rxIsDarkMode.value ? 'dark' : 'light'}");
  }

  Future<void> setTheme(bool isDark) async {
    rxIsDarkMode.value = isDark;
    await _storage.writeString(_key, isDark ? 'dark' : 'light');
    var themeMode = getThemeMode();
    Get.changeThemeMode(themeMode);
  }
}
