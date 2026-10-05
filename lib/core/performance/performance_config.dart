/// Central performance configuration for the POS application.
///
/// All tunable constants live here so that optimizing the app
/// only requires changing one file. Every module imports from here
/// instead of defining its own magic numbers.
class PerfConfig {
  PerfConfig._(); // non-instantiable

  // ── Debounce ───────────────────────────────────────────────────────────────

  /// Default debounce duration for search inputs (ms).
  /// 300 ms is the sweet-spot: fast enough to feel instant,
  /// slow enough to avoid hammering ObjectBox on every keystroke.
  static const int searchDebounceMs = 300;

  /// Debounce for barcode scanner input.
  /// USB HID barcode guns emit rapid keystrokes — debounce avoids
  /// partial-barcode queries.
  static const int barcodeDebounceMs = 150;

  // ── Pagination ─────────────────────────────────────────────────────────────

  /// Default page size for all list views (items, customers, suppliers, etc.).
  static const int defaultPageSize = 20;

  /// Page size for audit log views.
  static const int auditLogPageSize = 50;

  /// Page size for report tables.
  static const int reportPageSize = 50;

  // ── Query limits ───────────────────────────────────────────────────────────

  /// Maximum results returned by a search query before warning the user.
  static const int maxSearchResults = 500;

  /// Maximum number of recent audit log entries to fetch.
  static const int maxRecentAuditLogs = 200;

  // ── Timer / Scheduler ──────────────────────────────────────────────────────

  /// How many minutes between each scheduled plan-expiry check (fallback).
  /// The primary mechanism is a one-shot timer that fires at the exact
  /// expiry moment; this is only a safety net.
  static const int expiryFallbackCheckMinutes = 30;

  // ── Isolate thresholds ─────────────────────────────────────────────────────

  /// When a list/JSON payload has more than this many items, offload the
  /// processing to an Isolate so the main thread stays at 60 FPS.
  static const int isolateThreshold = 500;

  /// Maximum number of items to bulk-insert in a single ObjectBox
  /// transaction before yielding back to the event loop.
  static const int bulkBatchSize = 200;
}
