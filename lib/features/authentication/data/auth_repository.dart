import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../enums/enum_permission.dart';
import '../../../model/entity_user.dart';
import '../../../model/model_brand.dart';
import '../../../model/model_branch.dart';
import '../../../repository/repo_storage.dart';
import '../../../service/service_brand_api.dart';
import '../../../service/service_branch_api.dart';
import '../../../service/service_brand_context.dart';
import 'auth_api.dart';
import 'models/auth_response_model.dart';

/// Result wrapper for authentication attempts.
class AuthResult {
  final bool success;
  final EntityUser? user;
  final AuthLoginResponse? authResponse;
  final String? errorMessage;
  final bool isFromApi;

  AuthResult({
    required this.success,
    this.user,
    this.authResponse,
    this.errorMessage,
    this.isFromApi = true,
  });
}

/// Authentication Repository handling backend API login, token persistence,
/// session context storage, and user profile management.
///
/// After a successful login it also:
///  - Fetches the full brand details using brandId from the JWT response
///  - Fetches the full branch details using branchId from the JWT response
///  - Saves both as JSON strings in TokenStorage (encrypted local storage)
///  - Populates ServiceBrandContext so the rest of the app has instant access
class AuthRepository {
  final AuthApi _api;
  final TokenStorage _tokenStorage;
  final RepoStorage _repoStorage;
  final ServiceBrandContext _brandContext;
  final ServiceBrandApi? _brandApi;
  final ServiceBranchApi? _branchApi;

  AuthRepository({
    required AuthApi api,
    required TokenStorage tokenStorage,
    required RepoStorage repoStorage,
    required ServiceBrandContext brandContext,
    ServiceBrandApi? brandApi,
    ServiceBranchApi? branchApi,
  })  : _api = api,
        _tokenStorage = tokenStorage,
        _repoStorage = repoStorage,
        _brandContext = brandContext,
        _brandApi = brandApi,
        _branchApi = branchApi;

