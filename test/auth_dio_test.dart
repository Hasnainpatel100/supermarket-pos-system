import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/core/network/api_exception.dart';
import 'package:super_market/core/network/auth_interceptor.dart';
import 'package:super_market/core/storage/token_storage.dart';
import 'package:super_market/features/authentication/data/auth_api.dart';
import 'package:super_market/service/service_storage.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  group('Authentication & Dio Integration Tests', () {
    late ServiceStorage serviceStorage;
    late TokenStorage tokenStorage;

    setUp(() async {
      serviceStorage = ServiceStorage();
      tokenStorage = TokenStorage(serviceStorage);
    });

    test('TokenStorage saves and retrieves tokens without error', () async {
      await tokenStorage.saveAccessToken('test_access_token_123');
      await tokenStorage.saveRefreshToken('test_refresh_token_456');
      await tokenStorage.saveBrandId('brand_789');

      expect(tokenStorage.getAccessToken(), equals('test_access_token_123'));
      expect(tokenStorage.getRefreshToken(), equals('test_refresh_token_456'));
      expect(tokenStorage.getBrandId(), equals('brand_789'));

      await tokenStorage.clearTokens();
      expect(tokenStorage.getAccessToken(), isNull);
      expect(tokenStorage.getRefreshToken(), isNull);
    });

    test('AuthApi login succeeds on HTTP 200 and parses AuthLoginResponse', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://172.19.112.1:8080'));

      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path == '/auth/login') {
          final payload = options.data as Map<String, dynamic>;
          expect(payload['username'], equals('admin'));
          expect(payload['pin'], equals('888888'));

          final responseJson = jsonEncode({
            'accessToken': 'jwt_access_token_mock',
            'refreshToken': 'jwt_refresh_token_mock',
            'expiresIn': 900,
            'userId': 'user_123',
            'username': 'admin',
            'role': 'superAdmin',
            'brandId': 'brand_mumkin_1',
            'branchId': 'branch_karma_1',
            'permissions': ['dashboard', 'pos', 'brandManage']
          });

          return ResponseBody.fromString(
            responseJson,
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        }
        return ResponseBody.fromString('Not Found', 404);
      });

      final authApi = AuthApi(dio);
      final response = await authApi.login(username: 'admin', pin: '888888');

      expect(response.accessToken, equals('jwt_access_token_mock'));
      expect(response.refreshToken, equals('jwt_refresh_token_mock'));
      expect(response.brandId, equals('brand_mumkin_1'));
      expect(response.branchId, equals('branch_karma_1'));
      expect(response.role, equals('superAdmin'));
    });

    test('AuthInterceptor attaches Bearer token header to protected requests', () async {
      await tokenStorage.saveAccessToken('secret_jwt_token');

      final dio = Dio(BaseOptions(baseUrl: 'http://172.19.112.1:8080'));
      dio.interceptors.add(AuthInterceptor(
        tokenStorage: tokenStorage,
        baseUrl: 'http://172.19.112.1:8080',
      ));

      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.headers['Authorization'], equals('Bearer secret_jwt_token'));
        return ResponseBody.fromString('{"data": []}', 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
      });

      final response = await dio.get('/api/brands');
      expect(response.statusCode, equals(200));
    });

    test('ApiException parses backend error structures cleanly', () {
      final errorResponse = Response(
        requestOptions: RequestOptions(path: '/api/brands'),
        statusCode: 401,
        data: {
          'error': {
            'code': 'UNAUTHORIZED',
            'message': 'Authentication required',
          }
        },
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/brands'),
        response: errorResponse,
        type: DioExceptionType.badResponse,
      );

      final apiEx = ApiException.fromDioError(dioException);
      expect(apiEx.statusCode, equals(401));
      expect(apiEx.message, equals('Authentication required'));
      expect(apiEx.code, equals('UNAUTHORIZED'));
    });
  });
}
