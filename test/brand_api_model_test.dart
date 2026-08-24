import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/model/model_brand.dart';
import 'package:super_market/service/service_brand_api.dart';
import 'package:super_market/service/service_storage.dart';

/// Simple mock adapter for Dio unit tests
class MockDioAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockDioAdapter(this.handler);

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

  const userPayloadJsonString = '''{ 
    "name": { 
        "en": "Mumkin Restaurant BR" 
    }, 
    "registration": { 
        "gstNo": "104099208100003", 
        "gstType": "VAT", 
        "gstRegistrationDate": "2026-07-04", 
        "fssaiNo": "", 
        "fssaiExpiryDate": "", 
        "cin": "" 
    }, 
    "contact": { 
        "phones": { 
            "primary": "+971504847006", 
            "alternate": "", 
            "whatsapp": "+971504847006" 
        }, 
        "email": "mumkin2023@gmail.com", 
        "website": "" 
    }, 
    "appType": "MARKET", 
    "status": "ACTIVE" 
}''';

  group('ModelBrand JSON Serialization Tests', () {
    test('Correctly deserializes user API payload', () {
      final decoded = jsonDecode(userPayloadJsonString) as Map<String, dynamic>;
      final brand = ModelBrand.fromJson(decoded);

      expect(brand.name.en, equals('Mumkin Restaurant BR'));
      expect(brand.registration.gstNo, equals('104099208100003'));
      expect(brand.registration.gstType, equals('VAT'));
      expect(brand.registration.gstRegistrationDate, equals('2026-07-04'));
      expect(brand.registration.fssaiNo, equals(''));
      expect(brand.registration.fssaiExpiryDate, equals(''));
      expect(brand.registration.cin, equals(''));
      expect(brand.contact.phones.primary, equals('+971504847006'));
      expect(brand.contact.phones.alternate, equals(''));
      expect(brand.contact.phones.whatsapp, equals('+971504847006'));
      expect(brand.contact.email, equals('mumkin2023@gmail.com'));
      expect(brand.contact.website, equals(''));
      expect(brand.appType, equals('MARKET'));
      expect(brand.status, equals('ACTIVE'));
      expect(brand.isActive, isTrue);
      expect(brand.isMarket, isTrue);
    });

    test('toJson produces exact payload format expected by POST /api/brands', () {
      final decoded = jsonDecode(userPayloadJsonString) as Map<String, dynamic>;
      final brand = ModelBrand.fromJson(decoded);
      final jsonMap = brand.toJson();

      expect(jsonMap['name']['en'], equals('Mumkin Restaurant BR'));
      expect(jsonMap['registration']['gstNo'], equals('104099208100003'));
      expect(jsonMap['registration']['gstType'], equals('VAT'));
      expect(jsonMap['registration']['gstRegistrationDate'], equals('2026-07-04'));
      expect(jsonMap['contact']['phones']['primary'], equals('+971504847006'));
      expect(jsonMap['contact']['phones']['whatsapp'], equals('+971504847006'));
      expect(jsonMap['contact']['email'], equals('mumkin2023@gmail.com'));
      expect(jsonMap['appType'], equals('MARKET'));
      expect(jsonMap['status'], equals('ACTIVE'));
    });
  });

  group('ServiceBrandApi Dio REST Client Tests', () {
    late ServiceStorage storage;

    setUp(() async {
      storage = ServiceStorage();
    });

    test('createBrand sends POST to /api/brands with correct JSON using Dio', () async {
      final mockAdapter = MockDioAdapter((options) async {
        expect(options.method, equals('POST'));
        expect(options.path, equals('/api/brands'));

        final body = options.data is Map ? options.data as Map<String, dynamic> : jsonDecode(options.data.toString());
        expect(body['name']['en'], equals('Mumkin Restaurant BR'));
        expect(body['appType'], equals('MARKET'));

        final responsePayload = {
          'success': true,
          'data': {
            'id': 'brand_mongo_12345',
            ...body,
          }
        };

        return ResponseBody.fromString(
          jsonEncode(responsePayload),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = mockAdapter;
      final service = ServiceBrandApi(storage, dioClient: dio);
      final decoded = jsonDecode(userPayloadJsonString) as Map<String, dynamic>;
      final brandToCreate = ModelBrand.fromJson(decoded);

      final response = await service.createBrand(brandToCreate);

      expect(response.success, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.id, equals('brand_mongo_12345'));
      expect(response.data!.name.en, equals('Mumkin Restaurant BR'));
    });

    test('getBrands sends GET to /api/brands with appType query parameter using Dio', () async {
      final mockAdapter = MockDioAdapter((options) async {
        expect(options.method, equals('GET'));
        expect(options.path, equals('/api/brands'));
        expect(options.queryParameters['appType'], equals('MARKET'));

        final responsePayload = {
          'success': true,
          'data': [
            {
              'id': 'brand_1',
              'name': {'en': 'Mumkin Supermarket'},
              'appType': 'MARKET',
              'status': 'ACTIVE',
            }
          ]
        };

        return ResponseBody.fromString(
          jsonEncode(responsePayload),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = mockAdapter;
      final service = ServiceBrandApi(storage, dioClient: dio);
      final response = await service.getBrands(appType: 'MARKET');

      expect(response.success, isTrue);
      expect(response.data!.length, equals(1));
      expect(response.data!.first.name.en, equals('Mumkin Supermarket'));
    });

    test('updateBrand sends PUT to /api/brands/:id using Dio', () async {
      final mockAdapter = MockDioAdapter((options) async {
        expect(options.method, equals('PUT'));
        expect(options.path, equals('/api/brands/brand_123'));

        final body = options.data is Map ? options.data as Map<String, dynamic> : jsonDecode(options.data.toString());
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'id': 'brand_123', ...body}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = mockAdapter;
      final service = ServiceBrandApi(storage, dioClient: dio);
      final decoded = jsonDecode(userPayloadJsonString) as Map<String, dynamic>;
      final brand = ModelBrand.fromJson(decoded);

      final response = await service.updateBrand('brand_123', brand);

      expect(response.success, isTrue);
      expect(response.data!.id, equals('brand_123'));
    });

    test('deleteBrand sends DELETE to /api/brands/:id using Dio', () async {
      final mockAdapter = MockDioAdapter((options) async {
        expect(options.method, equals('DELETE'));
        expect(options.path, equals('/api/brands/brand_123'));
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = mockAdapter;
      final service = ServiceBrandApi(storage, dioClient: dio);
      final response = await service.deleteBrand('brand_123');

      expect(response.success, isTrue);
    });
  });
}
