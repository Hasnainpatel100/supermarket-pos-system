import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Helper utilities for running heavy work off the main (UI) thread.
///
/// ## Why not just `compute()`?
/// `compute()` is fine for simple functions but has two limitations:
/// 1. It creates a **new** Isolate every call — there is ~2-5 ms of overhead.
/// 2. Flutter's `compute` does not support sending a `Store.reference` directly.
///
/// For most POS use-cases the built-in `Isolate.run()` (Dart 2.19+) or
/// `compute()` is sufficient because:
/// - Excel parsing, PDF generation, report calculations happen at most
///   once per user gesture (not 60 fps).
/// - The overhead is negligible compared to the 50-300 ms of actual work.
///
/// ## ObjectBox in Isolates
/// ObjectBox C-library is **not** fork-safe, but you can share a
/// `Store.reference` with a new Isolate that opens its own `Store` handle.
/// See [IsolateObjectBox] for a convenience wrapper.
///
/// ## Usage
/// ```dart
/// final result = await IsolateHelper.run(() {
///   // heavy synchronous computation here
///   return expensiveCalculation(data);
/// });
/// ```
class IsolateHelper {
  IsolateHelper._();

  /// Runs [computation] in a background Isolate and returns the result.
  ///
  /// - For payloads **below** the isolate threshold (< 500 items),
  ///   consider running inline to avoid the ~2 ms Isolate spawn cost.
  /// - The [computation] callback must be a **top-level** or **static**
  ///   function — closures that capture controller state will fail.
  ///
  /// Falls back to synchronous execution on web or if Isolate.run
  /// is unavailable.
  static Future<R> run<R>(R Function() computation) async {
    try {
      return await Isolate.run(computation);
    } catch (e) {
      // Fallback: run on main thread (e.g. web or isolate unsupported)
      debugPrint('[IsolateHelper] Fallback to main thread: $e');
      return computation();
    }
  }

  /// Runs [callback] with [message] in a background Isolate.
  ///
  /// This is the equivalent of Flutter's `compute()` but with
  /// explicit error handling and debug logging.
  static Future<R> runWithMessage<M, R>(
    R Function(M) callback,
    M message,
  ) async {
    try {
      return await compute(callback, message);
    } catch (e) {
      debugPrint('[IsolateHelper] Fallback to main thread: $e');
      return callback(message);
    }
  }
}
