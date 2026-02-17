import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';

class ServiceObjectBox extends GetxService {
  late final Store store;

  Future<ServiceObjectBox> init() async {
    if (kDebugMode) {
      store = Store(
        getObjectBoxModel(),
        directory: "market", // db name
      );
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      store = Store(
        getObjectBoxModel(),
        directory: '${appSupportDir.path}/market',
      );
    }
    return this;
  }

  Box<T> box<T>() => store.box<T>();

  @override
  void onClose() {
    store.close();
    super.onClose();
  }
}
