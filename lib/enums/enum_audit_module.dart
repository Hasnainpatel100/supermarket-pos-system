/// Typed enum for the [EntityAuditLog.module] field.
///
/// Each value represents a top-level functional area of the application.
/// Serialized to/from its [name] string when stored in ObjectBox.
enum AuditModule {
  pos,
  inventory,
  purchase,
  supplier,
  customer,
  system,
  reports,
  backup,
  finance,
}

extension AuditModuleExtension on AuditModule {
  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case AuditModule.pos:
        return 'POS';
      case AuditModule.inventory:
        return 'Inventory';
      case AuditModule.purchase:
        return 'Purchase';
      case AuditModule.supplier:
        return 'Supplier';
      case AuditModule.customer:
        return 'Customer';
      case AuditModule.system:
        return 'System';
      case AuditModule.reports:
        return 'Reports';
      case AuditModule.backup:
        return 'Backup';
      case AuditModule.finance:
        return 'Finance';
    }
  }

  /// Parse from stored string (e.g. 'system' → [AuditModule.system]).
  /// Returns null if the value is unrecognised.
  static AuditModule? fromName(String? value) {
    if (value == null) return null;
    try {
      return AuditModule.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}
