import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';

class ServiceObjectBox extends GetxService {
  late Store store;

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

  /// Re-opens the ObjectBox store after a restore.
  ///
  /// Call this after the database files on disk have been replaced.
  /// Closes the old store (if still open) and opens a fresh one.
  Future<void> reopen() async {
    if (!store.isClosed()) {
      store.close();
    }

    if (kDebugMode) {
      store = Store(
        getObjectBoxModel(),
        directory: "market",
      );
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      store = Store(
        getObjectBoxModel(),
        directory: '${appSupportDir.path}/market',
      );
    }
  }

  Box<T> box<T>() => store.box<T>();

  @override
  void onClose() {
    if (!store.isClosed()) {
      store.close();
    }
    super.onClose();
  }
}
