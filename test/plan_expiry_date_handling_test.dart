import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/model/model_branch.dart';
import 'package:super_market/service/service_brand_context.dart';
import 'package:get/get.dart';

void main() {
  group('Plan Expiration & Date Handling Tests', () {
    final now = DateTime.now();

    test('Plan expiring tomorrow is NOT expired and has 1 day remaining', () {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final plan = BranchPlanDetails(
        expiryAt: tomorrow.millisecondsSinceEpoch,
        note: 'Premium plan assigned',
      );

      expect(plan.isExpired, isFalse, reason: 'Plan expiring tomorrow must NOT be marked expired');
      expect(plan.daysRemaining, equals(1), reason: 'Tomorrow should have 1 day remaining');
      expect(plan.expiryStatusText, equals('Expires Tomorrow'));
    });

    test('Plan expiring today is NOT expired and remains active for the full day', () {
      // Even if set to midnight today 00:00:00
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final plan = BranchPlanDetails(
        expiryAt: todayMidnight.millisecondsSinceEpoch,
        note: 'Premium plan assigned',
      );

      expect(plan.isExpired, isFalse, reason: 'Plan expiring today is valid until 23:59:59.999');
      expect(plan.daysRemaining, equals(0), reason: 'Today should have 0 days remaining');
      expect(plan.expiryStatusText, equals('Expires Today'));
    });

    test('Plan expired yesterday IS expired with negative remaining days', () {
      final yesterday = DateTime(now.year, now.month, now.day - 1, 10, 0, 0);
      final plan = BranchPlanDetails(
        expiryAt: yesterday.millisecondsSinceEpoch,
        note: 'Expired plan',
      );

      expect(plan.isExpired, isTrue, reason: 'Plan expired yesterday must be expired');
      expect(plan.daysRemaining, equals(-1));
      expect(plan.expiryStatusText, equals('Expired Yesterday'));
    });

    test('Plan expired 5 days ago displays correct days ago text', () {
      final pastDate = DateTime(now.year, now.month, now.day - 5);
      final plan = BranchPlanDetails(
        expiryAt: pastDate.millisecondsSinceEpoch,
        note: 'Old plan',
      );

      expect(plan.isExpired, isTrue);
      expect(plan.daysRemaining, equals(-5));
      expect(plan.expiryStatusText, equals('Expired 5 days ago'));
    });

    test('Plan expiring in 10 days displays correct days remaining text', () {
      final futureDate = DateTime(now.year, now.month, now.day + 10);
      final plan = BranchPlanDetails(
        expiryAt: futureDate.millisecondsSinceEpoch,
        note: 'Active plan',
      );

      expect(plan.isExpired, isFalse);
      expect(plan.daysRemaining, equals(10));
      expect(plan.expiryStatusText, equals('Expires in 10 days'));
    });

    test('ServiceBrandContext correctly evaluates isPlanExpired and isPlanExpiredOrToday', () {
      Get.reset();
      final brandContext = Get.put(ServiceBrandContext());

      final tomorrow = DateTime(now.year, now.month, now.day + 1);
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

    test('ServiceBrandContext blocks only when plan is truly expired (past expiry date)', () {
      Get.reset();
      final brandContext = Get.put(ServiceBrandContext());

      final pastDate = DateTime(now.year, now.month, now.day - 2);
      final branchWithExpiredPlan = ModelBranch(
        branchCode: 'D-Mart-02',
        name: const BranchName(en: 'D-Mart Solapur'),
        address: const BranchAddress(full: 'Solapur'),
        contact: const BranchContact(phones: BranchPhones(primary: '1234567890'), email: 'test@dmart.com'),
        brandId: 'brand123',
        planDetails: BranchPlanDetails(
          expiryAt: pastDate.millisecondsSinceEpoch,
          note: 'Expired plan',
        ),
      );

      brandContext.selectBranch(branchWithExpiredPlan);

      expect(brandContext.isPlanExpired, isTrue, reason: 'Must report true when plan expired 2 days ago');
      expect(brandContext.isPlanExpiredOrToday, isTrue);
    });

    test('Parses various date and timestamp formats accurately', () {
      // 1. ISO date string
      const isoPlan = BranchPlanDetails(expiryAt: '2026-10-03');
      expect(isoPlan.expiryDate?.year, equals(2026));
      expect(isoPlan.expiryDate?.month, equals(10));
      expect(isoPlan.expiryDate?.day, equals(3));

      // 2. UTC ISO timestamp string
      const utcPlan = BranchPlanDetails(expiryAt: '2026-10-03T00:00:00.000Z');
      expect(utcPlan.expiryDate, isNotNull);

      // 3. String numeric epoch timestamp
      const strEpochPlan = BranchPlanDetails(expiryAt: '1790985600000');
      expect(strEpochPlan.expiryDate, isNotNull);

      // 4. num / int epoch timestamp
      const intEpochPlan = BranchPlanDetails(expiryAt: 1790985600000);
      expect(intEpochPlan.expiryDate, isNotNull);
    });
  });
}
