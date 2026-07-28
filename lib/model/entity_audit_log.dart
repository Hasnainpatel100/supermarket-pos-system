import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

import '../enums/enum_audit_action.dart';
import '../enums/enum_audit_module.dart';

/// Immutable audit-trail record for any significant action taken in the app.
///
/// **Append-only** — entries must never be updated or deleted after creation.
/// There is intentionally no [updatedAtUtcMs] field to enforce this contract.
///
/// ## Indexed fields (for efficient querying)
/// - [userId]          — filter all actions by a specific operator
/// - [module]          — filter by functional area (e.g. "system", "pos")
/// - [action]          — filter by action type (e.g. "create", "delete")
/// - [entityType]      — filter by entity class name (e.g. "EntityUser")
/// - [createdAtUtcMs]  — primary sort key; enables date-range queries
///
/// ## JSON snapshots
/// [oldData] and [newData] store the entity state before/after the action
/// as JSON-encoded strings. Both are optional:
///   - CREATE → [oldData] is null, [newData] holds the new record.
///   - UPDATE → both populated.
///   - DELETE → [oldData] holds the deleted record, [newData] is null.
@Entity()
class EntityAuditLog {
  // ── ObjectBox primary key ────────────────────────────────────────────────

  @Id()
  int id = 0;

  // ── Distributed / sync identifier ───────────────────────────────────────

  /// MongoDB-compatible ObjectId hex string.
  /// Auto-generated on construction; unique across the collection.
  @Unique()
  String objectId = ObjectId().hexString;

  // ── Who ─────────────────────────────────────────────────────────────────

  /// FK → EntityUser.id (local ObjectBox id).
  /// Indexed for fast per-user audit queries.
  @Index()
  int? userId;

  /// Denormalized display name to avoid joins when rendering the log.
  /// Format: "firstName lastName" or username fallback.
  String? userName;

  // ── What / Where ─────────────────────────────────────────────────────────

  /// Functional area of the application.
  /// Stored as [AuditModule.name] (e.g. "system", "pos", "inventory").
  /// Indexed for module-level filtering.
  @Index()
  String? module;

  /// Action performed.
  /// Stored as [AuditAction.name] (e.g. "create", "update", "delete").
  /// Indexed for action-type filtering.
  @Index()
  String? action;

  /// Dart class name of the affected entity (e.g. "EntityUser", "EntityItem").
  /// Indexed for entity-type filtering.
  @Index()
  String? entityType;

  /// String representation of the affected entity's primary key.
  /// Use the ObjectBox int id or objectId hex string — whichever is more stable.
  String? entityId;

  // ── Human-readable context ───────────────────────────────────────────────

  /// Short, plain-English summary of what changed.
  /// Example: "Updated selling price for item SKU-0042 from ₹120 to ₹135."
  String? description;

  // ── Before / After snapshots ─────────────────────────────────────────────

  /// JSON-encoded snapshot of the entity **before** the action.
  /// Null for CREATE actions.
  String? oldData;

  /// JSON-encoded snapshot of the entity **after** the action.
  /// Null for DELETE actions.
  String? newData;

  // ── Optional metadata ────────────────────────────────────────────────────

  /// User-provided justification for the action (e.g. "Price correction").
  /// Useful for sensitive operations like price overrides or user disabling.
  String? reason;

  /// Branch or store context when the system operates in multi-branch mode.
  /// Matches EntityUser.storeId.
  String? branchId;

  // ── Timestamp ────────────────────────────────────────────────────────────

  /// UTC epoch milliseconds at the moment the log entry was created.
  /// Indexed as the primary sort key for time-range queries.
  @Index()
  int? createdAtUtcMs;

  // ── Constructor ──────────────────────────────────────────────────────────

  EntityAuditLog({
    this.id = 0,
    this.userId,
    this.userName,
    this.module,
    this.action,
    this.entityType,
    this.entityId,
    this.description,
    this.oldData,
    this.newData,
    this.reason,
    this.branchId,
    this.createdAtUtcMs,
  });

  // ── Typed helpers ────────────────────────────────────────────────────────

  /// Parses [action] back to a typed [AuditAction]. Returns null if unknown.
  AuditAction? get auditAction => AuditActionExtension.fromName(action);

  /// Parses [module] back to a typed [AuditModule]. Returns null if unknown.
  AuditModule? get auditModule => AuditModuleExtension.fromName(module);

  // ── Factory constructors ─────────────────────────────────────────────────

  /// Convenience factory — builds a log entry from typed enums.
  ///
  /// [createdAtUtcMs] defaults to now (UTC) if omitted.
  factory EntityAuditLog.create({
    required int? userId,
    required String? userName,
    required AuditModule module,
    required AuditAction action,
    required String entityType,
    String? entityId,
    String? description,
    String? oldData,
    String? newData,
    String? reason,
    String? branchId,
    int? createdAtUtcMs,
  }) {
    return EntityAuditLog(
      userId: userId,
      userName: userName,
      module: module.name,
      action: action.name,
      entityType: entityType,
      entityId: entityId,
      description: description,
      oldData: oldData,
      newData: newData,
      reason: reason,
      branchId: branchId,
      createdAtUtcMs:
          createdAtUtcMs ?? DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  // ── Serialization ────────────────────────────────────────────────────────

  /// Converts this entry to a plain [Map] (e.g. for export / sync).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'objectId': objectId,
      'userId': userId,
      'userName': userName,
      'module': module,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'oldData': oldData,
      'newData': newData,
      'reason': reason,
      'branchId': branchId,
      'createdAtUtcMs': createdAtUtcMs,
    };
  }

  /// Reconstructs an [EntityAuditLog] from a [Map] (e.g. from sync payload).
  factory EntityAuditLog.fromMap(Map<String, dynamic> map) {
    return EntityAuditLog(
      id: map['id'] ?? 0,
      userId: map['userId'],
      userName: map['userName'],
      module: map['module'],
      action: map['action'],
      entityType: map['entityType'],
      entityId: map['entityId'],
      description: map['description'],
      oldData: map['oldData'],
      newData: map['newData'],
      reason: map['reason'],
      branchId: map['branchId'],
      createdAtUtcMs: map['createdAtUtcMs'],
    );
  }
}
