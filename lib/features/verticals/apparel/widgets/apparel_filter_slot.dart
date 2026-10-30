import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app_type/app_type_service.dart';

/// Apparel toolbar slot — size & color filter chips bound to the active profile.
class ApparelFilterSlot extends StatelessWidget {
  const ApparelFilterSlot({super.key});

  static const sizes = ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  static const colors = [
    ('Black', Color(0xFF1F2937)),
    ('White', Color(0xFFF9FAFB)),
    ('Red', Color(0xFFDC2626)),
    ('Blue', Color(0xFF2563EB)),
    ('Green', Color(0xFF10B981)),
    ('Beige', Color(0xFFD2B48C)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final profile = AppTypeService.to.currentProfile;

      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: badge + size chips
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: profile.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: profile.primaryColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(profile.icon, size: 16, color: profile.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        profile.title.toUpperCase(),
                        style: TextStyle(
                          color: profile.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('Size:', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                const SizedBox(width: 6),
                ...sizes.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChoiceChip(
                        label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: false,
                        onSelected: (_) {},
                        visualDensity: VisualDensity.compact,
                        showCheckmark: false,
                        selectedColor: profile.primaryColor,
                        labelStyle: TextStyle(color: cs.onSurface),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 6),
            // Row 2: color chips
            Row(
              children: [
                const SizedBox(width: 118),
                Text('Color:', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                const SizedBox(width: 6),
                ...colors.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: c.$2,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                      ),
                    )),
                const Spacer(),
                if (profile.enableSizeColorMatrix)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: profile.secondaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Size × Color Matrix Active',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: profile.secondaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}