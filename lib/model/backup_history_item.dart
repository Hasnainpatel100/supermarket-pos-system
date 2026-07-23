import 'dart:convert';

/// Represents one entry in the local backup history list.
///
/// The list is persisted as a JSON array string inside [ServiceStorage]
/// under the key [BackupHistoryItem.storageKey].
class BackupHistoryItem {
  static const String storageKey = 'backup_history_list';

  final String name;

  /// Absolute path to the ZIP file on disk.
  final String path;

  /// Size in bytes of the ZIP file.
  final int sizeBytes;

  final DateTime createdAt;

  const BackupHistoryItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.createdAt,
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BackupHistoryItem.fromJson(Map<String, dynamic> json) {
    return BackupHistoryItem(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // ── List helpers ───────────────────────────────────────────────────────────

  static String listToJsonString(List<BackupHistoryItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<BackupHistoryItem> listFromJsonString(String raw) {
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(BackupHistoryItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Convenience ────────────────────────────────────────────────────────────

  /// Human-readable size: "12.4 MB", "800 KB", etc.
  String get readableSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$sizeBytes B';
  }

  @override
  String toString() => 'BackupHistoryItem($name, $readableSize)';
}
