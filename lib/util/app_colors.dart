import 'package:flutter/material.dart';

/// Centralized brand colors for the POS application.
/// Use these instead of hardcoded Color() literals throughout the app.
class AppColors {
  // Brand primary
  static const brandTeal = Color(0xFF005963);
  static const brandTealLight = Color(0xFF00796B);
  static const brandTealDark = Color(0xFF004D54);
  static const brandTealDarker = Color(0xFF00383F);

  // Semantic colors
  static const info = Color(0xFF0284C7);
  static const infoLight = Color(0xFFE0F2FE);
  static const infoDark = Color(0xFF0369A1);
  static const infoLightDark = Color(0xFF38BDF8);
  static const teal = Color(0xFF0D9488);
  static const tealLight = Color(0xFFCCFBF1);
  static const tealDark = Color(0xFF0F766E);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFEDE9FE);
  static const errorRed = Color(0xFFEF4444);

  // Neutral backgrounds
  static const surfaceDark = Color(0xFF1E293B);
  static const surfaceLight = Color(0xFFF8FAFC);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const cardLight = Color(0xFFF1F5F9);
  static const cardTealLight = Color(0xFFCFE1E3);
  static const tagBgLight = Color(0xFFE2F0F0);

  // Semantic colors
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFDCFCE7);
  static const successDark = Color(0xFF064E3B);
  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEE2E2);
  static const errorDark = Color(0xFF7F1D1D);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const warningDark = Color(0xFF78350F);
  static const orange = Color(0xFFEA580C);
  static const orangeLight = Color(0xFFFED7AA);
  static const orangeDark = Color(0xFF7C2D12);

  // Text colors
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textSecondaryLight = Color(0xFF94A3B8);
  static const textSecondaryDark = Color(0xFF475569);
  static const textTertiary = Color(0xFF94A3B8);
  static const textWhite = Colors.white;
  static const textWhiteOverlay18 = Color(0x2EFFFFFF);

  // Border colors
  static const borderLight = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF3E4E46);
  static const dividerLight = Color(0xFFE2E8F0);

  // Shadow
  static const shadowLight = Color(0x03000000);
  static const shadowDark = Color(0x40000000);
  static const shadowSubtle = Color(0x03000000);
}
