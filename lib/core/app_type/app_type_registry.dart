import 'package:flutter/material.dart';

import 'app_type_profile.dart';
import 'enum_app_type.dart';

/// Central registry of all 7 POS verticals.
///
/// Pre-defines static const configurations for each vertical with exact design
/// schemes, dynamic lexicon, and feature gates.
class AppTypeRegistry {
  AppTypeRegistry._();

  /// Map of [AppType] to its specific [AppTypeProfile].
  static final Map<AppType, AppTypeProfile> profiles = {
    AppType.steel: const AppTypeProfile(
      type: AppType.steel,
      title: 'Steel Terminal',
      subtitle: 'Construction & Industrial Supplies',
      primaryColor: Color(0xFFFF7A00), // Industrial Orange
      secondaryColor: Color(0xFF1E3A5F), // Steel Navy
      accentColor: Color(0xFF0D9488), // Teal
      cardGradient: [Color(0xFF1E293B), Color(0xFF0F172A)],
      icon: Icons.precision_manufacturing_rounded,
      partyLabel: 'Contractor',
      codeLabel: 'Section/Size',
      unitsList: ['MT', 'KG', 'Bundle', 'Pcs'],
      enableWeighbridge: true,
      enableSectionCalculator: true,
      defaultPrintFormat: 'a4',
    ),
    AppType.market: const AppTypeProfile(
      type: AppType.market,
      title: 'Super Market',
      subtitle: 'Grocery & FMCG Store',
      primaryColor: Color(0xFF0F766E), // Emerald Teal
      secondaryColor: Color(0xFF10B981), // Fresh Green
      accentColor: Color(0xFFF59E0B), // Amber
      cardGradient: [Color(0xFF0F766E), Color(0xFF115E59)],
      icon: Icons.shopping_basket_rounded,
      partyLabel: 'Customer',
      codeLabel: 'Barcode/PLU',
      unitsList: ['Kg', 'Gm', 'Pcs', 'Packet', 'Litre'],
      enableWeightScaleUsb: true,
      enableExpiryAndBatch: true,
      defaultPrintFormat: '80mm',
    ),
    AppType.apparel: const AppTypeProfile(
      type: AppType.apparel,
      title: 'Apparel & Boutique',
      subtitle: 'Fashion & Garments Store',
      primaryColor: Color(0xFF7C3AED), // Royal Violet
      secondaryColor: Color(0xFFF59E0B), // Amber Gold
      accentColor: Color(0xFFEC4899), // Pink
      cardGradient: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      icon: Icons.checkroom_rounded,
      partyLabel: 'Customer',
      codeLabel: 'Style Code',
      unitsList: ['Pcs', 'Set', 'Pair', 'Meter'],
      enableSizeColorMatrix: true,
      defaultPrintFormat: '80mm',
    ),
    AppType.electronics: const AppTypeProfile(
      type: AppType.electronics,
      title: 'Electronics & Mobiles',
      subtitle: 'Gadgets & Home Appliances',
      primaryColor: Color(0xFF0284C7), // Tech Cobalt
      secondaryColor: Color(0xFF06B6D4), // Neon Cyan
      accentColor: Color(0xFF8B5CF6), // Purple
      cardGradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      icon: Icons.devices_other_rounded,
      partyLabel: 'Customer',
      codeLabel: 'IMEI/Serial',
      unitsList: ['Pcs', 'Box', 'Set'],
      enableImeiSerialScanner: true,
      defaultPrintFormat: 'a4',
    ),
    AppType.jewellery: const AppTypeProfile(
      type: AppType.jewellery,
      title: 'Jewellery & Gems',
      subtitle: 'Ornaments & Precious Metals',
      primaryColor: Color(0xFFD97706), // Royal Gold
      secondaryColor: Color(0xFF831843), // Deep Maroon
      accentColor: Color(0xFF059669), // Emerald
      cardGradient: [Color(0xFFD97706), Color(0xFFB45309)],
      icon: Icons.diamond_rounded,
      partyLabel: 'Customer',
      codeLabel: 'Hallmark ID',
      unitsList: ['Gram', 'Mg', 'Pcs'],
      enableGoldRateTicker: true,
      defaultPrintFormat: 'a4',
    ),
    AppType.optical: const AppTypeProfile(
      type: AppType.optical,
      title: 'Vision & Optical',
      subtitle: 'Eyewear & Clinic',
      primaryColor: Color(0xFF0891B2), // Clinical Cyan
      secondaryColor: Color(0xFF3B82F6), // Electric Blue
      accentColor: Color(0xFF10B981), // Green
      cardGradient: [Color(0xFF0891B2), Color(0xFF0E7490)],
      icon: Icons.visibility_rounded,
      partyLabel: 'Patient',
      codeLabel: 'Frame ID',
      unitsList: ['Pcs', 'Pair'],
      enableOpticalRxGrid: true,
      defaultPrintFormat: '80mm',
    ),
    AppType.footwear: const AppTypeProfile(
      type: AppType.footwear,
      title: 'Footwear & Leather',
      subtitle: 'Shoes & Sandals Store',
      primaryColor: Color(0xFFDC2626), // Sport Red
      secondaryColor: Color(0xFF1F2937), // Charcoal Black
      accentColor: Color(0xFFF97316), // Orange
      cardGradient: [Color(0xFFDC2626), Color(0xFF991B1B)],
      icon: Icons.ice_skating_rounded,
      partyLabel: 'Customer',
      codeLabel: 'Article No',
      unitsList: ['Pair', 'Pcs'],
      enablePairVerification: true,
      defaultPrintFormat: '80mm',
    ),
  };

  /// Returns the profile for the given [type].
  ///
  /// Falls back to the market profile if the type is not registered.
  static AppTypeProfile getProfile(AppType type) {
    return profiles[type] ?? profiles[AppType.market]!;
  }
}