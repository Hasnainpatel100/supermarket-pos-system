import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/objectbox.g.dart';
import 'package:super_market/model/entity_bill.dart';
import 'package:super_market/model/entity_bill_item.dart';
import 'package:super_market/model/entity_sale.dart';
import 'package:super_market/model/entity_purchase.dart';

void main() {
  test('Check bills and sales', () {
    final dir = Directory('market_backup_safety_check');
    final store = Store(getObjectBoxModel(), directory: dir.path);

    final billBox = store.box<EntityBill>();
    final billItemBox = store.box<EntityBillItem>();
    final saleBox = store.box<EntitySale>();
    final purchaseBox = store.box<EntityPurchase>();

    print('Total bills: ${billBox.count()}');
    print('Total bill items: ${billItemBox.count()}');
    print('Total sales: ${saleBox.count()}');
    print('Total purchases: ${purchaseBox.count()}');

    store.close();
  });
}
