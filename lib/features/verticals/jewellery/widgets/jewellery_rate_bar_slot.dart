import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app_type/app_type_service.dart';

/// Jewellery toolbar slot — live gold/silver rate ticker with a refresh action.
class JewelleryRateSlot extends StatelessWidget {
  JewelleryRateSlot({super.key});

  // Live commodity rates (10% vertical state, isolated here)
  final RxDouble rxBuyGold = 75200.0.obs;
  final RxDouble rxSellGold = 75420.0.obs;
  final RxDouble rxBuySilver = 89000.0.obs;
  final RxDouble rxSellSilver = 89310.0.obs;

  void _refreshRates() {
    rxBuyGold.value = rxBuyGold.value + (DateTime.now().millisecond % 40 - 20);
    rxSellGold.value = rxBuyGold.value + 220;
    rxBuySilver.value = rxBuySilver.value + (DateTime.now().millisecond % 30 - 15);
    rxSellSilver.value = rxBuySilver.value + 310;
  }

  @override
  Widget build(BuildContext context) {
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
            // Gold rate
            _RatePill(
              label: 'Gold',
              buy: rxBuyGold.value,
              sell: rxSellGold.value,
              color: profile.primaryColor,
            ),
            const SizedBox(width: 8),
            // Silver rate
            _RatePill(
              label: 'Silver',
              buy: rxBuySilver.value,
              sell: rxSellSilver.value,
              color: profile.secondaryColor,
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: _refreshRates,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              child: const Text('Refresh Rates'),
            ),
          ],
        ),
      );
    });
  }
}

class _RatePill extends StatelessWidget {
  final String label;
  final double buy;
  final double sell;
  final Color color;

  const _RatePill({
    required this.label,
    required this.buy,
    required this.sell,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '₹${buy.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_upward_rounded, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            '₹${sell.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}