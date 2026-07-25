import 'package:get/get.dart';
import 'package:super_market/service/service_locale.dart';

import '../repository/repo_storage.dart';
import '../service/service_audit_log.dart';
import '../service/service_currency.dart';
import '../service/service_object_box.dart';
import '../service/service_storage.dart';
import '../service/service_theme.dart';

class StaticMethods {
  static Future<void> initServices() async {
    // how to call?
    // final themeService = Get.find<ServiceTheme>();
    // final localeService = Get.find<ServiceLocale>();
    // final currencyService = Get.find<ServiceCurrency>();
    // final repoStorage = Get.find<RepoStorage>();

    // storage
    var storage = await ServiceStorage().init();
    Get.put<ServiceStorage>(storage, permanent: true);
    RepoStorage().onInit(storage: storage);
    await Get.putAsync<RepoStorage>(
      () async => RepoStorage().onInit(storage: storage),
      permanent: true,
    );
    // ObjectBox
    await Get.putAsync<ServiceObjectBox>(
      () async => ServiceObjectBox().init(),
      permanent: true,
    );

    // Audit log — depends on ServiceObjectBox; register immediately after it
    Get.put<AuditLogService>(
      AuditLogService(Get.find<ServiceObjectBox>()),
      permanent: true,
    );

    // Initialize services
    Get.put<ServiceTheme>(
      ServiceTheme().onInit(storage: storage),
      permanent: true,
    );

    Get.put<ServiceLocale>(
      ServiceLocale().onInit(storage: storage),
      permanent: true,
    );

    Get.put<ServiceCurrency>(
      ServiceCurrency().onInit(storage: storage),
      permanent: true,
    );
  }
}
