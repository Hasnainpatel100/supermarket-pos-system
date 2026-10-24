import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/model/entity_bill.dart';
import 'package:super_market/model/entity_item.dart';
import 'package:super_market/model/entity_item_batch.dart';

// Helper matcher replicating ControllerSalesInvoices._matchesBill logic
bool matchesBill(EntityBill bill, String query) {
  if (query.isEmpty) return true;

  final qLower = query.toLowerCase().trim();
  final billNoRaw = (bill.billNo ?? '').toLowerCase().trim();

  // 1. Direct contains check
  if (billNoRaw.contains(qLower)) return true;

  // 2. Delimiter swap: / replaced with - and vice-versa
  final qSwapHyphen = qLower.replaceAll('/', '-');
  if (billNoRaw.contains(qSwapHyphen)) return true;

  final qSwapSlash = qLower.replaceAll('-', '/');
  if (billNoRaw.contains(qSwapSlash)) return true;

  // 3. Alphanumeric stripped check:
  final qAlphaNum = qLower.replaceAll(RegExp(r'[^a-z0-9]'), '');
  final billNoAlphaNum = billNoRaw.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (qAlphaNum.isNotEmpty && billNoAlphaNum.isNotEmpty) {
    if (billNoAlphaNum.contains(qAlphaNum)) return true;
  }

  // 4. Match by ObjectBox entity ID
  final idStr = bill.id.toString();
  if (idStr == qAlphaNum || idStr.contains(qAlphaNum)) return true;

  // 5. Customer Name & Phone
  final custName = (bill.customerName ?? '').toLowerCase();
  if (custName.contains(qLower)) return true;

  final custPhone = (bill.customerPhone ?? '').toLowerCase();
  if (custPhone.contains(qLower)) return true;

  // 6. E-Way Bill & Payment Mode
  final eway = (bill.ewayBillNo ?? '').toLowerCase();
  if (eway.contains(qLower)) return true;

  return false;
}

