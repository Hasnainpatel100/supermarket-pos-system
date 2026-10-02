import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/model_branch.dart';
import '../model/model_brand.dart';
import '../screens/home/controller_home.dart';
import '../service/service_brand_context.dart';
import 'app_dialog_components.dart';
import 'dialog_plan_expiry.dart';

/// A card displayed in the sidebar corner that shows the active Brand and Branch.
/// Expands/collapses with the drawer and reads live data from [ServiceBrandContext].
/// Tapping the card opens a dialog with full Brand and Branch details.
class BrandBranchCard extends StatelessWidget {
  const BrandBranchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHome homeCtrl = Get.find();
    final ServiceBrandContext brandCtx = Get.find();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final collapsed = homeCtrl.isDrawerCollapsed.value;
      final brand = brandCtx.rxSelectedBrand.value;
      final branch = brandCtx.rxSelectedBranch.value;
      final plan = branch?.planDetails;

      final isExpired = plan?.isExpired ?? false;
      final isExpiringSoon = plan?.isExpiringSoon ?? false;
      final Color planColor = isExpired
          ? const Color(0xFFEF4444)
          : isExpiringSoon
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981);
      final IconData planIcon = isExpired
          ? Icons.error_outline_rounded
          : isExpiringSoon
              ? Icons.warning_amber_rounded
              : Icons.verified_user_rounded;

      // Collapsed: compact avatar with tooltip and click action
      if (collapsed) {
        return Tooltip(
          message: '${brandCtx.contextSummary}\nPlan: ${plan?.expiryStatusText ?? "Active"}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showDetailsDialog(context, brand, branch),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.store_mall_directory_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (plan != null && (isExpired || isExpiringSoon))
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: planColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }

      // Expanded: full brand + branch card
      final brandName = brand?.name.en ?? 'No Brand';
      final branchName = branch?.name.en ?? 'No Branch';
      final branchCode = branch?.branchCode ?? '';
      final status = branch?.status.toLowerCase() ?? '';
      final isActive = status == 'active';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showDetailsDialog(context, brand, branch),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                    : colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isExpired || isExpiringSoon)
                      ? planColor.withValues(alpha: 0.5)
                      : colorScheme.primary.withValues(alpha: 0.2),
                  width: (isExpired || isExpiringSoon) ? 1.4 : 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Brand Row ────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brand',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              brandName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.35),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),

                  // ── Branch Row ───────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Branch',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    branchName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (branchCode.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      branchCode,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Status dot
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green.shade400 : Colors.orange.shade400,
                        ),
                      ),
                    ],
                  ),

                  // ── Plan Expiry Button / Chip ─────────────────────────────
                  if (plan != null) ...[
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => DialogPlanExpiry.show(context, branch: branch),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: planColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: planColor.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(planIcon, size: 13, color: planColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  plan.expiryStatusText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: planColor,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 9,
                                color: planColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showDetailsDialog(BuildContext context, ModelBrand? brand, ModelBranch? branch) {
    final colorScheme = Theme.of(context).colorScheme;

    Get.dialog(
      AppDialog(
        maxWidth: 520,
        maxHeight: 560,
        header: const DialogHeader(
          title: 'Active Brand & Branch',
          icon: Icons.store_mall_directory_rounded,
          iconColor: Colors.deepPurple,
        ),
        body: DialogBody(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand Section
              _buildSectionCard(
                context,
                title: 'Brand Details',
                icon: Icons.storefront_rounded,
                iconColor: colorScheme.primary,
                items: [
                  _DetailRow('Name (EN)', brand?.name.en ?? 'N/A'),
                  if (brand?.name.ar != null && brand!.name.ar!.isNotEmpty)
                    _DetailRow('Name (AR)', brand.name.ar!),
                  if (brand?.name.hi != null && brand!.name.hi!.isNotEmpty)
                    _DetailRow('Name (HI)', brand.name.hi!),
                  if (brand?.branchCode != null && brand!.branchCode!.isNotEmpty)
                    _DetailRow('Code', brand.branchCode!),
                  if (brand?.registration.gstNo != null &&
                      brand!.registration.gstNo.isNotEmpty)
                    _DetailRow('GST / Tax No', brand.registration.gstNo),
                  if (brand?.status != null)
                    _DetailRow('Status', brand!.status.toUpperCase()),
                ],
              ),
              const SizedBox(height: 16),

              // Branch Section
              _buildSectionCard(
                context,
                title: 'Branch Details',
                icon: Icons.location_on_rounded,
                iconColor: Colors.deepPurple,
                items: [
                  _DetailRow('Name (EN)', branch?.name.en ?? 'N/A'),
                  if (branch?.branchCode != null && branch!.branchCode.isNotEmpty)
                    _DetailRow('Branch Code', branch.branchCode),
                  if (branch?.status != null)
                    _DetailRow('Status', branch!.status.toUpperCase()),
                  if (branch?.address.full != null && branch!.address.full.isNotEmpty)
                    _DetailRow('Address', branch.address.full),
                  if (branch?.address.city != null && branch!.address.city.isNotEmpty)
                    _DetailRow('City', branch.address.city),
                  if (branch?.contact.phones.primary != null &&
                      branch!.contact.phones.primary.isNotEmpty)
                    _DetailRow('Phone', branch.contact.phones.primary),
                  if (branch?.contact.email != null &&
                      branch!.contact.email.isNotEmpty)
                    _DetailRow('Email', branch.contact.email),
                ],
              ),

              // Plan & Subscription Section
              if (branch?.planDetails != null) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  context,
                  title: 'Plan & Subscription',
                  icon: Icons.card_membership_rounded,
                  iconColor: branch!.planDetails!.isExpiringSoon || branch.planDetails!.isExpired
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                  items: [
                    _DetailRow('Plan Tier / Note', branch.planDetails!.note),
                    _DetailRow('Expiry Status', branch.planDetails!.expiryStatusText),
                    _DetailRow('Expires On', branch.planDetails!.formattedExpiry),
                    _DetailRow('Expiry Alarm', 'Notifies ${Get.find<ServiceBrandContext>().expiryAlarmDays} days before expiry'),
                    _DetailRow('Max Users', '${branch.planDetails!.maxUsers} allowed'),
                    _DetailRow('Max POS Devices', '${branch.planDetails!.maxPosDevices} terminals'),
                    if (branch.planDetails!.assignedAt != null)
                      _DetailRow('Assigned On', branch.planDetails!.formattedAssignedAt),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        DialogPlanExpiry.showHistory(context, branch: branch);
                      },
                      icon: const Icon(Icons.history_edu_rounded, size: 14),
                      label: const Text('Plan History'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Get.back();
                        DialogPlanExpiry.show(context, branch: branch);
                      },
                      icon: const Icon(Icons.credit_card_rounded, size: 14),
                      label: const Text('Plan Details & Alarm'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        footer: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_DetailRow> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
          const SizedBox(height: 10),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        it.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        it.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}
