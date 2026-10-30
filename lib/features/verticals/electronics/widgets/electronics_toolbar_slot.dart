import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app_type/app_type_service.dart';

/// Electronics toolbar slot — IMEI/serial scanner and accessory attachment tracking.
class ElectronicsToolbarSlot extends StatelessWidget {
  const ElectronicsToolbarSlot({super.key});

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
            const SizedBox(width: 14),
            const Icon(Icons.badge_outlined, size: 18),
            const SizedBox(width: 6),
            Text(
              profile.enableImeiSerialScanner ? 'IMEI Tracking Active' : 'Serial Tracking',
              style: TextStyle(
                fontSize: 11.5,
                color: profile.enableImeiSerialScanner ? profile.secondaryColor : cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.qr_code_scanner, size: 16),
              label: const Text('Scan IMEI / Serial'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    });
  }
}