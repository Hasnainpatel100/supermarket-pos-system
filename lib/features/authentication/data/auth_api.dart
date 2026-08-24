import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import 'models/auth_response_model.dart';

/// API service for authentication endpoints.
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// POST /auth/login
  /// Authenticates user credentials against backend HTTP API.
  Future<AuthLoginResponse> login({
    required String username,
    required String pin,
  }) async {
    try {
      final payload = {
        'username': username,
        'pin': pin,
      };

      final response = await _dio.post('/auth/login', data: payload);
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 201) {
        if (kDebugMode) {
          debugPrint('LOGIN SUCCESS');
        }
        return AuthLoginResponse.fromJson(response.data);
      }

      throw ApiException(
        message: _extractErrorMessage(response.data, statusCode),
        statusCode: statusCode,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /auth/refresh
  /// Refreshes access token using refresh token.
  Future<AuthLoginResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final statusCode = response.statusCode ?? 200;

      if (statusCode == 200 || statusCode == 201) {
        return AuthLoginResponse.fromJson(response.data);
      }

      throw ApiException(
        message: _extractErrorMessage(response.data, statusCode),
        statusCode: statusCode,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  String _extractErrorMessage(dynamic body, int statusCode) {
    if (body is Map<String, dynamic>) {
      if (body['error'] is Map && body['error']['message'] != null) {
        return body['error']['message'].toString();
      }
      if (body['message'] != null) return body['message'].toString();
      if (body['error'] != null) return body['error'].toString();
    }
    return 'Authentication failed with HTTP $statusCode';
  }
}
