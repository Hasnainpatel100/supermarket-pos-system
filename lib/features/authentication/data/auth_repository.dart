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

      // ── 1. Strictly enforce appType == 'MARKET' requirement ────────────────
      final appTypeUpper = (response.appType ?? '').trim().toUpperCase();

      if (appTypeUpper != 'MARKET') {
        if (kDebugMode) {
          debugPrint('🚫 [AuthRepository] Login rejected: appType "$appTypeUpper" is not MARKET');
        }
        return AuthResult(
          success: false,
          errorMessage:
              'Access denied: Only MARKET accounts are permitted to login. Current appType: "${response.appType ?? 'none'}".',
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

      bool isValidMongoId(String? id) {
        if (id == null || id.isEmpty) return false;
        return RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
      }

      // ── 3. Function 1: Fetch brand details ONLY for this user's brandId ───
      final brandIdToFetch = response.brandId ?? '';
      await fetchAndSaveBrandDetails(brandIdToFetch);

      // ── 4. Function 2: Fetch branch details ONLY for this user's branchId ──
      final branchIdToFetch = response.branchId ?? '';
      await fetchAndSaveBranchDetails(
        branchIdToFetch,
        brandId: _brandContext.selectedBrandId ?? (isValidMongoId(brandIdToFetch) ? brandIdToFetch : null),
      );

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

      // Ensure all local operational POS permissions (items, customers, pos, stocks, reports, expenses)
      // are granted to operational users, while stripping brand, branch, and user management.
      final operationalPermissions = EnumPermission.values
          .map((e) => e.name)
          .where((p) => !restrictedPermissions.contains(p))
          .toSet();

      // Also retain any server permissions that are not restricted
      operationalPermissions.addAll(
        response.permissions.where((p) => !restrictedPermissions.contains(p)),
      );

      final effectivePermissions = operationalPermissions.toList();

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
    // 1. Restore brand from cache if present
    final brandJson = _tokenStorage.getBrandJson();
    if (brandJson != null && brandJson.isNotEmpty) {
      try {
        final map = jsonDecode(brandJson) as Map<String, dynamic>;
        final brand = ModelBrand.fromJson(map);
        _brandContext.selectBrand(brand);
        if (kDebugMode) {
          debugPrint('✅ [AuthRepository] Brand context restored from cache: ${brand.name.en}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthRepository] Failed to restore brand from cache: $e');
        }
      }
    }

    // 2. Restore branch from cache if present
    final branchJson = _tokenStorage.getBranchJson();
    if (branchJson != null && branchJson.isNotEmpty) {
      try {
        final map = jsonDecode(branchJson) as Map<String, dynamic>;
        final branch = ModelBranch.fromJson(map);
        _brandContext.selectBranch(branch);
        if (kDebugMode) {
          debugPrint('✅ [AuthRepository] Branch context restored from cache: ${branch.name.en}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthRepository] Failed to restore branch from cache: $e');
        }
      }
    }

    // 3. Fallback: If brand or branch is still missing, fetch live from backend
    if (!_brandContext.hasBrand) {
      final savedBrandId = _tokenStorage.getBrandId() ?? '';
      await fetchAndSaveBrandDetails(savedBrandId);
    }
    if (!_brandContext.hasBranch) {
      final savedBranchId = _tokenStorage.getBranchId() ?? '';
      await fetchAndSaveBranchDetails(
        savedBranchId,
        brandId: _brandContext.selectedBrandId,
      );
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
    try {
      final brandApi = _getBrandApi();
      if (brandApi == null) {
        if (kDebugMode) debugPrint('⚠️ [AuthRepository] ServiceBrandApi unavailable');
        return;
      }

      ModelBrand? brand;
      if (brandId.isNotEmpty && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(brandId)) {
        final result = await brandApi.getBrandById(brandId);
        if (result.success && result.data != null) {
          brand = result.data!;
        }
      }

      // Fallback: If not found directly by ID, query brands list for MARKET
      if (brand == null) {
        final allBrands = await brandApi.getBrands(appType: 'MARKET');
        if (allBrands.success && allBrands.data != null && allBrands.data!.isNotEmpty) {
          if (brandId.isNotEmpty) {
            brand = allBrands.data!.firstWhereOrNull((b) => b.id == brandId);
          }
          brand ??= allBrands.data!.firstWhereOrNull((b) => b.status.toLowerCase() == 'active') ?? allBrands.data!.first;
        }
      }

      if (brand != null) {
        // Save full JSON to encrypted local storage
        await _tokenStorage.saveBrandJson(jsonEncode(brand.toMap()));
        if (brand.id != null) {
          await _tokenStorage.saveBrandId(brand.id!);
        }
        // Populate session context
        _brandContext.selectBrand(brand);
        if (kDebugMode) {
          debugPrint('✅ [AuthRepository] Brand data fetched & cached: ${brand.name.en} (${brand.id})');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthRepository] Could not resolve brand for brandId ($brandId)');
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
  Future<void> fetchAndSaveBranchDetails(String branchId, {String? brandId}) async {
    try {
      final branchApi = _getBranchApi();
      if (branchApi == null) {
        if (kDebugMode) debugPrint('⚠️ [AuthRepository] ServiceBranchApi unavailable');
        return;
      }

      final activeBrandId = brandId ?? _brandContext.selectedBrandId ?? _tokenStorage.getBrandId();
      ModelBranch? branch;

      // 1. Try fetching by branchId if valid
      if (branchId.isNotEmpty && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(branchId)) {
        final result = await branchApi.getBranchById(branchId);
        if (result.success && result.data != null) {
          branch = result.data!;
        }
      }

      // 2. Fallback: If not found by ID or placeholder, fetch branches for the active brand
      if (branch == null && activeBrandId != null && activeBrandId.isNotEmpty) {
        final branchesResult = await branchApi.getBranchesByBrand(activeBrandId);
        if (branchesResult.success && branchesResult.data != null && branchesResult.data!.isNotEmpty) {
          if (branchId.isNotEmpty) {
            branch = branchesResult.data!.firstWhereOrNull((b) => b.id == branchId);
          }
          branch ??= branchesResult.data!.firstWhereOrNull((b) => b.status.toLowerCase() == 'active') ?? branchesResult.data!.first;
        }
      }

      if (branch != null) {
        // Save full JSON (including planDetails, serviceTypes, payment, etc.)
        await _tokenStorage.saveBranchJson(jsonEncode(branch.toMap()));
        if (branch.id != null) {
          await _tokenStorage.saveBranchId(branch.id!);
        }
        // Populate session context
        _brandContext.selectBranch(branch);
        if (kDebugMode) {
          debugPrint(
              '✅ [AuthRepository] Branch data fetched & cached: ${branch.name.en} (${branch.id}) '
              '(maxUsers=${branch.planDetails?.maxUsers}, '
              'maxDevices=${branch.planDetails?.maxPosDevices})');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthRepository] Could not resolve branch for branchId ($branchId), brandId ($activeBrandId)');
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
