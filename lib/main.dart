import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'service/service_locale.dart';
import 'service/service_theme.dart';
import 'util/app_route.dart';
import 'util/app_theme.dart';
import 'util/app_translation.dart';
import 'util/static_methods.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guard against known Flutter desktop framework assertion desyncs in HardwareKeyboard
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    if (msg.contains('hardware_keyboard.dart') &&
        (msg.contains('is already pressed') || msg.contains('is not pressed'))) {
      // Suppress benign HardwareKeyboard assertion desync on Windows desktop
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains('hardware_keyboard.dart') &&
        (msg.contains('is already pressed') || msg.contains('is not pressed'))) {
      return true; // Mark as handled to prevent crashing platform message callback
    }
    return false;
  };

  await AppTranslation.loadTranslations();
  await StaticMethods.initServices();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final themeService = Get.find<ServiceTheme>();
  final localeService = Get.find<ServiceLocale>();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        smartManagement: SmartManagement.full,
        debugShowCheckedModeBanner: false,
        title: 'app_title'.tr,
        translations: AppTranslation(),
        locale: localeService.rxLocale.value,
        fallbackLocale: const Locale('en', 'US'),
        theme: AppThemes.light,
        darkTheme: AppThemes.dark,
        themeMode: themeService.rxIsDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        initialRoute: AppRoute.splash,
        getPages: AppRoute.pages,
      ),
    );
  }
}

















