import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../model/model_brand.dart';
import 'service_storage.dart';

/// Generic response wrapper for Brand API calls.
class BrandApiResponse<T> {
  final bool success;
  final T? data;
  final int statusCode;
  final String message;
  final dynamic rawBody;

  const BrandApiResponse({
    required this.success,
    this.data,
    required this.statusCode,
    required this.message,
    this.rawBody,
  });

  factory BrandApiResponse.success(T data, {int statusCode = 200, String message = 'Success'}) {
    return BrandApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
      message: message,
    );
  }

  factory BrandApiResponse.error(String message, {int statusCode = 500, dynamic rawBody}) {
    return BrandApiResponse(
      success: false,
      data: null,
      statusCode: statusCode,
      message: message,
      rawBody: rawBody,
    );
  }
}

/// Service managing REST API interactions for Brand entities using the Dio HTTP client.
class ServiceBrandApi {
  final ServiceStorage _storage;
  static const String storageKeyBaseUrl = 'brand_api_base_url';
  static const String storageKeyAuthToken = 'brand_api_auth_token';
  static const String defaultBaseUrl = 'http://172.19.112.1:8080';

  late final Dio _dio;

  Dio get dio => _dio;

  ServiceBrandApi(this._storage, {Dio? dioClient}) {
    _dio = dioClient ?? _createDio();
  }

  /// Factory to initialize Dio with default configuration and interceptors
  Dio _createDio() {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    );

    final dioInstance = Dio(options);

