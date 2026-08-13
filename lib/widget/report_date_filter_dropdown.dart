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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportDateFilter>(
          value: selectedFilter,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: themeColor),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          items: ReportDateFilter.values.map((filter) {
            return DropdownMenuItem<ReportDateFilter>(
              value: filter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filter.icon, size: 16, color: themeColor),
                  const SizedBox(width: 8),
                  Text(filter.label),
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
