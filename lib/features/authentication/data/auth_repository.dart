import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../enums/enum_permission.dart';
import '../../../model/entity_user.dart';
import '../../../repository/repo_storage.dart';
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
class AuthRepository {
  final AuthApi _api;
  final TokenStorage _tokenStorage;
  final RepoStorage _repoStorage;
  final ServiceBrandContext _brandContext;

  AuthRepository({
    required AuthApi api,
    required TokenStorage tokenStorage,
    required RepoStorage repoStorage,
    required ServiceBrandContext brandContext,
  })  : _api = api,
        _tokenStorage = tokenStorage,
        _repoStorage = repoStorage,
        _brandContext = brandContext;

  /// Performs backend login using username and pin/password.
  Future<AuthResult> login({
    required String username,
    required String pin,
  }) async {
    try {
      final response = await _api.login(username: username, pin: pin);

      // Save tokens securely without logging token values
      if (response.accessToken.isNotEmpty) {
        await _tokenStorage.saveAccessToken(response.accessToken);
      }
      if (response.refreshToken.isNotEmpty) {
        await _tokenStorage.saveRefreshToken(response.refreshToken);
      }

      // Preserve brandId and branchId in context & storage if provided by backend
      if (response.brandId != null && response.brandId!.isNotEmpty) {
        await _tokenStorage.saveBrandId(response.brandId!);
      }
      if (response.branchId != null && response.branchId!.isNotEmpty) {
        await _tokenStorage.saveBranchId(response.branchId!);
      }

      // Preserve appType for MARKET validation on session restore
      if (response.appType != null && response.appType!.isNotEmpty) {
        await _tokenStorage.saveAppType(response.appType!);
      }

      // Map AuthLoginResponse to EntityUser for application session compatibility
      final roleNormalized = response.role?.toUpperCase().replaceAll('_', '') ?? '';
      final isSuperAdmin = roleNormalized == 'SUPERADMIN' ||
          response.userType?.toUpperCase() == 'PLATFORM';

      final allPermissions = EnumPermission.values.map((e) => e.name).toList();

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

      // Save user profile JSON in RepoStorage
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

  /// Logout current user and clear stored tokens and session context.
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _brandContext.clear();
    await _repoStorage.setUser('');
  }
}
