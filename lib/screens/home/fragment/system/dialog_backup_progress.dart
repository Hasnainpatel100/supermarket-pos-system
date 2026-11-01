import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller_backup.dart';

/// Blocking loading dialog shown while a backup is being created or restored.
///
/// It cannot be dismissed by the user; [ControllerBackup] closes it when the
/// operation finishes, fails, or needs the user's confirmation.
class DialogBackupProgress extends StatelessWidget {
  final ControllerBackup controller;

  const DialogBackupProgress({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Obx(() {
              final isBackup = controller.rxIsBackingUp.value;
              final accent = isBackup ? Colors.green.shade600 : Colors.orange.shade700;
              final progress = controller.rxProgress.value.clamp(0.0, 1.0).toDouble();
              final percent = (progress * 100).round();
              final label = controller.rxProgressLabel.value;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            color: accent,
                            backgroundColor: accent.withValues(alpha: 0.12),
                          ),
                        ),
                        Icon(
                          isBackup ? Icons.backup_outlined : Icons.restore_outlined,
                          size: 34,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isBackup ? 'Creating Backup' : 'Restoring Backup',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBackup
                        ? 'Your data is being compressed into a backup file.'
                        : 'Your data is being restored from the backup file.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Keep the application open until this finishes.',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
