import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';

import '../../../../enums/enum_audit_action.dart';
import '../../../../enums/enum_audit_module.dart';
import '../../../../model/entity_audit_log.dart';
import '../../../../model/entity_user.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../service/service_object_box.dart';

enum AuditDatePreset {
  allTime,
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  custom,
}

extension AuditDatePresetLabel on AuditDatePreset {
  String get label => switch (this) {
        AuditDatePreset.allTime => 'All Time',
        AuditDatePreset.today => 'Today',
        AuditDatePreset.yesterday => 'Yesterday',
        AuditDatePreset.last7Days => 'Last 7 Days',
        AuditDatePreset.last30Days => 'Last 30 Days',
        AuditDatePreset.thisMonth => 'This Month',
        AuditDatePreset.custom => 'Custom Range...',
      };
}

class ControllerAuditLogs extends GetxController {
  late final Box<EntityAuditLog> _boxAuditLog;
  late final Box<EntityUser> _boxUser;

  // ── Date Preset & Range ──
  final rxDatePreset = AuditDatePreset.allTime.obs;
  final rxFromDate = Rxn<DateTime>();
  final rxToDate = Rxn<DateTime>();

  // ── Filters ──
  final rxSelectedUserId = RxnInt(); // null = All
  final rxSelectedModule = Rxn<AuditModule>(); // null = All
  final rxSelectedAction = Rxn<AuditAction>(); // null = All
  final rxSearchQuery = ''.obs;
  final searchController = TextEditingController();

  // ── Available Users for Filter Dropdown ──
  final rxUserList = <EntityUser>[].obs;

  // ── Pagination ──
  final rxPageSize = 15.obs;
  final currentPage = 0.obs;
  final totalCount = 0.obs;
  final rxListLogs = <EntityAuditLog>[].obs;
  final rxIsExporting = false.obs;

  int get totalPages => (totalCount.value / rxPageSize.value).ceil();
  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * rxPageSize.value < totalCount.value;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxAuditLog = ob.box<EntityAuditLog>();
    _boxUser = ob.box<EntityUser>();

    loadUsers();
    loadLogs();

