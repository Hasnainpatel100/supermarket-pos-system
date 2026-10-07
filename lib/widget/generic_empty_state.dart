import 'package:flutter/material.dart';

/// Standard empty state widget for list views.
///
/// Replaces the copy-pasted Center > Column > gradient icon circle + title/subtitle
/// pattern found in 10+ fragment files.
///
/// Usage:
/// ```dart
/// body: Obx(() => controller.rxList.isEmpty
///   ? const GenericEmptyState(
///       icon: Icons.inventory_2_outlined,
///       title: 'No items found',
///       subtitle: 'Add a new item to get started',
///       gradientColors: [Colors.blue.shade100, Colors.cyan.shade100],
///     )
///   : _buildTable(),
/// )
/// ```
class GenericEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Color> gradientColors;
  final double iconSize;
  final Color? iconColor;

  const GenericEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.gradientColors,
    this.iconSize = 64,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, size: iconSize, color: iconColor ?? gradientColors.last),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}
