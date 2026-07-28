import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../model/entity_audit_log.dart';
import '../../../../service/service_audit_log.dart';

/// Audit Logs viewer fragment.
/// Displays all audit log entries stored in the local ObjectBox database.
class FragAuditLogs extends StatefulWidget {
  const FragAuditLogs({super.key});

  @override
  State<FragAuditLogs> createState() => _FragAuditLogsState();
}

class _FragAuditLogsState extends State<FragAuditLogs> {
  late List<EntityAuditLog> _logs;
  String _searchQuery = '';
  String? _selectedModule;

  final List<String> _modules = [
    'All',
    'pos',
    'item',
    'inventory',
    'stock',
    'customer',
    'purchase',
    'supplier',
    'user',
    'system',
    'finance',
    'expenses',
    'settings',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _logs = AuditLogService.instance.getAll();
  }

  List<EntityAuditLog> get _filtered {
    return _logs.where((log) {
      final matchModule = _selectedModule == null ||
          _selectedModule == 'All' ||
          (log.module?.toLowerCase() == _selectedModule!.toLowerCase());

      final query = _searchQuery.toLowerCase();
      final matchSearch = query.isEmpty ||
          (log.description?.toLowerCase().contains(query) ?? false) ||
          (log.module?.toLowerCase().contains(query) ?? false) ||
          (log.action?.toLowerCase().contains(query) ?? false) ||
          (log.entityType?.toLowerCase().contains(query) ?? false);

      return matchModule && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.history, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            const Text('Audit Logs',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(_loadLogs),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + filter bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search logs…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedModule ?? 'All',
                  borderRadius: BorderRadius.circular(10),
                  items: _modules
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedModule = v),
                ),
              ],
            ),
          ),

          // ── Log count ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} entries',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // ── Log list ───────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off,
                            size: 64,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'No audit logs found',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => _LogTile(log: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final EntityAuditLog log;
  const _LogTile({required this.log});

  Color _actionColor(BuildContext context, String? action) {
    final cs = Theme.of(context).colorScheme;
    switch (action?.toLowerCase()) {
      case 'create':
        return Colors.green.shade700;
      case 'update':
        return cs.primary;
      case 'delete':
        return cs.error;
      case 'login':
        return Colors.teal.shade600;
      case 'logout':
        return Colors.orange.shade700;
      default:
        return cs.onSurface;
    }
  }

  IconData _actionIcon(String? action) {
    switch (action?.toLowerCase()) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'print':
        return Icons.print_outlined;
      case 'export':
        return Icons.upload_file_outlined;
      case 'cancel':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dt = DateTime.fromMillisecondsSinceEpoch(log.createdAtUtcMs,
        isUtc: true).toLocal();
    final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _actionColor(context, log.action).withValues(alpha: 0.12),
          child: Icon(
            _actionIcon(log.action),
            color: _actionColor(context, log.action),
            size: 20,
          ),
        ),
        title: Text(
          log.description ?? '${log.action ?? 'action'} on ${log.entityType ?? 'entity'}',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (log.module != null) ...[
              _Chip(label: log.module!, color: colorScheme.primaryContainer),
              const SizedBox(width: 6),
            ],
            if (log.action != null) ...[
              _Chip(
                  label: log.action!,
                  color: _actionColor(context, log.action)
                      .withValues(alpha: 0.15)),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                timeStr,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        onTap: () => _showDetail(context, log),
      ),
    );
  }

  void _showDetail(BuildContext context, EntityAuditLog log) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Audit Log Detail'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Module', log.module),
              _DetailRow('Action', log.action),
              _DetailRow('Entity Type', log.entityType),
              _DetailRow('Entity ID', log.entityId),
              _DetailRow('Description', log.description),
              _DetailRow('Reason', log.reason),
              if (log.oldData != null) _DetailRow('Old Data', log.oldData),
              if (log.newData != null) _DetailRow('New Data', log.newData),
              _DetailRow('User ID', log.userId?.toString()),
              _DetailRow('Username', log.userName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(value!, style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 12),
        ],
      ),
    );
  }
}
