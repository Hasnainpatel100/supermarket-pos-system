import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../model/backup_history_item.dart';
import 'controller_backup.dart';

/// Backup & Recovery screen.
///
/// The controller is instantiated here lazily (no Binding class).
/// All business logic lives in [ControllerBackup] → [ServiceBackup].
class FragHomeBackup extends StatelessWidget {
  const FragHomeBackup({super.key});

  @override
  Widget build(BuildContext context) {
    // Lazy-put: created on first visit, auto-removed when not needed
    final controller = Get.put(ControllerBackup());
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.backup_outlined, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Backup & Recovery',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Status Card ───────────────────────────────────────────────────
          _StatusCard(controller: controller, isDark: isDark),
          const SizedBox(height: 20),

          // ── Quick Actions Row ──────────────────────────────────────────────
          _QuickActionsRow(controller: controller),
          const SizedBox(height: 20),

          // ── Backup Location Card ──────────────────────────────────────────
          _BackupLocationCard(controller: controller, isDark: isDark,
              colorScheme: colorScheme),
          const SizedBox(height: 20),

          // ── History ───────────────────────────────────────────────────────
          _BackupHistorySection(controller: controller, isDark: isDark,
              colorScheme: colorScheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final ControllerBackup controller;
  final bool isDark;
  const _StatusCard({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? cs.surfaceContainerHigh : cs.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          // Show progress overlay when backup/restore running
          if (controller.rxIsBackingUp.value || controller.rxIsRestoring.value) {
            return _ProgressView(controller: controller);
          }
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.shield_outlined, color: cs.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Protection',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final last = controller.rxLastBackupDate.value;
                      if (last == null) {
                        return Text(
                          'No backup created yet',
                          style: TextStyle(
                              color: cs.error, fontSize: 13),
                        );
                      }
                      final formatted =
                          DateFormat('dd MMM yyyy  hh:mm a').format(last);
                      return Text(
                        'Last backup: $formatted',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            fontSize: 13),
                      );
                    }),
                  ],
                ),
              ),
              Obx(() {
                final last = controller.rxLastBackupDate.value;
                final isOld = last != null &&
                    DateTime.now().difference(last).inDays > 7;
                return Icon(
                  last == null
                      ? Icons.warning_amber_rounded
                      : isOld
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                  color: last == null || isOld ? cs.error : Colors.green,
                  size: 28,
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS VIEW (shown inside status card while running)
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressView extends StatelessWidget {
  final ControllerBackup controller;
  const _ProgressView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => Text(
              controller.rxIsBackingUp.value ? 'Creating Backup…' : 'Restoring Backup…',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            )),
        const SizedBox(height: 10),
        Obx(() => LinearProgressIndicator(
              value: controller.rxProgress.value,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            )),
        const SizedBox(height: 8),
        Obx(() => Text(
              controller.rxProgressLabel.value,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final ControllerBackup controller;
  const _QuickActionsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => _ActionButton(
                icon: Icons.backup_outlined,
                label: 'Backup Now',
                color: Colors.green,
                loading: controller.rxIsBackingUp.value,
                disabled:
                    controller.rxIsBackingUp.value || controller.rxIsRestoring.value,
                onTap: controller.onBackupNow,
              )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => _ActionButton(
                icon: Icons.restore_outlined,
                label: 'Restore Backup',
                color: Colors.orange,
                loading: controller.rxIsRestoring.value,
                disabled:
                    controller.rxIsBackingUp.value || controller.rxIsRestoring.value,
                onTap: () => controller.onRestoreBackup(),
              )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.folder_open_outlined,
            label: 'Open Folder',
            color: Colors.blue,
            loading: false,
            disabled: false,
            onTap: controller.onOpenBackupFolder,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: disabled ? 0.08 : 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(color)),
                    )
                  : Icon(icon,
                      color: disabled ? color.withValues(alpha: 0.35) : color,
                      size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: disabled
                      ? color.withValues(alpha: 0.35)
                      : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKUP LOCATION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BackupLocationCard extends StatelessWidget {
  final ControllerBackup controller;
  final bool isDark;
  final ColorScheme colorScheme;

  const _BackupLocationCard({
    required this.controller,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Backup Location',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final loc = controller.rxBackupLocation.value;
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Text(
                  loc.isEmpty ? 'Not set — click Change to set a location' : loc,
                  style: TextStyle(
                    fontSize: 13,
                    color: loc.isEmpty
                        ? colorScheme.onSurface.withValues(alpha: 0.45)
                        : colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              );
            }),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: controller.onChangeBackupLocation,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Change Location'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKUP HISTORY SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _BackupHistorySection extends StatelessWidget {
  final ControllerBackup controller;
  final bool isDark;
  final ColorScheme colorScheme;

  const _BackupHistorySection({
    required this.controller,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Backup History',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final list = controller.rxHistory;
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'No backups yet.\nPress "Backup Now" to create your first backup.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            );
          }
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
              itemBuilder: (context, index) {
                final item = list[index];
                return _HistoryTile(
                  item: item,
                  controller: controller,
                  colorScheme: colorScheme,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY TILE
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final BackupHistoryItem item;
  final ControllerBackup controller;
  final ColorScheme colorScheme;

  const _HistoryTile({
    required this.item,
    required this.controller,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy  hh:mm a').format(item.createdAt);
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.archive_outlined,
            color: Colors.green, size: 22),
      ),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: TextStyle(fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.55))),
          Text(
            '${item.readableSize}  ·  ${item.path}',
            style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.45)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Restore
          Tooltip(
            message: 'Restore',
            child: IconButton(
              icon: const Icon(Icons.restore_outlined, size: 20),
              color: Colors.orange,
              onPressed: () =>
                  controller.onRestoreBackup(zipPath: item.path),
            ),
          ),
          // Open Folder
          Tooltip(
            message: 'Open Folder',
            child: IconButton(
              icon: const Icon(Icons.folder_open_outlined, size: 20),
              color: Colors.blue,
              onPressed: () => controller.onOpenFolderForItem(item),
            ),
          ),
          // Delete
          Tooltip(
            message: 'Delete',
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: colorScheme.error,
              onPressed: () => controller.onDeleteHistoryItem(item),
            ),
          ),
        ],
      ),
    );
  }
}
