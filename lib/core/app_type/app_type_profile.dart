import 'package:flutter/material.dart';

import 'enum_app_type.dart';

/// Immutable per-vertical configuration contract.
///
/// 90% of the POS codebase is shared. The 10% that differs between
/// verticals is expressed entirely through this profile -- no scattered
/// `if (appType == "STEEL")` branches in widget files.
///
/// Consumers read properties off the active profile:
///   - [primaryColor] / [secondaryColor] / [accentColor] drive the theme.
///   - [unitsList] / [codeLabel] / [partyLabel] drive the lexicon.
///   - Feature booleans gate vertical-specific UI (weighbridge, IMEI, Rx grid...).
class AppTypeProfile {
  final AppType type;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final List<Color> cardGradient;
  final IconData icon;

  // ── Dynamic Lexicon ──────────────────────────────────────────────
  final String partyLabel;
  final String codeLabel;
  final List<String> unitsList;

  // ── Feature Gates ────────────────────────────────────────────────
  final bool enableWeighbridge;
  final bool enableSectionCalculator;
  final bool enableWeightScaleUsb;
  final bool enableExpiryAndBatch;
  final bool enableSizeColorMatrix;
  final bool enableImeiSerialScanner;
  final bool enableGoldRateTicker;
  final bool enableOpticalRxGrid;
  final bool enablePairVerification;

  // ── Print / Paper ────────────────────────────────────────────────
  final String defaultPrintFormat;

  const AppTypeProfile({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.cardGradient,
    required this.icon,
    required this.partyLabel,
    required this.codeLabel,
    required this.unitsList,
    this.enableWeighbridge = false,
    this.enableSectionCalculator = false,
    this.enableWeightScaleUsb = false,
    this.enableExpiryAndBatch = false,
    this.enableSizeColorMatrix = false,
    this.enableImeiSerialScanner = false,
    this.enableGoldRateTicker = false,
    this.enableOpticalRxGrid = false,
    this.enablePairVerification = false,
    this.defaultPrintFormat = '80mm',
  });

  // ── Convenience getters ──────────────────────────────────────────

  /// True for verticals that sell by weight (steel, market, jewellery).
  bool get isWeightBased => unitsList
      .any((u) => const {'kg', 'gram', 'mt', 'ton', 'tonne'}.contains(u.toLowerCase()));

  /// True for verticals that track serial numbers / IMEI.
  bool get isSerialBased => enableImeiSerialScanner;

  /// True for verticals where items are sold in pairs (footwear, optical).
  bool get isPairBased => enablePairVerification;

  /// True for verticals where prescription / Rx data is captured.
  bool get isRxBased => enableOpticalRxGrid;

  /// True for verticals where live commodity pricing drives the UI.
  bool get isCommodityPriced => enableGoldRateTicker;
}

/// Iconography per vertical -- kept separate from [AppTypeProfile] so the
/// profile remains a pure data contract (icons are not serializable).
class VerticalIcon {
  final IconData icon;
  final Color color;

  const VerticalIcon({required this.icon, required this.color});
}