import 'dart:convert';

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
          if (kDebugMode) {
            debugPrint('🔑 [Branch Auth] token=${token != null ? "PRESENT (${token.length} chars)" : "MISSING/NULL"}');
            debugPrint('🌐 [Branch Auth] baseUrl=$baseUrl');
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
            if (kDebugMode) {
              debugPrint('⚠️ [Branch Auth] NO TOKEN — request will fail with 401/500');
            }
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
      if (clean.isNotEmpty) {
        if (kDebugMode) _warnIfJwtExpired(clean, 'auth_access_token');
        return clean;
      }
    }
    final token = _storage.readString(storageKeyAuthToken);
    if (token != null && token.trim().isNotEmpty) {
      final clean = sanitizeToken(token);
      if (clean.isNotEmpty) {
        if (kDebugMode) _warnIfJwtExpired(clean, storageKeyAuthToken);
        return clean;
      }
    }
    return null;
  }

  void _warnIfJwtExpired(String token, String keyName) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      // Simple base64 decode
      final bytes = base64Decode(payload);
      final json = utf8.decode(bytes);
      final map = jsonDecode(json) as Map<String, dynamic>;
      final exp = map['exp'];
      final userId = map['userId']?.toString() ?? '';
      final brandId = map['brandId']?.toString() ?? '';
      if (exp is int) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now();
        if (expiry.isBefore(now)) {
          debugPrint('🔴 [Branch Auth] TOKEN EXPIRED! key=$keyName expired=${expiry.toIso8601String()} (${now.difference(expiry).inDays} days ago)');
          debugPrint('🔴 [Branch Auth] Go to Settings → Brand API Config and enter a fresh token!');
        } else {
          debugPrint('✅ [Branch Auth] Token valid until ${expiry.toIso8601String()} userId=$userId brandId=$brandId');
        }
        if (brandId == '000000000000000000000000') {
          debugPrint('⚠️ [Branch Auth] brandId in token is all-zeros placeholder! Server will return 500 when filtering branches by this brandId.');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Branch Auth] Could not decode JWT for expiry check: $e');
    }
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

  /// POST /api/branches/create
  Future<BranchApiResponse<ModelBranch>> createBranch(ModelBranch branch) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(branch.brandId)) {
      return BranchApiResponse.error(
        'Cannot create branch: Brand ID "${branch.brandId}" is not a valid 24-character hexadecimal ObjectId.',
      );
    }

    try {
      final payload = branch.toJson();
      final response = await _dio.post('/api/branches/create', data: payload);
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

  /// Fetches branches.
  ///
  /// CRITICAL ARCHITECTURAL NOTE:
  /// The Ktor backend has NO global `GET /api/branches` or `GET /api/branches/list` route.
  /// The route `GET /api/branches/{branchId}` captures any subpath like `/list` or `/all`,
  /// and `branchId.toMongoObjectId()` throws "state should be: hexString has 24 characters" (HTTP 500).
  ///
  /// The valid way to retrieve branches is via `GET /api/branches/brand/{brandId}`.
  /// When fetching all branches, we first query `GET /api/brands` to obtain valid brand IDs,
  /// then query `GET /api/branches/brand/{brandId}` for each brand and aggregate the branches.
  Future<BranchApiResponse<List<ModelBranch>>> getBranches({
    String? brandId,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      // 1. If a specific valid brandId is requested, query it directly
      if (brandId != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(brandId)) {
        return getBranchesByBrand(brandId, page: page, limit: limit);
      }

      // 2. Fetch all brands first
      Response brandsResp;
      try {
        brandsResp = await _dio.get('/api/brands', queryParameters: {'limit': 100});
      } on DioException catch (e) {
        return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
      }

      final brandStatus = brandsResp.statusCode ?? 200;
      if (brandStatus != 200 && brandStatus != 201) {
        return BranchApiResponse.error(
          _extractErrorMessage(brandsResp.data, brandStatus),
          statusCode: brandStatus,
          rawBody: brandsResp.data,
        );
      }

      final brandIds = _extractBrandIds(brandsResp.data);
      if (brandIds.isEmpty) {
        return BranchApiResponse.success(
          const [],
          statusCode: 200,
          message: 'No brands found on server.',
        );
      }

      // 3. For each valid brand ID, retrieve its branches
      final allBranches = <ModelBranch>[];
      final seenIds = <String>{};

      for (final bId in brandIds) {
        if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(bId)) continue;
        try {
          final bResp = await _dio.get(
            '/api/branches/brand/$bId',
            queryParameters: {'page': 1, 'limit': limit},
          );
          if (bResp.statusCode == 200) {
            final list = _extractBranchList(bResp.data);
            for (final branch in list) {
              final key = branch.id ?? '${branch.brandId}_${branch.branchCode}';
              if (seenIds.add(key)) {
                allBranches.add(branch);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [Branch] Error fetching branches for brand $bId: $e');
          }
        }
      }

      return BranchApiResponse.success(
        allBranches,
        statusCode: 200,
        message: 'Loaded ${allBranches.length} branches across ${brandIds.length} brands',
      );
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Unexpected error fetching branches: $e');
    }
  }

  /// GET /api/branches/brand/:brandId?page=1&limit=100
  Future<BranchApiResponse<List<ModelBranch>>> getBranchesByBrand(
    String brandId, {
    int page = 1,
    int limit = 100,
  }) async {
    // If brandId is not a valid 24-char hex string, safely fall back to all branches
    if (brandId.isEmpty || !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(brandId)) {
      return getBranches(page: page, limit: limit);
    }

    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      final response = await _dio.get('/api/branches/brand/$brandId', queryParameters: params);
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200) {
        final list = _extractBranchList(response.data);
        return BranchApiResponse.success(
          list,
          statusCode: statusCode,
          message: 'Loaded ${list.length} branches for brand',
        );
      }
      if (statusCode == 404) {
        // Brand has no branches or does not exist — return empty list instead of failing
        return BranchApiResponse.success(
          const [],
          statusCode: 200,
          message: 'No branches found for this brand',
        );
      }
      return BranchApiResponse.error(
        _extractErrorMessage(response.data, statusCode),
        statusCode: statusCode,
        rawBody: response.data,
      );
    } on DioException catch (e) {
      return BranchApiResponse.error(_handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e) {
      return BranchApiResponse.error('Error fetching branches by brand: $e');
    }
  }

  /// GET /api/branches/:id
  Future<BranchApiResponse<ModelBranch>> getBranchById(String id) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return BranchApiResponse.error('Cannot get branch: ID "$id" is not a valid 24-character hexadecimal ObjectId.');
    }
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

  /// PUT /api/branches/:id
  Future<BranchApiResponse<ModelBranch>> updateBranch(String id, ModelBranch branch) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return BranchApiResponse.error('Cannot update branch: ID "$id" is not a valid 24-character hexadecimal ObjectId.');
    }
    try {
      final payload = branch.toJson();
      final response = await _dio.put('/api/branches/$id', data: payload);
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
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return BranchApiResponse.error('Cannot assign plan: Branch ID "$id" is not a valid 24-character hexadecimal ObjectId.');
    }
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

  /// GET /api/branches/:id/plan-history?page=0&limit=20
  Future<BranchApiResponse<List<ModelBranchPlanHistory>>> getBranchPlanHistory(
    String id, {
    int page = 0,
    int limit = 20,
  }) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return BranchApiResponse.error('Cannot get plan history: Branch ID "$id" is not a valid 24-character hexadecimal ObjectId.');
    }
    try {
      final response = await _dio.get(
        '/api/branches/$id/plan-history',
        queryParameters: {'page': page, 'limit': limit},
      );
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200) {
        List<dynamic> rawList = [];
        final body = response.data;
        if (body is List) {
          rawList = body;
        } else if (body is Map<String, dynamic>) {
          final data = body['data'];
          if (data is List) {
            rawList = data;
          } else if (data is Map<String, dynamic>) {
            // As seen in API: { "data": { "data": [ ... ], "page": 0, "limit": 20, "total": 1 } }
            rawList = (data['data'] as List?) ??
                (data['history'] as List?) ??
                (data['items'] as List?) ??
                (data['docs'] as List?) ??
                [];
          } else if (body['history'] is List) {
            rawList = body['history'] as List;
          }
        }
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((m) => ModelBranchPlanHistory.fromJson(m))
            .toList();

        // Sort newest first
        list.sort((a, b) {
          final tA = a.assignedDate?.millisecondsSinceEpoch ?? 0;
          final tB = b.assignedDate?.millisecondsSinceEpoch ?? 0;
          return tB.compareTo(tA);
        });

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
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return BranchApiResponse.error('Cannot delete branch: ID "$id" is not a valid 24-character hexadecimal ObjectId.');
    }
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

  List<String> _extractBrandIds(dynamic decoded) {
    List<dynamic> raw = [];
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        raw = data;
      } else if (data is Map<String, dynamic>) {
        raw = (data['content'] as List?) ??
            (data['brands'] as List?) ??
            (data['items'] as List?) ??
            (data['docs'] as List?) ??
            (data['data'] as List?) ??
            [];
      } else if (decoded['brands'] is List) {
        raw = decoded['brands'] as List;
      }
    }
    final ids = <String>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString() ?? item['_id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    return ids;
  }

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
