import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app_type/app_type_service.dart';

/// Footwear toolbar slot — UK/IND size curve selection buttons.
class FootwearSizeSlot extends StatelessWidget {
  FootwearSizeSlot({super.key});

  // Selected size state (10% vertical logic, isolated here)
  final RxInt rxSelectedSize = 8.obs;

  static const ukSizes = ['5', '6', '7', '8', '9', '10', '11'];
  static const indSizes = ['5', '6', '7', '8', '9', '10', '11'];

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
                Text('UK Size:', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                const SizedBox(width: 6),
                ...ukSizes.map((s) {
                  final idx = ukSizes.indexOf(s);
                  final selected = rxSelectedSize.value == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: selected,
                      onSelected: (_) => rxSelectedSize.value = idx,
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                      selectedColor: profile.primaryColor,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : cs.onSurface,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            // Row 2: IND size curve + pair verification
            Row(
              children: [
                const SizedBox(width: 118),
                Text('IND Size:', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                const SizedBox(width: 6),
                ...indSizes.map((s) {
                  final idx = indSizes.indexOf(s);
                  final selected = rxSelectedSize.value == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: selected,
                      onSelected: (_) => rxSelectedSize.value = idx,
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                      selectedColor: profile.secondaryColor,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : cs.onSurface,
                      ),
                    ),
                  );
                }),
                const Spacer(),
                if (profile.enablePairVerification)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: profile.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Pair Verification Active',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: profile.primaryColor,
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