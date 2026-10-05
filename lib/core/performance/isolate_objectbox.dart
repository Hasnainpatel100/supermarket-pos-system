import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../objectbox.g.dart';

/// Provides a way to run heavy ObjectBox queries in a background Isolate
/// so the UI thread stays at 60 FPS.
///
/// ## How it works
/// ObjectBox's C-library Store is **not** fork-safe, but it supports
/// sharing via `Store.reference`. A new Isolate receives this reference,
/// opens its own lightweight Store handle, runs the query, closes the
/// handle, and returns the result.
///
/// ## Usage
/// ```dart
/// // In your controller / service:
/// final store = Get.find<ServiceObjectBox>().store;
///
/// final results = await IsolateObjectBox.query<EntityItem>(
///   storeRef: store.reference,
///   work: (store) {
///     final box = store.box<EntityItem>();
///     return box.query(EntityItem_.isActive.equals(true))
///         .order(EntityItem_.name)
///         .build()
///         .find();
///   },
/// );
/// ```
///
/// ## Constraints
/// - The [work] callback must be a **top-level** or **static** function.
///   Instance methods and closures that capture `this` will fail because
///   they cannot be sent across Isolate boundaries.
/// - Return types must be serializable (plain Dart objects, Lists, Maps,
///   entity classes — but NOT `Box`, `Query`, or `Store` handles).
/// - ObjectBox entity classes are fine because they are simple data classes
///   with no C-pointers.
class IsolateObjectBox {
  IsolateObjectBox._();

  /// Runs [work] in a background Isolate with its own Store handle.
  ///
  /// - [storeRef] — obtain via `store.reference` on the main thread.
  /// - [work]     — top-level or static function that receives a fresh Store.
  ///
  /// The background Store is automatically closed after [work] completes.
  static Future<R> query<R>({
    required ByteData storeRef,
    required R Function(Store store) work,
  }) async {
    try {
      return await Isolate.run(() {
        final bgStore = Store.fromReference(getObjectBoxModel(), storeRef);
        try {
          return work(bgStore);
        } finally {
          bgStore.close();
        }
      });
    } catch (e) {
      // Fallback: run on main thread if isolate fails
      // (e.g. web platform, or Store.fromReference not supported)
      debugPrint('[IsolateObjectBox] Fallback to main thread: $e');
      // We need a Store on the main thread — caller should handle this
      rethrow;
    }
  }

  /// Convenience: runs a bulk insert/update in a background Isolate.
  ///
  /// Accepts a list of entities and a [putAll] function that receives
  /// the Store and the entity list.
  static Future<List<int>> bulkPut<T>({
    required ByteData storeRef,
    required List<T> entities,
    required List<int> Function(Store store, List<T> items) putAll,
  }) async {
    try {
      return await Isolate.run(() {
        final bgStore = Store.fromReference(getObjectBoxModel(), storeRef);
        try {
          return putAll(bgStore, entities);
        } finally {
          bgStore.close();
        }
      });
    } catch (e) {
      debugPrint('[IsolateObjectBox] bulkPut fallback: $e');
      rethrow;
    }
  }
}
