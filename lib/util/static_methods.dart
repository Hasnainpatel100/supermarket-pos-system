import 'package:get/get.dart';
import 'package:super_market/service/service_locale.dart';

import '../core/network/dio_client.dart';
import '../core/storage/token_storage.dart';
import '../features/authentication/data/auth_api.dart';
import '../features/authentication/data/auth_repository.dart';
import '../repository/repo_brand.dart';
import '../repository/repo_branch.dart';
import '../repository/repo_api_user.dart';
import '../repository/repo_storage.dart';
import '../service/service_audit_log.dart';
import '../service/service_brand_api.dart';
import '../service/service_brand_context.dart';
import '../service/service_branch_api.dart';
import '../service/service_api_user.dart';
import '../service/service_currency.dart';
import '../service/service_object_box.dart';
import '../service/service_storage.dart';
import '../service/service_theme.dart';

class StaticMethods {
  static Future<void> initServices() async {
    // 1. Storage
    var storage = await ServiceStorage().init();
    Get.put<ServiceStorage>(storage, permanent: true);

    var repoStorage = RepoStorage()..onInit(storage: storage);
    Get.put<RepoStorage>(repoStorage, permanent: true);

    // 2. Token Storage abstraction
    final tokenStorage = Get.put<TokenStorage>(
      TokenStorage(storage),
      permanent: true,
    );

    // 3. Centralized Dio Client (load saved URL from storage or default to 127.0.0.1:8080)
    final savedBaseUrl = storage.readString('brand_api_base_url') ??
        storage.readString('api_base_url') ??
        'http://127.0.0.1:8080';

    final dioClient = Get.put<DioClient>(
      DioClient(tokenStorage: tokenStorage, baseUrl: savedBaseUrl),
      permanent: true,
    );

    // 4. ObjectBox Database (Synchronous Get.put after awaiting init())
    final objectBoxService = await ServiceObjectBox().init();
    Get.put<ServiceObjectBox>(
      objectBoxService,
      permanent: true,
    );

    // 5. Audit Log Service
    Get.put<AuditLogService>(
      AuditLogService(objectBoxService),
      permanent: true,
    );

    // 6. UI Preferences Services
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

    // 7. Brand + Branch Session Context (POS-wide)
    final brandContext = Get.put<ServiceBrandContext>(
      ServiceBrandContext(),
      permanent: true,
    );

    // 8. Auth API & Repository
    final authApi = Get.put<AuthApi>(
      AuthApi(dioClient.dio),
      permanent: true,
    );

    Get.put<AuthRepository>(
      AuthRepository(
        api: authApi,
        tokenStorage: tokenStorage,
        repoStorage: repoStorage,
        brandContext: brandContext,
      ),
      permanent: true,
    );

    // 9. Brand API Service & Repo (uses Centralized Dio)
    final brandApi = Get.put<ServiceBrandApi>(
      ServiceBrandApi(storage, dioClient: dioClient.dio),
      permanent: true,
    );
    Get.put<RepoBrand>(
      RepoBrand(api: brandApi, storage: storage),
      permanent: true,
    );

    // 10. Branch API Service & Repo (uses Centralized Dio)
    final branchApi = Get.put<ServiceBranchApi>(
      ServiceBranchApi(storage, dioClient: dioClient.dio),
      permanent: true,
    );
    Get.put<RepoBranch>(
      RepoBranch(api: branchApi, storage: storage),
      permanent: true,
    );

    // 11. API User Service & Repo (uses Centralized Dio)
    final apiUserApi = Get.put<ServiceApiUser>(
      ServiceApiUser(storage, dioClient: dioClient.dio),
      permanent: true,
    );
    Get.put<RepoApiUser>(
      RepoApiUser(api: apiUserApi, storage: storage),
      permanent: true,
    );
  }
}
