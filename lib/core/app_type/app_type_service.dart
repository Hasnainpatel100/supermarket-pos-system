import 'package:flutter/foundation.dart';
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

  // _buildThemes removed: global theme stays green (AppThemes.light / AppThemes.dark).
  // Vertical-specific widgets read profile.primaryColor directly for their own accents.

  /// No-op: the global app theme is always the green brand theme (AppThemes.light /
  /// AppThemes.dark). Vertical colours live only in their own slot widgets via
  /// [currentProfile].primaryColor. This intentionally does NOT call Get.changeTheme.
  void _updateDynamicTheme(AppTypeProfile profile) {
    // Intentionally empty — global theme stays green for all verticals.
    if (kDebugMode) {
      debugPrint('🎨 [AppTypeService] Profile swapped to: ${profile.title} (theme stays green)');
    }
  }

  /// Re-applies the active vertical's theme for the requested brightness.
  ///
  /// Called by [ServiceTheme] after a Light/Dark toggle. Injects the vertical's
  /// palette directly via [Get.changeTheme] so the host's hardcoded
  /// [AppThemes.light]/[AppThemes.dark] never override the vertical brand colors
  /// (Orange for Steel, Green for Market, ...).
  void refreshTheme(bool isDark) {
    // Intentionally empty — ServiceTheme.switchTheme() owns ThemeMode.
  }

  // No cached dynamic themes — global theme is always AppThemes.light / AppThemes.dark.
}