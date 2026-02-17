import 'package:get/get.dart';

import 'service_storage.dart';

class ServiceCurrency {
  late ServiceStorage _storage;
  static const _key = 'cu';

  final RxString rxCurrency = '₹'.obs;

  ServiceCurrency onInit({required ServiceStorage storage}) {
    _storage = storage;
    final currency = _storage.readString(_key) ?? '₹';
    rxCurrency.value = currency;
    return this;
  }

  Future<void> update(String value) async {
    await _storage.writeString(_key, value);
    rxCurrency.value = value;
  }
}