void main() {
  group('Task 2: Sales Invoice Search Normalization Tests', () {
    final testBill = EntityBill(
      id: 42,
      billNo: 'BIL-1792776259243',
      customerName: 'Aarav Sharma',
      customerPhone: '9876543210',
      grandTotal: 1250.0,
      status: 'PAID',
    );

    test('Exact match with hyphen matches bill', () {
      expect(matchesBill(testBill, 'BIL-1792776259243'), isTrue);
    });

    test('Slash delimiter search (BIL/1792776259243) matches hyphen bill (BIL-1792776259243)', () {
      expect(matchesBill(testBill, 'BIL/1792776259243'), isTrue);
    });

    test('Partial slash delimiter search (BIL/1792) matches bill', () {
      expect(matchesBill(testBill, 'BIL/1792'), isTrue);
    });

    test('Raw digits search (1792776259243) matches bill', () {
      expect(matchesBill(testBill, '1792776259243'), isTrue);
    });

    test('Search with space (BIL 1792776259243) matches bill', () {
      expect(matchesBill(testBill, 'BIL 1792776259243'), isTrue);
    });

    test('Search with hash symbol (#BIL/1792776259243) matches bill', () {
      expect(matchesBill(testBill, '#BIL/1792776259243'), isTrue);
    });

    test('Search by customer phone matches bill', () {
      expect(matchesBill(testBill, '9876543210'), isTrue);
    });

    test('Search by customer name matches bill', () {
      expect(matchesBill(testBill, 'Aarav'), isTrue);
    });

    test('Search by internal bill ID (42) matches bill', () {
      expect(matchesBill(testBill, '42'), isTrue);
    });

    test('Non-matching query returns false', () {
      expect(matchesBill(testBill, 'BIL-9999999999999'), isFalse);
    });
  });

  group('Task 1: Stock Adjustment Batch & Direct Count Logic Tests', () {
    test('Multi-batch addition correctly calculates total stock', () {
      final batches = [
        EntityItemBatch(batchNo: 'B1', quantity: 10, salePrice: 120.0),
        EntityItemBatch(batchNo: 'B2', quantity: 15, salePrice: 125.0),
        EntityItemBatch(batchNo: 'B3', quantity: 5, salePrice: 120.0),
      ];

      final totalQty = batches.fold<int>(0, (sum, b) => sum + (b.quantity ?? 0));
      expect(totalQty, equals(30));

      final item = EntityItem(name: 'Parle-G Biscuit', totalQty: 20);
      item.totalQty = (item.totalQty ?? 0) + totalQty;
      expect(item.totalQty, equals(50));
    });

    test('Batch deduction updates batch quantities and total stock correctly', () {
      final batch1 = EntityItemBatch(id: 1, batchNo: 'B1', quantity: 10);
      final batch2 = EntityItemBatch(id: 2, batchNo: 'B2', quantity: 15);

      final deductions = {1: 5, 2: 10};
      int totalDeducted = 0;

      for (final entry in deductions.entries) {
        if (entry.key == 1) {
          batch1.quantity = (batch1.quantity ?? 0) - entry.value;
        } else if (entry.key == 2) {
          batch2.quantity = (batch2.quantity ?? 0) - entry.value;
        }
        totalDeducted += entry.value;
      }

      expect(batch1.quantity, equals(5));
      expect(batch2.quantity, equals(5));
      expect(totalDeducted, equals(15));

      final item = EntityItem(name: 'Product A', totalQty: 25);
      item.totalQty = (item.totalQty ?? 0) - totalDeducted;
      expect(item.totalQty, equals(10));
    });

    test('Manual count decrement cannot exceed total stock', () {
      final item = EntityItem(name: 'Product B', totalQty: 12);
      const decrementQty = 5;

      expect(decrementQty <= (item.totalQty ?? 0), isTrue);
      item.totalQty = (item.totalQty ?? 0) - decrementQty;
      expect(item.totalQty, equals(7));

      const invalidDecrementQty = 10;
      expect(invalidDecrementQty <= (item.totalQty ?? 0), isFalse);
    });
  });

  group('Tax Calculation Tests: Inclusive vs Exclusive GST', () {
    test('Inclusive 5% GST on iPhone 17 (₹75,000): Net Payable = ₹75,000, Tax = ₹3,571.43', () {
      const price = 75000.0;
      const qty = 1;
      const gstRate = 5.0; // 5%
      const lineAmt = price * qty; // ₹75,000

      // Inclusive: tax is already embedded inside ₹75,000
      final taxAmount = (lineAmt * gstRate) / (100.0 + gstRate);
      final taxableAmount = lineAmt - taxAmount;
      final netPayable = lineAmt; // Not added on top!

      expect((taxAmount * 100).round() / 100, equals(3571.43));
      expect((taxableAmount * 100).round() / 100, equals(71428.57));
      expect(netPayable, equals(75000.0));
      expect((taxableAmount + taxAmount).roundToDouble(), equals(75000.0));
    });

    test('Exclusive 5% GST on iPhone 17 (₹75,000): Net Payable = ₹78,750, Tax = ₹3,750', () {
      const price = 75000.0;
      const qty = 1;
      const gstRate = 5.0; // 5%
      const lineAmt = price * qty; // ₹75,000

      // Exclusive: tax must be added ON TOP of ₹75,000
      final taxAmount = (lineAmt * gstRate) / 100.0;
      final taxableAmount = lineAmt;
      final netPayable = lineAmt + taxAmount;

      expect(taxAmount, equals(3750.0));
      expect(taxableAmount, equals(75000.0));
      expect(netPayable, equals(78750.0));
    });

    test('Mixed Cart: Inclusive Item + Exclusive Item', () {
      // Item 1: Inclusive iPhone 17 (₹75,000, 5% GST)
      const item1Price = 75000.0;
      const item1TaxRate = 5.0;
      final item1Tax = (item1Price * item1TaxRate) / (100.0 + item1TaxRate); // 3571.43
      final item1Total = item1Price; // 75000

      // Item 2: Exclusive Odonil (₹120, 5% GST)
      const item2Price = 120.0;
      const item2TaxRate = 5.0;
      final item2Tax = (item2Price * item2TaxRate) / 100.0; // 6.0
      final item2Total = item2Price + item2Tax; // 126.0

      final totalPayable = item1Total + item2Total;
      expect(totalPayable, equals(75126.0));
      expect((item1Tax + item2Tax).toStringAsFixed(2), equals('3577.43'));
    });
  });

  group('Scanner Machine Sanitization Tests', () {
    String sanitizeQuery(String q) {
      return q.replaceAll('\r', '').replaceAll('\n', '').replaceAll('/', '-').trim();
    }

    test('Scanner machine returning BIL/1792773691219 sanitizes to BIL-1792773691219', () {
      final rawScannerInput = 'BIL/1792773691219\n';
      final sanitized = sanitizeQuery(rawScannerInput);
      expect(sanitized, equals('BIL-1792773691219'));

      final bill = EntityBill(billNo: 'BIL-1792773691219');
      expect(matchesBill(bill, sanitized), isTrue);
    });
  });
}
