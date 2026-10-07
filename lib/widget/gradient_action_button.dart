import 'package:flutter/material.dart';

/// Gradient action button used in appBar actions across list fragments.
///
/// Replaces the copy-pasted Container + LinearGradient + InkWell + Row pattern
/// found in item, supplier, purchase, and customer fragments.
///
/// Usage:
/// ```dart
/// GradientActionButton(
///   icon: Icons.add_circle_outline_rounded,
///   label: 'add_item'.tr,
///   gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
///   onTap: () => Get.dialog(const ActivityItemForm()),
/// )
/// ```
class GradientActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const GradientActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
