import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized POS typography for consistent hierarchy, tabular alignment,
/// and technical readability across all 7 verticals.
class PosTypography {
  static TextStyle get _base => GoogleFonts.plusJakartaSans();
  static TextStyle get _mono => GoogleFonts.jetBrainsMono();

  static TextStyle grandTotal(BuildContext context) => _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle itemTitle(BuildContext context) => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle price(BuildContext context) => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: Theme.of(context).colorScheme.primary,
      );

  static TextStyle code(BuildContext context) => _mono.copyWith(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.2,
      );

  static TextStyle badge(BuildContext context) => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle tableHeader(BuildContext context) => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      );
}
