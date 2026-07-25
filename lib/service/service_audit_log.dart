import 'package:get/get.dart';

import '../enums/enum_audit_action.dart';
import '../enums/enum_audit_module.dart';
import '../model/entity_audit_log.dart';
import '../repository/repo_audit_log.dart';
import '../screens/home/controller_home.dart';
import '../service/service_object_box.dart';

/// Application-wide service for writing audit log entries.
///
/// **Why use this instead of [RepoAuditLog] directly?**
/// - Typed convenience methods (`logCreate`, `logUpdate`, `logDelete`)
///   auto-fill the `action` field and generate a default `description`,
///   so call-sites only supply the data that varies.
/// - All modules remain decoupled from ObjectBox — they call this service
///   and never touch the Box directly.
/// - A single place to add cross-cutting concerns later (e.g. async flushing,
///   batch buffering, remote sync).
///
/// ## Registration
/// Registered permanently in `StaticMethods.initServices()`:
/// ```dart
/// Get.put<AuditLogService>(
///   AuditLogService(Get.find<ServiceObjectBox>()),
///   permanent: true,
/// );
/// ```
///
/// ## Retrieval
/// ```dart
/// final audit = Get.find<AuditLogService>();
/// ```
class AuditLogService {
  final RepoAuditLog _repo;

  AuditLogService(ServiceObjectBox objectBoxService)
      : _repo = RepoAuditLog(objectBoxService);

  // ── Convenience constructors ─────────────────────────────────────────────

  /// Log a **CREATE** action.
  ///
  /// - [oldData] is always `null` for creates — do not pass it.
  /// - [newData] should be a JSON-encoded snapshot of the newly created record.
  /// - [description] is auto-generated from [entityType] + [entityId] if omitted.
  /// - [userId] and [userName] auto-resolve from active session if omitted.
  ///
  /// Returns the ObjectBox id of the inserted log entry.
  int logCreate({
    int? userId,
    String? userName,
    required AuditModule module,
    required String entityType,
    String? entityId,
    String? newData,
    String? description,
    String? reason,
    String? branchId,
  }) {
    final (resolvedId, resolvedName) = _resolveUser(userId, userName);
    return _repo.log(
      EntityAuditLog.create(
        userId: resolvedId,
        userName: resolvedName,
        module: module,
        action: AuditAction.create,
        entityType: entityType,
        entityId: entityId,
        description: description ?? _defaultDesc(AuditAction.create, entityType, entityId),
        oldData: null,
        newData: newData,
        reason: reason,
        branchId: branchId,
      ),
    );
  }

  /// Log an **UPDATE** action.
  ///
  /// - [oldData] should be a JSON-encoded snapshot of the record **before** the change.
  /// - [newData] should be a JSON-encoded snapshot of the record **after** the change.
  /// - [description] is auto-generated if omitted.
  /// - [userId] and [userName] auto-resolve from active session if omitted.
  ///
  /// Returns the ObjectBox id of the inserted log entry.
  int logUpdate({
    int? userId,
    String? userName,
    required AuditModule module,
    required String entityType,
    String? entityId,
    String? oldData,
    String? newData,
    String? description,
    String? reason,
    String? branchId,
  }) {
    final (resolvedId, resolvedName) = _resolveUser(userId, userName);
    return _repo.log(
      EntityAuditLog.create(
        userId: resolvedId,
        userName: resolvedName,
        module: module,
        action: AuditAction.update,
        entityType: entityType,
        entityId: entityId,
        description: description ?? _defaultDesc(AuditAction.update, entityType, entityId),
        oldData: oldData,
        newData: newData,
        reason: reason,
        branchId: branchId,
      ),
    );
  }

  /// Log a **DELETE** action.
  ///
  /// - [oldData] should be a JSON-encoded snapshot of the record that was deleted.
  /// - [newData] is always `null` for deletes — do not pass it.
  /// - [description] is auto-generated if omitted.
  /// - [userId] and [userName] auto-resolve from active session if omitted.
  ///
  /// Returns the ObjectBox id of the inserted log entry.
  int logDelete({
    int? userId,
    String? userName,
    required AuditModule module,
    required String entityType,
    String? entityId,
    String? oldData,
    String? description,
    String? reason,
    String? branchId,
  }) {
    final (resolvedId, resolvedName) = _resolveUser(userId, userName);
    return _repo.log(
      EntityAuditLog.create(
        userId: resolvedId,
        userName: resolvedName,
        module: module,
        action: AuditAction.delete,
        entityType: entityType,
        entityId: entityId,
        description: description ?? _defaultDesc(AuditAction.delete, entityType, entityId),
        oldData: oldData,
        newData: null,
        reason: reason,
        branchId: branchId,
      ),
    );
  }

