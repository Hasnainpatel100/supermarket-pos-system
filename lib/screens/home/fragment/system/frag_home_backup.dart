import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Placeholder backup/export fragment.
/// This screen will be expanded with actual backup functionality.
class FragHomeBackup extends StatelessWidget {
  const FragHomeBackup({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.backup_outlined, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            Text('Backup & Restore',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 72, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Backup & Restore',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Data backup and restore functionality coming soon.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export Data'),
              onPressed: () {
                Get.snackbar(
                  'Coming Soon',
                  'Data export will be available in a future update.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Import / Restore'),
              onPressed: () {
                Get.snackbar(
                  'Coming Soon',
                  'Data restore will be available in a future update.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
