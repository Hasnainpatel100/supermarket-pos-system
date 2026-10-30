import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app_type/app_type_service.dart';

/// Optical toolbar slot — prescription (Rx) grid: SPH / CYL / AXIS for left & right.
class OpticalRxSlot extends StatelessWidget {
  OpticalRxSlot({super.key});

  // Rx prescription state (10% vertical logic, isolated here)
  final RxString rxRightSph = ''.obs;
  final RxString rxRightCyl = ''.obs;
  final RxString rxRightAxis = ''.obs;
  final RxString rxLeftSph = ''.obs;
  final RxString rxLeftCyl = ''.obs;
  final RxString rxLeftAxis = ''.obs;

  static const spherics = ['-6.00', '-5.00', '-4.00', '-3.00', '-2.00', '-1.00',
    '0.00', '+0.50', '+1.00', '+1.50', '+2.00', '+3.00', '+4.00'];
  static const cylinders = ['-2.50', '-2.00', '-1.50', '-1.00', '-0.50', '0.00', '+0.50'];
  static final axes = List.generate(18, (i) => (i * 10).toString());

  void _cycleRx(RxString rxTarget, List<String> options) {
    final currentIndex = options.indexOf(rxTarget.value);
    if (currentIndex == -1 || currentIndex >= options.length - 1) {
      rxTarget.value = options.first;
    } else {
      rxTarget.value = options[currentIndex + 1];
    }
  }

  void _openRxDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Optical Prescription (Rx) Grid'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Prescription Values for Right & Left Eyes:'),
              const SizedBox(height: 16),
              // Right Eye row
              Row(
                children: [
                  const SizedBox(width: 40, child: Text('RE:', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Obx(() => DropdownButton<String>(
                          value: rxRightSph.value.isEmpty ? null : rxRightSph.value,
                          hint: const Text('SPH'),
                          isExpanded: true,
                          items: spherics.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => rxRightSph.value = v ?? '',
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Left Eye row
              Row(
                children: [
                  const SizedBox(width: 40, child: Text('LE:', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Obx(() => DropdownButton<String>(
                          value: rxLeftSph.value.isEmpty ? null : rxLeftSph.value,
                          hint: const Text('SPH'),
                          isExpanded: true,
                          items: spherics.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => rxLeftSph.value = v ?? '',
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
            const Icon(Icons.visibility_rounded, size: 18),
            const SizedBox(width: 6),
            Text(
              profile.enableOpticalRxGrid ? 'Rx Grid Active' : 'Rx Grid',
              style: TextStyle(
                fontSize: 11.5,
                color: profile.enableOpticalRxGrid ? profile.secondaryColor : cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            // Quick Rx summary pills — tap to cycle the sphere value
            _RxPill(
              label: 'R',
              sph: rxRightSph.value,
              color: profile.primaryColor,
              onCycle: () => _cycleRx(rxRightSph, spherics),
            ),
            const SizedBox(width: 4),
            _RxPill(
              label: 'L',
              sph: rxLeftSph.value,
              color: profile.secondaryColor,
              onCycle: () => _cycleRx(rxLeftSph, spherics),
            ),
            const SizedBox(width: 10),
            FilledButton.tonal(
              onPressed: () => _openRxDialog(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              child: const Text('Enter Rx Grid'),
            ),
          ],
        ),
      );
    });
  }
}

class _RxPill extends StatelessWidget {
  final String label;
  final String sph;
  final Color color;
  final VoidCallback onCycle;

  const _RxPill({
    required this.label,
    required this.sph,
    required this.color,
    required this.onCycle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onCycle,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$label: ${sph.isEmpty ? 'Select SPH' : sph}',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: sph.isEmpty ? cs.onSurfaceVariant : color,
          ),
        ),
      ),
    );
  }
}