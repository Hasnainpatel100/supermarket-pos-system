import 'package:dio/dio.dart';

/// Centralized Exception for API errors across the application.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  final dynamic rawData;

  ApiException({
    required this.message,
    this.statusCode = 500,
    this.code,
    this.rawData,
  });

  @override
  String toString() => message;

  /// Factory to parse a [DioException] into a human-readable [ApiException].
  factory ApiException.fromDioError(DioException error, {String? defaultBaseUrl}) {
    final response = error.response;
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;

    String extractedMessage = '';
    String? errorCode;

    if (data is Map<String, dynamic>) {
      // Check for nested error object: { "error": { "code": "...", "message": "..." } }
      if (data['error'] is Map<String, dynamic>) {
        final errObj = data['error'] as Map<String, dynamic>;
        extractedMessage = errObj['message']?.toString() ?? '';
        errorCode = errObj['code']?.toString();
      } else if (data['error'] is String) {
        extractedMessage = data['error'].toString();
      } else if (data['message'] != null) {
        extractedMessage = data['message'].toString();
      }
    }

    if (extractedMessage.isNotEmpty) {
      return ApiException(
        message: extractedMessage,
        statusCode: statusCode,
        code: errorCode,
        rawData: data,
      );
    }

    // Default messages per HTTP status code
    switch (statusCode) {
      case 400:
        return ApiException(
          message: 'Invalid request parameters. Please verify input data.',
          statusCode: 400,
          code: 'BAD_REQUEST',
          rawData: data,
        );
      case 401:
        return ApiException(
          message: 'Authentication required. Please login again.',
          statusCode: 401,
          code: 'UNAUTHORIZED',
          rawData: data,
        );
      case 403:
        return ApiException(
          message: 'Access denied. You do not have permission for this action.',
          statusCode: 403,
          code: 'FORBIDDEN',
          rawData: data,
        );
      case 404:
        return ApiException(
          message: 'The requested resource was not found on the server.',
          statusCode: 404,
          code: 'NOT_FOUND',
          rawData: data,
        );
      case 409:
        return ApiException(
          message: 'A conflict occurred. The resource already exists.',
          statusCode: 409,
          code: 'CONFLICT',
          rawData: data,
        );
      case 422:
        return ApiException(
          message: 'Validation failed. Please review the highlighted fields.',
          statusCode: 422,
          code: 'VALIDATION_ERROR',
          rawData: data,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message: 'Server error ($statusCode). Please try again later.',
          statusCode: statusCode,
          code: 'SERVER_ERROR',
          rawData: data,
        );
      default:
        break;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Connection timed out. Please verify the server is running and reachable.',
          statusCode: 408,
          code: 'CONNECTION_TIMEOUT',
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Request send timed out.',
          statusCode: 408,
          code: 'SEND_TIMEOUT',
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Server response timed out. The server took too long to respond.',
          statusCode: 408,
          code: 'RECEIVE_TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Cannot connect to backend server. Please verify the server is running.',
          statusCode: 503,
          code: 'CONNECTION_ERROR',
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          statusCode: 499,
          code: 'CANCELLED',
        );
      default:
        return ApiException(
          message: error.message ?? 'An unexpected network error occurred.',
          statusCode: statusCode,
          code: 'UNKNOWN',
        );
    }
  }
}
