import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/model/entity_day_session.dart';
import 'package:super_market/model/entity_drawer_movement.dart';
import 'package:super_market/model/entity_shift_session.dart';

void main() {
  group('Cash Drawer & Denomination Calculations', () {
    test('Denomination cash total calculation', () {
      final denominations = {
        2000: 1, // 2000
        1000: 1, // 1000
        500: 2,  // 1000
        200: 5,  // 1000
        100: 10, // 1000
        50: 0,
        20: 0,
        10: 0,
      };

      double total = 0;
      for (var entry in denominations.entries) {
        total += entry.key * entry.value;
      }

      expect(total, 6000.0);
    });

    test('Closing Balance calculation formula matches UI specs', () {
      const openingBalance = 7000.0;
      const cashIn = 1000.0;
      const salesCash = 811.50;
      const cashOut = 2000.0;
      const expenses = 0.0;

      // Formula: Opening + CashIn + Sales - CashOut - Expenses
      final closingBalance =
          openingBalance + cashIn + salesCash - cashOut - expenses;

      expect(closingBalance, 6811.50);
    });

    test('Denominations map serialize and deserialize JSON correctly', () {
      final denominations = {2000: 1, 1000: 1, 500: 0};
      final jsonStr = jsonEncode(
        denominations.map((k, v) => MapEntry(k.toString(), v)),
      );

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['2000'], 1);
      expect(decoded['1000'], 1);
      expect(decoded['500'], 0);
    });
  });

  group('Day & Shift Session Entities', () {
    test('Day Session lifecycle and properties', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final day = EntityDaySession(
        startTimestampMs: now,
        isOpen: true,
        openingCash: 3000.0,
        startedByUsername: 'Hasnain',
        openingComment: 'Morning shift opening',
      );

      expect(day.isOpen, isTrue);
      expect(day.openingCash, 3000.0);
      expect(day.startedByUsername, 'Hasnain');

      // Close day
      day.isOpen = false;
      day.endTimestampMs = now + 3600000;
      day.closingCash = 6811.50;
      day.closedByUsername = 'Hasnain';

      expect(day.isOpen, isFalse);
      expect(day.closingCash, 6811.50);
    });

    test('Shift Session lifecycle and order metrics', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final shift = EntityShiftSession(
        daySessionId: 1,
        startTimestampMs: now,
        isOpen: true,
        openingCash: 3000.0,
        cashIn: 1000.0,
        cashOut: 500.0,
        salesCash: 2500.0,
        expensesCash: 200.0,
        fulfilledOrders: 15,
        cancelledOrders: 1,
        complimentaryOrders: 0,
      );

      expect(shift.isOpen, isTrue);
      expect(shift.fulfilledOrders, 15);
      expect(shift.cancelledOrders, 1);

      // Verify net cash in drawer for shift
      final calculatedDrawer = shift.openingCash +
          shift.cashIn +
          shift.salesCash -
          shift.cashOut -
          shift.expensesCash;
      expect(calculatedDrawer, 5800.0);
    });

    test('Drawer Movement records Cash In and Cash Out', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cashIn = EntityDrawerMovement(
        shiftSessionId: 1,
        daySessionId: 1,
        type: 'CASH_IN',
        amount: 500.0,
        reason: 'Added float change',
        timestampMs: now,
      );

      final cashOut = EntityDrawerMovement(
        shiftSessionId: 1,
        daySessionId: 1,
        type: 'CASH_OUT',
        amount: 200.0,
        reason: 'Fuel expense',
        timestampMs: now + 1000,
      );

      expect(cashIn.type, 'CASH_IN');
      expect(cashIn.amount, 500.0);
      expect(cashOut.type, 'CASH_OUT');
      expect(cashOut.amount, 200.0);
    });
  });
}
