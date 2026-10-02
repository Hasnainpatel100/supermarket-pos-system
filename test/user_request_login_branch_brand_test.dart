import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/features/authentication/data/models/auth_response_model.dart';
import 'package:super_market/model/model_branch.dart';
import 'package:super_market/model/model_brand.dart';

void main() {
  const userLoginPayload = '''{
    "data": {
        "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2YWJlMzRkYzhjM2U4NTMyOWQ4YzllZWUiLCJicmFuZElkIjoiNmFiZTMzNDY4YzNlODUzMjlkOGM5ZWVjIiwicm9sZSI6IldBSVRFUiIsInRva2VuVHlwZSI6ImFjY2VzcyIsInVzZXJUeXBlIjoiQlJBTkQiLCJhcHBUeXBlIjoiTUFSS0VUIiwiZXhwIjoxNzkwODUxMzc3LCJicmFuY2hJZCI6IjZhYmUzM2UzOGMzZTg1MzI5ZDhjOWVlZCJ9.8DJCJrRndInrVOH3kEhG5SmQPXkubsj33z8GR4rQBjc",
        "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2YWJlMzRkYzhjM2U4NTMyOWQ4YzllZWUiLCJicmFuZElkIjoiNmFiZTMzNDY4YzNlODUzMjlkOGM5ZWVjIiwicm9sZSI6IldBSVRFUiIsInRva2VuVHlwZSI6InJlZnJlc2giLCJ1c2VyVHlwZSI6IkJSQU5EIiwiYXBwVHlwZSI6Ik1BUktFVCIsImV4cCI6MTc5MTQ1NTI3Nywibm9uY2UiOjAsImJyYW5jaElkIjoiNmFiZTMzZTM4YzNlODUzMjlkOGM5ZWVkIn0.01N_X36LyccVGC6SvShboNvsDo6EVNq_D7lU0UXe6CE",
        "expiresIn": 900,
        "userId": "6abe34dc8c3e85329d8c9eee",
        "username": "Hasnain",
        "firstName": "Hasnain",
        "lastName": "Patel",
        "brandId": "6abe33468c3e85329d8c9eec",
        "branchId": "6abe33e38c3e85329d8c9eed",
        "role": "WAITER",
        "userType": "BRAND",
        "permissions": [
            "USER_CREATE", "USER_READ", "ORDER_CREATE", "PAYMENT_PROCESS"
        ],
        "appType": "MARKET",
        "inventoryMode": null
    },
    "message": null,
    "meta": null
}''';

  const userBranchPayload = '''{
    "data": {
        "id": "6abe37498c3e85329d8c9eef",
        "brandId": "6abe33468c3e85329d8c9eec",
        "branchCode": "D-Mart-02",
        "name": {
            "en": "D-Mart Solapur"
        },
        "contact": {
            "phones": {
                "primary": "+91 8364835401",
                "alternate": "",
                "whatsapp": "+91 6453859274"
            },
            "email": "DMartSolapur@gmail.com"
        },
        "address": {
            "full": "NEXT TO LULU HYPERMARKET-MASJID AL MANSOORI BUILDING AL KARMA - DUBAI",
            "city": "Latur",
            "state": "Maharastra",
            "country": "India",
            "countryCode": null,
            "zipCode": "",
            "latitude": 0.0,
            "longitude": 0.0,
            "gMapUrl": "",
            "gMapPlaceId": ""
        },
        "registration": {
            "gstNo": "",
            "gstType": "",
            "gstRegistrationDate": "",
            "fssaiNo": "",
            "fssaiExpiryDate": "",
            "cin": ""
        },
        "settings": {
            "isMasterBranch": false,
            "onlineMode": null,
            "inventoryMode": null,
            "open": "",
            "close": "",
            "currency": "",
            "timezone": "",
            "theme": "",
            "billing": {
                "billResetDays": 0,
                "kotResetDays": 0,
                "billPrefix": ""
            },
            "invoice": {
                "showGstBreakup": false,
                "showFssaiNo": false,
                "footerText": "",
                "qrCode": null,
                "qrFooterText": null
            }
        },
        "serviceTypes": [
            "DINE_IN",
            "QUICK_BILL",
            "TAKEAWAY",
            "DELIVERY"
        ],
        "payment": {
            "supportedPaymentModes": [],
            "upi": {
                "upiId": "",
                "qrImage": ""
            },
            "bank": {
                "bankName": "",
                "branchName": "",
                "ifsc": "",
                "accountNumber": "",
                "beneficiaryName": ""
            },
            "pan": ""
        },
        "planDetails": {
            "note": "Default",
            "maxUsers": 5,
            "maxPosDevices": 2,
            "expiryAt": 1792060489174,
            "pushFromLastDays": null,
            "assignedBy": "6abe34dc8c3e85329d8c9eee",
            "assignedAt": 1790850889174
        },
        "appType": "MARKET",
        "status": "active",
        "createdAt": 1790850889174,
        "createdBy": "6abe34dc8c3e85329d8c9eee",
        "updatedAt": null,
        "updatedBy": null,
        "imageId": null,
        "directOriginalUrl": "",
        "directThumbnailUrl": "",
        "carouselImageIds": [],
        "carouselImages": []
    },
    "message": null,
    "meta": null
}''';

  const userBrandPayload = '''{
    "data": {
        "id": "6abe33468c3e85329d8c9eec",
        "ownerId": "000000000000000000000001",
        "branchCode": "HO",
        "name": {
            "en": "D-Mart"
        },
        "registration": {
            "gstNo": "104099208125354",
            "gstType": "VAT",
            "gstRegistrationDate": "2026-10-04",
            "fssaiNo": "",
            "fssaiExpiryDate": "",
            "cin": ""
        },
        "contact": {
            "phones": {
                "primary": "+918767527475",
                "alternate": "",
                "whatsapp": "+917150484706"
            },
            "email": "D-Mart@gmail.com",
            "website": ""
        },
        "appType": "MARKET",
        "status": "active",
        "statusReason": "",
        "imageId": null,
        "directOriginalUrl": "",
        "directThumbnailUrl": "",
        "createdAt": 1790849862811,
        "createdBy": "000000000000000000000001",
        "updatedAt": null,
        "updatedBy": null
    },
    "message": null,
    "meta": null
}''';

  group('User Request 1: Strict appType == MARKET login condition', () {
    test('Parses login response and confirms appType is MARKET', () {
      final json = jsonDecode(userLoginPayload) as Map<String, dynamic>;
      final response = AuthLoginResponse.fromJson(json);

      expect(response.username, equals('Hasnain'));
      expect(response.userId, equals('6abe34dc8c3e85329d8c9eee'));
      expect(response.brandId, equals('6abe33468c3e85329d8c9eec'));
      expect(response.branchId, equals('6abe33e38c3e85329d8c9eed'));
      expect(response.appType, equals('MARKET'));
      expect((response.appType ?? '').trim().toUpperCase() == 'MARKET', isTrue);
    });

    test('Strict check rejects any appType other than MARKET', () {
      // restaurant
      final nonMarketResponse = AuthLoginResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        username: 'John',
        appType: 'RESTAURANT',
      );
      final isAllowed = (nonMarketResponse.appType ?? '').trim().toUpperCase() == 'MARKET';
      expect(isAllowed, isFalse);

      // null or empty
      final emptyResponse = AuthLoginResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        username: 'NoAppType',
        appType: null,
      );
      expect((emptyResponse.appType ?? '').trim().toUpperCase() == 'MARKET', isFalse);
    });
  });

  group('User Request 2: Branch Details & Plan Tracking', () {
    test('Parses Branch Details and tracks planDetails', () {
      final json = jsonDecode(userBranchPayload) as Map<String, dynamic>;
      final branchMap = json['data'] as Map<String, dynamic>;
      final branch = ModelBranch.fromJson(branchMap);

      expect(branch.id, equals('6abe37498c3e85329d8c9eef'));
      expect(branch.brandId, equals('6abe33468c3e85329d8c9eec'));
      expect(branch.name.en, equals('D-Mart Solapur'));
      expect(branch.branchCode, equals('D-Mart-02'));
      expect(branch.contact.phones.primary, equals('+91 8364835401'));

      final plan = branch.planDetails;
      expect(plan, isNotNull);
      expect(plan!.note, equals('Default'));
      expect(plan.maxUsers, equals(5));
      expect(plan.maxPosDevices, equals(2));
      expect(plan.expiryAt, equals(1792060489174));

      // Expiry calculation
      expect(plan.expiryDate, isNotNull);
      expect(plan.assignedDate, isNotNull);
      expect(plan.formattedExpiry, isNotEmpty);
      expect(plan.expiryStatusText, isNotEmpty);
    });
  });

  group('User Request 3: Brand Details Resolution', () {
    test('Parses Brand Details correctly using brandId', () {
      final json = jsonDecode(userBrandPayload) as Map<String, dynamic>;
      final brandMap = json['data'] as Map<String, dynamic>;
      final brand = ModelBrand.fromJson(brandMap);

      expect(brand.id, equals('6abe33468c3e85329d8c9eec'));
      expect(brand.name.en, equals('D-Mart'));
      expect(brand.branchCode, equals('HO'));
      expect(brand.contact.email, equals('D-Mart@gmail.com'));
      expect(brand.appType, equals('MARKET'));
      expect(brand.status.toLowerCase(), equals('active'));
    });
  });

  group('User Request 4: Plan History & Renewal Tracking ("Last Plan vs New Plan")', () {
    const postmanPlanHistoryPayload = '''{
      "data": {
        "data": [
          {
            "id": "6abe42388c3e85329d8c9ef0",
            "branchId": "6abe33e38c3e85329d8c9eed",
            "brandId": "6abe33468c3e85329d8c9eec",
            "note": "Premium plan assigned",
            "maxUsers": 2,
            "maxPosDevices": 3,
            "expiryAt": 1790741090000,
            "pushFromLastDays": 30,
            "assignedBy": "000000000000000000000001",
            "assignedAt": 1790853688102
          }
        ],
        "page": 0,
        "limit": 20,
        "total": 1,
        "totalPages": 1
      },
      "message": null,
      "meta": null
    }''';

    test('Parses Plan History from Postman response structure', () {
      final json = jsonDecode(postmanPlanHistoryPayload) as Map<String, dynamic>;
      final dataWrapper = json['data'] as Map<String, dynamic>;
      final list = dataWrapper['data'] as List<dynamic>;

      final historyRecords = list
          .map((item) => ModelBranchPlanHistory.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(historyRecords.length, equals(1));
      final record = historyRecords.first;
      expect(record.id, equals('6abe42388c3e85329d8c9ef0'));
      expect(record.branchId, equals('6abe33e38c3e85329d8c9eed'));
      expect(record.brandId, equals('6abe33468c3e85329d8c9eec'));
      expect(record.note, equals('Premium plan assigned'));
      expect(record.maxUsers, equals(2));
      expect(record.maxPosDevices, equals(3));
      expect(record.expiryAt, equals(1790741090000));
      expect(record.pushFromLastDays, equals(30));
      expect(record.assignedBy, equals('000000000000000000000001'));
      expect(record.assignedAt, equals(1790853688102));

      expect(record.expiryDate, isNotNull);
      expect(record.assignedDate, isNotNull);
      expect(record.formattedExpiry, isNotEmpty);
      expect(record.formattedAssignedAt, isNotEmpty);
      expect(record.expiryStatusText, isNotEmpty);
    });

    test('Tracks delta between Last Plan and New Renewed Plan', () {
      // Historical last plan
      const lastPlan = ModelBranchPlanHistory(
        branchId: '6abe33e38c3e85329d8c9eed',
        note: 'Basic Starter Plan',
        maxUsers: 2,
        maxPosDevices: 1,
        expiryAt: 1780000000000,
        pushFromLastDays: 15,
      );

      // New renewed plan
      const newPlan = BranchPlanDetails(
        note: 'Premium Enterprise Renewal',
        maxUsers: 5,
        maxPosDevices: 3,
        expiryAt: 1790741090000,
        pushFromLastDays: 30,
      );

      final userDelta = newPlan.maxUsers - lastPlan.maxUsers;
      final posDelta = newPlan.maxPosDevices - lastPlan.maxPosDevices;

      expect(userDelta, equals(3), reason: 'User capacity increased by 3');
      expect(posDelta, equals(2), reason: 'POS terminals increased by 2');
      expect(newPlan.note, isNot(equals(lastPlan.note)), reason: 'Tier was upgraded upon renewal');
    });
  });
}

