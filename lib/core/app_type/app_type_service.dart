import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_type_profile.dart';
import 'app_type_registry.dart';
import 'enum_app_type.dart';
import '../storage/token_storage.dart';

/// Central reactive service governing application vertical configuration.
///
/// Holds the currently active [AppTypeProfile] as an Rx object, persists selections,
/// and allows swapping global dynamic application themes.
class AppTypeService extends GetxService {
  static AppTypeService get to => Get.find<AppTypeService>();

  /// Eagerly initialized to the native default (MARKET) so the reactive profile
  /// is always available — even if `init()` is never awaited. This prevents
  /// LateInitializationError on first access to `currentProfile`/`currentType`.
  final Rx<AppTypeProfile> rxCurrentProfile =
      Rx<AppTypeProfile>(AppTypeRegistry.getProfile(AppType.market));

  AppTypeProfile get currentProfile => rxCurrentProfile.value;
  AppType get currentType => currentProfile.type;

  /// Initializes the service with the native default ([AppType.market]).
  ///
  /// Idempotent: safe to call multiple times. Restoring a persisted appType
  /// from storage happens via [applyAppType] after login.
  Future<AppTypeService> init() async {
    rxCurrentProfile.value = AppTypeRegistry.getProfile(AppType.market);

    if (kDebugMode) {
      debugPrint('⚡ [AppTypeService] Initialized with AppType: MARKET (native default)');
    }

    return this;
  }

  /// Applies a new application type from raw backend string or enum.
  /// Persists to storage, updates reactive profile, and dynamically adjusts theme.
  Future<void> applyAppType(String rawType) async {
    final appType = parseAppType(rawType);
    final profile = AppTypeRegistry.getProfile(appType);

    rxCurrentProfile.value = profile;

    // Persist to storage
    try {
      if (Get.isRegistered<TokenStorage>()) {
        await Get.find<TokenStorage>().saveAppType(appType.name.toUpperCase());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AppTypeService] Failed to persist appType: $e');
      }
    }

    // Apply primary color dynamic theme update if context exists
    _updateDynamicTheme(profile);

    if (kDebugMode) {
      debugPrint('🎨 [AppTypeService] Swapped vertical context to: ${profile.title}');
    }
  }

  /// Dynamically updates primary brand colors in the global theme.
  void _updateDynamicTheme(AppTypeProfile profile) {
    try {
      final isDark = Get.isDarkMode;
      final colorScheme = ColorScheme.fromSeed(
        seedColor: profile.primaryColor,
        primary: profile.primaryColor,
        secondary: profile.secondaryColor,
        tertiary: profile.accentColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      );

      final newTheme = ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: isDark ? const Color(0xFF161D31) : Colors.white,
      );

      Get.changeTheme(newTheme);
    } catch (_) {}
  }
}