import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Centralized Dio client manager for the application.
/// Provides a configured Dio singleton pointing to http://172.19.112.1:8080
/// with automatic token injection and 401 refresh interceptor.
class DioClient {
  static const String defaultBaseUrl = 'http://172.19.112.1:8080';

  final TokenStorage tokenStorage;
  final String baseUrl;
  late final Dio _dio;

  DioClient({
    required this.tokenStorage,
    this.baseUrl = defaultBaseUrl,
    Dio? dioOverride,
  }) {
    _dio = dioOverride ?? _createDio();
  }

  Dio get dio => _dio;

  Dio _createDio() {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    );

    final dioInstance = Dio(options);

    // Register Auth Interceptor
    dioInstance.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        baseUrl: baseUrl,
      ),
    );

    if (kDebugMode) {
      debugPrint('🚀 [DioClient] Centralized Dio initialized for $baseUrl');
    }

    return dioInstance;
  }
}
