import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/backup_history_item.dart';
import '../../../../model/backup_info.dart';
import '../../../../service/service_backup.dart';
import '../../../../service/service_storage.dart';
import '../../controller_home.dart';

/// GetX controller that owns all reactive state for the Backup & Recovery UI.
///
/// Business logic is in [ServiceBackup].
/// This controller only wires UI → service → reactive state.
class ControllerBackup extends GetxController {
  late final ServiceBackup _service;

  // ── Reactive State ─────────────────────────────────────────────────────────

  final rxIsBackingUp   = false.obs;
  final rxIsRestoring   = false.obs;
  final rxProgress      = 0.0.obs;  // 0.0 – 1.0
  final rxProgressLabel = ''.obs;
  final rxBackupLocation = ''.obs;
  final rxHistory       = <BackupHistoryItem>[].obs;
  final rxLastBackupDate = Rx<DateTime?>(null);
  final rxError         = ''.obs;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _service = ServiceBackup(storage: Get.find<ServiceStorage>());
    _loadInitial();
  }

  void _loadInitial() {
    rxBackupLocation.value = _service.getSavedBackupLocation() ?? '';
    _refreshHistory();
  }

  void _refreshHistory() {
    final list = _service.getHistory();
    rxHistory.assignAll(list);
    if (list.isNotEmpty) {
      rxLastBackupDate.value = list.first.createdAt;
    }
  }

  // ── Backup Now ────────────────────────────────────────────────────────────

  Future<void> onBackupNow() async {
    if (rxIsBackingUp.value || rxIsRestoring.value) return;

    rxIsBackingUp.value = true;
    rxProgress.value    = 0.0;
    rxProgressLabel.value = 'Starting backup…';
    rxError.value = '';

    await _service.backupNow(
      onProgress: (progress, label) {
        rxProgress.value      = progress;
        rxProgressLabel.value = label;
      },
      onSuccess: (item) {
        rxIsBackingUp.value = false;
        rxBackupLocation.value = _service.getSavedBackupLocation() ?? '';
        _refreshHistory();
        _showSuccess(
          'Backup Created',
          '${item.name} (${item.readableSize})\nSaved to: ${item.path}',
        );
      },
      onError: (error) {
        rxIsBackingUp.value = false;
        rxError.value = error;
        _showError('Backup Failed', error);
      },
    );
  }

  // ── Restore (from file picker) ─────────────────────────────────────────────

  Future<void> onRestoreBackup({String? zipPath}) async {
    if (rxIsBackingUp.value || rxIsRestoring.value) return;

    rxIsRestoring.value   = true;
    rxProgress.value      = 0.0;
    rxProgressLabel.value = 'Preparing restore…';
    rxError.value = '';

    await _service.restoreBackup(
      preselectedZipPath: zipPath,
      onProgress: (progress, label) {
        rxProgress.value      = progress;
        rxProgressLabel.value = label;
      },
      onValidated: (BackupInfo info) async {
        // Show confirmation dialog
        final result = await Get.dialog<bool>(
          _RestoreConfirmDialog(info: info),
          barrierDismissible: false,
        );
        return result == true;
      },
      onSuccess: () {
        rxIsRestoring.value = false;
        _showRestartDialog();
      },
      onError: (error) {
        rxIsRestoring.value = false;
        if (!error.contains('cancelled')) {
          rxError.value = error;
          _showError('Restore Failed', error);
        }
      },
    );
  }

  // ── Change Backup Location ─────────────────────────────────────────────────

  Future<void> onChangeBackupLocation() async {
    final picked = await _service.changeBackupLocation();
    if (picked != null) {
      rxBackupLocation.value = picked;
      _showSuccess(
        'Backup Location Updated',
        'New location:\n$picked',
      );
    }
  }

  // ── Open Backup Folder ────────────────────────────────────────────────────

  Future<void> onOpenBackupFolder() async {
    await _service.openBackupFolder(
      onError: (error) => _showError('Cannot Open Folder', error),
    );
  }

  // ── Open Folder for a history item ───────────────────────────────────────

  Future<void> onOpenFolderForItem(BackupHistoryItem item) async {
    await _service.openFolderForItem(
      item: item,
      onError: (error) => _showError('Cannot Open Folder', error),
    );
  }

  // ── Delete history item ───────────────────────────────────────────────────

  Future<void> onDeleteHistoryItem(BackupHistoryItem item) async {
    // Confirm dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Backup?'),
        content: Text(
          'Are you sure you want to permanently delete:\n${item.name}\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _service.deleteBackup(
      item: item,
      onError: (error) => _showError('Delete Failed', error),
    );
    _refreshHistory();
  }

  // ── Restart App ───────────────────────────────────────────────────────────

  Future<void> _restartApp() async {
    await _service.restartApp();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  void _showError(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          FilledButton(
            onPressed: Get.back,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    // In debug mode: show "restart manually" prompt (exit(0) would kill the debugger).
    // In release mode: show "Restart Now" and auto-relaunch.
    final isDebug = _service.isDebugMode;

    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Restore Complete'),
          ],
        ),
        content: Text(
          isDebug
              ? 'The backup has been restored successfully.\n\n'
                'You are running in debug mode.\n'
                'Please stop the app and re-run it to apply the restored data.'
              : 'The backup has been restored successfully.\n\n'
                'The application will now restart to apply the changes.',
        ),
        actions: [
          if (isDebug) ...[
            TextButton(
              onPressed: () {
                Get.back();
                _refreshAppStates();
              },
              child: const Text('Reload UI Now'),
            ),
            FilledButton(
              onPressed: () {
                Get.back();
                _refreshAppStates();
              },
              child: const Text('OK'),
            ),
          ] else
            FilledButton(
              onPressed: _restartApp,
              child: const Text('Restart Now'),
            ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _refreshAppStates() {
    _loadInitial();
    if (Get.isRegistered<ControllerHome>()) {
      Get.find<ControllerHome>().getUserDetails();
    }
  }
}

// ── Restore Confirmation Dialog ───────────────────────────────────────────────

class _RestoreConfirmDialog extends StatelessWidget {
  final BackupInfo info;
  const _RestoreConfirmDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restore, color: Colors.orange),
          SizedBox(width: 8),
          Text('Restore Backup?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The following backup will be restored. '
            'All current data will be replaced.\n',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          _infoRow('App Version', info.appVersion),
          _infoRow('Backup Date', info.backupDate),
          _infoRow('Store Name', info.storeName),
          _infoRow('Device', info.device),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone. The app will restart automatically.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Get.back(result: true),
          style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error),
          child: const Text('Restore'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
