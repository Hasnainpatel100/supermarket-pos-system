import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Centralized Dio client manager for the application.
/// Provides a configured Dio singleton pointing to http://172.19.112.1:8080
/// with automatic token injection and 401 refresh interceptor.
class DioClient {
  static const String defaultBaseUrl = 'http://127.0.0.1:8080';

  final TokenStorage tokenStorage;
  String baseUrl;
  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  DioClient({
    required this.tokenStorage,
    this.baseUrl = defaultBaseUrl,
    Dio? dioOverride,
  }) {
    _dio = dioOverride ?? _createDio();
  }

  Dio get dio => _dio;

  void setBaseUrl(String newUrl) {
    final sanitized = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    baseUrl = sanitized;
    _dio.options.baseUrl = sanitized;
    _authInterceptor.setBaseUrl(sanitized);
    if (kDebugMode) {
      debugPrint('🔄 [DioClient] BaseUrl updated to: $sanitized');
    }
  }

  Dio _createDio() {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    );

    final dioInstance = Dio(options);

    // Register Auth Interceptor
    _authInterceptor = AuthInterceptor(
      tokenStorage: tokenStorage,
      baseUrl: baseUrl,
    );
    dioInstance.interceptors.add(_authInterceptor);

    if (kDebugMode) {
      debugPrint('🚀 [DioClient] Centralized Dio initialized for $baseUrl');
    }

    return dioInstance;
  }
}
