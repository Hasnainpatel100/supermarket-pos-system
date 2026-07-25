import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../enums/enum_audit_action.dart';
import '../../../../enums/enum_audit_module.dart';
import '../../../../enums/enum_permission.dart';
import '../../controller_home.dart';
import 'controller_audit_logs.dart';
import 'dialog_audit_log_detail.dart';

class FragAuditLogs extends StatelessWidget {
  const FragAuditLogs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Permission Gate ──
    final controllerHome = Get.isRegistered<ControllerHome>() ? Get.find<ControllerHome>() : null;
    final hasPermission = controllerHome != null ? controllerHome.can(EnumPermission.auditLogView) : true;

    if (!hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.gavel_rounded,
                size: 72,
                color: theme.colorScheme.error.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission (auditLogView) to view system audit logs.\nContact your administrator to request access.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = Get.put(ControllerAuditLogs());

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Bar ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit Logs',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Immutable, tamper-resistant event trail for security, actions, and compliance.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Obx(() => Chip(
                      avatar: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text('${controller.totalCount.value} Logs'),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    )),
              ],
            ),

            const SizedBox(height: 16),

            // ── Unified Single-Row Filters Bar ──
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 1. Inline Date Range Dropdown with Presets
                      _buildDateRangePickerDropdown(context, controller),

                      const SizedBox(width: 10),

                      // 2. User Dropdown
                      Obx(() {
                        final users = controller.rxUserList;
                        return Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: controller.rxSelectedUserId.value,
                              hint: const Text('All Users'),
                              isDense: true,
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('All Users'),
                                ),
                                ...users.map((u) => DropdownMenuItem<int?>(
                                      value: u.id,
                                      child: Text(u.username ?? 'User #${u.id}'),
                                    )),
                              ],
                              onChanged: controller.setSelectedUser,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(width: 10),

                      // 3. Module Dropdown
                      Obx(() {
                        return Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AuditModule?>(
                              value: controller.rxSelectedModule.value,
                              hint: const Text('All Modules'),
                              isDense: true,
                              items: [
                                const DropdownMenuItem<AuditModule?>(
                                  value: null,
                                  child: Text('All Modules'),
                                ),
                                ...AuditModule.values.map((m) => DropdownMenuItem<AuditModule?>(
                                      value: m,
                                      child: Text(m.label),
                                    )),
                              ],
                              onChanged: controller.setSelectedModule,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(width: 10),

                      // 4. Action Dropdown
                      Obx(() {
                        return Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AuditAction?>(
                              value: controller.rxSelectedAction.value,
                              hint: const Text('All Actions'),
                              isDense: true,
                              items: [
                                const DropdownMenuItem<AuditAction?>(
                                  value: null,
                                  child: Text('All Actions'),
                                ),
                                ...AuditAction.values.map((a) => DropdownMenuItem<AuditAction?>(
                                      value: a,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Color(a.colorValue),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(a.label),
                                        ],
                                      ),
                                    )),
                              ],
                              onChanged: controller.setSelectedAction,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(width: 10),

                      // 5. Search Bar
                      SizedBox(
                        width: 220,
                        height: 38,
                        child: TextField(
                          controller: controller.searchController,
                          onChanged: controller.updateSearch,
                          decoration: InputDecoration(
                            hintText: 'Search logs...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: Obx(() => controller.rxSearchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      controller.searchController.clear();
                                      controller.updateSearch('');
                                    },
                                  )
                                : const SizedBox.shrink()),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 6. Reset Filters Button
                      IconButton(
                        onPressed: controller.clearFilters,
                        icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                        tooltip: 'Reset Filters',
                      ),

                      const SizedBox(width: 6),

                      // 7. Export Excel Button
                      Obx(() {
                        final isExporting = controller.rxIsExporting.value;
                        return FilledButton.icon(
                          onPressed: isExporting ? null : controller.exportToExcel,
                          icon: isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.explicit_outlined, size: 18),
                          label: Text(isExporting ? 'Exporting...' : 'Export Excel'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Paginated Audit Log Table ──
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Obx(() {
                  final logs = controller.rxListLogs;
                  final searchQ = controller.rxSearchQuery.value;

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No audit logs found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your search criteria or date filters.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 170, child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 140, child: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 110, child: Text('Module', style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 110, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 140, child: Text('Entity', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Table ListView
                      Expanded(
                        child: ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final actionEnum = log.auditAction;
                            final actionColor = actionEnum != null
                                ? Color(actionEnum.colorValue)
                                : theme.colorScheme.primary;

                            final entityStr = '${log.entityType ?? "-"}${log.entityId != null ? " #${log.entityId}" : ""}';

                            return InkWell(
                              onTap: () {
                                Get.dialog(DialogAuditLogDetail(log: log));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    // Date & Time
                                    SizedBox(
                                      width: 170,
                                      child: Text(
                                        controller.formatDate(log.createdAtUtcMs),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),

                                    // User (With Highlighted Text)
                                    SizedBox(
                                      width: 140,
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _buildHighlightedText(
                                              log.userName ?? 'System',
                                              searchQ,
                                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Module
                                    SizedBox(
                                      width: 110,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            log.auditModule?.label ?? (log.module ?? '-'),
                                            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Action Badge
                                    SizedBox(
                                      width: 110,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: actionColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            actionEnum?.label ?? (log.action ?? '-'),
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: actionColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Entity (With Highlighted Text)
                                    SizedBox(
                                      width: 140,
                                      child: _buildHighlightedText(
                                        entityStr,
                                        searchQ,
                                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                                      ),
                                    ),

                                    // Description (With Highlighted Text)
                                    Expanded(
                                      child: _buildHighlightedText(
                                        log.description ?? '-',
                                        searchQ,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            // ── Pagination Footer ──
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Obx(() {
                  final page = controller.currentPage.value + 1;
                  final totalPages = controller.totalPages == 0 ? 1 : controller.totalPages;

                  return Row(
                    children: [
                      Text(
                        'Showing ${controller.rxListLogs.length} of ${controller.totalCount.value} logs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),

                      // Rows per page
                      Text('Rows per page:', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: controller.rxPageSize.value,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 15, child: Text('15')),
                          DropdownMenuItem(value: 25, child: Text('25')),
                          DropdownMenuItem(value: 50, child: Text('50')),
                          DropdownMenuItem(value: 100, child: Text('100')),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.setPageSize(val);
                        },
                      ),

                      const SizedBox(width: 24),

                      // Prev & Next Buttons
                      IconButton(
                        onPressed: controller.hasPrev ? controller.prevPage : null,
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Previous Page',
                      ),
                      Text(
                        'Page $page of $totalPages',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        onPressed: controller.hasNext ? controller.nextPage : null,
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Next Page',
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact inline Date Range Dropdown Button with Quick Presets
  Widget _buildDateRangePickerDropdown(
    BuildContext context,
    ControllerAuditLogs controller,
  ) {
    final theme = Theme.of(context);
    return Obx(() {
      final label = controller.dateRangeDisplayLabel;
      final hasDateFilter = controller.rxFromDate.value != null || controller.rxToDate.value != null;

      return PopupMenuButton<AuditDatePreset>(
        tooltip: 'Select Date Range',
        onSelected: (preset) async {
          if (preset == AuditDatePreset.custom) {
            final now = DateTime.now();
            final initialRange = (controller.rxFromDate.value != null && controller.rxToDate.value != null)
                ? DateTimeRange(start: controller.rxFromDate.value!, end: controller.rxToDate.value!)
                : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

            final picked = await showDateRangePicker(
              context: context,
              initialDateRange: initialRange,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              controller.setDatePreset(AuditDatePreset.custom, customRange: picked);
            }
          } else {
            controller.setDatePreset(preset);
          }
        },
        itemBuilder: (context) => [
          ...AuditDatePreset.values.map((p) => PopupMenuItem<AuditDatePreset>(
                value: p,
                child: Row(
                  children: [
                    Icon(
                      controller.rxDatePreset.value == p
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 16,
                      color: controller.rxDatePreset.value == p
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(p.label),
                  ],
                ),
              )),
        ],
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasDateFilter ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
            color: hasDateFilter ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: hasDateFilter ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasDateFilter ? FontWeight.bold : FontWeight.normal,
                  color: hasDateFilter ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: hasDateFilter ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Highlight matching search substring in cell text
  Widget _buildHighlightedText(
    String text,
    String query, {
    TextStyle? style,
  }) {
    final trimmedQ = query.trim();
    if (trimmedQ.isEmpty) {
      return Text(text, style: style, overflow: TextOverflow.ellipsis, maxLines: 1);
    }

    final lowerText = text.toLowerCase();
    final lowerQ = trimmedQ.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index;

    while ((index = lowerText.indexOf(lowerQ, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + lowerQ.length),
        style: (style ?? const TextStyle()).copyWith(
          backgroundColor: Colors.amber.shade200,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + lowerQ.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
