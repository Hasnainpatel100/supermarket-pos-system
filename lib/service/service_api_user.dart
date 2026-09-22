import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../model/model_api_user.dart';
import 'service_storage.dart';

/// Generic response wrapper for API User calls.
class ApiUserResponse<T> {
  final bool success;
  final T? data;
  final int statusCode;
  final String message;
  final dynamic rawBody;

  const ApiUserResponse({
    required this.success,
    this.data,
    required this.statusCode,
    required this.message,
    this.rawBody,
  });

  factory ApiUserResponse.success(T data, {int statusCode = 200, String message = 'Success'}) {
    return ApiUserResponse(
      success: true,
      data: data,
      statusCode: statusCode,
      message: message,
    );
  }

  factory ApiUserResponse.error(String message, {int statusCode = 500, dynamic rawBody}) {
    return ApiUserResponse(
      success: false,
      data: null,
      statusCode: statusCode,
      message: message,
      rawBody: rawBody,
    );
  }
}

/// Service managing REST API interactions for API Users using Dio.
class ServiceApiUser {
  final ServiceStorage _storage;
  static const String storageKeyBaseUrl = 'brand_api_base_url';
  static const String storageKeyAuthToken = 'brand_api_auth_token';
  static const String defaultBaseUrl = 'http://172.19.112.1:8080';

  late final Dio _dio;

  Dio get dio => _dio;

