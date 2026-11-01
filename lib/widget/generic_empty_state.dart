import 'package:flutter/material.dart';

/// Standard empty state widget for list views.
/// Clean, modern design with soft shadows and no gradients.
///
/// Usage:
/// ```dart
/// body: Obx(() => controller.rxList.isEmpty
///   ? const GenericEmptyState(
///       icon: Icons.inventory_2_outlined,
///       title: 'No items found',
///       subtitle: 'Add a new item to get started',
///     )
///   : _buildTable(),
/// )
/// ```
class GenericEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double iconSize;
  final Color? iconColor;

  const GenericEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconSize = 72,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconBgColor = iconColor ?? cs.secondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: iconBgColor.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(icon, size: iconSize, color: iconBgColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
