import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../model/backup_history_item.dart';
import '../model/backup_info.dart';
import '../repository/repo_backup.dart';
import '../service/service_object_box.dart';
import '../service/service_storage.dart';
import '../util/util_device.dart';

/// Orchestrates all backup and recovery workflows.
///
/// Business logic lives here.
/// File-system operations delegate to [RepoBackup].
/// UI state is updated through callbacks supplied by [ControllerBackup].
class ServiceBackup {
  static const String _appVersion = '1.0.0';
  static const int _databaseVersion = 1;

  /// Minimum free disk space required as a safety buffer (200 MB).
  static const int _minFreeBuffer = 200 * 1024 * 1024;

  final RepoBackup _repo;

  ServiceBackup({required ServiceStorage storage})
      : _repo = RepoBackup(storage: storage);

  // ── Backup Location ────────────────────────────────────────────────────────

  String? getSavedBackupLocation() => _repo.getSavedBackupLocation();

  Future<void> saveBackupLocation(String path) =>
      _repo.saveBackupLocation(path);

  // ── History ────────────────────────────────────────────────────────────────

  List<BackupHistoryItem> getHistory() => _repo.getHistoryList();

  // ── Backup Now ────────────────────────────────────────────────────────────

  /// Runs the full backup workflow.
  ///
  /// [onProgress] — called with (0.0–1.0, label) during ZIP creation.
  /// [onSuccess]  — called with the resulting [BackupHistoryItem] when done.
  /// [onError]    — called with a user-friendly error string on failure.
  Future<void> backupNow({
    required void Function(double progress, String label) onProgress,
    required void Function(BackupHistoryItem item) onSuccess,
    required void Function(String error) onError,
  }) async {
    String? tempDir;
    try {
      // 1. Resolve backup destination folder ─────────────────────────────────
      String? destFolder = _repo.getSavedBackupLocation();

      if (destFolder == null || destFolder.isEmpty) {
        final picked = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Backup Location',
        );
        if (picked == null) {
          onError('Backup cancelled: no folder selected.');
          return;
        }
        destFolder = picked;
        await _repo.saveBackupLocation(destFolder);
      }

      // 2. Pre-flight validations ─────────────────────────────────────────────
      final dbDir = await _repo.getDatabaseDirectory();

      if (!Directory(dbDir).existsSync()) {
        onError('Backup failed: ObjectBox database not found.\nPath: $dbDir');
        return;
      }

      final writable = await _repo.isFolderWritable(destFolder);
      if (!writable) {
        onError(
            'Backup failed: destination folder is not writable.\n'
            'Path: $destFolder\n'
            'Check folder permissions or run as Administrator.');
        return;
      }

      final dbSize = await _repo.getDirectorySize(Directory(dbDir));
      final freeBytes = await _repo.getFreeDiskBytes(destFolder);
      if (freeBytes < dbSize + _minFreeBuffer) {
        onError(
            'Backup failed: not enough disk space.\n'
            'Required ≈ ${_fmtBytes(dbSize + _minFreeBuffer)}  |  '
            'Available: ${_fmtBytes(freeBytes)}');
        return;
      }

      // 3. Build ZIP file name ────────────────────────────────────────────────
      final now = DateTime.now();
      final stamp = _dateStamp(now);
      final zipName = 'Backup_$stamp.zip';
      final zipPath = p.join(destFolder, zipName);

      // 4. Build backup_info.json ─────────────────────────────────────────────
      final serviceStorage = Get.find<ServiceStorage>();
      final storeName =
          serviceStorage.readString('store_name') ?? 'Super Market';
      final device = await UtilDevice.getDeviceName();

      final backupInfo = BackupInfo(
        appVersion: _appVersion,
        databaseVersion: _databaseVersion,
        backupDate: now.toIso8601String().substring(0, 19),
        storeName: storeName,
        device: device,
      );

      // Write info JSON to temp dir so it can be added to ZIP
      tempDir = await _repo.createTempExtractDir();
      final infoFile = File(p.join(tempDir, 'backup_info.json'));
      await infoFile.writeAsString(backupInfo.toJsonString());

      // 5. Collect ZIP entries ────────────────────────────────────────────────
      final settingsFile = await _repo.getSettingsFilePath();
      final imagesDir = await _repo.getImagesDirectory();

      final entries = <BackupZipEntry>[
        // database/
        BackupZipEntry(sourcePath: dbDir, zipName: 'database'),
        // settings/.sys_cache_9a3f.dat
        if (File(settingsFile).existsSync())
          BackupZipEntry(
            sourcePath: settingsFile,
            zipName: 'settings/.sys_cache_9a3f.dat',
          ),
        // images/  (optional — may not exist yet)
        if (imagesDir != null)
          BackupZipEntry(sourcePath: imagesDir.path, zipName: 'images'),
      ];

      onProgress(0.0, 'Preparing backup…');

      // 6. Create ZIP ─────────────────────────────────────────────────────────
      await _repo.createZip(
        entries: entries,
        infoFilePath: infoFile.path,
        destZipPath: zipPath,
        onProgress: onProgress,
      );

      // 7. Cleanup temp ───────────────────────────────────────────────────────
      await _repo.deleteTempDir(tempDir);
      tempDir = null;

      // 8. Record history ─────────────────────────────────────────────────────
      final zipSize = await File(zipPath).length();
      final historyItem = BackupHistoryItem(
        name: zipName,
        path: zipPath,
        sizeBytes: zipSize,
        createdAt: now,
      );
      await _repo.addToHistory(historyItem);

      onSuccess(historyItem);
    } on FileSystemException catch (e) {
      if (tempDir != null) await _repo.deleteTempDir(tempDir);
      onError(_fmtFsError(e));
    } catch (e) {
      if (tempDir != null) await _repo.deleteTempDir(tempDir);
      onError('Backup failed: ${e.toString()}');
    }
  }

  // ── Change Backup Location ─────────────────────────────────────────────────

  /// Opens a folder picker, saves the chosen location, returns it (or null if
  /// cancelled).
  Future<String?> changeBackupLocation() async {
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Change Backup Location',
    );
    if (picked != null && picked.isNotEmpty) {
      await _repo.saveBackupLocation(picked);
    }
    return picked;
  }

  // ── Open Backup Folder ────────────────────────────────────────────────────

  Future<void> openBackupFolder({required void Function(String) onError}) async {
    final location = _repo.getSavedBackupLocation();
    if (location == null || location.isEmpty) {
      onError('No backup location set. Please create a backup first.');
      return;
    }
    if (!Directory(location).existsSync()) {
      onError('Backup folder not found:\n$location');
      return;
    }
    await _repo.openFolderInExplorer(location);
  }

  // ── Open Folder for a history item ────────────────────────────────────────

  Future<void> openFolderForItem({
    required BackupHistoryItem item,
    required void Function(String) onError,
  }) async {
    final folder = p.dirname(item.path);
    if (!Directory(folder).existsSync()) {
      onError('Folder not found:\n$folder');
      return;
    }
    await _repo.openFolderInExplorer(folder);
  }

  // ── Delete Backup ─────────────────────────────────────────────────────────

  Future<void> deleteBackup({
    required BackupHistoryItem item,
    required void Function(String) onError,
  }) async {
    try {
      await _repo.deleteBackupFile(item.path);
      await _repo.removeFromHistory(item.path);
    } on FileSystemException catch (e) {
      onError(_fmtFsError(e));
    } catch (e) {
      onError('Delete failed: ${e.toString()}');
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  /// Full restore workflow.
  ///
  /// [preselectedZipPath] — set from history restore button (skips picker).
  /// [onProgress]         — (0.0–1.0, label).
  /// [onValidated]        — async callback that receives [BackupInfo] and
  ///                        returns true (proceed) / false (cancel).
  /// [onSuccess]          — called after all files are replaced.
  /// [onError]            — user-friendly error string.
  Future<void> restoreBackup({
    String? preselectedZipPath,
    required void Function(double, String) onProgress,
    required Future<bool> Function(BackupInfo info) onValidated,
    required void Function() onSuccess,
    required void Function(String) onError,
  }) async {
    String? tempDir;
    try {
      // 1. Pick ZIP ───────────────────────────────────────────────────────────
      String? zipPath = preselectedZipPath;
      if (zipPath == null || zipPath.isEmpty) {
        final result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Select Backup ZIP to Restore',
          type: FileType.custom,
          allowedExtensions: ['zip'],
          allowMultiple: false,
        );
        if (result == null || result.files.isEmpty) {
          onError('Restore cancelled: no file selected.');
          return;
        }
        zipPath = result.files.single.path;
        if (zipPath == null) {
          onError('Restore failed: unable to read selected file path.');
          return;
        }
      }

      // 2. Validate ZIP magic bytes ───────────────────────────────────────────
      final isZip = await _repo.isValidZipFile(zipPath);
      if (!isZip) {
        onError('Restore failed: the selected file is not a valid ZIP archive.');
        return;
      }

      onProgress(0.05, 'Extracting backup…');

      // 3. Extract to temp ────────────────────────────────────────────────────
      tempDir = await _repo.createTempExtractDir();
      await _repo.extractZip(zipPath, tempDir);

      onProgress(0.35, 'Validating backup…');

      // 4. Validate content ───────────────────────────────────────────────────
      final validationError = await _repo.validateExtractedBackup(tempDir);
      if (validationError != null) {
        await _repo.deleteTempDir(tempDir);
        onError(validationError);
        return;
      }

      // 5. Parse backup_info ─────────────────────────────────────────────────
      final infoJson =
          await File(p.join(tempDir, 'backup_info.json')).readAsString();
      final backupInfo = BackupInfo.fromJsonString(infoJson);

      // 6. Confirmation dialog (caller responsibility) ────────────────────────
      final confirmed = await onValidated(backupInfo);
      if (!confirmed) {
        await _repo.deleteTempDir(tempDir);
        onError('Restore cancelled.');
        return;
      }

      onProgress(0.5, 'Closing database…');

      // 7. Close ObjectBox ───────────────────────────────────────────────────
      try {
        final obService = Get.find<ServiceObjectBox>();
        if (!obService.store.isClosed()) {
          obService.store.close();
        }
      } catch (_) {}

      onProgress(0.6, 'Restoring database…');

      // 8. Replace database ──────────────────────────────────────────────────
      final currentDbDir = await _repo.getDatabaseDirectory();
      await _repo.replaceDatabase(p.join(tempDir, 'database'), currentDbDir);

      onProgress(0.75, 'Restoring settings…');

      // 9. Replace settings ──────────────────────────────────────────────────
      final currentSettings = await _repo.getSettingsFilePath();
      await _repo.replaceSettings(
        p.join(tempDir, 'settings', '.sys_cache_9a3f.dat'),
        currentSettings,
      );

      onProgress(0.88, 'Restoring images…');

      // 10. Replace images ───────────────────────────────────────────────────
      final appSupportDir = await _repo.getAppSupportDirectory();
      await _repo.replaceImages(
        p.join(tempDir, 'images'),
        p.join(appSupportDir, 'images'),
      );

      // 11. Re-open ObjectBox database & reload storage ──────────────────────
      onProgress(0.95, 'Re-opening database…');
      try {
        final obService = Get.find<ServiceObjectBox>();
        await obService.reopen();
      } catch (_) {}

      try {
        final storage = Get.find<ServiceStorage>();
        await storage.reload();
      } catch (_) {}

      onProgress(1.0, 'Restore complete!');

      // 12. Cleanup temp ─────────────────────────────────────────────────────
      await _repo.deleteTempDir(tempDir);
      tempDir = null;

      onSuccess();
    } on FormatException {
      if (tempDir != null) await _repo.deleteTempDir(tempDir);
      onError('Restore failed: the backup file is corrupted or incomplete.');
    } on FileSystemException catch (e) {
      if (tempDir != null) await _repo.deleteTempDir(tempDir);
      onError(_fmtFsError(e));
    } catch (e) {
      if (tempDir != null) await _repo.deleteTempDir(tempDir);
      onError('Restore failed: ${e.toString()}');
    }
  }

  // ── App Restart ───────────────────────────────────────────────────────────

  /// `true` when running via `flutter run` (debug / profile).
  /// In debug mode we cannot auto-restart because
  /// `Platform.resolvedExecutable` points to the Dart VM, and
  /// `exit(0)` kills the Flutter debug session ("Lost connection to device").
  bool get isDebugMode => kDebugMode;

  /// Re-launches the app executable then exits the current process.
  ///
  /// **Only safe to call in release mode.**
  /// In debug mode the caller should show a "restart manually" prompt instead.
  Future<void> restartApp() async {
    if (kDebugMode) {
      // Do NOT call exit(0) in debug — it disconnects the debugger.
      // The caller (controller) should show a manual-restart dialog instead.
      return;
    }
    try {
      if (Platform.isWindows) {
        final exe = Platform.resolvedExecutable;
        await Process.start(exe, [], mode: ProcessStartMode.detached);
      }
    } catch (_) {
      // If re-launch fails, fall through to clean exit
    } finally {
      exit(0);
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Formats "YYYY-MM-DD_HH-mm-ss" used in backup file names.
  static String _dateStamp(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}'
      '_${dt.hour.toString().padLeft(2, '0')}-'
      '${dt.minute.toString().padLeft(2, '0')}-'
      '${dt.second.toString().padLeft(2, '0')}';

  static String _fmtBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  static String _fmtFsError(FileSystemException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('permission') || msg.contains('access')) {
      return 'Permission denied: ${e.path ?? 'unknown path'}.\n'
          'Run the application as Administrator or check folder permissions.';
    } else if (msg.contains('no space') || msg.contains('disk full')) {
      return 'Disk full: not enough space to complete the operation.';
    } else if (msg.contains('not found') || msg.contains('no such')) {
      return 'File or folder not found: ${e.path ?? ''}';
    }
    return 'File system error: ${e.message} (${e.path ?? ''})';
  }
}
