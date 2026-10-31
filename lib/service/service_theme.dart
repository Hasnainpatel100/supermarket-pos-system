import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/app_type/app_type_service.dart';
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

  /// Applies the requested brightness mode and re-themes the UI.
  ///
  /// 1. Persists the preference to storage.
  /// 2. Notifies [AppTypeService] to re-apply the active vertical's palette
  ///    (Orange for Steel, Green for Market, ...) for the new brightness so
  ///    Light/Dark toggling never destroys the vertical's brand colors.
  /// 3. Switches the host's [ThemeMode] so the root [GetMaterialApp] rebuilds.
  Future<void> switchTheme() async {
    rxIsDarkMode.value = !rxIsDarkMode.value;
    await _storage.writeString(_key, rxIsDarkMode.value ? 'dark' : 'light');
    _applyBrightness(rxIsDarkMode.value);
    debugPrint("Theme changed to: ${rxIsDarkMode.value ? 'dark' : 'light'}");
  }

  Future<void> setTheme(bool isDark) async {
    rxIsDarkMode.value = isDark;
    await _storage.writeString(_key, isDark ? 'dark' : 'light');
    _applyBrightness(isDark);
  }

  /// Re-applies the active vertical's theme for the given brightness.
  void _applyBrightness(bool isDark) {
    // Let AppTypeService rebuild its per-vertical light/dark theme variants
    // and inject them directly via Get.changeTheme. Do NOT call
    // Get.changeThemeMode() — that would force the host's hardcoded
    // AppThemes.light/dark (Market teal) over the vertical palette.
    if (Get.isRegistered<AppTypeService>()) {
      Get.find<AppTypeService>().refreshTheme(isDark);
    }
  }
}
