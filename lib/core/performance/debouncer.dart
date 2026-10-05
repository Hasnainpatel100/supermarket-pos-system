import 'dart:async';

/// Reusable debouncer utility.
///
/// Usage:
/// ```dart
/// final _debouncer = Debouncer(milliseconds: 300);
///
/// void onSearchChanged(String query) {
///   _debouncer.run(() => performSearch(query));
/// }
///
/// @override
/// void onClose() {
///   _debouncer.dispose();
///   super.onClose();
/// }
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Cancels any pending invocation and schedules [action] to run
  /// after [milliseconds] of inactivity.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Returns true if a debounced call is currently pending.
  bool get isActive => _timer?.isActive ?? false;

  /// Cancels any pending call and releases the timer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
