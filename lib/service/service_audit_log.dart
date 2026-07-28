import 'package:get/get.dart';

import '../enums/enum_audit_action.dart';
import '../enums/enum_audit_module.dart';
import '../model/entity_audit_log.dart';
import '../objectbox.g.dart';
import 'service_object_box.dart';

/// Singleton service for writing audit log entries to the local ObjectBox store.
///
/// Usage:
///   AuditLogService.instance.logCreate(module: AuditModule.pos, ...);
///   AuditLogService.instance.logAction(module: AuditModule.system, action: AuditAction.logout, ...);
class AuditLogService extends GetxService {
  final ServiceObjectBox _objectBoxService;
  late final Box<EntityAuditLog> _box;

  AuditLogService(this._objectBoxService);

  @override
  void onInit() {
    super.onInit();
    _box = _objectBoxService.box<EntityAuditLog>();
  }

  /// Singleton accessor — resolves via GetX.
  static AuditLogService get instance => Get.find<AuditLogService>();

  // ── Core write method ──────────────────────────────────────────────────────

  void _write(EntityAuditLog log) {
    try {
      _box.put(log);
    } catch (e) {
      // Never crash the app because of an audit log failure.
      // ignore: avoid_print
      print('[AuditLogService] Failed to write log: $e');
    }
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// Log a CREATE action.
  void logCreate({
    required AuditModule module,
    String? entityType,
    String? entityId,
    String? description,
    String? newData,
    String? branchId,
  }) {
    _write(EntityAuditLog(
      module: module.name,
      action: AuditAction.create.name,
      entityType: entityType,
      entityId: entityId,
      description: description,
      newData: newData,
      branchId: branchId,
      userId: _currentUserId,
      userName: _currentUserName,
    ));
  }

  /// Log an UPDATE action.
  void logUpdate({
    required AuditModule module,
    String? entityType,
    String? entityId,
    String? description,
    String? oldData,
    String? newData,
    String? reason,
    String? branchId,
  }) {
    _write(EntityAuditLog(
      module: module.name,
      action: AuditAction.update.name,
      entityType: entityType,
      entityId: entityId,
      description: description,
      oldData: oldData,
      newData: newData,
      reason: reason,
      branchId: branchId,
      userId: _currentUserId,
      userName: _currentUserName,
    ));
  }

  /// Log a DELETE action.
  void logDelete({
    required AuditModule module,
    String? entityType,
    String? entityId,
    String? description,
    String? oldData,
    String? reason,
    String? branchId,
  }) {
    _write(EntityAuditLog(
      module: module.name,
      action: AuditAction.delete.name,
      entityType: entityType,
      entityId: entityId,
      description: description,
      oldData: oldData,
      reason: reason,
      branchId: branchId,
      userId: _currentUserId,
      userName: _currentUserName,
    ));
  }

  /// Log any arbitrary [AuditAction].
  void logAction({
    required AuditModule module,
    AuditAction action = AuditAction.update,
    String? entityType,
    String? entityId,
    String? description,
    String? oldData,
    String? newData,
    String? reason,
    String? branchId,
    int? userId,
    String? userName,
  }) {
    _write(EntityAuditLog(
      module: module.name,
      action: action.name,
      entityType: entityType,
      entityId: entityId,
      description: description,
      oldData: oldData,
      newData: newData,
      reason: reason,
      branchId: branchId,
      userId: userId ?? _currentUserId,
      userName: userName ?? _currentUserName,
    ));
  }

  // ── Query helpers ──────────────────────────────────────────────────────────

  /// Retrieve all audit log entries sorted by most recent first.
  List<EntityAuditLog> getAll() {
    return _box
        .query()
        .order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Retrieve audit logs for a specific [module].
  List<EntityAuditLog> getByModule(AuditModule module) {
    return _box
        .query(EntityAuditLog_.module.equals(module.name))
        .order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Retrieve audit logs for a specific entity.
  List<EntityAuditLog> getByEntity(String entityType, String entityId) {
    return _box
        .query(
          EntityAuditLog_.entityType.equals(entityType).and(
                EntityAuditLog_.entityId.equals(entityId),
              ),
        )
        .order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find();
  }

  /// Delete all audit log entries older than [days] days.
  int pruneOlderThan(int days) {
    final cutoff = DateTime.now()
        .toUtc()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final q = _box
        .query(EntityAuditLog_.createdAtUtcMs.lessThan(cutoff))
        .build();
    final ids = q.findIds();
    q.close();
    _box.removeMany(ids);
    return ids.length;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  int? get _currentUserId {
    try {
      // ControllerHome stores the logged-in user; avoid hard dependency.
      return null;
    } catch (_) {
      return null;
    }
  }

  String? get _currentUserName {
    try {
      return null;
    } catch (_) {
      return null;
    }
  }
}
