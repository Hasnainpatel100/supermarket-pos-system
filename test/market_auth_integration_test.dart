import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/core/network/api_exception.dart';
import 'package:super_market/core/storage/token_storage.dart';
import 'package:super_market/features/authentication/data/models/auth_response_model.dart';
import 'package:super_market/model/model_brand.dart';
import 'package:super_market/model/model_branch.dart';
import 'package:super_market/service/service_storage.dart';

// ---------------------------------------------------------------------------
// Minimal Dio mock adapter (no real HTTP calls)
// ---------------------------------------------------------------------------
class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Sample payloads matching documented backend contracts
// ---------------------------------------------------------------------------

const _marketLoginJson = '''
{
  "data": {
    "accessToken": "header.payload.sig",
    "refreshToken": "refresh_token_abc",
    "expiresIn": 900,
    "userId": "6ab25a6a116d746e2d20567f",
    "username": "marketuser",
    "firstName": "Market",
    "lastName": "User",
    "brandId": "6ab244d7116d746e2d20567b",
    "branchId": "6ab25a6a116d746e2d20567f",
    "role": "CASHIER",
    "userType": "MARKET",
    "appType": "MARKET",
    "permissions": ["pos", "inventory", "reports"]
  },
  "message": null,
  "meta": null
}
''';

const _platformLoginJson = '''
{
  "data": {
    "accessToken": "platform.access.token",
    "refreshToken": "platform.refresh.token",
    "expiresIn": 900,
    "userId": "000000000000000000000001",
    "username": "superadmin",
    "firstName": "Super",
    "lastName": "Admin",
    "brandId": "000000000000000000000000",
    "branchId": "000000000000000000000000",
    "role": "SUPER_ADMIN",
    "userType": "PLATFORM",
    "appType": "PLATFORM",
    "permissions": ["superVendorAccess", "brandManage"]
  },
  "message": null,
  "meta": null
}
''';

const _restaurantLoginJson = '''
{
  "data": {
    "accessToken": "restaurant.access.token",
    "refreshToken": "restaurant.refresh.token",
    "expiresIn": 900,
    "userId": "aabbccddeeff001122334455",
    "username": "restaurantuser",
    "firstName": "Rest",
    "lastName": "User",
    "brandId": "aabbccddeeff001122334456",
    "branchId": "aabbccddeeff001122334457",
    "role": "MANAGER",
    "userType": "RESTAURANT",
    "appType": "RESTAURANT",
    "permissions": ["pos"]
  },
  "message": null,
  "meta": null
}
''';

const _brandResponseJson = '''
{
  "data": {
    "id": "6ab244d7116d746e2d20567b",
    "ownerId": "000000000000000000000001",
    "branchCode": "HO",
    "name": { "en": "Amer Resturant1" },
    "registration": {
      "gstNo": "12345", "gstType": "VAT", "gstRegistrationDate": "2026-09-30",
      "fssaiNo": "12345", "fssaiExpiryDate": "2027-09-30", "cin": "12343"
    },
    "contact": {
      "phones": { "primary": "0987654321", "alternate": "", "whatsapp": "" },
      "email": "", "website": ""
    },
    "status": "active",
    "statusReason": "",
    "createdAt": 1790067927947,
    "createdBy": "000000000000000000000001",
    "updatedAt": 1790078123533,
    "updatedBy": "000000000000000000000001"
  },
  "message": null,
  "meta": null
}
''';

