import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import '../../service/service_storage.dart';
import '../../util/app_route.dart';
import '../../util/snackbar_util.dart';
import '../storage/token_storage.dart';

/// Dio authentication interceptor.
///
/// Responsibilities:
///  1. Inject `Authorization: Bearer <accessToken>` into every non-auth request.
///  2. On 401 Unauthorized, call `POST /auth/refresh` ONCE with the stored
///     refreshToken to obtain a new accessToken, save it, and retry the original
///     request transparently.
///  3. If the refresh also fails (refresh token expired / missing), clear all
///     tokens and redirect the user to the login screen.
///  4. Uses a mutex (_isRefreshing + _refreshCompleter) so that if multiple
///     requests 401 simultaneously, only ONE refresh call is made and the rest
///     wait for its result.
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  String _baseUrl;

  // ── Refresh-lock state ─────────────────────────────────────────────────────
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    String baseUrl = 'http://172.19.112.1:8080',
  })  : _tokenStorage = tokenStorage,
        _baseUrl = baseUrl;

  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl;
  }

  // ── onRequest ──────────────────────────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Always keep base URL in sync
    if (options.baseUrl.isEmpty) {
      options.baseUrl = _baseUrl;
    }

    final path = options.path;
    final isAuthEndpoint =
        path.startsWith('/auth/login') || path.startsWith('/auth/refresh');

    // Attach the Bearer token to every non-auth request
    if (!isAuthEndpoint) {
      final token = _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [AuthInterceptor] No access token — request may 401');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('🌿 [Dio] ${options.method} ${options.baseUrl}${options.path}');
    }

    return handler.next(options);
  }

  // ── onResponse ─────────────────────────────────────────────────────────────

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '📥 [Dio] HTTP ${response.statusCode} - ${response.requestOptions.path}');
    }
    return handler.next(response);
  }

  // ── onError ────────────────────────────────────────────────────────────────

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    if (kDebugMode) {
      debugPrint(
          '❌ [Dio] HTTP ${response?.statusCode} for ${requestOptions.path}');
    }

    final is401 = response?.statusCode == 401;
    final isAlreadyRetried = requestOptions.extra['isRetry'] == true;
    final isAuthEndpoint = requestOptions.path.startsWith('/auth/login') ||
        requestOptions.path.startsWith('/auth/refresh');

    // Only attempt refresh on a fresh 401 on a non-auth endpoint
    if (!is401 || isAlreadyRetried || isAuthEndpoint) {
      return handler.next(err);
    }

    if (kDebugMode) {
      debugPrint('🔄 [AuthInterceptor] 401 detected. Attempting token refresh...');
    }

    // ── Mutex: if a refresh is already running, wait for it ───────────────────
    if (_isRefreshing) {
      if (kDebugMode) {
        debugPrint('⏳ [AuthInterceptor] Refresh in progress — queuing request.');
      }
      final newToken = await _refreshCompleter!.future;
      if (newToken != null && newToken.isNotEmpty) {
        requestOptions.extra['isRetry'] = true;
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await _retryRequest(requestOptions);
          return handler.resolve(retryResponse);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      }
      return handler.next(err);
    }

    // ── Start the refresh ──────────────────────────────────────────────────────
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    final storedRefreshToken = _tokenStorage.getRefreshToken();
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ [AuthInterceptor] No refresh token stored. Forcing re-login.');
      }
      _finishRefresh(null);
      await _clearAndRedirectToLogin();
      return handler.next(err);
    }

    final newAccessToken = await _callRefreshEndpoint(storedRefreshToken);

    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      // Save to TokenStorage (primary source used by this interceptor)
      await _tokenStorage.saveAccessToken(newAccessToken);

      // Also propagate to legacy ServiceStorage keys used by ServiceBrandApi /
      // ServiceBranchApi so their own Dio interceptors pick up the new token.
      try {
        final storage = Get.find<ServiceStorage>();
        await storage.writeString('auth_access_token', newAccessToken);
        await storage.writeString('brand_api_auth_token', newAccessToken);
      } catch (_) {}

      _finishRefresh(newAccessToken);

      if (kDebugMode) {
        debugPrint(
            '✅ [AuthInterceptor] Token refreshed. Retrying original request.');
      }

      requestOptions.extra['isRetry'] = true;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      try {
        final retryResponse = await _retryRequest(requestOptions);
        return handler.resolve(retryResponse);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    } else {
      // Refresh failed — session completely expired
      _finishRefresh(null);
      await _clearAndRedirectToLogin();
      return handler.next(err);
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  /// Releases the mutex and notifies all waiting requests.
  void _finishRefresh(String? token) {
    _isRefreshing = false;
    _refreshCompleter?.complete(token);
    _refreshCompleter = null;
  }

  /// Calls POST /auth/refresh using a fresh Dio instance (no auth interceptor
  /// to avoid recursion). Parses both top-level and `data`-nested responses.
  ///
  /// Server response format (from Postman):
  /// ```json
  /// {
  ///   "data": {
  ///     "accessToken": "...",
  ///     "refreshToken": "...",
  ///     "expiresIn": 900
  ///   },
  ///   "message": null,
  ///   "meta": null
  /// }
  /// ```
  Future<String?> _callRefreshEndpoint(String refreshToken) async {
    try {
      final refreshDio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
        // A 401 here means the refresh token itself is expired — treat as error
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (kDebugMode) {
        debugPrint(
            '🔑 [AuthInterceptor] /auth/refresh → HTTP ${response.statusCode}');
      }

      final body = response.data;
      if (body is Map<String, dynamic>) {
        // Handle both nested { data: { accessToken } } and flat { accessToken }
        final inner = body['data'];
        final Map<String, dynamic> payload =
            (inner is Map<String, dynamic>) ? inner : body;

        final newAccess = payload['accessToken']?.toString();
        final newRefresh = payload['refreshToken']?.toString();

        // Persist rotated refresh token
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await _tokenStorage.saveRefreshToken(newRefresh);
          try {
            final storage = Get.find<ServiceStorage>();
            await storage.writeString('auth_refresh_token', newRefresh);
          } catch (_) {}
          if (kDebugMode) {
            debugPrint('♻️ [AuthInterceptor] Refresh token rotated and saved.');
          }
        }

        return (newAccess != null && newAccess.isNotEmpty) ? newAccess : null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AuthInterceptor] /auth/refresh request failed: $e');
      }
    }
    return null;
  }

  /// Retries the original request with a fresh Dio instance so it does NOT
  /// pass through this interceptor again (avoids infinite loop).
  Future<Response> _retryRequest(RequestOptions options) async {
    final retryDio = Dio(BaseOptions(
      baseUrl: options.baseUrl.isNotEmpty ? options.baseUrl : _baseUrl,
      connectTimeout: options.connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout: options.receiveTimeout ?? const Duration(seconds: 30),
      sendTimeout: options.sendTimeout ?? const Duration(seconds: 30),
      headers: options.headers,
      validateStatus: (s) => s != null && s >= 200 && s < 300,
    ));
    return retryDio.fetch(options);
  }

  /// Clears all tokens and navigates back to the login screen.
  Future<void> _clearAndRedirectToLogin() async {
    await _tokenStorage.clearTokens();

    // Clear legacy storage keys too
    try {
      final storage = Get.find<ServiceStorage>();
      await storage.delete('auth_access_token');
      await storage.delete('auth_refresh_token');
      await storage.delete('brand_api_auth_token');
    } catch (_) {}

    if (kDebugMode) {
      debugPrint('🔴 [AuthInterceptor] Session expired. Redirecting to login.');
    }

    SnackbarUtil.showWarning(
      'Your session has expired. Please log in again.',
    );

    try {
      if (Get.currentRoute != AppRoute.login) {
        Get.offAllNamed(AppRoute.login);
      }
    } catch (e) {
      debugPrint('⚠️ [AuthInterceptor] Could not navigate to login: $e');
    }
  }
}

