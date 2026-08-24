import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';

class ServiceObjectBox extends GetxService {
  Store? _store;

  Store get store {
    if (_store == null || _store!.isClosed()) {
      throw StateError('ServiceObjectBox Store is not initialized or has been closed.');
    }
    return _store!;
  }

  Future<ServiceObjectBox> init() async {
    if (_store != null && !_store!.isClosed()) {
      return this;
    }

    if (kDebugMode) {
      _store = Store(
        getObjectBoxModel(),
        directory: "market", // db name
      );
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      _store = Store(
        getObjectBoxModel(),
        directory: '${appSupportDir.path}/market',
      );
    }
    return this;
  }

  /// Re-opens the ObjectBox store after a restore or logout reset.
  Future<void> reopen() async {
    if (_store != null && !_store!.isClosed()) {
      _store!.close();
    }

    if (kDebugMode) {
      _store = Store(
        getObjectBoxModel(),
        directory: "market",
      );
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      _store = Store(
        getObjectBoxModel(),
        directory: '${appSupportDir.path}/market',
      );
    }
  }

  Box<T> box<T>() => store.box<T>();

  @override
  void onClose() {
    if (_store != null && !_store!.isClosed()) {
      _store!.close();
    }
    super.onClose();
  }
}