    // Add interceptors
    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Dynamically ensure baseUrl and AuthToken are always up to date
          options.baseUrl = baseUrl;
          final token = authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            debugPrint('🚀 [Dio Request] ${options.method} ${options.baseUrl}${options.path}');
            if (options.data != null) {
              debugPrint('📦 [Dio Payload] ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('📥 [Dio Response] ${response.statusCode} for ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ [Dio Error] ${e.type} - ${e.message} (${e.response?.statusCode})');
          }
          return handler.next(e);
        },
      ),
    );

    return dioInstance;
  }

  /// Gets the currently configured API Base URL
  String get baseUrl {
    final url = _storage.readString(storageKeyBaseUrl);
    if (url != null && url.trim().isNotEmpty) {
      return _sanitizeUrl(url.trim());
    }
    return defaultBaseUrl;
  }

  /// Sets the API Base URL and updates active Dio instance
  Future<void> setBaseUrl(String url) async {
    final sanitized = _sanitizeUrl(url.trim());
    await _storage.writeString(storageKeyBaseUrl, sanitized);
    _dio.options.baseUrl = sanitized;
  }

  /// Gets the auth token if any
  String? get authToken {
    final mainToken = _storage.readString('auth_access_token');
    if (mainToken != null && mainToken.trim().isNotEmpty) {
      return mainToken.trim();
    }
    final token = _storage.readString(storageKeyAuthToken);
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    return null;
  }

  /// Sets the auth token
  Future<void> setAuthToken(String token) async {
    final trimmed = token.trim();
    await _storage.writeString('auth_access_token', trimmed);
    await _storage.writeString(storageKeyAuthToken, trimmed);
  }

  String _sanitizeUrl(String url) {
    var result = url.trim();
    if (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    if (!result.startsWith('http://') && !result.startsWith('https://')) {
      result = 'http://$result';
    }
    return result;
  }

  /// Tests connectivity to a given base URL using Dio.
  Future<BrandApiResponse<bool>> testConnection([String? customUrl]) async {
    final targetUrl = _sanitizeUrl(customUrl ?? baseUrl);
    try {
      final testDio = Dio(
        BaseOptions(
          baseUrl: targetUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authToken != null && authToken!.isNotEmpty)
              'Authorization': 'Bearer $authToken',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final response = await testDio.get('/api/brands');

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 500) {
        return BrandApiResponse.success(
          true,
          statusCode: response.statusCode ?? 200,
          message: 'Connected successfully to $targetUrl (HTTP ${response.statusCode})',
        );
      } else {
        return BrandApiResponse.error(
          'Server returned HTTP status ${response.statusCode}',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      return BrandApiResponse.error(
        _handleDioError(e, targetUrl),
        statusCode: e.response?.statusCode ?? 0,
      );
    } catch (e) {
      return BrandApiResponse.error('Connection failed: $e', statusCode: 500);
    }
  }

  /// POST /api/brands/create or POST /api/brands
  /// Creates a new brand with the specified payload using Dio.
  Future<BrandApiResponse<ModelBrand>> createBrand(ModelBrand brand) async {
    final payloadJson = brand.toJson();

    try {
      Response response;
      try {
        response = await _dio.post(
          '/api/brands',
          data: payloadJson,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.post(
            '/api/brands/create',
            data: payloadJson,
          );
        } else {
          rethrow;
        }
      }

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 201) {
        final decoded = response.data;
        final brandData = _extractBrandObject(decoded);
        final createdBrand = brandData != null
            ? ModelBrand.fromJson(brandData)
            : (decoded is Map<String, dynamic>
                ? brand.copyWith(id: decoded['id']?.toString() ?? decoded['_id']?.toString() ?? (decoded['data'] is Map ? (decoded['data']['id']?.toString() ?? decoded['data']['_id']?.toString()) : null))
                : brand);

        if (kDebugMode) {
          debugPrint('BRAND CREATE SUCCESS');
        }

        return BrandApiResponse.success(
          createdBrand,
          statusCode: statusCode,
          message: 'Brand created successfully',
        );
      } else {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        return BrandApiResponse.error(
          errorMsg,
          statusCode: statusCode,
          rawBody: response.data,
        );
      }
    } on DioException catch (e) {
      final errorMsg = _handleDioError(e, baseUrl);
      return BrandApiResponse.error(
        errorMsg,
        statusCode: e.response?.statusCode ?? 0,
        rawBody: e.response?.data,
      );
    } catch (e) {
      return BrandApiResponse.error(
        'Unexpected error while creating brand: $e',
        statusCode: 500,
      );
    }
  }

  /// GET /api/brands
  /// Fetches brands list with appType=MARKET query parameter.
  Future<BrandApiResponse<List<ModelBrand>>> getBrands({String? appType}) async {
    final queryParams = <String, dynamic>{};
    if (appType != null && appType.isNotEmpty && appType.toUpperCase() != 'ALL') {
      queryParams['appType'] = appType.toUpperCase();
    } else if (appType == null) {
      queryParams['appType'] = 'MARKET';
    }

    try {
      final response = await _dio.get(
        '/api/brands',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200) {
        final list = _extractBrandList(response.data);
        return BrandApiResponse.success(
          list,
          statusCode: statusCode,
          message: 'Loaded ${list.length} brands',
        );
      } else {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        return BrandApiResponse.error(
          errorMsg,
          statusCode: statusCode,
          rawBody: response.data,
        );
      }
    } on DioException catch (e) {
      final errorMsg = _handleDioError(e, baseUrl);
      return BrandApiResponse.error(
        errorMsg,
        statusCode: e.response?.statusCode ?? 0,
        rawBody: e.response?.data,
      );
    } catch (e) {
      return BrandApiResponse.error(
        'Unexpected error while fetching brands: $e',
        statusCode: 500,
      );
    }
  }
  /// PUT /api/brands/:id
  Future<BrandApiResponse<ModelBrand>> updateBrand(String id, ModelBrand brand) async {
    final payloadJson = brand.toJson();

    try {
      final response = await _dio.put(
        '/api/brands/$id',
        data: payloadJson,
      );

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 204) {
        final brandData = _extractBrandObject(response.data);
        final updated = brandData != null
            ? ModelBrand.fromJson(brandData)
            : brand.copyWith(id: id);
        return BrandApiResponse.success(
          updated,
          statusCode: statusCode,
          message: 'Brand updated successfully',
        );
      } else {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        return BrandApiResponse.error(errorMsg, statusCode: statusCode);
      }
    } on DioException catch (e) {
      return BrandApiResponse.error(_handleDioError(e, baseUrl), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BrandApiResponse.error('Error updating brand: $e');
    }
  }

  /// DELETE /api/brands/:id
  Future<BrandApiResponse<bool>> deleteBrand(String id) async {
    try {
      final response = await _dio.delete('/api/brands/$id');
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 204) {
        return BrandApiResponse.success(
          true,
          statusCode: statusCode,
          message: 'Brand deleted successfully',
        );
      } else {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        return BrandApiResponse.error(errorMsg, statusCode: statusCode);
      }
    } on DioException catch (e) {
      return BrandApiResponse.error(_handleDioError(e, baseUrl), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BrandApiResponse.error('Error deleting brand: $e');
    }
  }


  // ── Helper parsers & Dio error handler ──────────────────────────────────────

  Map<String, dynamic>? _extractBrandObject(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      if (decoded.containsKey('brand') && decoded['brand'] is Map<String, dynamic>) {
        return decoded['brand'] as Map<String, dynamic>;
      }
      return decoded;
    }
    return null;
  }

  List<ModelBrand> _extractBrandList(dynamic decoded) {
    List<dynamic> rawList = [];
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        rawList = (data['content'] as List?) ??
            (data['brands'] as List?) ??
            (data['items'] as List?) ??
            (data['docs'] as List?) ??
            (data['data'] as List?) ??
            [];
      } else if (decoded['brands'] is List) {
        rawList = decoded['brands'] as List;
      } else if (decoded['items'] is List) {
        rawList = decoded['items'] as List;
      } else if (decoded['content'] is List) {
        rawList = decoded['content'] as List;
      }
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((m) => ModelBrand.fromJson(m))
        .toList();
  }

  String _extractErrorMessage(dynamic body, int statusCode) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('message') && body['message'] != null) {
        return body['message'].toString();
      }
      if (body.containsKey('error') && body['error'] != null) {
        return body['error'].toString();
      }
    }
    return 'Server responded with HTTP $statusCode: $body';
  }

  String _handleDioError(DioException e, String targetUrl) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out while reaching $targetUrl';
      case DioExceptionType.sendTimeout:
        return 'Send request timed out';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond (Receive timeout)';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        return _extractErrorMessage(data, status ?? 500);
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.connectionError:
        return 'Cannot reach server at $targetUrl. Connection refused or server offline.';
      case DioExceptionType.badCertificate:
        return 'SSL Certificate verification failed';
      case DioExceptionType.unknown:
      default:
        return 'Network error: ${e.message ?? e.toString()}';
    }
  }
}
