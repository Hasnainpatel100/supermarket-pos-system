import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app_type/app_type_service.dart';
import '../../../../screens/home/fragment/pos/controller_home_pos.dart';

/// Market / Kirana toolbar slot — fast barcode scanner switch, weighing scale
/// indicator, and a reactive units dropdown bound to the active profile.
class MarketToolbarSlot extends StatelessWidget {
  const MarketToolbarSlot({super.key});

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
        child: Row(
          children: [
            // Vertical badge
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
            const SizedBox(width: 14),

            // Weighing scale indicator
            Icon(
              profile.enableWeightScaleUsb ? Icons.scale_rounded : Icons.scale_outlined,
              size: 18,
              color: profile.enableWeightScaleUsb ? profile.secondaryColor : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              profile.enableWeightScaleUsb ? 'Scale Sync Ready' : 'Scale Disabled',
              style: TextStyle(
                fontSize: 11.5,
                color: profile.enableWeightScaleUsb ? profile.secondaryColor : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),

            // Reactive units dropdown bound to the active profile
            Text('Unit:', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: profile.unitsList.isNotEmpty ? profile.unitsList.first : null,
                  items: profile.unitsList
                      .map((u) => DropdownMenuItem<String>(
                            value: u,
                            child: Text(u, style: const TextStyle(fontSize: 11.5)),
                          ))
                      .toList(),
                  onChanged: (_) {},
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 16),
                  isDense: true,
                  underline: const SizedBox(),
                ),
              ),
            ),
            const Spacer(),
            // Barcode scanner focus button
            FilledButton.tonalIcon(
              onPressed: () {
                if (Get.isRegistered<ControllerHomePos>()) {
                  Get.find<ControllerHomePos>().requestSearchFocus();
                }
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
              label: const Text('Focus Scanner'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    });
  }
}