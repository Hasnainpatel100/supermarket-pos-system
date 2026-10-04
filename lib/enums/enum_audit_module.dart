import 'package:get/get.dart';

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
  brand,
  branch,
}

extension AuditModuleExtension on AuditModule {
  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case AuditModule.pos:
        return 'audit_pos'.tr;
      case AuditModule.inventory:
        return 'audit_inventory'.tr;
      case AuditModule.purchase:
        return 'audit_purchase'.tr;
      case AuditModule.supplier:
        return 'audit_supplier'.tr;
      case AuditModule.customer:
        return 'audit_customer'.tr;
      case AuditModule.system:
        return 'audit_system'.tr;
      case AuditModule.reports:
        return 'audit_reports'.tr;
      case AuditModule.backup:
        return 'audit_backup'.tr;
      case AuditModule.finance:
        return 'audit_finance'.tr;
      case AuditModule.brand:
        return 'audit_brand'.tr;
      case AuditModule.branch:
        return 'audit_branch'.tr;
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
