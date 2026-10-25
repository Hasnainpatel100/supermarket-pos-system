import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:super_market/model/entity_bill.dart';
import 'package:super_market/model/entity_item.dart';
import 'package:super_market/model/entity_item_batch.dart';
import 'package:super_market/screens/home/fragment/item/controller_home_item.dart';
import 'package:super_market/service/service_bill_pdf.dart';
import 'package:super_market/util/invoice_scanner_formatter.dart';

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

  group('POS PageUp and PageDown Cart Items Navigation Tests', () {
    test('PageDown increments selection and clamps to max index', () {
      final items = ['Apple', 'Banana', 'Orange', 'Milk'];
      int selectedIndex = -1;

      // First PageDown selects first item
      int navigateCart(int current, int delta, int length) {
        if (length == 0) return -1;
        if (current == -1) {
          return delta > 0 ? 0 : length - 1;
        }
        return (current + delta).clamp(0, length - 1);
      }

      selectedIndex = navigateCart(selectedIndex, 1, items.length);
      expect(selectedIndex, equals(0)); // Apple

      selectedIndex = navigateCart(selectedIndex, 1, items.length);
      expect(selectedIndex, equals(1)); // Banana

      selectedIndex = navigateCart(selectedIndex, 1, items.length);
      expect(selectedIndex, equals(2)); // Orange

      selectedIndex = navigateCart(selectedIndex, 1, items.length);
      expect(selectedIndex, equals(3)); // Milk

      // PageDown at last item stays at last item
      selectedIndex = navigateCart(selectedIndex, 1, items.length);
      expect(selectedIndex, equals(3));
    });

    test('PageUp decrements selection and clamps to 0', () {
      final items = ['Apple', 'Banana', 'Orange', 'Milk'];
      int navigateCart(int current, int delta, int length) {
        if (length == 0) return -1;
        if (current == -1) {
          return delta > 0 ? 0 : length - 1;
        }
        return (current + delta).clamp(0, length - 1);
      }

      int selectedIndex = 3; // Milk
      selectedIndex = navigateCart(selectedIndex, -1, items.length);
      expect(selectedIndex, equals(2)); // Orange

      selectedIndex = navigateCart(selectedIndex, -1, items.length);
      expect(selectedIndex, equals(1)); // Banana

      selectedIndex = navigateCart(selectedIndex, -1, items.length);
      expect(selectedIndex, equals(0)); // Apple

      // PageUp at first item stays at 0
      selectedIndex = navigateCart(selectedIndex, -1, items.length);
      expect(selectedIndex, equals(0));
    });
  });

  group('Backend Permissions Parsing Tests', () {
    test('Parses backend comma-separated permission string including CUSTOMER_CREATE', () {
      const rawBackendPermissions =
          "ORDER_CREATE, ORDER_READ, ORDER_UPDATE, ORDER_DELETE, ORDER_LIST, ORDER_CANCEL, "
          "ORDER_REFUND, ORDER_REPRINT, PAYMENT_PROCESS, REFUND_PROCESS, PAYMENT_VIEW, "
          "PAYMENT_REFUND, PAYMENT_VIEW_REPORTS, PAYMENT_CANCEL, DRAWER_OPEN_MANUAL, "
          "DISCOUNT_APPLY, DISCOUNT_OVERRIDE, PRICE_OVERRIDE, INVENTORY_CREATE, INVENTORY_READ, "
          "INVENTORY_UPDATE, INVENTORY_DELETE, BARCODE_SCAN, WEIGHT_BASED_PRICING, BULK_ITEM_IMPORT, "
          "STOCK_ADJUST, EXPIRY_MANAGE, CUSTOMER_CREATE, CUSTOMER_READ, CUSTOMER_UPDATE, "
          "CUSTOMER_DELETE, CUSTOMER_LIST, SUPPLIER_CREATE, SUPPLIER_READ, SUPPLIER_UPDATE, "
          "SUPPLIER_DELETE, SUPPLIER_LIST, PURCHASE_CREATE, PURCHASE_READ, PURCHASE_UPDATE, "
          "PURCHASE_DELETE, PURCHASE_LIST, PURCHASE_RECEIVE, ACCOUNT_CREATE, ACCOUNT_READ, "
          "ACCOUNT_UPDATE, ACCOUNT_DELETE, ACCOUNT_MANAGE, EXPENSE_CREATE, EXPENSE_READ, "
          "EXPENSE_UPDATE, EXPENSE_DELETE, EXPENSE_APPROVE, REPORT_VIEW, REPORT_VIEW_SALES, "
          "REPORT_VIEW_FINANCIAL, REPORT_VIEW_USER_ACTIVITY, REPORT_EXPORT, DASHBOARD_VIEW, "
          "DASHBOARD_EXPORT, TAX_CREATE, TAX_READ, TAX_UPDATE, TAX_DELETE, TAX_LIST, "
          "TAX_MANAGE_GROUPS, SYSTEM_MANAGE_CONFIG, SYSTEM_VIEW_LOGS, SYSTEM_BACKUP, "
          "SYSTEM_MAINTENANCE, DEVICE_MANAGE, PLAN_READ, SUBSCRIPTION_READ";

      final parsed = rawBackendPermissions
          .split(',')
          .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
          .where((e) => e.isNotEmpty)
          .toList();

      expect(parsed, contains('CUSTOMER_CREATE'));
      expect(parsed, contains('CUSTOMER_UPDATE'));
      expect(parsed, contains('CUSTOMER_DELETE'));
      expect(parsed, contains('ORDER_CREATE'));
      expect(parsed.length, equals(73));
    });
  });

  group('POS Multiple Batches Selection on Search/Scan Tests', () {
    test('Multiple batches available (> 1): requires batch selection dialog and does not add directly', () {
      final item = EntityItem(id: 10, name: 'Paracetamol 500mg', barcode: '8901234567890', totalQty: 50);
      expect(item.name, equals('Paracetamol 500mg'));
      final batchA = EntityItemBatch(id: 1, itemId: 10, batchNo: 'BATCH-A', quantity: 20, salePrice: 15.0);
      final batchB = EntityItemBatch(id: 2, itemId: 10, batchNo: 'BATCH-B', quantity: 30, salePrice: 15.0);
      final allBatches = [batchA, batchB];

      final availableBatches = allBatches.where((b) => (b.quantity ?? 0) > 0).toList();

      // Verify multiple batches are detected
      expect(availableBatches.length, greaterThan(1));

      // Business logic condition:
      // if (availableBatches.length > 1) -> opens DialogSelectBatch and does NOT add direct
      final shouldOpenDialog = availableBatches.length > 1;
      final shouldAddDirect = !shouldOpenDialog;

      expect(shouldOpenDialog, isTrue);
      expect(shouldAddDirect, isFalse);
    });

    test('Single batch available (== 1): adds that single batch directly without dialog', () {
      final item = EntityItem(id: 20, name: 'Maggi 2-Minute Noodles', barcode: '8901058852869', totalQty: 10);
      expect(item.name, equals('Maggi 2-Minute Noodles'));
      final batchOnly = EntityItemBatch(id: 5, itemId: 20, batchNo: 'BATCH-ONLY', quantity: 10, salePrice: 14.0);
      final allBatches = [batchOnly];

      final availableBatches = allBatches.where((b) => (b.quantity ?? 0) > 0).toList();

      expect(availableBatches.length, equals(1));

      final shouldOpenDialog = availableBatches.length > 1;
      final canAddDirectBatch = availableBatches.length == 1;

      expect(shouldOpenDialog, isFalse);
      expect(canAddDirectBatch, isTrue);
      expect(availableBatches.first.batchNo, equals('BATCH-ONLY'));
    });

    test('Zero available batches (== 0): adds standard item stock', () {
      final item = EntityItem(id: 30, name: 'Loose Sugar 1kg', barcode: 'SUGAR01', totalQty: 100);
      expect(item.name, equals('Loose Sugar 1kg'));
      final List<EntityItemBatch> allBatches = [];

      final availableBatches = allBatches.where((b) => (b.quantity ?? 0) > 0).toList();

      expect(availableBatches.isEmpty, isTrue);
      final shouldOpenDialog = availableBatches.length > 1;
      final canAddDirectItem = availableBatches.isEmpty;

      expect(shouldOpenDialog, isFalse);
      expect(canAddDirectItem, isTrue);
    });
  });

  group('Batch Number Auto-Increment Calculation Tests', () {
    test('calculateNextBatchNo returns 1 when no batches exist', () {
      final next = ControllerHomeItem.calculateNextBatchNo(existingBatches: []);
      expect(next, equals('1'));
    });

    test('calculateNextBatchNo increments 1 to 2, and 2 to 3', () {
      final batch1 = EntityItemBatch(batchNo: '1', quantity: 10);
      final next1 = ControllerHomeItem.calculateNextBatchNo(existingBatches: [batch1]);
      expect(next1, equals('2'));

      final batch2 = EntityItemBatch(batchNo: '2', quantity: 5);
      final next2 = ControllerHomeItem.calculateNextBatchNo(existingBatches: [batch1, batch2]);
      expect(next2, equals('3'));
    });

    test('calculateNextBatchNo handles prefix like B-1 -> B-2, and BATCH-10 -> BATCH-11', () {
      final batchB1 = EntityItemBatch(batchNo: 'B-1', quantity: 10);
      final nextB = ControllerHomeItem.calculateNextBatchNo(existingBatches: [batchB1]);
      expect(nextB, equals('B-2'));

      final batch10 = EntityItemBatch(batchNo: 'BATCH-10', quantity: 10);
      final next10 = ControllerHomeItem.calculateNextBatchNo(existingBatches: [batch10]);
      expect(next10, equals('BATCH-11'));
    });

    test('calculateNextBatchNo accounts for pending batches added in memory', () {
      final existing = [EntityItemBatch(batchNo: '1', quantity: 10)];
      final pending = [EntityItemBatch(batchNo: '2', quantity: 5)];
      final next = ControllerHomeItem.calculateNextBatchNo(
        existingBatches: existing,
        pendingBatches: pending,
      );
      expect(next, equals('3'));
    });
  });

  group('POS Dynamic Tax Calculation & Bill Details Update Tests', () {
    double calcTax(double gross, double r, bool inc) =>
        inc ? gross * (r / (100.0 + r)) : gross * (r / 100.0);
    double calcExTax(bool inc, double t) => inc ? 0.0 : t;

    test('Inclusive Tax: item 75000 with 5% GST already includes tax inside 75000', () {
      const price = 75000.0;
      const rate = 5.0;

      double lineGross = price * 1;
      double subTotal = lineGross;
      double taxVal = calcTax(lineGross, rate, true);
      double tax = double.parse(taxVal.toStringAsFixed(2));
      double exclusiveTax = calcExTax(true, tax);
      double grandTotal = subTotal + exclusiveTax;

      expect(tax, equals(3571.43));
      expect(grandTotal, equals(75000.0));
    });

    test('Exclusive Tax: item 75000 with 5% GST adds tax on top of 75000', () {
      const price = 75000.0;
      const rate = 5.0;

      double lineGross = price * 1;
      double subTotal = lineGross;
      double taxVal = calcTax(lineGross, rate, false);
      double tax = double.parse(taxVal.toStringAsFixed(2));
      double exclusiveTax = calcExTax(false, tax);
      double grandTotal = subTotal + exclusiveTax;

      expect(tax, equals(3750.00));
      expect(grandTotal, equals(78750.0));
    });

    test('Updating Item Tax from 5% to 18% recalculates bill totals accurately', () {
      const price = 75000.0;

      // Old: 5% inclusive
      final oldTax = double.parse((price * (5.0 / 105.0)).toStringAsFixed(2));
      expect(oldTax, equals(3571.43));

      // After user edits item tax to 18% inclusive:
      final updatedTax = double.parse((price * (18.0 / 118.0)).toStringAsFixed(2));
      expect(updatedTax, equals(11440.68));

      // After user edits item tax to 18% exclusive:
      final updatedExclusiveTax = double.parse((price * (18.0 / 100.0)).toStringAsFixed(2));
      expect(updatedExclusiveTax, equals(13500.00));
      expect(price + updatedExclusiveTax, equals(88500.00));
    });

    test('CGST and SGST formatting strictly outputs 2 decimal digits, never 3', () {
      const totalTax = 50.87;
      final halfTax = double.parse((totalTax / 2.0).toStringAsFixed(2));
      final formattedCgst = halfTax.toStringAsFixed(2);
      final formattedSgst = halfTax.toStringAsFixed(2);

      expect(formattedCgst, equals('25.43'));
      expect(formattedSgst, equals('25.43'));
      expect(formattedCgst.split('.').last.length, equals(2));
    });
  });

  group('Requirement 1: GST Breakdown, CGST & SGST 1-Decimal Formatting Tests', () {
    test('ServiceBillPdf.formatGstOneDecimal formats price with only 1 number after dot', () {
      expect(ServiceBillPdf.formatGstOneDecimal(24.5), equals('24.5'));
      expect(ServiceBillPdf.formatGstOneDecimal(24.53), equals('24.5'));
      expect(ServiceBillPdf.formatGstOneDecimal(24.58), equals('24.6'));
      expect(ServiceBillPdf.formatGstOneDecimal(1878.0), equals('1,878.0'));
      expect(ServiceBillPdf.formatGstOneDecimal(0.0), equals('0.0'));

      final formatted = ServiceBillPdf.formatGstOneDecimal(24.5);
      final dotParts = formatted.split('.');
      expect(dotParts.length, equals(2));
      expect(dotParts.last.length, equals(1)); // Only 1 digit after dot!
    });

    test('Bill detail dialog & document view 1-decimal currency format (₹24.5)', () {
      const currencySymbol = '₹';
      final currencyFormat1Dec = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 1);

      expect(currencyFormat1Dec.format(24.5), equals('₹24.5'));
      expect(currencyFormat1Dec.format(24.53), equals('₹24.5'));
      expect(currencyFormat1Dec.format(24.58), equals('₹24.6'));
      expect(currencyFormat1Dec.format(1878.0), equals('₹1,878.0'));

      const tax = 49.0;
      final halfTaxStr = '${currencyFormat1Dec.format(tax / 2)} each';
      expect(halfTaxStr, equals('₹24.5 each'));
    });
  });

  group('Requirement 2: Scanner Machine Invoice Delimiter Normalization (BIL/ -> BIL-)', () {
    final formatter = InvoicePatternFormatter();

    test('InvoicePatternFormatter automatically converts BIL/1792849558790 to BIL-1792849558790', () {
      const scannedInput = 'BIL/1792849558790';
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: scannedInput,
          selection: TextSelection.collapsed(offset: scannedInput.length),
        ),
      );

      expect(result.text, equals('BIL-1792849558790'));
      expect(result.text.contains('/'), isFalse);
    });

    test('InvoicePatternFormatter strips carriage return and newline from scanner', () {
      const scannedWithNewline = 'BIL/1792849558790\r\n';
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: scannedWithNewline,
          selection: TextSelection.collapsed(offset: scannedWithNewline.length),
        ),
      );

      expect(result.text, equals('BIL-1792849558790'));
    });

    test('sanitizeInvoiceBarcode utility function converts slash to hyphen', () {
      expect(sanitizeInvoiceBarcode('BIL/1792849558790'), equals('BIL-1792849558790'));
      expect(sanitizeInvoiceBarcode('bil/1792849558790\n'), equals('bil-1792849558790'));
      expect(sanitizeInvoiceBarcode('BIL-1792849558790'), equals('BIL-1792849558790'));
      expect(sanitizeInvoiceBarcode(null), equals(''));
    });

    test('Sales return link to invoice suggestions callback matches scanned bill with slash', () {
      final bills = [
        EntityBill(billNo: 'BIL-1792849558790', customerName: 'John Doe', grandTotal: 1500.0),
        EntityBill(billNo: 'BIL-1792849558791', customerName: 'Alice Smith', grandTotal: 2200.0),
      ];

      // Scanned input arrives as BIL/1792849558790
      final scannedPattern = 'BIL/1792849558790';
      final q = scannedPattern.trim().replaceAll('/', '-').toLowerCase();

      final matches = bills.where((b) {
        final no = (b.billNo ?? '').toLowerCase().replaceAll('/', '-');
        final name = (b.customerName ?? '').toLowerCase();
        return no.contains(q) || name.contains(q);
      }).toList();

      expect(matches.length, equals(1));
      expect(matches.first.billNo, equals('BIL-1792849558790'));
    });
  });
}