  /// Log **any action** not covered by [logCreate], [logUpdate], or [logDelete].
  ///
  /// Use this for actions such as `login`, `logout`, `enable`, `disable`,
  /// `export`, or `restore`.
  /// - [userId] and [userName] auto-resolve from active session if omitted.
  ///
  /// Returns the ObjectBox id of the inserted log entry.
  int logAction({
    int? userId,
    String? userName,
    required AuditModule module,
    required AuditAction action,
    required String entityType,
    String? entityId,
    String? oldData,
    String? newData,
    String? description,
    String? reason,
    String? branchId,
  }) {
    final (resolvedId, resolvedName) = _resolveUser(userId, userName);
    return _repo.log(
      EntityAuditLog.create(
        userId: resolvedId,
        userName: resolvedName,
        module: module,
        action: action,
        entityType: entityType,
        entityId: entityId,
        description: description ?? _defaultDesc(action, entityType, entityId),
        oldData: oldData,
        newData: newData,
        reason: reason,
        branchId: branchId,
      ),
    );
  }

  // ── Read pass-throughs ───────────────────────────────────────────────────
  // Thin delegation to the repo — keeps callers from depending on RepoAuditLog.

  /// Returns all log entries for a user, newest first.
  List<EntityAuditLog> getByUser(
    int userId, {
    int? fromUtcMs,
    int? toUtcMs,
  }) =>
      _repo.queryByUser(userId, fromUtcMs: fromUtcMs, toUtcMs: toUtcMs);

  /// Returns all log entries for a module, newest first.
  List<EntityAuditLog> getByModule(
    AuditModule module, {
    int? fromUtcMs,
    int? toUtcMs,
  }) =>
      _repo.queryByAuditModule(module, fromUtcMs: fromUtcMs, toUtcMs: toUtcMs);

  /// Returns all log entries for an action type, newest first.
  List<EntityAuditLog> getByAction(
    AuditAction action, {
    int? fromUtcMs,
    int? toUtcMs,
  }) =>
      _repo.queryByAuditAction(action, fromUtcMs: fromUtcMs, toUtcMs: toUtcMs);

  /// Returns the full change history of a single entity record.
  List<EntityAuditLog> getByEntity(String entityType, String entityId) =>
      _repo.queryByEntity(entityType, entityId);

  /// Returns the [limit] most-recent entries across all modules.
  List<EntityAuditLog> getRecent({int limit = 100}) =>
      _repo.queryRecent(limit: limit);

  /// Total number of audit entries in the store.
  int count() => _repo.countAll();

  // ── Static accessor ──────────────────────────────────────────────────────

  /// Shortcut to retrieve the registered instance from GetX.
  ///
  /// Equivalent to `Get.find<AuditLogService>()`.
  static AuditLogService get instance => Get.find<AuditLogService>();

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Generates a plain-English fallback description from the action + entity.
  static String _defaultDesc(
    AuditAction action,
    String entityType,
    String? entityId,
  ) {
    final label = action.label; // e.g. "Created", "Updated"
    final entity = _prettify(entityType); // e.g. "EntityUser" → "User"
    final suffix = entityId != null ? ' #$entityId' : '';
    return '$label $entity$suffix.';
  }

  /// Strips the "Entity" prefix for friendlier default descriptions.
  /// "EntityUser" → "User", "EntityItem" → "Item".
  static String _prettify(String entityType) {
    if (entityType.startsWith('Entity')) {
      return entityType.substring('Entity'.length);
    }
    return entityType;
  }

  /// Automatically resolves the active user from [ControllerHome] if not passed.
  static (int?, String?) _resolveUser(int? userId, String? userName) {
    if (userId != null && userName != null) return (userId, userName);
    if (Get.isRegistered<ControllerHome>()) {
      final homeController = Get.find<ControllerHome>();
      final user = homeController.rxUser.value;
      if (user != null) {
        userId ??= user.id;
        if (userName == null || userName.isEmpty) {
          final first = user.first ?? '';
          final last = user.last ?? '';
          final fullName = '$first $last'.trim();
          userName = fullName.isNotEmpty ? fullName : (user.username ?? 'User');
        }
      }
    }
    return (userId, userName);
  }
}
