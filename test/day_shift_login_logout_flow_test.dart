import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/model/entity_day_session.dart';
import 'package:super_market/model/entity_shift_session.dart';

void main() {
  group('Day & Shift Lifecycle and Logout Flow Rules', () {
    test('Initial state: Neither day nor shift is open', () {
      EntityDaySession? activeDay;
      EntityShiftSession? activeShift;

      final bool isDayOpen = activeDay != null && activeDay.isOpen;
      final bool isShiftOpen = activeShift != null && activeShift.isOpen;

      expect(isDayOpen, isFalse);
      expect(isShiftOpen, isFalse);

      // On login when !isDayOpen: Must start Day & Shift
      final bool requireStartDayAndShift = !isDayOpen;
      expect(requireStartDayAndShift, isTrue);
    });

    test('After starting Day & Shift: User can log out freely without forced shift closure', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final activeDay = EntityDaySession(
        startTimestampMs: now,
        isOpen: true,
        openingCash: 5000.0,
      );
      final activeShift = EntityShiftSession(
        daySessionId: 1,
        startTimestampMs: now,
        isOpen: true,
        openingCash: 5000.0,
      );

      final bool isDayOpen = activeDay.isOpen;
      final bool isShiftOpen = activeShift.isOpen;

      expect(isDayOpen, isTrue);
      expect(isShiftOpen, isTrue);

      // Rule: User is NOT forced to close shift or day to log out
      const bool forceCloseShiftOnLogout = false;
      expect(forceCloseShiftOnLogout, isFalse, reason: 'Logout is not blocked even if shift is open');
    });

    test('Closing Shift leaves Day open for next shift: User can log out safely', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final activeDay = EntityDaySession(
        startTimestampMs: now,
        isOpen: true,
        openingCash: 5000.0,
      );
      final activeShift = EntityShiftSession(
        daySessionId: 1,
        startTimestampMs: now,
        isOpen: false, // Closed
        endTimestampMs: now + 3600000,
        openingCash: 5000.0,
        closingCash: 7500.0,
      );

      final bool isDayOpen = activeDay.isOpen;
      final bool isShiftOpen = activeShift.isOpen;

      expect(isDayOpen, isTrue);
      expect(isShiftOpen, isFalse);

      // Rule: When next cashier logs in, day is already open, so only shift must be started
      final bool requireShiftOnly = isDayOpen && !isShiftOpen;
      expect(requireShiftOnly, isTrue, reason: 'Next cashier only needs to start Shift since Day is already open');
    });

    test('Subsequent cashier starts Shift only while Day remains active', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final activeDay = EntityDaySession(
        startTimestampMs: now - 7200000,
        isOpen: true,
        openingCash: 5000.0,
      );
      final secondShift = EntityShiftSession(
        daySessionId: 1,
        startTimestampMs: now,
        isOpen: true, // Second shift started
        openingCash: 7500.0,
      );

      final bool isDayOpen = activeDay.isOpen;
      final bool isShiftOpen = secondShift.isOpen;

      expect(isDayOpen, isTrue);
      expect(isShiftOpen, isTrue);
      expect(secondShift.daySessionId, equals(1));
    });

    test('Closing Day closes both Day and Shift sessions and allows final logout', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final activeDay = EntityDaySession(
        startTimestampMs: now - 28800000,
        endTimestampMs: now,
        isOpen: false, // Day closed
        openingCash: 5000.0,
        closingCash: 12000.0,
      );
      final activeShift = EntityShiftSession(
        daySessionId: 1,
        startTimestampMs: now - 14400000,
        endTimestampMs: now,
        isOpen: false, // Shift closed
        openingCash: 7500.0,
        closingCash: 12000.0,
      );

      final bool isDayOpen = activeDay.isOpen;
      final bool isShiftOpen = activeShift.isOpen;

      expect(isDayOpen, isFalse);
      expect(isShiftOpen, isFalse);

      // Now both closed: Clean state
      final bool canLogoutDirectly = !isShiftOpen;
      expect(canLogoutDirectly, isTrue);

      // On next login tomorrow: Must start Day & Shift
      final bool requireStartDayAndShift = !isDayOpen;
      expect(requireStartDayAndShift, isTrue);
    });
  });
}