  ServiceApiUser(this._storage, {Dio? dioClient}) {
    _dio = dioClient ?? _createDio();
  }

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
      validateStatus: (status) => true, // Accept all status codes to read error body
    );

    final dioInstance = Dio(options);

    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = baseUrl;
          final token = authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          if (kDebugMode) {
            debugPrint('🚀 [API User Request] ${options.method} ${options.baseUrl}${options.path}');
            if (options.data != null) {
              debugPrint('📦 [API User Payload] ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('📥 [API User Response] ${response.statusCode} for ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ [API User Error] ${e.type} - ${e.message} (${e.response?.statusCode})');
          }
          return handler.next(e);
        },
      ),
    );

    return dioInstance;
  }

  String get baseUrl {
    final url = _storage.readString(storageKeyBaseUrl);
    if (url != null && url.trim().isNotEmpty) {
      return _sanitizeUrl(url.trim());
    }
    return defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final sanitized = _sanitizeUrl(url.trim());
    await _storage.writeString(storageKeyBaseUrl, sanitized);
    _dio.options.baseUrl = sanitized;
  }

  /// Strips redundant 'Bearer ' prefixes, whitespace, quotes, and newlines
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

  String? get authToken {
    final mainToken = _storage.readString('auth_access_token');
    if (mainToken != null && mainToken.trim().isNotEmpty) {
      final clean = sanitizeToken(mainToken);
      if (clean.isNotEmpty) return clean;
    }
    final token = _storage.readString(storageKeyAuthToken);
    if (token != null && token.trim().isNotEmpty) {
      final clean = sanitizeToken(token);
      if (clean.isNotEmpty) return clean;
    }
    return null;
  }

  Future<void> setAuthToken(String token) async {
    final clean = sanitizeToken(token);
    if (clean.isEmpty) {
      await _storage.delete('auth_access_token');
      await _storage.delete(storageKeyAuthToken);
      _dio.options.headers.remove('Authorization');
    } else {
      await _storage.writeString('auth_access_token', clean);
      await _storage.writeString(storageKeyAuthToken, clean);
      _dio.options.headers['Authorization'] = 'Bearer $clean';
    }
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

  /// Tests connection to backend API server.
  Future<ApiUserResponse<bool>> testConnection([String? customUrl, String? customToken]) async {
    final targetUrl = _sanitizeUrl(customUrl ?? baseUrl);
    final rawToken = customToken != null ? sanitizeToken(customToken) : (authToken ?? '');

    try {
      final storedBrandId = _storage.readString('auth_brand_id');
      final queryParams = <String, dynamic>{'appType': 'MARKET'};
      if (storedBrandId != null && storedBrandId.isNotEmpty) {
        queryParams['brandId'] = storedBrandId;
      }

      final testDio = Dio(
        BaseOptions(
          baseUrl: targetUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (rawToken.isNotEmpty)
              'Authorization': 'Bearer $rawToken',
          },
          validateStatus: (status) => true,
        ),
      );

      final response = await testDio.get('/api/users', queryParameters: queryParams);
      final status = response.statusCode ?? 0;

      if (status >= 200 && status < 300) {
        return ApiUserResponse.success(
          true,
          statusCode: status,
          message: 'Connected successfully to $targetUrl (HTTP $status)',
        );
      } else if (status == 401) {
        return ApiUserResponse.error(
          rawToken.isEmpty
              ? 'Authentication required (HTTP 401). Please enter a valid Bearer Token.'
              : 'Invalid or expired token (HTTP 401). The server rejected the auth token.',
          statusCode: 401,
          rawBody: response.data,
        );
      } else if (status == 403) {
        return ApiUserResponse.error(
          'Forbidden (HTTP 403): Token does not have permission to access /api/users.',
          statusCode: 403,
          rawBody: response.data,
        );
      } else {
        return ApiUserResponse.error(
          _extractErrorMessage(response.data, status),
          statusCode: status,
          rawBody: response.data,
        );
      }
    } on DioException catch (e) {
      return ApiUserResponse.error(
        _handleDioError(e, targetUrl),
        statusCode: e.response?.statusCode ?? 0,
      );
    } catch (e) {
      return ApiUserResponse.error('Connection failed: $e', statusCode: 500);
    }
  }

  /// POST /api/users/create (with fallback to POST /api/users on 404)
  Future<ApiUserResponse<ModelApiUser>> createApiUser(ModelApiUser user) async {
    final payloadJson = user.toCreatePayloadJson();

    try {
      Response response = await _dio.post('/api/users/create', data: payloadJson);

      if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('⚠️ [User] /api/users/create was 404, trying /api/users');
        }
        final fallback = await _dio.post('/api/users', data: payloadJson);
        if (fallback.statusCode != 404) {
          response = fallback;
        }
      }

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 201) {
        final decoded = response.data;
        final userData = _extractUserObject(decoded);
        final createdUser = userData != null
            ? ModelApiUser.fromJson(userData)
            : (decoded is Map<String, dynamic>
                ? user.copyWith(id: decoded['id']?.toString() ?? decoded['_id']?.toString() ?? (decoded['data'] is Map ? (decoded['data']['id']?.toString() ?? decoded['data']['_id']?.toString()) : null))
                : user);

        final msg = (decoded is Map<String, dynamic> && decoded['message'] != null)
            ? decoded['message'].toString()
            : 'User created successfully';

        return ApiUserResponse.success(
          createdUser,
          statusCode: statusCode,
          message: msg,
        );
      } else {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        return ApiUserResponse.error(
          errorMsg,
          statusCode: statusCode,
          rawBody: response.data,
        );
      }
    } on DioException catch (e) {
      final errorMsg = _handleDioError(e, baseUrl);
      return ApiUserResponse.error(
        errorMsg,
        statusCode: e.response?.statusCode ?? 0,
        rawBody: e.response?.data,
      );
    } catch (e) {
      return ApiUserResponse.error(
        'Unexpected error while creating API user: $e',
        statusCode: 500,
      );
    }
  }

  /// GET /api/users
  /// Fetches API users list from server with appType=MARKET and optional brandId.
  Future<ApiUserResponse<List<ModelApiUser>>> getApiUsers({
    String? brandId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Only send brandId if we have a real one — backend rejects dummy IDs
      final effectiveBrandId = (brandId != null && brandId.isNotEmpty)
          ? brandId
          : _storage.readString('auth_brand_id');

      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        'appType': 'MARKET',
      };
      if (effectiveBrandId != null && effectiveBrandId.isNotEmpty) {
        params['brandId'] = effectiveBrandId;
      }

      final response = await _dio.get(
        '/api/users',
        queryParameters: params,
      );
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200) {
        final list = _extractUserList(response.data);
        return ApiUserResponse.success(
          list,
          statusCode: statusCode,
          message: 'Loaded ${list.length} API users',
        );
      } else {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        return ApiUserResponse.error(
          errorMsg,
          statusCode: statusCode,
          rawBody: response.data,
        );
      }
    } on DioException catch (e) {
      final errorMsg = _handleDioError(e, baseUrl);
      return ApiUserResponse.error(
        errorMsg,
        statusCode: e.response?.statusCode ?? 0,
        rawBody: e.response?.data,
      );
    } catch (e) {
      return ApiUserResponse.error(
        'Unexpected error while fetching API users: $e',
        statusCode: 500,
      );
    }
  }

  /// PUT /api/users/:id
  Future<ApiUserResponse<ModelApiUser>> updateApiUser(String id, ModelApiUser user) async {
    if (id.startsWith('local_')) {
      return createApiUser(user.copyWith(id: null));
    }

    final payloadJson = user.toCreatePayloadJson();

    try {
      final response = await _dio.put(
        '/api/users/$id',
        data: payloadJson,
      );

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 204) {
        final userData = _extractUserObject(response.data);
        final updated = userData != null
            ? ModelApiUser.fromJson(userData)
            : user.copyWith(id: id);
        return ApiUserResponse.success(
          updated,
          statusCode: statusCode,
          message: 'API user updated successfully',
        );
      } else {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        return ApiUserResponse.error(errorMsg, statusCode: statusCode);
      }
    } on DioException catch (e) {
      return ApiUserResponse.error(_handleDioError(e, baseUrl), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return ApiUserResponse.error('Error updating API user: $e');
    }
  }

  /// DELETE /api/users/:id
  Future<ApiUserResponse<bool>> deleteApiUser(String id) async {
    if (id.startsWith('local_')) {
      return ApiUserResponse.success(true, statusCode: 200, message: 'Local user removed');
    }

    try {
      final response = await _dio.delete('/api/users/$id');
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 204) {
        return ApiUserResponse.success(
          true,
          statusCode: statusCode,
          message: 'API user deleted successfully',
        );
      } else {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        return ApiUserResponse.error(errorMsg, statusCode: statusCode);
      }
    } on DioException catch (e) {
      return ApiUserResponse.error(_handleDioError(e, baseUrl), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return ApiUserResponse.error('Error deleting API user: $e');
    }
  }

  // ── Helper parsers ──

  Map<String, dynamic>? _extractUserObject(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
        final dataMap = decoded['data'] as Map<String, dynamic>;
        if (dataMap.containsKey('user') && dataMap['user'] is Map<String, dynamic>) {
          return dataMap['user'] as Map<String, dynamic>;
        }
        return dataMap;
      }
      if (decoded.containsKey('user') && decoded['user'] is Map<String, dynamic>) {
        return decoded['user'] as Map<String, dynamic>;
      }
      return decoded;
    }
    return null;
  }

  List<ModelApiUser> _extractUserList(dynamic decoded) {
    List<dynamic> rawList = [];
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        rawList = (data['content'] as List?) ??
            (data['users'] as List?) ??
            (data['items'] as List?) ??
            (data['docs'] as List?) ??
            (data['data'] as List?) ??
            [];
      } else if (decoded['users'] is List) {
        rawList = decoded['users'] as List;
      } else if (decoded['items'] is List) {
        rawList = decoded['items'] as List;
      } else if (decoded['content'] is List) {
        rawList = decoded['content'] as List;
      }
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((m) => ModelApiUser.fromJson(m))
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
        return 'Server took too long to respond';
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
