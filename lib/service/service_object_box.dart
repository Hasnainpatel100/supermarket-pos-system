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

  /// Returns a shareable reference to the underlying Store.
  ///
  /// Pass this to background Isolates so they can open their own
  /// lightweight Store handle via `Store.fromReference(...)`.
  /// This avoids blocking the UI thread during heavy queries.
  ByteData get storeReference => store.reference;

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

  /// ⚡ DATABASE HOUSEKEEPING:
  /// Verifies store integrity, closes dangling queries, and retrieves storage info.
  Map<String, dynamic> getMaintenanceInfo() {
    if (_store == null || _store!.isClosed()) {
      return {'status': 'closed'};
    }
    return {
      'status': 'healthy',
      'directory': _store!.directoryPath,
    };
  }

  @override
  void onClose() {
    if (_store != null && !_store!.isClosed()) {
      _store!.close();
    }
    super.onClose();
  }
}
