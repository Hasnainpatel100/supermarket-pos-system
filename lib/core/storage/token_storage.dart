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
  static const String keyAppType = 'auth_app_type';
  /// Full brand model JSON saved after login for offline session restore.
  static const String keyBrandJson = 'auth_session_brand_json';
  /// Full branch model JSON saved after login for offline session restore.
  static const String keyBranchJson = 'auth_session_branch_json';

  TokenStorage(this._storage);

  /// Cleans and strips 'Bearer ' prefixes, quotes, whitespace, and newlines
  static String sanitizeToken(String? raw) {
    if (raw == null) return '';
    var token = raw.trim();
    if ((token.startsWith('"') && token.endsWith('"')) ||
        (token.startsWith("'") && token.endsWith("'"))) {
      token = token.substring(1, token.length - 1).trim();
    }
    while (token.toLowerCase().startsWith('bearer ')) {
      token = token.substring(7).trim();
    }
    return token.replaceAll('\r', '').replaceAll('\n', '').trim();
  }

  /// Save the JWT access token.
  Future<void> saveAccessToken(String token) async {
    final clean = sanitizeToken(token);
    await _storage.writeString(keyAccessToken, clean);
    await _storage.writeString('brand_api_auth_token', clean);
  }

  /// Get stored JWT access token, or null if not available.
  String? getAccessToken() {
    final token = _storage.readString(keyAccessToken);
    if (token == null || token.trim().isEmpty) return null;
    final clean = sanitizeToken(token);
    return clean.isNotEmpty ? clean : null;
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

  /// Save the authenticated user's appType (e.g. MARKET, RESTAURANT).
  Future<void> saveAppType(String appType) async {
    await _storage.writeString(keyAppType, appType);
  }

  /// Get stored appType, or null if not available.
  String? getAppType() {
    return _storage.readString(keyAppType);
  }

  /// Save the full brand model as a JSON string.
  Future<void> saveBrandJson(String json) async {
    await _storage.writeString(keyBrandJson, json);
  }

  /// Get the stored brand JSON string (full ModelBrand), or null.
  String? getBrandJson() {
    return _storage.readString(keyBrandJson);
  }

  /// Save the full branch model as a JSON string.
  Future<void> saveBranchJson(String json) async {
    await _storage.writeString(keyBranchJson, json);
  }

  /// Get the stored branch JSON string (full ModelBranch), or null.
  String? getBranchJson() {
    return _storage.readString(keyBranchJson);
  }

  /// Check if user is currently authenticated (has access token).
  bool get hasAccessToken {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all tokens and session context (e.g. on logout or refresh failure).
  Future<void> clearTokens() async {
    await _storage.delete(keyAccessToken);
    await _storage.delete('brand_api_auth_token');
    await _storage.delete(keyRefreshToken);
    await _storage.delete(keyBrandId);
    await _storage.delete(keyBranchId);
    await _storage.delete(keyUserInfo);
    await _storage.delete(keyAppType);
    await _storage.delete(keyBrandJson);
    await _storage.delete(keyBranchJson);
    if (kDebugMode) {
      debugPrint('🔑 [TokenStorage] Tokens and session cleared.');
    }
  }
}

