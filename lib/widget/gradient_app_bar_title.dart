import 'package:flutter/material.dart';

/// Standard app-bar title used across list fragments (items, customers, suppliers, purchases).
///
/// Usage:
/// ```dart
/// appBar: AppBar(
///   title: AppBarTitle(
///     icon: Icons.inventory_2_rounded,
///     title: 'item_list_title'.tr,
///     subtitle: 'manage_inventory'.tr,
///   ),
/// )
/// ```
class AppBarTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const AppBarTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = iconBackgroundColor ?? cs.secondaryContainer;
    final fg = iconColor ?? cs.secondary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: fg, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                color: cs.onSurface,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
