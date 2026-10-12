import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:super_market/model/entity_bill.dart';
import 'package:super_market/model/entity_quotation.dart';
import 'package:super_market/model/entity_sales_return.dart';
import 'package:super_market/objectbox.g.dart';
import 'package:super_market/screens/sales/invoice/activity_create_sales_invoice.dart';
import 'package:super_market/screens/sales/quotation/activity_create_quotation.dart';
import 'package:super_market/screens/sales/returns/activity_create_sales_return.dart';
import 'package:super_market/service/service_currency.dart';
import 'package:super_market/service/service_object_box.dart';

class MockServiceObjectBox extends ServiceObjectBox {
  final Store mockStore;
  MockServiceObjectBox(this.mockStore);

  @override
  Store get store => mockStore;

  @override
  Box<T> box<T>() => mockStore.box<T>();
}

void main() {
  late Store store;
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('test_sales_');
    store = Store(getObjectBoxModel(), directory: tempDir.path);

    final ob = MockServiceObjectBox(store);
    Get.put<ServiceObjectBox>(ob);

    final curr = ServiceCurrency();
    Get.put<ServiceCurrency>(curr);
  });

  tearDownAll(() async {
    store.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Test ActivityCreateSalesInvoice with editingBill (CASH)', (tester) async {
    final billBox = store.box<EntityBill>();
    final bill = EntityBill(
      billNo: 'INV-100',
      billDate: '12/10/2026',
      customerName: 'Test Customer',
      customerPhone: '1234567890',
      grandTotal: 100.0,
      paymentMode: 'CASH', // Upper case as saved by ControllerCreateSalesInvoice!
      status: 'PAID',
    );
    billBox.put(bill);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: ActivityCreateSalesInvoice(editingBill: bill),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActivityCreateSalesInvoice), findsOneWidget);
  });

  testWidgets('Test ActivityCreateQuotation with editingQuotation', (tester) async {
    final quoteBox = store.box<EntityQuotation>();
    final quote = EntityQuotation(
      quotationNo: 'KI/26-27/1',
      quotationDate: '12/10/2026',
      customerName: 'Test Customer',
      grandTotal: 150.0,
      status: 'Open',
    );
    quoteBox.put(quote);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: ActivityCreateQuotation(editingQuotation: quote),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActivityCreateQuotation), findsOneWidget);
  });

  testWidgets('Test ActivityCreateSalesReturn with editingReturn (CASH)', (tester) async {
    final retBox = store.box<EntitySalesReturn>();
    final ret = EntitySalesReturn(
      returnNo: 'RET-100',
      returnDate: '12/10/2026',
      customerName: 'Test Customer',
      refundAmount: 50.0,
      paymentMode: 'CASH',
      status: 'Completed',
    );
    retBox.put(ret);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: ActivityCreateSalesReturn(editingReturn: ret),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActivityCreateSalesReturn), findsOneWidget);
  });
}
