import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../screens/home/fragment/pos/controller_home_pos.dart';
import '../controllers/controller_steel_pos.dart';
import '../models/steel_spec.dart';
import '../utils/steel_weight_calculator.dart';
import 'dialog_steel_calculator.dart';
import 'dialog_weighbridge_dispatch.dart';

class SteelPosToolbar extends StatelessWidget {
  const SteelPosToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerSteelPos steelCtrl = Get.isRegistered<ControllerSteelPos>()
        ? Get.find<ControllerSteelPos>()
        : Get.put(ControllerSteelPos(), permanent: true);

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Steel Metrics & Quick Tool Buttons ──
          Row(
            children: [
              // Steel Terminal Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.6)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.precision_manufacturing_rounded, size: 16, color: Color(0xFFFF9F43)),
                    SizedBox(width: 6),
                    Text(
                      'STEEL TERMINAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Live Cart Tonnage Tracker
              Obx(() {
                final totalKg = steelCtrl.getCartTotalWeightKg();
                final totalMt = SteelWeightCalculator.kgToMetricTons(totalKg);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: totalKg > 0
                        ? const Color(0xFFFFF2E5)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: totalKg > 0
                          ? const Color(0xFFFF7A00).withValues(alpha: 0.5)
                          : cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.scale_rounded,
                        size: 16,
                        color: totalKg > 0 ? const Color(0xFFFF7A00) : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total Order Weight: ',
                        style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                      ),
                      Text(
                        '${totalMt.toStringAsFixed(3)} MT (${totalKg.toStringAsFixed(0)} Kg)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: totalKg > 0 ? const Color(0xFF0D9488) : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Spacer(),

              // Quick Action 1: Sectional Weight Calculator
              FilledButton.tonalIcon(
                onPressed: () => DialogSteelCalculator.show(context),
                icon: const Icon(Icons.architecture_rounded, size: 16),
                label: const Text('Section Calculator'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 8),

              // Quick Action 2: Weighbridge & Truck Dispatch
              Obx(() {
                final vNo = steelCtrl.rxVehicleNo.value.trim();
                final hasVehicle = vNo.isNotEmpty;

                return FilledButton.icon(
                  onPressed: () => DialogWeighbridgeDispatch.show(context),
                  icon: Icon(
                    hasVehicle ? Icons.local_shipping_rounded : Icons.local_shipping_outlined,
                    size: 16,
                  ),
                  label: Text(hasVehicle ? 'Truck: $vNo' : 'Truck & Weighbridge'),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasVehicle ? const Color(0xFFD97706) : const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: Category Filter Bar ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Materials',
                  category: null,
                  steelCtrl: steelCtrl,
                  cs: cs,
                ),
                ...SteelCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildFilterChip(
                      label: cat.displayName,
                      category: cat,
                      steelCtrl: steelCtrl,
                      cs: cs,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required SteelCategory? category,
    required ControllerSteelPos steelCtrl,
    required ColorScheme cs,
  }) {
    return Obx(() {
      final isSelected = steelCtrl.rxSelectedCategory.value == category;

      return InkWell(
        onTap: () {
          steelCtrl.rxSelectedCategory.value = category;
          // Apply search or category filter in ControllerHomePos if present
          if (Get.isRegistered<ControllerHomePos>()) {
            final pos = Get.find<ControllerHomePos>();
            if (category == null) {
              pos.selectCategory('All');
            } else {
              pos.selectCategory(category.displayName);
            }
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF7A00)
                  : cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : cs.onSurface,
            ),
          ),
        ),
      );
    });
  }
}

