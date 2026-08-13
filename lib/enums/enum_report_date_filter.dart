import 'package:flutter/material.dart';

enum ReportDateFilter {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  custom;

  String get label => switch (this) {
    ReportDateFilter.today     => 'Today',
    ReportDateFilter.yesterday => 'Yesterday',
    ReportDateFilter.thisWeek  => 'This Week',
    ReportDateFilter.thisMonth => 'This Month',
    ReportDateFilter.custom    => 'Custom Range',
  };

  IconData get icon => switch (this) {
    ReportDateFilter.today     => Icons.today_rounded,
    ReportDateFilter.yesterday => Icons.history_rounded,
    ReportDateFilter.thisWeek  => Icons.date_range_rounded,
    ReportDateFilter.thisMonth => Icons.calendar_month_rounded,
    ReportDateFilter.custom    => Icons.edit_calendar_rounded,
  };

  /// Computes (start, end) DateTime range for this preset.
  /// Returns null for `custom` as the user chooses custom dates.
  (DateTime start, DateTime end)? getDateRange() {
    final now = DateTime.now();
    switch (this) {
      case ReportDateFilter.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case ReportDateFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        final start = DateTime(y.year, y.month, y.day, 0, 0, 0, 0);
        final end = DateTime(y.year, y.month, y.day, 23, 59, 59, 999);
        return (start, end);
      case ReportDateFilter.thisWeek:
        final ws = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(ws.year, ws.month, ws.day, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case ReportDateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case ReportDateFilter.custom:
        return null;
    }
  }
}
