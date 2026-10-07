import 'package:flutter/material.dart';

import '../../../../util/app_colors.dart';
import '../../../../util/app_spacing.dart';

/// Reusable stat pill badge — used in dialogs and cards.
class StatPill extends StatelessWidget {
  final String text;
  final bool isDark;
  final ColorScheme cs;

  const StatPill({
    super.key,
    required this.text,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : AppColors.brandTeal,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: isDark
            ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.5))
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? cs.onSurface : AppColors.textWhite,
          fontSize: AppSpacing.fontMd,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