  /// Performs backend login using username and pin/password.
  ///
  /// On success, automatically fetches & caches the brand and branch
  /// associated with the logged-in user so the app is fully configured
  /// without requiring any additional user action.
  Future<AuthResult> login({
    required String username,
    required String pin,
  }) async {
    try {
      final response = await _api.login(username: username, pin: pin);

      // ── 1. Persist tokens ─────────────────────────────────────────────────
      if (response.accessToken.isNotEmpty) {
        await _tokenStorage.saveAccessToken(response.accessToken);
      }
      if (response.refreshToken.isNotEmpty) {
        await _tokenStorage.saveRefreshToken(response.refreshToken);
      }
      if (response.brandId != null && response.brandId!.isNotEmpty) {
        await _tokenStorage.saveBrandId(response.brandId!);
      }
      if (response.branchId != null && response.branchId!.isNotEmpty) {
        await _tokenStorage.saveBranchId(response.branchId!);
      }
      if (response.appType != null && response.appType!.isNotEmpty) {
        await _tokenStorage.saveAppType(response.appType!);
      }

      // ── 2. Build EntityUser ───────────────────────────────────────────────
      final roleNormalized =
          response.role?.toUpperCase().replaceAll('_', '') ?? '';
      final isSuperAdmin = roleNormalized == 'SUPERADMIN' ||
          response.userType?.toUpperCase() == 'PLATFORM';

      final allPermissions =
          EnumPermission.values.map((e) => e.name).toList();

      final entityUser = EntityUser(
        username: response.username,
        first: response.firstName ?? response.username,
        last: response.lastName ?? '',
        role: response.role ?? 'superAdmin',
        mongoId: response.userId,
        permissions: isSuperAdmin
            ? allPermissions
            : (response.permissions.isNotEmpty
                ? response.permissions
                : allPermissions),
        isActive: true,
      );

      await _repoStorage.setUser(json.encode(entityUser.toMap()));

      // ── 3. Fetch & cache brand details using brandId from JWT ─────────────
      if (response.brandId != null && response.brandId!.isNotEmpty) {
        await _fetchAndSaveBrand(response.brandId!);
      }

      // ── 4. Fetch & cache branch details using branchId from JWT ──────────
      if (response.branchId != null && response.branchId!.isNotEmpty) {
        await _fetchAndSaveBranch(response.branchId!);
      }

      return AuthResult(
        success: true,
        user: entityUser,
        authResponse: response,
        isFromApi: true,
      );
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthRepository] API Login error: ${e.message}');
      }
      return AuthResult(
        success: false,
        errorMessage: e.message,
        isFromApi: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthRepository] Unexpected login error: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: e.toString(),
        isFromApi: false,
      );
    }
  }

  /// Restores brand and branch context from local storage on app start
  /// (when the user is already logged in and the app is resumed).
  ///
  /// Call this from the splash/init flow after confirming a valid access token exists.
  Future<void> restoreSessionContext() async {
    // Restore brand
    final brandJson = _tokenStorage.getBrandJson();
    if (brandJson != null && brandJson.isNotEmpty) {
      try {
        final map = jsonDecode(brandJson) as Map<String, dynamic>;
        final brand = ModelBrand.fromJson(map);
        _brandContext.selectBrand(brand);
        if (kDebugMode) {
          debugPrint('✅ [AuthRepository] Brand context restored: ${brand.name.en}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthRepository] Failed to restore brand from cache: $e');
        }
      }
    }

    // Restore branch
    final branchJson = _tokenStorage.getBranchJson();
    if (branchJson != null && branchJson.isNotEmpty) {
      try {
        final map = jsonDecode(branchJson) as Map<String, dynamic>;
        final branch = ModelBranch.fromJson(map);
        _brandContext.selectBranch(branch);
        if (kDebugMode) {
          debugPrint(
              '✅ [AuthRepository] Branch context restored: ${branch.name.en}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthRepository] Failed to restore branch from cache: $e');
        }
      }
    }
  }

  /// Logout current user and clear stored tokens and session context.
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _brandContext.clear();
    await _repoStorage.setUser('');
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Fetches brand by ID, saves JSON to storage, and updates [ServiceBrandContext].
  Future<void> _fetchAndSaveBrand(String brandId) async {
    try {
      final brandApi = _getBrandApi();
      if (brandApi == null) return;

      final result = await brandApi.getBrandById(brandId);
      if (result.success && result.data != null) {
        final brand = result.data!;
        await _tokenStorage.saveBrandJson(jsonEncode(brand.toMap()));
        _brandContext.selectBrand(brand);
        if (kDebugMode) {
          debugPrint('✅ [AuthRepository] Brand fetched and saved: ${brand.name.en}');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [AuthRepository] Could not fetch brand ($brandId): ${result.message}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthRepository] Brand fetch error: $e');
      }
    }
  }

  /// Fetches branch by ID, saves JSON to storage, and updates [ServiceBrandContext].
  Future<void> _fetchAndSaveBranch(String branchId) async {
    try {
      final branchApi = _getBranchApi();
      if (branchApi == null) return;

      final result = await branchApi.getBranchById(branchId);
      if (result.success && result.data != null) {
        final branch = result.data!;
        await _tokenStorage.saveBranchJson(jsonEncode(branch.toMap()));
        _brandContext.selectBranch(branch);
        if (kDebugMode) {
          debugPrint(
              '✅ [AuthRepository] Branch fetched and saved: ${branch.name.en} '
              '(maxUsers=${branch.planDetails?.maxUsers}, '
              'maxDevices=${branch.planDetails?.maxPosDevices})');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [AuthRepository] Could not fetch branch ($branchId): ${result.message}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthRepository] Branch fetch error: $e');
      }
    }
  }

  ServiceBrandApi? _getBrandApi() {
    if (_brandApi != null) return _brandApi;
    try {
      if (Get.isRegistered<ServiceBrandApi>()) {
        return Get.find<ServiceBrandApi>();
      }
    } catch (_) {}
    return null;
  }

  ServiceBranchApi? _getBranchApi() {
    if (_branchApi != null) return _branchApi;
    try {
      if (Get.isRegistered<ServiceBranchApi>()) {
        return Get.find<ServiceBranchApi>();
      }
    } catch (_) {}
    return null;
  }
}
