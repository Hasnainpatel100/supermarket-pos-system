import 'package:flutter/material.dart';

/// Primary action button used in appBar actions across list fragments.
/// Uses the theme's primary color with proper elevation and shadow.
///
/// Usage:
/// ```dart
/// PrimaryActionButton(
///   icon: Icons.add_circle_outline_rounded,
///   label: 'add_item'.tr,
///   onTap: () => Get.dialog(const ActivityItemForm()),
/// )
/// ```
class PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<Color>? gradientColors;

  const PrimaryActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.primary;
    final fg = foregroundColor ?? cs.onPrimary;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: bg.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action button for appBar - outlined style.
class SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;

  const SecondaryActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.padding,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: cs.onSurface),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Backwards-compatible alias for PrimaryActionButton.
typedef GradientActionButton = PrimaryActionButton;
