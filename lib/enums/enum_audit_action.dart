/// Typed enum for the [EntityAuditLog.action] field.
///
/// Serialized to/from its [name] string when stored in ObjectBox.
enum AuditAction {
  create,
  update,
  delete,
  login,
  logout,
  enable,
  disable,
  export,
  restore,
}

extension AuditActionExtension on AuditAction {
  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case AuditAction.create:
        return 'Create';
      case AuditAction.update:
        return 'Update';
      case AuditAction.delete:
        return 'Delete';
      case AuditAction.login:
        return 'Login';
      case AuditAction.logout:
        return 'Logout';
      case AuditAction.enable:
        return 'Enable';
      case AuditAction.disable:
        return 'Disable';
      case AuditAction.export:
        return 'Export';
      case AuditAction.restore:
        return 'Restore';
    }
  }

  /// Badge color value for UI chips.
  int get colorValue {
    switch (this) {
      case AuditAction.create:
        return 0xFF4CAF50; // green
      case AuditAction.update:
        return 0xFF2196F3; // blue
      case AuditAction.delete:
        return 0xFFF44336; // red
      case AuditAction.login:
        return 0xFF9C27B0; // purple
      case AuditAction.logout:
        return 0xFF9E9E9E; // grey
      case AuditAction.enable:
        return 0xFF00BCD4; // cyan
      case AuditAction.disable:
        return 0xFFFF9800; // orange
      case AuditAction.export:
        return 0xFF795548; // brown
      case AuditAction.restore:
        return 0xFF607D8B; // blue-grey
    }
  }

  /// Parse from stored string (e.g. 'create' → [AuditAction.create]).
  /// Returns null if the value is unrecognised.
  static AuditAction? fromName(String? value) {
    if (value == null) return null;
    try {
      return AuditAction.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}
