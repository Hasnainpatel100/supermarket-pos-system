import '../enums/enum_audit_action.dart';
import '../enums/enum_audit_module.dart';
import '../model/entity_audit_log.dart';
import '../objectbox.g.dart';
import '../service/service_object_box.dart';

/// Repository for the append-only [EntityAuditLog] store.
///
/// **Contract**: Entries must never be updated or deleted after insertion.
/// All write methods only expose `put`-style operations; no delete or
/// update helpers are provided intentionally.
///
/// ## Usage
/// ```dart
/// final repo = RepoAuditLog(Get.find<ServiceObjectBox>());
///
/// repo.log(
///   EntityAuditLog.create(
///     userId: 1,
///     userName: 'Ali Hassan',
///     module: AuditModule.system,
///     action: AuditAction.update,
///     entityType: 'EntityUser',
///     entityId: '3',
///     description: 'Changed user role from CASHIER to MANAGER.',
///     oldData: '{"role":"CASHIER"}',
///     newData: '{"role":"MANAGER"}',
///     reason: 'Promotion approved by admin.',
///   ),
/// );
/// ```
class RepoAuditLog {
  final Box<EntityAuditLog> _box;

  RepoAuditLog(ServiceObjectBox objectBoxService)
      : _box = objectBoxService.box<EntityAuditLog>();

  // ── Write (append only) ──────────────────────────────────────────────────

  /// Appends a single audit log entry and returns its assigned ObjectBox [id].
  int log(EntityAuditLog entry) => _box.put(entry);

  /// Appends multiple audit log entries in a single transaction.
  /// Returns the list of assigned ObjectBox ids in insertion order.
  List<int> logAll(List<EntityAuditLog> entries) => _box.putMany(entries);

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Returns all log entries for [userId], optionally within a UTC ms range.
  /// Results are ordered from newest to oldest.
  List<EntityAuditLog> queryByUser(
    int userId, {
    int? fromUtcMs,
    int? toUtcMs,
  }) {
    final condition = _withDateRange(
      EntityAuditLog_.userId.equals(userId),
      fromUtcMs: fromUtcMs,
      toUtcMs: toUtcMs,
    );
    return _box
        .query(condition)
        .order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Returns all log entries for a given [module] string (e.g. "system").
  /// Prefer using [AuditModule.name] as the value.
  /// Results are ordered from newest to oldest.
  List<EntityAuditLog> queryByModule(
    String module, {
    int? fromUtcMs,
    int? toUtcMs,
  }) {
    final condition = _withDateRange(
      EntityAuditLog_.module.equals(module),
      fromUtcMs: fromUtcMs,
      toUtcMs: toUtcMs,
    );
    return _box
        .query(condition)
        .order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Typed overload — accepts an [AuditModule] enum value directly.
  List<EntityAuditLog> queryByAuditModule(
    AuditModule module, {
    int? fromUtcMs,
    int? toUtcMs,
  }) =>
      queryByModule(module.name, fromUtcMs: fromUtcMs, toUtcMs: toUtcMs);

  /// Returns all log entries for a given [action] string (e.g. "delete").
  /// Prefer using [AuditAction.name] as the value.
  /// Results are ordered from newest to oldest.
  List<EntityAuditLog> queryByAction(
    String action, {
    int? fromUtcMs,
    int? toUtcMs,
  }) {
    final condition = _withDateRange(
      EntityAuditLog_.action.equals(action),
      fromUtcMs: fromUtcMs,
      toUtcMs: toUtcMs,
    );
    return _box
        .query(condition)
        .order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Typed overload — accepts an [AuditAction] enum value directly.
  List<EntityAuditLog> queryByAuditAction(
    AuditAction action, {
    int? fromUtcMs,
    int? toUtcMs,
  }) =>
      queryByAction(action.name, fromUtcMs: fromUtcMs, toUtcMs: toUtcMs);

  /// Returns the complete change history of a single entity record,
  /// identified by its class name and string primary key.
  ///
  /// Example:
  /// ```dart
  /// repo.queryByEntity('EntityUser', '5');
  /// ```
  List<EntityAuditLog> queryByEntity(String entityType, String entityId) {
    return _box
        .query(
          EntityAuditLog_.entityType.equals(entityType) &
              EntityAuditLog_.entityId.equals(entityId),
        )
        .order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Returns the [limit] most-recent log entries across all modules.
  List<EntityAuditLog> queryRecent({int limit = 100}) {
    return _box
        .query()
        .order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find()
        .take(limit)
        .toList();
  }

  /// Returns the total number of audit log entries in the store.
  int countAll() => _box.count();

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Optionally AND-chains a [createdAtUtcMs] range onto [base].
  Condition<EntityAuditLog> _withDateRange(
    Condition<EntityAuditLog> base, {
    int? fromUtcMs,
    int? toUtcMs,
  }) {
    var cond = base;
    if (fromUtcMs != null) {
      cond = cond & EntityAuditLog_.createdAtUtcMs.greaterOrEqual(fromUtcMs);
    }
    if (toUtcMs != null) {
      cond = cond & EntityAuditLog_.createdAtUtcMs.lessOrEqual(toUtcMs);
    }
    return cond;
  }
}
