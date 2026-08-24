import 'package:flutter/foundation.dart';
import '../../service/service_storage.dart';

/// Secure token & session context storage abstraction.
/// Encapsulates storage keys and avoids scattering token management logic.
/// Never logs tokens, pins, or passwords.
class TokenStorage {
  final ServiceStorage _storage;

  static const String keyAccessToken = 'auth_access_token';
  static const String keyRefreshToken = 'auth_refresh_token';
  static const String keyBrandId = 'auth_brand_id';
  static const String keyBranchId = 'auth_branch_id';
  static const String keyUserInfo = 'auth_user_info_json';

  TokenStorage(this._storage);

  /// Save the JWT access token.
  Future<void> saveAccessToken(String token) async {
    await _storage.writeString(keyAccessToken, token);
  }

  /// Get stored JWT access token, or null if not available.
  String? getAccessToken() {
    return _storage.readString(keyAccessToken);
  }

  /// Save the refresh token.
  Future<void> saveRefreshToken(String token) async {
    await _storage.writeString(keyRefreshToken, token);
  }

  /// Get stored refresh token, or null if not available.
  String? getRefreshToken() {
    return _storage.readString(keyRefreshToken);
  }

  /// Save active brand ID.
  Future<void> saveBrandId(String brandId) async {
    await _storage.writeString(keyBrandId, brandId);
  }

  /// Get active brand ID.
  String? getBrandId() {
    return _storage.readString(keyBrandId);
  }

  /// Save active branch ID.
  Future<void> saveBranchId(String branchId) async {
    await _storage.writeString(keyBranchId, branchId);
  }

  /// Get active branch ID.
  String? getBranchId() {
    return _storage.readString(keyBranchId);
  }

  /// Check if user is currently authenticated (has access token).
  bool get hasAccessToken {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all tokens and session context (e.g. on logout or refresh failure).
  Future<void> clearTokens() async {
    await _storage.delete(keyAccessToken);
    await _storage.delete(keyRefreshToken);
    await _storage.delete(keyBrandId);
    await _storage.delete(keyBranchId);
    await _storage.delete(keyUserInfo);
    if (kDebugMode) {
      debugPrint('🔑 [TokenStorage] Tokens and session cleared.');
    }
  }
}
