import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../model/backup_history_item.dart';
import '../service/service_storage.dart';

/// All file-system operations for Backup & Recovery.
///
/// This class contains ZERO business logic and ZERO UI.
/// It is the single place that touches the file system for backup tasks.
class RepoBackup {
  static const String _locationKey = 'backup_location';

  final ServiceStorage _storage;

  RepoBackup({required ServiceStorage storage}) : _storage = storage;

  // ── Backup Location ────────────────────────────────────────────────────────

  /// Returns the saved backup destination folder, or null if never set.
  String? getSavedBackupLocation() => _storage.readString(_locationKey);

  /// Persists the chosen backup folder path.
  Future<void> saveBackupLocation(String path) =>
      _storage.writeString(_locationKey, path);

  // ── Database Path ──────────────────────────────────────────────────────────

  /// Returns the directory that holds the ObjectBox database files.
  Future<String> getDatabaseDirectory() async {
    if (kDebugMode) {
      // In debug mode the store is opened with directory: "market"
      // which resolves relative to the current working directory.
      return p.join(Directory.current.path, 'market');
    } else {
      final appSupport = await getApplicationSupportDirectory();
      return p.join(appSupport.path, 'market');
    }
  }

  /// Returns the application support directory (used for settings file).
  Future<String> getAppSupportDirectory() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  // ── Settings File ──────────────────────────────────────────────────────────

