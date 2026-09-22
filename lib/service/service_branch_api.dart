import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../model/model_branch.dart';
import 'service_storage.dart';

/// Generic response wrapper for Branch API calls.
class BranchApiResponse<T> {
  final bool success;
  final T? data;
  final int statusCode;
  final String message;
  final dynamic rawBody;

  const BranchApiResponse({
    required this.success,
    this.data,
    required this.statusCode,
    required this.message,
    this.rawBody,
  });

  factory BranchApiResponse.success(T data, {int statusCode = 200, String message = 'Success'}) {
    return BranchApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
      message: message,
    );
  }

  factory BranchApiResponse.error(String message, {int statusCode = 500, dynamic rawBody}) {
    return BranchApiResponse(
      success: false,
      data: null,
      statusCode: statusCode,
      message: message,
      rawBody: rawBody,
    );
  }
}

/// Dio-powered REST API service for Branch entities.
/// Base URL: http://172.19.112.1:8080 (same backend as Brand).
class ServiceBranchApi {
  final ServiceStorage _storage;
  static const String storageKeyAuthToken = 'brand_api_auth_token'; // reuse same auth token
  static const String defaultBaseUrl = 'http://172.19.112.1:8080';
  static const String storageKeyBaseUrl = 'brand_api_base_url'; // shared with brand service

  late final Dio _dio;

  Dio get dio => _dio;

  ServiceBranchApi(this._storage, {Dio? dioClient}) {
    _dio = dioClient ?? _createDio();
  }

