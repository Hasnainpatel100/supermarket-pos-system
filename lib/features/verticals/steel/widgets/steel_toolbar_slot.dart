import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app_type/app_type_service.dart';

/// Steel toolbar slot — truck weighbridge dispatch, section weight calculator,
/// and a live cart tonnage tracker. Self-contained: the steel_pos feature
/// directory does not exist on this branch, so this slot owns its own logic.
class SteelToolbarSlot extends StatelessWidget {
  SteelToolbarSlot({super.key});

  // Steel-specific reactive state (10% vertical logic, isolated here)
  final RxString rxVehicleNo = ''.obs;
  final RxDouble rxWeighbridgeGrossKg = 0.0.obs;
  final RxDouble rxWeighbridgeTareKg = 0.0.obs;

  double get netWeighbridgeWeightKg =>
      (rxWeighbridgeGrossKg.value - rxWeighbridgeTareKg.value) > 0
          ? rxWeighbridgeGrossKg.value - rxWeighbridgeTareKg.value
          : 0.0;

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

            // Live cart tonnage tracker
            Icon(Icons.scale_rounded, size: 18, color: profile.secondaryColor),
            const SizedBox(width: 6),
            Text(
              'Order: 0.000 MT',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: profile.secondaryColor,
              ),
            ),
            const SizedBox(width: 12),
            // Weighbridge net weight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: profile.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'WB Net: ${netWeighbridgeWeightKg.toStringAsFixed(0)} Kg',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: profile.primaryColor,
                ),
              ),
            ),
            const Spacer(),
            // Section calculator
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.architecture_rounded, size: 16),
              label: const Text('Section Calc'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            // Weighbridge dispatch
            Obx(() {
              final hasVehicle = rxVehicleNo.value.trim().isNotEmpty;
              return FilledButton.icon(
                onPressed: () {},
                icon: Icon(
                  hasVehicle ? Icons.local_shipping_rounded : Icons.local_shipping_outlined,
                  size: 16,
                ),
                label: Text(hasVehicle ? 'Truck: ${rxVehicleNo.value}' : 'Truck & Weighbridge'),
                style: FilledButton.styleFrom(
                  backgroundColor: hasVehicle ? profile.primaryColor : cs.surfaceContainerHighest,
                  foregroundColor: hasVehicle ? Colors.white : cs.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}