  /// Returns the path of the encrypted settings data file.
  Future<String> getSettingsFilePath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, '.sys_cache_9a3f.dat');
  }

  // ── Images Directory ───────────────────────────────────────────────────────

  /// Returns the images directory (appSupport/images).
  /// If the directory does not exist yet, returns null so the backup
  /// can skip it gracefully.
  Future<Directory?> getImagesDirectory() async {
    final dir = await getApplicationSupportDirectory();
    final imgDir = Directory(p.join(dir.path, 'images'));
    if (await imgDir.exists()) return imgDir;
    return null;
  }

  // ── Disk Space ─────────────────────────────────────────────────────────────

  /// Returns free disk bytes on the volume containing [directory].
  /// On Windows this uses `wmic logicaldisk` via a process call.
  Future<int> getFreeDiskBytes(String directory) async {
    try {
      if (Platform.isWindows) {
        final drive = p.rootPrefix(directory); // e.g. "C:\"
        final letter = drive.replaceAll(r'\', '').replaceAll('/', '');
        final result = await Process.run('cmd', [
          '/c',
          'wmic logicaldisk where "DeviceID=\'$letter\'" get FreeSpace /value',
        ]);
        final out = result.stdout as String;
        final match = RegExp(r'FreeSpace=(\d+)').firstMatch(out);
        if (match != null) {
          return int.tryParse(match.group(1)!) ?? 0;
        }
      }
      return 10 * 1024 * 1024 * 1024; // fallback: assume 10 GB
    } catch (_) {
      return 10 * 1024 * 1024 * 1024; // fallback
    }
  }

  /// Returns the total size (bytes) of a directory tree.
  Future<int> getDirectorySize(Directory dir) async {
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  // ── ZIP Creation ───────────────────────────────────────────────────────────

  /// Creates a ZIP archive at [destZipPath].
  ///
  /// [entries] is a list of (sourcePath, zipEntryName) pairs.
  /// Files are added; directories are added recursively.
  /// [infoFilePath] when provided is added as "backup_info.json" at the
  /// root of the ZIP.
  ///
  /// [onProgress] receives a value from 0.0 to 1.0.
  Future<void> createZip({
    required List<BackupZipEntry> entries,
    required String destZipPath,
    String? infoFilePath,
    void Function(double progress, String label)? onProgress,
  }) async {
    final encoder = ZipFileEncoder();
    encoder.create(destZipPath);
    try {
      // Add backup_info.json first if provided
      if (infoFilePath != null) {
        final infoFile = File(infoFilePath);
        if (await infoFile.exists()) {
          encoder.addFile(infoFile, 'backup_info.json');
        }
      }

      final total = entries.length.toDouble();
      int done = 0;

      for (final entry in entries) {
        final src = FileSystemEntity.typeSync(entry.sourcePath);

        if (src == FileSystemEntityType.file) {
          final file = File(entry.sourcePath);
          if (await file.exists()) {
            encoder.addFile(file, entry.zipName);
          }
        } else if (src == FileSystemEntityType.directory) {
          final dir = Directory(entry.sourcePath);
          if (await dir.exists()) {
            await _addDirectoryToZip(encoder, dir, entry.zipName, onProgress);
          }
        }

        done++;
        onProgress?.call(done / total, entry.zipName);
      }
    } finally {
      await encoder.close();
    }
  }

  Future<void> _addDirectoryToZip(
    ZipFileEncoder encoder,
    Directory dir,
    String zipBaseName,
    void Function(double, String)? onProgress,
  ) async {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relative = p.relative(entity.path, from: dir.path);
        final zipName = p.join(zipBaseName, relative).replaceAll(r'\', '/');
        encoder.addFile(entity, zipName);
        onProgress?.call(0, p.basename(entity.path));
      }
    }
  }

  // ── ZIP Extraction ─────────────────────────────────────────────────────────

  /// Extracts a ZIP file to [destDir]. Returns the [Directory] it extracted to.
  ///
  /// Throws [FormatException] if the ZIP cannot be decoded.
  Future<Directory> extractZip(String zipPath, String destDir) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final out = Directory(destDir);
    await out.create(recursive: true);

    for (final file in archive) {
      final filePath = p.join(destDir, file.name);
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
    return out;
  }

  // ── ZIP Validation ─────────────────────────────────────────────────────────

  /// Returns null if valid, or a human-readable error string on failure.
  Future<String?> validateExtractedBackup(String extractedDir) async {
    final infoFile = File(p.join(extractedDir, 'backup_info.json'));
    if (!await infoFile.exists()) {
      return 'Invalid backup: backup_info.json not found.';
    }

    final dbDir = Directory(p.join(extractedDir, 'database'));
    if (!await dbDir.exists()) {
      return 'Invalid backup: database folder not found.';
    }

    // Make sure there's at least one file in the database folder (recursively)
    bool hasDbFile = false;
    await for (final entity in dbDir.list(recursive: true)) {
      if (entity is File) {
        hasDbFile = true;
        break;
      }
    }
    if (!hasDbFile) {
      return 'Invalid backup: database folder is empty.';
    }

    return null; // valid
  }

  // ── Database Replace ───────────────────────────────────────────────────────

  /// Replaces the current ObjectBox database with files from [srcDir].
  Future<void> replaceDatabase(String srcDir, String currentDbDir) async {
    Directory src = Directory(srcDir);
    final dest = Directory(currentDbDir);

    // If backup ZIP had nested database/market/data.mdb instead of database/data.mdb,
    // unwrap the nested folder automatically.
    final srcEntities = await src.list(recursive: false).toList();
    if (srcEntities.length == 1 && srcEntities.first is Directory) {
      src = srcEntities.first as Directory;
    }

    // Remove existing DB files in target directory
    if (await dest.exists()) {
      await for (final entity
          in dest.list(recursive: false, followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } else {
      await dest.create(recursive: true);
    }

    // Copy restored files
    await for (final entity in src.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relative = p.relative(entity.path, from: src.path);
        final destPath = p.join(dest.path, relative);
        await File(destPath).create(recursive: true);
        await entity.copy(destPath);
      }
    }
  }

  // ── Settings Replace ───────────────────────────────────────────────────────

  /// Replaces the current encrypted settings file with the backed-up one.
  Future<void> replaceSettings(String srcFile, String currentSettingsFile) async {
    final src = File(srcFile);
    if (await src.exists()) {
      await src.copy(currentSettingsFile);
    }
  }

  // ── Images Replace ────────────────────────────────────────────────────────

  /// Replaces the current images directory with the backed-up one.
  Future<void> replaceImages(String srcDir, String currentImagesDir) async {
    final src = Directory(srcDir);
    if (!await src.exists()) return;

    final dest = Directory(currentImagesDir);
    if (await dest.exists()) {
      await dest.delete(recursive: true);
    }
    await dest.create(recursive: true);

    await for (final entity in src.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relative = p.relative(entity.path, from: src.path);
        final destPath = p.join(dest.path, relative);
        await File(destPath).create(recursive: true);
        await entity.copy(destPath);
      }
    }
  }

  // ── History ────────────────────────────────────────────────────────────────

  List<BackupHistoryItem> getHistoryList() {
    final raw = _storage.readString(BackupHistoryItem.storageKey);
    if (raw == null || raw.isEmpty) return [];
    return BackupHistoryItem.listFromJsonString(raw);
  }

  Future<void> saveHistoryList(List<BackupHistoryItem> items) async {
    await _storage.writeString(
      BackupHistoryItem.storageKey,
      BackupHistoryItem.listToJsonString(items),
    );
  }

  Future<void> addToHistory(BackupHistoryItem item) async {
    final list = getHistoryList();
    list.insert(0, item); // newest first
    // Keep only the last 50 entries
    final trimmed = list.take(50).toList();
    await saveHistoryList(trimmed);
  }

  Future<void> removeFromHistory(String zipPath) async {
    final list = getHistoryList();
    list.removeWhere((e) => e.path == zipPath);
    await saveHistoryList(list);
  }

  // ── File Operations ────────────────────────────────────────────────────────

  /// Deletes a backup ZIP file from disk.
  Future<void> deleteBackupFile(String zipPath) async {
    final file = File(zipPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Opens Windows Explorer at the given folder path.
  Future<void> openFolderInExplorer(String folderPath) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [folderPath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [folderPath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [folderPath]);
    }
  }

  /// Returns a unique temp directory path for extraction.
  Future<String> createTempExtractDir() async {
    final temp = await getTemporaryDirectory();
    final dir = Directory(
        p.join(temp.path, 'backup_restore_${DateTime.now().millisecondsSinceEpoch}'));
    await dir.create(recursive: true);
    return dir.path;
  }

  /// Deletes a temporary extraction directory.
  Future<void> deleteTempDir(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  // ── Validation helpers ─────────────────────────────────────────────────────

  /// Returns true if the destination folder is writable.
  Future<bool> isFolderWritable(String folderPath) async {
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final testFile = File(p.join(folderPath, '.write_test'));
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the given path exists and is a valid ZIP file.
  Future<bool> isValidZipFile(String zipPath) async {
    try {
      final file = File(zipPath);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      // ZIP magic bytes: PK\x03\x04
      if (bytes.length < 4) return false;
      return bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04;
    } catch (_) {
      return false;
    }
  }
}

/// Entry descriptor used by [RepoBackup.createZip].
class BackupZipEntry {
  final String sourcePath;

  /// The name/path this entry will have inside the ZIP.
  final String zipName;

  const BackupZipEntry({required this.sourcePath, required this.zipName});
}
