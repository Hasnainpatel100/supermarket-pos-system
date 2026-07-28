import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../enums/enum_audit_action.dart';
import '../../../../enums/enum_audit_module.dart';
import '../../../../model/entity_audit_log.dart';

class DialogAuditLogDetail extends StatelessWidget {
  final EntityAuditLog log;

  const DialogAuditLogDetail({super.key, required this.log});

  String _formatDate(int? ms) {
    if (ms == null) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm:ss a').format(dt);
  }

  String _prettyJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return 'No Data';
    try {
      final parsed = jsonDecode(rawJson);
      return const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {
      return rawJson;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionEnum = log.auditAction;
    final moduleEnum = log.auditModule;
    final actionColor = actionEnum != null ? Color(actionEnum.colorValue) : theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.history_rounded, color: actionColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audit Log Detail #${log.id}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${log.objectId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── Metadata Grid ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        _buildMetaItem(
                          context,
                          icon: Icons.calendar_today_outlined,
                          label: 'Timestamp',
                          value: _formatDate(log.createdAtUtcMs),
                        ),
                        _buildMetaItem(
                          context,
                          icon: Icons.person_outline,
                          label: 'User',
                          value: log.userName ?? 'System',
                          badge: log.userId != null ? 'ID: ${log.userId}' : null,
                        ),
                        _buildMetaItem(
                          context,
                          icon: Icons.view_module_outlined,
                          label: 'Module',
                          value: moduleEnum?.label ?? (log.module ?? '-'),
                        ),
                        _buildMetaItem(
                          context,
                          icon: Icons.flash_on_outlined,
                          label: 'Action',
                          value: actionEnum?.label ?? (log.action ?? '-'),
                          valueColor: actionColor,
                        ),
                        _buildMetaItem(
                          context,
                          icon: Icons.category_outlined,
                          label: 'Entity',
                          value: '${log.entityType ?? "-"} ${log.entityId != null ? "#${log.entityId}" : ""}',
                        ),
                        if (log.branchId != null && log.branchId!.isNotEmpty)
                          _buildMetaItem(
                            context,
                            icon: Icons.store_outlined,
                            label: 'Branch ID',
                            value: log.branchId!,
                          ),
                      ],
                    ),

                    if (log.reason != null && log.reason!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Reason: ${log.reason}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Description Box ──
                    Text(
                      'Description',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log.description ?? 'No description provided.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── JSON Diff Section (Old Data vs New Data) ──
                    Text(
                      'Data Changes Snapshot',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 550;
                        final oldWidget = _buildJsonBox(
                          context,
                          title: 'Old Data (Before)',
                          jsonText: _prettyJson(log.oldData),
                          color: Colors.red,
                        );
                        final newWidget = _buildJsonBox(
                          context,
                          title: 'New Data (After)',
                          jsonText: _prettyJson(log.newData),
                          color: Colors.green,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: oldWidget),
                              const SizedBox(width: 14),
                              Expanded(child: newWidget),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              oldWidget,
                              const SizedBox(height: 14),
                              newWidget,
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badge, style: theme.textTheme.labelSmall),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJsonBox(
    BuildContext context, {
    required String title,
    required String jsonText,
    required MaterialColor color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? color.shade200 : color.shade800,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(
                jsonText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
