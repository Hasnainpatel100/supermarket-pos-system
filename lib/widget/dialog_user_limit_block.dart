import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../service/service_brand_context.dart';
import 'app_dialog_components.dart';
import 'dialog_renew_plan.dart';

/// Modal dialog displayed when an action would exceed the branch plan's maxUsers quota.
class DialogUserLimitBlock extends StatelessWidget {
  final int maxUsers;
  final int activeUsers;

  const DialogUserLimitBlock({
    super.key,
    required this.maxUsers,
    required this.activeUsers,
  });

  static Future<void> show(
    BuildContext context, {
    required int maxUsers,
    required int activeUsers,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DialogUserLimitBlock(
        maxUsers: maxUsers,
        activeUsers: activeUsers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppDialog(
      maxWidth: 480,
      maxHeight: 460,
      header: const DialogHeader(
        title: 'User Limit Reached',
        icon: Icons.group_off_rounded,
        iconColor: Color(0xFFF59E0B),
      ),
      body: DialogBody(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Quota Alert Box ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.4 : 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Color(0xFFD97706),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quota Full: $activeUsers / $maxUsers Users',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Maximum allowed by active store subscription.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Explanation text ──────────────────────────────────────────
            Text(
              'Your branch plan allows a maximum of $maxUsers active staff accounts. '
              'To add a new user or activate an existing account, you can either deactivate an inactive user or upgrade your plan.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 24),

            // ── Action Buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (Get.isRegistered<ServiceBrandContext>()) {
                        final branch = Get.find<ServiceBrandContext>().selectedBranch;
                        if (branch != null) {
                          DialogRenewPlan.show(context, branch: branch);
                        }
                      }
                    },
                    icon: const Icon(Icons.upgrade_rounded, size: 18),
                    label: const Text('Upgrade Plan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