  Dio _createDio() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
        validateStatus: (status) => true, // Accept all status codes to read error body
      ),
    );

    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = baseUrl; // always pick up latest URL
          final token = authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          if (kDebugMode) {
            debugPrint('🌿 [Branch] ${options.method} ${options.baseUrl}${options.path}');
            if (options.data != null) {
              debugPrint('📦 [Branch] Payload: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('📥 [Branch] Response ${response.statusCode}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ [Branch] Error ${e.type} - ${e.message} (${e.response?.statusCode})');
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
    if (result.endsWith('/')) result = result.substring(0, result.length - 1);
    if (!result.startsWith('http://') && !result.startsWith('https://')) {
      result = 'http://$result';
    }
    return result;
  }

  // ── CRUD Methods ─────────────────────────────────────────────────────────────

  /// POST /api/branches/create (with auto-fallback to POST /api/branches on 404)
  Future<BranchApiResponse<ModelBranch>> createBranch(ModelBranch branch) async {
    try {
      final payload = branch.toJson();
      Response response = await _dio.post('/api/branches/create', data: payload);

      // Auto-fallback to /api/branches if /api/branches/create is not found
      if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('⚠️ [Branch] /api/branches/create was 404, trying /api/branches');
        }
        final fallback = await _dio.post('/api/branches', data: payload);
        if (fallback.statusCode != 404) {
          response = fallback;
        }
      }

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 201) {
        final branchData = _extractBranchObject(response.data);
        final created = branchData != null
            ? ModelBranch.fromJson(branchData)
            : branch.copyWith(id: _extractId(response.data));
        if (kDebugMode) {
          debugPrint('✅ BRANCH CREATE SUCCESS: ${created.id}');
        }
        return BranchApiResponse.success(created, statusCode: statusCode, message: 'Branch created successfully');
      }
      return BranchApiResponse.error(
        _extractErrorMessage(response.data, statusCode),
        statusCode: statusCode,
        rawBody: response.data,
      );
    } on DioException catch (e) {
      return BranchApiResponse.error(
        _handleDioError(e),
        statusCode: e.response?.statusCode ?? 0,
        rawBody: e.response?.data,
      );
    } catch (e) {
      return BranchApiResponse.error('Unexpected error creating branch: $e');
    }
  }

  /// GET /api/branches?page=1&limit=20&appType=MARKET
  Future<BranchApiResponse<List<ModelBranch>>> getBranches({String? status, int page = 1, int limit = 100}) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        'appType': 'MARKET',
      };
      if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
        params['status'] = status;
      }
      Response response = await _dio.get('/api/branches', queryParameters: params);

      // Auto-fallback: If /api/branches with appType param returns 404, retry plain /api/branches
      if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('⚠️ [Branch] GET /api/branches?appType=MARKET was 404, trying plain /api/branches');
        }
        final fallback = await _dio.get('/api/branches');
        if (fallback.statusCode != 404) {
          response = fallback;
        }
      }

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200) {
        final list = _extractBranchList(response.data);
        return BranchApiResponse.success(list, statusCode: statusCode, message: 'Loaded ${list.length} branches');
      }
      return BranchApiResponse.error(_extractErrorMessage(response.data, statusCode), statusCode: statusCode);
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Unexpected error fetching branches: $e');
    }
  }

  /// GET /api/branches/:id
  Future<BranchApiResponse<ModelBranch>> getBranchById(String id) async {
    try {
      final response = await _dio.get('/api/branches/$id');
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200) {
        final data = _extractBranchObject(response.data);
        if (data != null) {
          return BranchApiResponse.success(ModelBranch.fromJson(data), statusCode: statusCode);
        }
      }
      return BranchApiResponse.error(_extractErrorMessage(response.data, statusCode), statusCode: statusCode);
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Error getting branch: $e');
    }
  }

  /// GET /api/branches/brand/:brandId?page=1&limit=20 (with fallback to ?brandId= query param)
  Future<BranchApiResponse<List<ModelBranch>>> getBranchesByBrand(String brandId, {int page = 1, int limit = 100}) async {
    // If brandId is invalid or dummy, fetch all branches instead of calling invalid backend route
    if (brandId.isEmpty || brandId == '000000000000000000000000' || brandId.startsWith('local_')) {
      return getBranches();
    }

    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      Response response = await _dio.get('/api/branches/brand/$brandId', queryParameters: params);

      if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('⚠️ [Branch] /api/branches/brand/$brandId was 404, falling back to query param');
        }
        final fallback = await _dio.get('/api/branches', queryParameters: {
          'brandId': brandId,
          'appType': 'MARKET',
          'page': page,
          'limit': limit,
        });
        if (fallback.statusCode != 404) {
          response = fallback;
        }
      }

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200) {
        final list = _extractBranchList(response.data);
        return BranchApiResponse.success(list, statusCode: statusCode, message: 'Loaded ${list.length} branches for brand');
      }
      return BranchApiResponse.error(_extractErrorMessage(response.data, statusCode), statusCode: statusCode);
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Error fetching branches by brand: $e');
    }
  }

  /// PUT /api/branches/:id (with fallback to PATCH or /update/:id on 404)
  Future<BranchApiResponse<ModelBranch>> updateBranch(String id, ModelBranch branch) async {
    try {
      final payload = branch.toJson();
      Response response = await _dio.put('/api/branches/$id', data: payload);

      if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('⚠️ [Branch] PUT /api/branches/$id was 404, trying PATCH');
        }
        final patchResp = await _dio.patch('/api/branches/$id', data: payload);
        if (patchResp.statusCode != 404) {
          response = patchResp;
        } else {
          final updateResp = await _dio.put('/api/branches/update/$id', data: payload);
          if (updateResp.statusCode != 404) {
            response = updateResp;
          }
        }
      }

      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 204) {
        final data = _extractBranchObject(response.data);
        final updated = data != null ? ModelBranch.fromJson(data) : branch.copyWith(id: id);
        return BranchApiResponse.success(updated, statusCode: statusCode, message: 'Branch updated successfully');
      }
      return BranchApiResponse.error(_extractErrorMessage(response.data, statusCode), statusCode: statusCode);
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Error updating branch: $e');
    }
  }

  /// PUT /api/branches/:id/plan
  Future<BranchApiResponse<ModelBranch>> assignPlanToBranch(String id, Map<String, dynamic> planPayload) async {
    try {
      final response = await _dio.put('/api/branches/$id/plan', data: planPayload);
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 204) {
        final data = _extractBranchObject(response.data);
        if (data != null) {
          return BranchApiResponse.success(ModelBranch.fromJson(data), statusCode: statusCode, message: 'Plan assigned successfully');
        }
        return BranchApiResponse.success(
          ModelBranch(brandId: '', name: const BranchName(en: ''), id: id),
          statusCode: statusCode,
          message: 'Plan assigned successfully',
        );
      }
      return BranchApiResponse.error(_extractErrorMessage(response.data, statusCode), statusCode: statusCode);
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Error assigning plan: $e');
    }
  }

  /// GET /api/branches/:id/plan-history
  Future<BranchApiResponse<List<dynamic>>> getBranchPlanHistory(String id) async {
    try {
      final response = await _dio.get('/api/branches/$id/plan-history');
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200) {
        List<dynamic> list = [];
        final body = response.data;
        if (body is List) {
          list = body;
        } else if (body is Map<String, dynamic>) {
          list = (body['data'] as List?) ?? (body['history'] as List?) ?? [];
        }
        return BranchApiResponse.success(list, statusCode: statusCode);
      }
      return BranchApiResponse.error(_extractErrorMessage(response.data, statusCode), statusCode: statusCode);
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Error fetching plan history: $e');
    }
  }

  /// DELETE /api/branches/:id
  Future<BranchApiResponse<bool>> deleteBranch(String id) async {
    try {
      final response = await _dio.delete('/api/branches/$id');
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 204) {
        return BranchApiResponse.success(true, statusCode: statusCode, message: 'Branch deleted successfully');
      }
      return BranchApiResponse.error(_extractErrorMessage(response.data, statusCode), statusCode: statusCode);
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Error deleting branch: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _extractId(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data['id']?.toString() ?? data['_id']?.toString();
      }
      return body['id']?.toString() ?? body['_id']?.toString();
    }
    return null;
  }

  Map<String, dynamic>? _extractBranchObject(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) return decoded['data'] as Map<String, dynamic>;
      if (decoded['branch'] is Map<String, dynamic>) return decoded['branch'] as Map<String, dynamic>;
      return decoded;
    }
    return null;
  }

  List<ModelBranch> _extractBranchList(dynamic decoded) {
    List<dynamic> rawList = [];
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        rawList = (data['content'] as List?) ??
            (data['branches'] as List?) ??
            (data['items'] as List?) ??
            (data['docs'] as List?) ??
            (data['data'] as List?) ??
            [];
      } else if (decoded['branches'] is List) {
        rawList = decoded['branches'] as List;
      } else if (decoded['items'] is List) {
        rawList = decoded['items'] as List;
      } else if (decoded['content'] is List) {
        rawList = decoded['content'] as List;
      }
    }
    return rawList.whereType<Map<String, dynamic>>().map((m) => ModelBranch.fromJson(m)).toList();
  }

  String _extractErrorMessage(dynamic body, int statusCode) {
    if (body is Map<String, dynamic>) {
      // Handle {code: INTERNAL_ERROR, message: ...} format
      if (body['message'] != null) return body['message'].toString();
      if (body['error'] is Map && body['error']['message'] != null) {
        return body['error']['message'].toString();
      }
      if (body['error'] != null) return body['error'].toString();
      if (body['detail'] != null) return body['detail'].toString();
    }
    // Return full raw body so nothing is hidden
    final rawStr = body?.toString() ?? '';
    switch (statusCode) {
      case 400:
        return rawStr.isNotEmpty ? rawStr : 'Invalid branch data. Please check all required fields.';
      case 401:
        return 'Unauthorized. Please check your authentication token.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Branch not found on the server.';
      case 409:
        return 'A branch with this code already exists under the selected brand.';
      case 422:
        return rawStr.isNotEmpty ? rawStr : 'Validation failed. Please review the form fields.';
      case 500:
        return rawStr.isNotEmpty ? 'Server error: $rawStr' : 'Internal server error. Please check server logs.';
      default:
        return rawStr.isNotEmpty ? rawStr : 'Server responded with HTTP $statusCode.';
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please verify the backend is running at $baseUrl.';
      case DioExceptionType.sendTimeout:
        return 'Request send timed out.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.badResponse:
        return _extractErrorMessage(e.response?.data, e.response?.statusCode ?? 500);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Cannot reach backend at $baseUrl. Is the Docker container running?';
      case DioExceptionType.badCertificate:
        return 'SSL Certificate verification failed.';
      case DioExceptionType.unknown:
      default:
        return 'Network error: ${e.message ?? e.toString()}';
    }
  }
}