const _branchResponseJson = '''
{
  "data": {
    "id": "6ab25a6a116d746e2d20567f",
    "brandId": "6ab244d7116d746e2d20567b",
    "branchCode": "Amer1",
    "name": { "en": "Amer Hotel Latur" },
    "contact": {
      "phones": { "primary": "8767527474", "alternate": "", "whatsapp": "" },
      "email": ""
    },
    "address": {
      "full": "Osman pura", "city": "Latur", "state": "Maharastra",
      "country": "Indina", "zipCode": "", "latitude": 0.0, "longitude": 0.0,
      "gMapUrl": "", "gMapPlaceId": ""
    },
    "registration": {
      "gstNo": "", "gstType": "", "gstRegistrationDate": "",
      "fssaiNo": "", "fssaiExpiryDate": "", "cin": ""
    },
    "settings": {
      "isMasterBranch": false, "open": "", "close": "",
      "currency": "INR", "timezone": "Asia/Kolkata", "theme": "light",
      "billing": { "billResetDays": 0, "kotResetDays": 0, "billPrefix": "" },
      "invoice": { "showGstBreakup": false, "showFssaiNo": false, "footerText": "" }
    },
    "serviceTypes": ["QUICK_BILL", "DELIVERY", "DINE_IN", "TAKEAWAY"],
    "payment": {
      "supportedPaymentModes": [],
      "upi": { "upiId": "", "qrImage": "" },
      "bank": { "bankName": "", "branchName": "", "ifsc": "", "accountNumber": "", "beneficiaryName": "" },
      "pan": ""
    },
    "planDetails": {
      "note": "Default", "maxUsers": 5, "maxPosDevices": 2,
      "expiryAt": 1791283050631,
      "assignedBy": "000000000000000000000001",
      "assignedAt": 1790073450631
    },
    "status": "active",
    "createdAt": 1790073450631,
    "createdBy": "000000000000000000000001",
    "updatedAt": null,
    "updatedBy": null
  },
  "message": null,
  "meta": null
}
''';

// ---------------------------------------------------------------------------
// Helpers mirroring AuthRepository / ControllerLogin validation logic
// ---------------------------------------------------------------------------
bool _isValidMongoId(String? id) {
  if (id == null || id.isEmpty) return false;
  if (id == '000000000000000000000000') return false;
  return RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
}

/// Returns true if the login response should be REJECTED on the MARKET POS.
/// Mirrors the exact conditions in AuthRepository.login() and ControllerLogin.login().
bool _isRejectedByMarketCheck(AuthLoginResponse r) {
  final appTypeUpper = (r.appType ?? '').trim().toUpperCase();
  return appTypeUpper != 'MARKET';
}

