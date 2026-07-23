import 'dart:convert';

/// Metadata written into every backup ZIP as `backup_info.json`.
class BackupInfo {
  final String appVersion;
  final int databaseVersion;

  /// ISO-8601 string  e.g. "2026-07-23T10:35:20"
  final String backupDate;
  final String storeName;
  final String device;

  const BackupInfo({
    required this.appVersion,
    required this.databaseVersion,
    required this.backupDate,
    required this.storeName,
    required this.device,
  });

  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'databaseVersion': databaseVersion,
        'backupDate': backupDate,
        'storeName': storeName,
        'device': device,
      };

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      appVersion: json['appVersion'] as String? ?? '',
      databaseVersion: (json['databaseVersion'] as num?)?.toInt() ?? 1,
      backupDate: json['backupDate'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      device: json['device'] as String? ?? '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static BackupInfo fromJsonString(String raw) =>
      BackupInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  @override
  String toString() => 'BackupInfo(v=$appVersion, date=$backupDate, store=$storeName)';
}
