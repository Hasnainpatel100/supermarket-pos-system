import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import '../../util/app_route.dart';
import '../storage/token_storage.dart';

/// Dio authentication interceptor.
/// Automatically injects `Authorization: Bearer <accessToken>` into requests.
/// On 401 Unauthorized errors, uses the refresh token API to obtain a new token
/// and retries the original request ONCE. Prevents infinite refresh loops.
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  String _baseUrl;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    String baseUrl = 'http://172.19.112.1:8080',
  })  : _tokenStorage = tokenStorage,
        _baseUrl = baseUrl;

  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Ensure base URL is synchronized
    if (options.baseUrl.isEmpty) {
      options.baseUrl = _baseUrl;
    }

    final path = options.path;

    // Do not attach authorization header to public authentication endpoints
    final isAuthEndpoint = path.startsWith('/auth/login') || path.startsWith('/auth/refresh');

    if (!isAuthEndpoint) {
      final token = _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (kDebugMode) {
      debugPrint('🌿 [Dio] ${options.method} ${options.baseUrl}${options.path}');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('📥 [Dio] HTTP ${response.statusCode} - ${response.requestOptions.path}');
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    if (kDebugMode) {
      debugPrint('❌ [Dio Error] HTTP ${response?.statusCode} for ${requestOptions.path}');
    }

    // Check if error is 401 Unauthorized and not already retried
    final is401 = response?.statusCode == 401;
    final isAlreadyRetried = requestOptions.extra['isRetry'] == true;
    final isAuthEndpoint = requestOptions.path.startsWith('/auth/login') ||
        requestOptions.path.startsWith('/auth/refresh');

    if (is401 && !isAlreadyRetried && !isAuthEndpoint) {
      requestOptions.extra['isRetry'] = true;

      final refreshToken = _tokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🔄 [AuthInterceptor] 401 received. Attempting token refresh...');
        }

        final newAccessToken = await _attemptTokenRefresh(refreshToken);

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ [AuthInterceptor] Token refresh successful. Retrying original request.');
          }

          // Save new token
          await _tokenStorage.saveAccessToken(newAccessToken);

          // Update header and retry request
          final cleanToken = TokenStorage.sanitizeToken(newAccessToken);
          requestOptions.headers['Authorization'] = 'Bearer $cleanToken';

          try {
            // Create a clean Dio instance to retry the original request
            final retryDio = Dio(BaseOptions(
              baseUrl: requestOptions.baseUrl.isNotEmpty ? requestOptions.baseUrl : _baseUrl,
              connectTimeout: requestOptions.connectTimeout,
              receiveTimeout: requestOptions.receiveTimeout,
              sendTimeout: requestOptions.sendTimeout,
              headers: requestOptions.headers,
            ));

            final retryResponse = await retryDio.fetch(requestOptions);
            return handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          } catch (e) {
            return handler.next(err);
          }
        }
      }

      // If refresh failed or no refresh token is present, clear state and redirect to login
      if (kDebugMode) {
        debugPrint('⚠️ [AuthInterceptor] Refresh failed or token missing. Clearing session.');
      }
      await _tokenStorage.clearTokens();
      _navigateToLogin();
    }

    return handler.next(err);
  }

  /// Call the backend Refresh Token API (/auth/refresh)
  Future<String?> _attemptTokenRefresh(String refreshToken) async {
    try {
      final refreshDio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final newToken = data['accessToken']?.toString() ??
              (data['data'] is Map ? data['data']['accessToken']?.toString() : null);

          // Also save new refreshToken if returned
          final newRefreshToken = data['refreshToken']?.toString() ??
              (data['data'] is Map ? data['data']['refreshToken']?.toString() : null);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await _tokenStorage.saveRefreshToken(newRefreshToken);
          }

          return newToken;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AuthInterceptor] Token refresh request failed: $e');
      }
    }
    return null;
  }

  void _navigateToLogin() {
    try {
      if (Get.currentRoute != AppRoute.login) {
        Get.offAllNamed(AppRoute.login);
      }
    } catch (e) {
      debugPrint('⚠️ Could not navigate to login: $e');
    }
  }
}