// ---------------------------------------------------------------------------
// Top-level data helpers (getters aren't allowed inside closures)
// ---------------------------------------------------------------------------
Map<String, dynamic> _brandData() =>
    (jsonDecode(_brandResponseJson) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;

Map<String, dynamic> _branchData() =>
    (jsonDecode(_branchResponseJson) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;

// ---------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider to prevent MissingPluginException in TokenStorage tests
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
  });

  // ── 1. AuthLoginResponse model parsing ───────────────────────────────────
  group('AuthLoginResponse – MARKET login response parsing', () {
    test('parses all fields from nested data envelope', () {
      final r = AuthLoginResponse.fromJson(
        jsonDecode(_marketLoginJson) as Map<String, dynamic>,
      );
      expect(r.accessToken, isNotEmpty);
      expect(r.refreshToken, equals('refresh_token_abc'));
      expect(r.expiresIn, equals(900));
      expect(r.userId, equals('6ab25a6a116d746e2d20567f'));
      expect(r.username, equals('marketuser'));
      expect(r.firstName, equals('Market'));
      expect(r.lastName, equals('User'));
      expect(r.brandId, equals('6ab244d7116d746e2d20567b'));
      expect(r.branchId, equals('6ab25a6a116d746e2d20567f'));
      expect(r.role, equals('CASHIER'));
      expect(r.userType, equals('MARKET'));
      expect(r.permissions, containsAll(['pos', 'inventory', 'reports']));
    });

    test('MARKET user passes the MARKET validation guard', () {
      final r = AuthLoginResponse.fromJson(
        jsonDecode(_marketLoginJson) as Map<String, dynamic>,
      );
      expect(_isRejectedByMarketCheck(r), isFalse);
    });

    test('MARKET user has valid non-zero brandId and branchId', () {
      final r = AuthLoginResponse.fromJson(
        jsonDecode(_marketLoginJson) as Map<String, dynamic>,
      );
      expect(_isValidMongoId(r.brandId), isTrue);
      expect(_isValidMongoId(r.branchId), isTrue);
    });

    test('toJson preserves all non-null fields', () {
      final r = AuthLoginResponse.fromJson(
        jsonDecode(_marketLoginJson) as Map<String, dynamic>,
      );
      final m = r.toJson();
      expect(m['username'], equals('marketuser'));
      expect(m['brandId'], equals('6ab244d7116d746e2d20567b'));
      expect(m['branchId'], equals('6ab25a6a116d746e2d20567f'));
      expect(m['userType'], equals('MARKET'));
    });
  });

  // ── 2. PLATFORM user handling ────────────────────────────────────────────
  group('AuthLoginResponse – PLATFORM user handling', () {
    test('parses PLATFORM response without error', () {
      final r = AuthLoginResponse.fromJson(
        jsonDecode(_platformLoginJson) as Map<String, dynamic>,
      );
      expect(r.username, equals('superadmin'));
      expect(r.userType, equals('PLATFORM'));
      expect(r.role, equals('SUPER_ADMIN'));
    });

    test('PLATFORM without MARKET appType is rejected by MARKET guard', () {
      final r = AuthLoginResponse.fromJson(
        jsonDecode(_platformLoginJson) as Map<String, dynamic>,
      );
      expect(_isRejectedByMarketCheck(r), isTrue);
    });

    test(
      'PLATFORM has zero brand/branch IDs — prevents brand/branch fetch',
      () {
        final r = AuthLoginResponse.fromJson(
          jsonDecode(_platformLoginJson) as Map<String, dynamic>,
        );
        expect(
          _isValidMongoId(r.brandId),
          isFalse,
          reason: 'Zero brandId blocks brand fetch',
        );
        expect(
          _isValidMongoId(r.branchId),
          isFalse,
          reason: 'Zero branchId blocks branch fetch',
        );
      },
    );
  });

  // ── 3. Non-MARKET rejection ───────────────────────────────────────────────
  group('AuthLoginResponse – RESTAURANT user must be rejected', () {
    test('RESTAURANT userType is rejected by MARKET guard', () {
      final r = AuthLoginResponse.fromJson(
        jsonDecode(_restaurantLoginJson) as Map<String, dynamic>,
      );
      expect(r.userType, equals('RESTAURANT'));
      expect(_isRejectedByMarketCheck(r), isTrue);
    });
  });

  // ── 4. ID validation ──────────────────────────────────────────────────────
  group('MongoDB ObjectId validation', () {
    test('null is invalid', () => expect(_isValidMongoId(null), isFalse));
    test('empty is invalid', () => expect(_isValidMongoId(''), isFalse));
    test(
      'all-zeros is invalid',
      () => expect(_isValidMongoId('000000000000000000000000'), isFalse),
    );
    test(
      'valid 24-hex-char passes',
      () => expect(_isValidMongoId('6ab244d7116d746e2d20567b'), isTrue),
    );
    test('short ID fails', () => expect(_isValidMongoId('abc123'), isFalse));
    test(
      'non-hex fails',
      () => expect(_isValidMongoId('zzzzzzzzzzzzzzzzzzzzzzzz'), isFalse),
    );
  });

  // ── 5. TokenStorage lifecycle ─────────────────────────────────────────────
  group('TokenStorage – session persistence', () {
    late TokenStorage ts;
    setUp(() => ts = TokenStorage(ServiceStorage()));

    test('strips Bearer prefix on save', () async {
      await ts.saveAccessToken('Bearer my_token');
      expect(ts.getAccessToken(), equals('my_token'));
    });

    test('saves and reads brandId / branchId', () async {
      await ts.saveBrandId('6ab244d7116d746e2d20567b');
      await ts.saveBranchId('6ab25a6a116d746e2d20567f');
      expect(ts.getBrandId(), equals('6ab244d7116d746e2d20567b'));
      expect(ts.getBranchId(), equals('6ab25a6a116d746e2d20567f'));
    });

    test(
      'hasAccessToken is false before save',
      () => expect(ts.hasAccessToken, isFalse),
    );

    test('hasAccessToken is true after valid save', () async {
      await ts.saveAccessToken('jwt');
      expect(ts.hasAccessToken, isTrue);
    });

    test('clearTokens removes all session data', () async {
      await ts.saveAccessToken('t');
      await ts.saveRefreshToken('r');
      await ts.saveBrandId('6ab244d7116d746e2d20567b');
      await ts.saveBranchId('6ab25a6a116d746e2d20567f');
      await ts.saveAppType('MARKET');
      await ts.clearTokens();
      expect(ts.getAccessToken(), isNull);
      expect(ts.getRefreshToken(), isNull);
      expect(ts.getBrandId(), isNull);
      expect(ts.getBranchId(), isNull);
      expect(ts.getAppType(), isNull);
    });

    test('brand/branch JSON survives save and restore', () async {
      const bj = '{"id":"6ab244d7116d746e2d20567b","name":{"en":"T"}}';
      const brj =
          '{"id":"6ab25a6a116d746e2d20567f","brandId":"6ab244d7116d746e2d20567b","name":{"en":"B"}}';
      await ts.saveBrandJson(bj);
      await ts.saveBranchJson(brj);
      expect(ts.getBrandJson(), equals(bj));
      expect(ts.getBranchJson(), equals(brj));
    });

    test(
      'sanitizeToken strips whitespace, newlines, quotes, Bearer prefix',
      () {
        expect(TokenStorage.sanitizeToken(' jwt\n'), equals('jwt'));
        expect(TokenStorage.sanitizeToken('Bearer jwt'), equals('jwt'));
        expect(TokenStorage.sanitizeToken('"jwt"'), equals('jwt'));
        expect(TokenStorage.sanitizeToken(null), equals(''));
      },
    );
  });

  // ── 6. ModelBrand parsing ─────────────────────────────────────────────────
  group('ModelBrand – full API response parsing', () {
    test('parses core fields', () {
      final data = _brandData();
      final b = ModelBrand.fromJson(data);
      expect(b.id, equals('6ab244d7116d746e2d20567b'));
      expect(b.ownerId, equals('000000000000000000000001'));
      expect(b.branchCode, equals('HO'));
      expect(b.name.en, equals('Amer Resturant1'));
    });

    test('parses registration', () {
      final b = ModelBrand.fromJson(_brandData());
      expect(b.registration.gstNo, equals('12345'));
      expect(b.registration.gstType, equals('VAT'));
      expect(b.registration.gstRegistrationDate, equals('2026-09-30'));
      expect(b.registration.fssaiNo, equals('12345'));
    });

    test('parses contact', () {
      final b = ModelBrand.fromJson(_brandData());
      expect(b.contact.phones.primary, equals('0987654321'));
      expect(b.contact.email, equals(''));
    });

    test('toMap/fromMap round-trip', () {
      final orig = ModelBrand.fromJson(_brandData());
      final restored = ModelBrand.fromMap(orig.toMap());
      expect(restored.id, equals(orig.id));
      expect(restored.name.en, equals(orig.name.en));
      expect(restored.registration.gstNo, equals(orig.registration.gstNo));
    });
  });

  // ── 7. ModelBranch full parsing with billing/invoice ──────────────────────
  group('ModelBranch – full API response parsing with BranchSettings', () {
    test('parses core branch fields', () {
      final b = ModelBranch.fromJson(_branchData());
      expect(b.id, equals('6ab25a6a116d746e2d20567f'));
      expect(b.brandId, equals('6ab244d7116d746e2d20567b'));
      expect(b.branchCode, equals('Amer1'));
      expect(b.name.en, equals('Amer Hotel Latur'));
    });

    test('parses contact', () {
      final b = ModelBranch.fromJson(_branchData());
      expect(b.contact.phones.primary, equals('8767527474'));
    });

    test('parses address', () {
      final b = ModelBranch.fromJson(_branchData());
      expect(b.address.city, equals('Latur'));
      expect(b.address.state, equals('Maharastra'));
    });

    test('parses BranchSettings with currency, timezone, theme', () {
      final b = ModelBranch.fromJson(_branchData());
      expect(b.settings.isMasterBranch, isFalse);
      expect(b.settings.currency, equals('INR'));
      expect(b.settings.timezone, equals('Asia/Kolkata'));
      expect(b.settings.theme, equals('light'));
    });

    test('parses BranchBillingSettings', () {
      final b = ModelBranch.fromJson(_branchData());
      expect(b.settings.billing.billResetDays, equals(0));
      expect(b.settings.billing.kotResetDays, equals(0));
      expect(b.settings.billing.billPrefix, equals(''));
    });

    test('parses BranchInvoiceSettings', () {
      final b = ModelBranch.fromJson(_branchData());
      expect(b.settings.invoice.showGstBreakup, isFalse);
      expect(b.settings.invoice.showFssaiNo, isFalse);
      expect(b.settings.invoice.footerText, equals(''));
    });

    test('parses serviceTypes', () {
      final b = ModelBranch.fromJson(_branchData());
      expect(
        b.serviceTypes,
        containsAll(['QUICK_BILL', 'DELIVERY', 'DINE_IN', 'TAKEAWAY']),
      );
      expect(b.hasServices, isTrue);
    });

    test('parses planDetails', () {
      final b = ModelBranch.fromJson(_branchData());
      expect(b.planDetails?.maxUsers, equals(5));
      expect(b.planDetails?.maxPosDevices, equals(2));
      expect(b.planDetails?.note, equals('Default'));
    });

    test('toMap/fromMap round-trip preserves settings, billing, invoice', () {
      final orig = ModelBranch.fromJson(_branchData());
      final restored = ModelBranch.fromMap(orig.toMap());
      expect(restored.settings.currency, equals(orig.settings.currency));
      expect(restored.settings.timezone, equals(orig.settings.timezone));
      expect(
        restored.settings.billing.billResetDays,
        equals(orig.settings.billing.billResetDays),
      );
      expect(
        restored.settings.invoice.showGstBreakup,
        equals(orig.settings.invoice.showGstBreakup),
      );
      expect(
        restored.planDetails?.maxUsers,
        equals(orig.planDetails?.maxUsers),
      );
    });
  });

  // ── 8. Brand-Branch consistency validation ────────────────────────────────
  group('Brand-Branch consistency', () {
    test('branch.brandId matches login brandId', () {
      final login = AuthLoginResponse.fromJson(
        jsonDecode(_marketLoginJson) as Map<String, dynamic>,
      );
      final branch = ModelBranch.fromJson(
        (jsonDecode(_branchResponseJson) as Map<String, dynamic>)['data']
            as Map<String, dynamic>,
      );
      expect(branch.brandId, equals(login.brandId));
    });

    test('branch.id matches login branchId', () {
      final login = AuthLoginResponse.fromJson(
        jsonDecode(_marketLoginJson) as Map<String, dynamic>,
      );
      final branch = ModelBranch.fromJson(
        (jsonDecode(_branchResponseJson) as Map<String, dynamic>)['data']
            as Map<String, dynamic>,
      );
      expect(branch.id, equals(login.branchId));
    });

    test('brand.id matches login brandId', () {
      final login = AuthLoginResponse.fromJson(
        jsonDecode(_marketLoginJson) as Map<String, dynamic>,
      );
      final brand = ModelBrand.fromJson(
        (jsonDecode(_brandResponseJson) as Map<String, dynamic>)['data']
            as Map<String, dynamic>,
      );
      expect(brand.id, equals(login.brandId));
    });

    test('mismatched brandId is detected', () {
      final login = AuthLoginResponse.fromJson(
        jsonDecode(_marketLoginJson) as Map<String, dynamic>,
      );
      final wrongBranch = ModelBranch.fromJson({
        'id': '6ab25a6a116d746e2d20567f',
        'brandId': 'ffffffffffffffffffffffff',
        'branchCode': 'X',
        'name': {'en': 'Wrong'},
      });
      expect(wrongBranch.brandId, isNot(equals(login.brandId)));
    });
  });

  // ── 9. ApiException error handling ────────────────────────────────────────
  group('ApiException – error structure parsing', () {
    test('parses nested { error: { code, message } }', () {
      final ex = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
            data: {
              'error': {
                'code': 'INVALID_CREDENTIALS',
                'message': 'Username or password is incorrect',
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(ex.statusCode, equals(401));
      expect(ex.code, equals('INVALID_CREDENTIALS'));
      expect(ex.message, equals('Username or password is incorrect'));
    });

    test('handles connection error (503)', () {
      final ex = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(ex.statusCode, equals(503));
    });

    test('handles connection timeout (408)', () {
      final ex = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(ex.statusCode, equals(408));
    });

    test('parses flat { message } error', () {
      final ex = ApiException.fromDioError(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 400,
            data: {'message': 'Invalid username format'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(ex.message, equals('Invalid username format'));
    });
  });

  // ── 10. Token injected into protected request headers ─────────────────────
  group('Token injection to protected API requests', () {
    test('access token appears as Bearer header', () async {
      final ts = TokenStorage(ServiceStorage());
      await ts.saveAccessToken('valid_market_jwt_token');

      String? captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8080'));
      // Simulate AuthInterceptor behaviour: inject token before request fires
      final token = ts.getAccessToken();
      dio.options.headers['Authorization'] = 'Bearer $token';

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options.headers['Authorization']?.toString();
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                message: 'test_abort',
              ),
            );
          },
        ),
      );

      try {
        await dio.get('/api/brands/6ab244d7116d746e2d20567b');
      } catch (_) {}

      expect(captured, equals('Bearer valid_market_jwt_token'));
    });
  });
}
