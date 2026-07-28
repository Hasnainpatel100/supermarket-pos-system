import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityAuditLog {
  @Id()
  int id;

  @Unique()
  String objectId;

  int? userId;
  String? userName;

  // e.g. 'pos', 'item', 'customer', 'user', 'system', 'finance'
  String? module;

  // e.g. 'create', 'update', 'delete', 'login', 'logout'
  String? action;

  // Entity type name, e.g. 'EntityBill', 'EntityItem'
  String? entityType;

  // String form of the entity's ObjectBox or Mongo ID
  String? entityId;

  // Human-readable description of what happened
  String? description;

  // JSON-encoded snapshot before the action (for updates/deletes)
  String? oldData;

  // JSON-encoded snapshot after the action (for creates/updates)
  String? newData;

  // Optional reason or remark provided by the user
  String? reason;

  // Branch / store identifier
  String? branchId;

  // UTC epoch ms of when the log entry was created
  int createdAtUtcMs;

  EntityAuditLog({
    this.id = 0,
    String? objectId,
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
    int? createdAtUtcMs,
  })  : objectId = objectId ?? ObjectId().hexString,
        createdAtUtcMs = createdAtUtcMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
}
