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
/// On login:
///  - Validates that userType / appType == 'MARKET'.
///  - Executes 2 functions to fetch Brand details (by brandId) and Branch details (by branchId).
///  - Strips Brand, Branch, and User management permissions from client users.
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
  /// Enforces:
  /// 1. userType/appType must be MARKET.
  /// 2. Executes 2 functions for brand and branch to fetch only this user's data.
  /// 3. Completely isolates client users by stripping brand, branch, and user management permissions.
  Future<AuthResult> login({
    required String username,
    required String pin,
  }) async {
    try {
      final response = await _api.login(username: username, pin: pin);

      // ── 1. Validate that userType == MARKET ────────────────────────────────
      final userTypeUpper = (response.userType ?? '').trim().toUpperCase();
      final appTypeUpper = (response.appType ?? '').trim().toUpperCase();
      final isMarket = userTypeUpper == 'MARKET' || appTypeUpper == 'MARKET';

      if (!isMarket) {
        final currentType = userTypeUpper.isNotEmpty
            ? userTypeUpper
            : (appTypeUpper.isNotEmpty ? appTypeUpper : 'UNKNOWN');
        if (kDebugMode) {
          debugPrint('🚫 [AuthRepository] Login rejected: userType ($currentType) is not MARKET');
        }
        return AuthResult(
          success: false,
          errorMessage:
              'Access denied: Only MARKET accounts are permitted on this Supermarket POS terminal. (Account type: $currentType)',
          isFromApi: true,
        );
      }

      // ── 2. Persist tokens and identifiers ──────────────────────────────────
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

      // ── 3. Function 1: Fetch brand details ONLY for this user's brandId ───
      if (response.brandId != null && response.brandId!.isNotEmpty) {
        await fetchAndSaveBrandDetails(response.brandId!);
      }

      // ── 4. Function 2: Fetch branch details ONLY for this user's branchId ──
      if (response.branchId != null && response.branchId!.isNotEmpty) {
        await fetchAndSaveBranchDetails(response.branchId!);
      }

      // ── 5. Build EntityUser (Stripping Brand, Branch & User access for clients) ──
      const Set<String> restrictedPermissions = {
        'superVendorAccess',
        'brandManage',
        'brandCreate',
        'brandUpdate',
        'brandDelete',
        'brandView',
        'branchManage',
        'branchCreate',
        'branchUpdate',
        'branchDelete',
        'branchView',
        'userCreate',
        'userUpdate',
        'userDisable',
        'roleAssign',
        'apiUserManage',
      };

      final isSuperVendor = (response.userType?.toUpperCase() == 'PLATFORM');

      List<String> effectivePermissions;
      if (isSuperVendor) {
        effectivePermissions = EnumPermission.values.map((e) => e.name).toList();
      } else {
        // Standard / Client User:
        // Client users cannot see or manage brands, branches, or other users.
        final base = response.permissions.isNotEmpty
            ? response.permissions
            : EnumPermission.values.map((e) => e.name).toList();
        effectivePermissions = base
            .where((p) => !restrictedPermissions.contains(p))
            .toList();
      }

      final entityUser = EntityUser(
        username: response.username,
        first: response.firstName ?? response.username,
        last: response.lastName ?? '',
        role: response.role ?? 'cashier',
        mongoId: response.userId,
        permissions: effectivePermissions,
        isActive: true,
      );

      await _repoStorage.setUser(json.encode(entityUser.toMap()));

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

  // ── 2 Functions for Brand & Branch Data Fetching ──────────────────────────

  /// Function 1: Fetches brand details strictly for the given [brandId],
  /// saves full JSON to local storage, and updates [ServiceBrandContext].
  Future<void> fetchAndSaveBrandDetails(String brandId) async {
    if (brandId.isEmpty) return;
    try {
      final brandApi = _getBrandApi();
      if (brandApi == null) {
        if (kDebugMode) debugPrint('⚠️ [AuthRepository] ServiceBrandApi unavailable');
        return;
      }

      final result = await brandApi.getBrandById(brandId);
      if (result.success && result.data != null) {
        final brand = result.data!;
        // Save full JSON to encrypted local storage
        await _tokenStorage.saveBrandJson(jsonEncode(brand.toMap()));
        // Populate session context
        _brandContext.selectBrand(brand);
        if (kDebugMode) {
          debugPrint('✅ [AuthRepository] Brand data fetched & cached strictly for user: ${brand.name.en} ($brandId)');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthRepository] Could not fetch brand ($brandId): ${result.message}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AuthRepository] Brand fetch error: $e');
      }
    }
  }

  /// Function 2: Fetches branch details strictly for the given [branchId],
  /// saves full JSON (including planDetails) to local storage, and updates [ServiceBrandContext].
  Future<void> fetchAndSaveBranchDetails(String branchId) async {
    if (branchId.isEmpty) return;
    try {
      final branchApi = _getBranchApi();
      if (branchApi == null) {
        if (kDebugMode) debugPrint('⚠️ [AuthRepository] ServiceBranchApi unavailable');
        return;
      }

      final result = await branchApi.getBranchById(branchId);
      if (result.success && result.data != null) {
        final branch = result.data!;
        // Save full JSON (including planDetails, serviceTypes, payment, etc.)
        await _tokenStorage.saveBranchJson(jsonEncode(branch.toMap()));
        // Populate session context
        _brandContext.selectBranch(branch);
        if (kDebugMode) {
          debugPrint(
              '✅ [AuthRepository] Branch data fetched & cached strictly for user: ${branch.name.en} ($branchId) '
              '(maxUsers=${branch.planDetails?.maxUsers}, '
              'maxDevices=${branch.planDetails?.maxPosDevices})');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthRepository] Could not fetch branch ($branchId): ${result.message}');
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
