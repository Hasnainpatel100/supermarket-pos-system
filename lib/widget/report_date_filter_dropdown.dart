import 'package:flutter/material.dart';
import '../enums/enum_report_date_filter.dart';

class ReportDateFilterDropdown extends StatelessWidget {
  final ReportDateFilter selectedFilter;
  final ValueChanged<ReportDateFilter> onFilterChanged;
  final VoidCallback onPickCustomRange;
  final Color themeColor;

  const ReportDateFilterDropdown({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onPickCustomRange,
    this.themeColor = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final effectiveColor = isDark
        ? (themeColor == Colors.indigo
            ? colorScheme.primary
            : Color.lerp(themeColor, Colors.white, 0.3) ?? themeColor)
        : themeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportDateFilter>(
          value: selectedFilter,
          isDense: true,
          dropdownColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: effectiveColor),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          items: ReportDateFilter.values.map((filter) {
            return DropdownMenuItem<ReportDateFilter>(
              value: filter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filter.icon, size: 16, color: effectiveColor),
                  const SizedBox(width: 8),
                  Text(
                    filter.label,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (ReportDateFilter? newFilter) {
            if (newFilter == null) return;
            if (newFilter == ReportDateFilter.custom) {
              onPickCustomRange();
            } else {
              onFilterChanged(newFilter);
            }
          },
        ),
      ),
    );
  }
}
