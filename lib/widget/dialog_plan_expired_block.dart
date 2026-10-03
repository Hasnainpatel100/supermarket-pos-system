import 'package:flutter/material.dart';

import '../model/model_branch.dart';
import 'app_dialog_components.dart';

/// Non-dismissible blocking dialog displayed when a branch subscription plan
/// has reached or passed its expiry date.
///
/// Prevents the user from logging in or using the POS until renewed by customer care.
class DialogPlanExpiredBlock extends StatelessWidget {
  final ModelBranch? branch;
  final BranchPlanDetails? plan;

  const DialogPlanExpiredBlock({
    super.key,
    this.branch,
    this.plan,
  });

  /// Displays the blocking plan expired modal dialog.
  /// Cannot be dismissed by tapping outside or pressing Back.
  static Future<void> show(
    BuildContext context, {
    ModelBranch? branch,
    BranchPlanDetails? plan,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: DialogPlanExpiredBlock(
          branch: branch,
          plan: plan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePlan = plan ?? branch?.planDetails;
    final branchName = branch?.name.en ?? 'Branch';
    final branchCode = branch?.branchCode ?? '';
    final primaryPhone = branch?.contact.phones.primary ?? '';
    final email = branch?.contact.email ?? '';
    final expiryFormatted = effectivePlan?.formattedExpiry ?? 'Expired';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return AppDialog(
      maxWidth: 520,
      maxHeight: 630,
      header: const DialogHeader(
        title: 'Plan Expired',
        icon: Icons.block_rounded,
        iconColor: Color(0xFFEF4444),
      ),
      body: DialogBody(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Big Red Alert Card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.45 : 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Color(0xFFEF4444),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your Plan Got Expired',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Access to this POS terminal is temporarily suspended because the subscription plan has reached its expiration date.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Branch & Expiry Details ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2530) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _infoRow(
                    'Branch',
                    '$branchName ${branchCode.isNotEmpty ? "($branchCode)" : ""}',
                    isDark: isDark,
                  ),
                  Divider(
                    height: 14,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                  ),
                  _infoRow(
                    'Expiry Date',
                    expiryFormatted,
                    valueColor: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                    isBold: true,
                    isDark: isDark,
                  ),
                  if (effectivePlan?.note.isNotEmpty == true) ...[
                    Divider(
                      height: 14,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                    ),
                    _infoRow('Plan Tier', effectivePlan!.note, isDark: isDark),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Customer Care Notice ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
                      : const Color(0xFF2563EB).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please Contact Customer Care',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please contact your organization administrator or customer care support team to renew your subscription plan.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800,
                          ),
                        ),
                        if (primaryPhone.isNotEmpty || email.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          if (primaryPhone.isNotEmpty)
                            Text(
                              '📞 Helpline: $primaryPhone',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.blue.shade200 : Colors.grey.shade900,
                              ),
                            ),
                          if (email.isNotEmpty)
                            Text(
                              '✉️ Support: $email',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.blue.shade200 : Colors.grey.shade900,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? (theme.cardTheme.color ?? theme.cardColor) : Colors.grey.shade50,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text(
                'I Understand',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}
