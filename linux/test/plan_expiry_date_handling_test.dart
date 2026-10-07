import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/model/model_branch.dart';
import 'package:super_market/service/service_brand_context.dart';
import 'package:get/get.dart';

void main() {
  group('Plan Expiration & Date Handling Tests (UTC Timing & Hours/Minutes)', () {
    final nowUtc = DateTime.now().toUtc();

    test('Plan expiring tomorrow is NOT expired and has 1 day remaining', () {
      final tomorrow = nowUtc.add(const Duration(days: 1, hours: 2));
      final plan = BranchPlanDetails(
        expiryAt: tomorrow.millisecondsSinceEpoch,
        note: 'Premium plan assigned',
      );

      expect(plan.isExpired, isFalse, reason: 'Plan expiring tomorrow must NOT be marked expired');
      expect(plan.daysRemaining, greaterThanOrEqualTo(1));
      expect(plan.expiryStatusText, contains('Expires'));
    });

    test('Plan expiring 2 hours in the future today (UTC) is NOT expired', () {
      final futureToday = nowUtc.add(const Duration(hours: 2));
      final plan = BranchPlanDetails(
        expiryAt: futureToday.millisecondsSinceEpoch,
        note: 'Premium plan assigned',
      );

      expect(plan.isExpired, isFalse, reason: 'Future hours/minutes in UTC must remain active');
      expect(plan.expiryStatusText, contains('Expires in'));
    });

    test('Plan whose UTC hours and minutes have passed (30 mins ago) IS expired', () {
      final pastToday = nowUtc.subtract(const Duration(minutes: 30));
      final plan = BranchPlanDetails(
        expiryAt: pastToday.millisecondsSinceEpoch,
        note: 'Expiring plan',
      );

      expect(plan.isExpired, isTrue, reason: 'Past UTC hour and minute must be marked expired');
      expect(plan.expiryStatusText, contains('Expired'));
      expect(plan.expiryStatusText, contains('mins ago'));
    });

    test('Plan expired yesterday IS expired with negative remaining days', () {
      final yesterday = nowUtc.subtract(const Duration(days: 1, hours: 1));
      final plan = BranchPlanDetails(
        expiryAt: yesterday.millisecondsSinceEpoch,
        note: 'Expired plan',
      );

      expect(plan.isExpired, isTrue, reason: 'Plan expired yesterday must be expired');
      expect(plan.daysRemaining, lessThan(0));
      expect(plan.expiryStatusText, equals('Expired Yesterday'));
    });

    test('Plan expired 5 days ago displays correct days ago text', () {
      final pastDate = nowUtc.subtract(const Duration(days: 5, hours: 1));
      final plan = BranchPlanDetails(
        expiryAt: pastDate.millisecondsSinceEpoch,
        note: 'Old plan',
      );

      expect(plan.isExpired, isTrue);
      expect(plan.daysRemaining, equals(-5));
      expect(plan.expiryStatusText, equals('Expired 5 days ago'));
    });

    test('Plan expiring in 10 days displays correct days remaining text', () {
      final futureDate = nowUtc.add(const Duration(days: 10));
      final plan = BranchPlanDetails(
        expiryAt: futureDate.millisecondsSinceEpoch,
        note: 'Active plan',
      );

      expect(plan.isExpired, isFalse);
      expect(plan.daysRemaining, equals(10));
      expect(plan.expiryStatusText, equals('Expires in 10 days'));
    });

    test('ServiceBrandContext correctly evaluates isPlanExpired for future plan', () {
      Get.reset();
      final brandContext = Get.put(ServiceBrandContext());

      final tomorrow = nowUtc.add(const Duration(days: 1));
      final branchWithTomorrowPlan = ModelBranch(
        branchCode: 'D-Mart-02',
        name: const BranchName(en: 'D-Mart Solapur'),
        address: const BranchAddress(full: 'Solapur'),
        contact: const BranchContact(phones: BranchPhones(primary: '1234567890'), email: 'test@dmart.com'),
        brandId: 'brand123',
        planDetails: BranchPlanDetails(
          expiryAt: tomorrow.millisecondsSinceEpoch,
          note: 'Premium plan assigned',
        ),
      );

      brandContext.selectBranch(branchWithTomorrowPlan);

      expect(brandContext.isPlanExpired, isFalse, reason: 'ServiceBrandContext should NOT report expired for tomorrow');
      expect(brandContext.isPlanExpiredOrToday, isFalse, reason: 'ServiceBrandContext should allow login when expiring tomorrow');
      expect(brandContext.planDaysRemaining, equals(1));
    });

    test('ServiceBrandContext blocks when plan has passed UTC expiry time (including hours/minutes)', () {
      Get.reset();
      final brandContext = Get.put(ServiceBrandContext());

      final pastTime = nowUtc.subtract(const Duration(minutes: 15));
      final branchWithExpiredPlan = ModelBranch(
        branchCode: 'D-Mart-02',
        name: const BranchName(en: 'D-Mart Solapur'),
        address: const BranchAddress(full: 'Solapur'),
        contact: const BranchContact(phones: BranchPhones(primary: '1234567890'), email: 'test@dmart.com'),
        brandId: 'brand123',
        planDetails: BranchPlanDetails(
          expiryAt: pastTime.millisecondsSinceEpoch,
          note: 'Expired plan',
        ),
      );

      brandContext.selectBranch(branchWithExpiredPlan);

      expect(brandContext.isPlanExpired, isTrue, reason: 'Must report true when plan passed UTC expiry');
      expect(brandContext.isPlanExpiredOrToday, isTrue);
    });

    test('Parses various date and timestamp formats accurately into UTC', () {
      // 1. ISO date string
      const isoPlan = BranchPlanDetails(expiryAt: '2026-10-03');
      expect(isoPlan.expiryDate?.isUtc, isTrue);
      expect(isoPlan.expiryDate?.year, equals(2026));
      expect(isoPlan.expiryDate?.month, equals(10));
      expect(isoPlan.expiryDate?.day, equals(3));

      // 2. UTC ISO timestamp string
      const utcPlan = BranchPlanDetails(expiryAt: '2026-10-03T09:30:00.000Z');
      expect(utcPlan.expiryDate, isNotNull);
      expect(utcPlan.expiryDate?.isUtc, isTrue);
      expect(utcPlan.expiryDate?.hour, equals(9));
      expect(utcPlan.expiryDate?.minute, equals(30));

      // 3. String numeric epoch timestamp
      const strEpochPlan = BranchPlanDetails(expiryAt: '1791019800000');
      expect(strEpochPlan.expiryDate, isNotNull);
      expect(strEpochPlan.expiryDate?.isUtc, isTrue);
      expect(strEpochPlan.expiryDate?.hour, equals(9));
      expect(strEpochPlan.expiryDate?.minute, equals(30));

      // 4. num / int epoch timestamp: 1791019800000 -> 2026-10-03 09:30 UTC
      const intEpochPlan = BranchPlanDetails(expiryAt: 1791019800000);
      expect(intEpochPlan.expiryDate, isNotNull);
      expect(intEpochPlan.expiryDate?.isUtc, isTrue);
      expect(intEpochPlan.expiryDate?.hour, equals(9));
      expect(intEpochPlan.expiryDate?.minute, equals(30));
      expect(intEpochPlan.formattedExpiry, equals('03/10/2026 09:30 UTC'));
    });
  });
}