    // Debounce text search for responsive typing
    debounce(
      rxSearchQuery,
      (_) {
        currentPage.value = 0;
        loadLogs();
      },
      time: const Duration(milliseconds: 300),
    );
  }

  void loadUsers() {
    final users = _boxUser.query().order(EntityUser_.username).build().find();
    rxUserList.assignAll(users);
  }

  void setDatePreset(AuditDatePreset preset, {DateTimeRange? customRange}) {
    rxDatePreset.value = preset;
    final now = DateTime.now();

    switch (preset) {
      case AuditDatePreset.allTime:
        rxFromDate.value = null;
        rxToDate.value = null;
        break;
      case AuditDatePreset.today:
        rxFromDate.value = DateTime(now.year, now.month, now.day);
        rxToDate.value = DateTime(now.year, now.month, now.day);
        break;
      case AuditDatePreset.yesterday:
        final y = now.subtract(const Duration(days: 1));
        rxFromDate.value = DateTime(y.year, y.month, y.day);
        rxToDate.value = DateTime(y.year, y.month, y.day);
        break;
      case AuditDatePreset.last7Days:
        final start = now.subtract(const Duration(days: 6));
        rxFromDate.value = DateTime(start.year, start.month, start.day);
        rxToDate.value = DateTime(now.year, now.month, now.day);
        break;
      case AuditDatePreset.last30Days:
        final start = now.subtract(const Duration(days: 29));
        rxFromDate.value = DateTime(start.year, start.month, start.day);
        rxToDate.value = DateTime(now.year, now.month, now.day);
        break;
      case AuditDatePreset.thisMonth:
        rxFromDate.value = DateTime(now.year, now.month, 1);
        rxToDate.value = DateTime(now.year, now.month, now.day);
        break;
      case AuditDatePreset.custom:
        if (customRange != null) {
          rxFromDate.value = customRange.start;
          rxToDate.value = customRange.end;
        }
        break;
    }

    currentPage.value = 0;
    loadLogs();
  }

  /// Label string displayed on the inline Date Range button
  String get dateRangeDisplayLabel {
    if (rxFromDate.value == null && rxToDate.value == null) {
      return 'Date Range';
    }
    final from = rxFromDate.value;
    final to = rxToDate.value;

    if (from != null && to != null) {
      final fStr = DateFormat('dd MMM').format(from);
      final tStr = DateFormat('dd MMM yyyy').format(to);
      if (from.year == to.year && from.month == to.month && from.day == to.day) {
        return DateFormat('dd MMM yyyy').format(from);
      }
      return '$fStr - $tStr';
    }
    if (from != null) return 'From ${DateFormat("dd MMM yyyy").format(from)}';
    if (to != null) return 'To ${DateFormat("dd MMM yyyy").format(to)}';
    return 'Date Range';
  }

  /// Builds a native ObjectBox [Condition] based on current active filters.
  Condition<EntityAuditLog>? _buildFilterCondition() {
    Condition<EntityAuditLog>? condition;

    // 1. Date Range Filter
    if (rxFromDate.value != null) {
      final startMs = DateTime(
        rxFromDate.value!.year,
        rxFromDate.value!.month,
        rxFromDate.value!.day,
      ).toUtc().millisecondsSinceEpoch;
      condition = EntityAuditLog_.createdAtUtcMs.greaterOrEqual(startMs);
    }

    if (rxToDate.value != null) {
      final endMs = DateTime(
        rxToDate.value!.year,
        rxToDate.value!.month,
        rxToDate.value!.day,
        23,
        59,
        59,
        999,
      ).toUtc().millisecondsSinceEpoch;
      final cond = EntityAuditLog_.createdAtUtcMs.lessOrEqual(endMs);
      condition = condition != null ? condition.and(cond) : cond;
    }

    // 2. User Filter
    if (rxSelectedUserId.value != null) {
      final cond = EntityAuditLog_.userId.equals(rxSelectedUserId.value!);
      condition = condition != null ? condition.and(cond) : cond;
    }

    // 3. Module Filter
    if (rxSelectedModule.value != null) {
      final cond = EntityAuditLog_.module.equals(rxSelectedModule.value!.name);
      condition = condition != null ? condition.and(cond) : cond;
    }

    // 4. Action Filter
    if (rxSelectedAction.value != null) {
      final cond = EntityAuditLog_.action.equals(rxSelectedAction.value!.name);
      condition = condition != null ? condition.and(cond) : cond;
    }

    // 5. Search Query Filter
    final q = rxSearchQuery.value.trim();
    if (q.isNotEmpty) {
      final searchCond = EntityAuditLog_.description
          .contains(q, caseSensitive: false)
          .or(EntityAuditLog_.userName.contains(q, caseSensitive: false))
          .or(EntityAuditLog_.entityType.contains(q, caseSensitive: false))
          .or(EntityAuditLog_.entityId.contains(q, caseSensitive: false))
          .or(EntityAuditLog_.reason.contains(q, caseSensitive: false));

      condition = condition != null ? condition.and(searchCond) : searchCond;
    }

    return condition;
  }

  /// High-performance paginated ObjectBox database query execution.
  void loadLogs() {
    final condition = _buildFilterCondition();
    final builder = condition != null
        ? _boxAuditLog.query(condition)
        : _boxAuditLog.query();

    builder.order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending);

    final query = builder.build();

    // Native C-level total count
    totalCount.value = query.count();

    // Native C-level database offset and limit (zero RAM overhead for large datasets)
    query
      ..offset = currentPage.value * rxPageSize.value
      ..limit = rxPageSize.value;

    rxListLogs.assignAll(query.find());
    query.close();
  }

  void setPageSize(int size) {
    rxPageSize.value = size;
    currentPage.value = 0;
    loadLogs();
  }

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      loadLogs();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      loadLogs();
    }
  }

  void setSelectedUser(int? userId) {
    rxSelectedUserId.value = userId;
    currentPage.value = 0;
    loadLogs();
  }

  void setSelectedModule(AuditModule? module) {
    rxSelectedModule.value = module;
    currentPage.value = 0;
    loadLogs();
  }

  void setSelectedAction(AuditAction? action) {
    rxSelectedAction.value = action;
    currentPage.value = 0;
    loadLogs();
  }

  void updateSearch(String val) {
    rxSearchQuery.value = val;
  }

  void clearFilters() {
    searchController.clear();
    rxSearchQuery.value = '';
    rxDatePreset.value = AuditDatePreset.allTime;
    rxFromDate.value = null;
    rxToDate.value = null;
    rxSelectedUserId.value = null;
    rxSelectedModule.value = null;
    rxSelectedAction.value = null;
    currentPage.value = 0;
    loadLogs();
  }

  /// Exports filtered audit logs to Excel workbook using existing [ServiceItemExcel] framework.
  Future<void> exportToExcel() async {
    rxIsExporting.value = true;
    try {
      final condition = _buildFilterCondition();
      final builder = condition != null
          ? _boxAuditLog.query(condition)
          : _boxAuditLog.query();

      builder.order(EntityAuditLog_.createdAtUtcMs, flags: Order.descending);
      final query = builder.build();
      final allFiltered = query.find();
      query.close();

      if (allFiltered.isEmpty) {
        Get.snackbar(
          'No Data',
          'No audit logs match current filters to export.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final headers = [
        'Log ID',
        'Date & Time',
        'User',
        'Module',
        'Action',
        'Entity Type',
        'Entity ID',
        'Description',
        'Reason',
      ];

      final rows = allFiltered.map((l) {
        return [
          l.id,
          formatDate(l.createdAtUtcMs),
          l.userName ?? 'System',
          l.auditModule?.label ?? (l.module ?? '-'),
          l.auditAction?.label ?? (l.action ?? '-'),
          l.entityType ?? '-',
          l.entityId ?? '-',
          l.description ?? '-',
          l.reason ?? '-',
        ];
      }).toList();

      final filterSummary = <String, String>{};
      if (rxFromDate.value != null && rxToDate.value != null) {
        filterSummary['Date Range'] = dateRangeDisplayLabel;
      }
      if (rxSelectedUserId.value != null) {
        final u = rxUserList.firstWhereOrNull((u) => u.id == rxSelectedUserId.value);
        filterSummary['User'] = u?.username ?? 'User #${rxSelectedUserId.value}';
      }
      if (rxSelectedModule.value != null) {
        filterSummary['Module'] = rxSelectedModule.value!.label;
      }
      if (rxSelectedAction.value != null) {
        filterSummary['Action'] = rxSelectedAction.value!.label;
      }
      if (rxSearchQuery.value.trim().isNotEmpty) {
        filterSummary['Search'] = rxSearchQuery.value.trim();
      }

      final excelService = ServiceItemExcel();
      final success = await excelService.exportReport(
        title: 'Audit Logs Report',
        headers: headers,
        rows: rows,
        appliedFilters: filterSummary.isNotEmpty ? filterSummary : {'Filters': 'All Records'},
        summaryData: {
          'Total Audit Logs': allFiltered.length,
          'Exported At': DateFormat('dd MMM yyyy hh:mm a').format(DateTime.now()),
        },
      );

      if (success) {
        Get.snackbar(
          'Export Successful',
          'Exported ${allFiltered.length} audit log records to Excel.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Export Failed',
        'An error occurred while exporting logs: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      rxIsExporting.value = false;
    }
  }

  String formatDate(int? ms) {
    if (ms == null) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
