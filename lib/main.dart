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
    return GetMaterialApp(
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
    );
  }
}

















