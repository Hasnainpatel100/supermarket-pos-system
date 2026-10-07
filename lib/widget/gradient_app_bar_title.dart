import 'package:flutter/material.dart';

/// Standard app-bar title used across list fragments (items, customers, suppliers, purchases).
///
/// Replaces the copy-pasted Container + LinearGradient + Icon + Column pattern
/// found in 8+ fragment files.
///
/// Usage:
/// ```dart
/// appBar: AppBar(
///   title: GradientAppBarTitle(
///     icon: Icons.inventory_2_rounded,
///     title: 'item_list_title'.tr,
///     subtitle: 'manage_inventory'.tr,
///     gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
///   ),
/// )
/// ```
class GradientAppBarTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Color> gradientColors;
  final Color? shadowColor;

  const GradientAppBarTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.gradientColors,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (shadowColor ?? gradientColors.first).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
