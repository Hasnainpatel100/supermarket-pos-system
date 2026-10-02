import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../model/model_branch.dart';
import '../repository/repo_branch.dart';
import '../service/service_brand_context.dart';
import '../util/snackbar_util.dart';
import 'app_dialog_components.dart';

/// Modal dialog for renewing or assigning a new plan to a branch.
/// Provides a clear "Last Plan" vs "New Plan" live preview so administrators
/// can review exactly what is changing when renewing the subscription.
class DialogRenewPlan extends StatefulWidget {
  final ModelBranch branch;
  final VoidCallback? onPlanUpdated;

  const DialogRenewPlan({
    super.key,
    required this.branch,
    this.onPlanUpdated,
  });

  /// Displays the Renew / Assign Plan dialog.
  static Future<ModelBranch?> show(
    BuildContext context, {
    required ModelBranch branch,
    VoidCallback? onPlanUpdated,
  }) async {
    return await Get.dialog<ModelBranch>(
      DialogRenewPlan(branch: branch, onPlanUpdated: onPlanUpdated),
      barrierDismissible: false,
    );
  }

  @override
  State<DialogRenewPlan> createState() => _DialogRenewPlanState();
}

class _DialogRenewPlanState extends State<DialogRenewPlan> {
  final _formKey = GlobalKey<FormState>();
  final RepoBranch _repoBranch = Get.find<RepoBranch>();

  late TextEditingController _noteController;
  late TextEditingController _usersController;
  late TextEditingController _posController;
  late TextEditingController _pushDaysController;

  late DateTime _selectedExpiry;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final currentPlan = widget.branch.planDetails;

    _noteController = TextEditingController(
      text: currentPlan?.note.isNotEmpty == true
          ? '${currentPlan!.note} (Renewed)'
          : 'Standard Plan Renewal',
    );
    _usersController = TextEditingController(
      text: '${currentPlan?.maxUsers ?? 5}',
    );
    _posController = TextEditingController(
      text: '${currentPlan?.maxPosDevices ?? 2}',
    );
    _pushDaysController = TextEditingController(
      text: '${currentPlan?.pushFromLastDays ?? 30}',
    );

    // Calculate default expiry: 30 days from now, or 30 days past current expiry
    final now = DateTime.now();
    final currentExp = currentPlan?.expiryDate;
    if (currentExp != null && currentExp.isAfter(now)) {
      _selectedExpiry = currentExp.add(const Duration(days: 30));
    } else {
      _selectedExpiry = now.add(const Duration(days: 30));
    }

    _noteController.addListener(_refreshState);
    _usersController.addListener(_refreshState);
    _posController.addListener(_refreshState);
  }

  void _refreshState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _noteController.removeListener(_refreshState);
    _usersController.removeListener(_refreshState);
    _posController.removeListener(_refreshState);
    _noteController.dispose();
    _usersController.dispose();
    _posController.dispose();
    _pushDaysController.dispose();
    super.dispose();
  }

  int get _parsedUsers => int.tryParse(_usersController.text.trim()) ?? 1;
  int get _parsedPos => int.tryParse(_posController.text.trim()) ?? 1;
  int get _parsedPushDays => int.tryParse(_pushDaysController.text.trim()) ?? 15;

  void _applyDurationOffset(int days) {
    setState(() {
      final now = DateTime.now();
      final currentExp = widget.branch.planDetails?.expiryDate;
      if (currentExp != null && currentExp.isAfter(now)) {
        _selectedExpiry = currentExp.add(Duration(days: days));
      } else {
        _selectedExpiry = now.add(Duration(days: days));
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiry.isAfter(now) ? _selectedExpiry : now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      helpText: 'Select New Plan Expiry Date',
      confirmText: 'SET EXPIRY',
    );
    if (picked != null) {
      setState(() {
        _selectedExpiry = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999);
      });
    }
  }

  Future<void> _submitRenewal() async {
    if (!_formKey.currentState!.validate()) return;

    final branchId = widget.branch.id;
    if (branchId == null || branchId.isEmpty) {
      SnackbarUtil.showError('Branch ID is missing.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'note': _noteController.text.trim(),
        'maxUsers': _parsedUsers,
        'maxPosDevices': _parsedPos,
        'expiryAt': _selectedExpiry.millisecondsSinceEpoch,
        'pushFromLastDays': _parsedPushDays,
      };

      final (updatedBranch, success, message) = await _repoBranch.assignPlanToBranch(branchId, payload);

      if (success) {
        // If this branch is currently selected in ServiceBrandContext, update it
        try {
          final ServiceBrandContext brandCtx = Get.find<ServiceBrandContext>();
          if (brandCtx.selectedBranch?.id == branchId) {
            final branchWithPlan = updatedBranch ??
                widget.branch.copyWith(
                  planDetails: BranchPlanDetails(
                    note: payload['note'] as String,
                    maxUsers: payload['maxUsers'] as int,
                    maxPosDevices: payload['maxPosDevices'] as int,
                    expiryAt: payload['expiryAt'],
                    pushFromLastDays: payload['pushFromLastDays'] as int,
                    assignedAt: DateTime.now().millisecondsSinceEpoch,
                  ),
                );
            brandCtx.rxSelectedBranch.value = branchWithPlan;
          }
        } catch (_) {}

        widget.onPlanUpdated?.call();
        SnackbarUtil.showSuccess(
          'Plan renewed successfully!\nNew plan "${payload['note']}" is now active and tracked.',
        );
        Get.back(result: updatedBranch);
      } else {
        SnackbarUtil.showError('Failed to renew plan: $message');
      }
    } catch (e) {
      SnackbarUtil.showError('Error renewing plan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPlan = widget.branch.planDetails;

    final formattedNewExpiry =
        '${_selectedExpiry.day.toString().padLeft(2, '0')}/${_selectedExpiry.month.toString().padLeft(2, '0')}/${_selectedExpiry.year}';

    // Calculate changes
    final int userDelta = _parsedUsers - (currentPlan?.maxUsers ?? 0);
    final int posDelta = _parsedPos - (currentPlan?.maxPosDevices ?? 0);

    return AppDialog(
      maxWidth: 680,
      maxHeight: 740,
      header: DialogHeader(
        title: 'Renew / Update Branch Plan',
        icon: Icons.published_with_changes_rounded,
        iconColor: colorScheme.primary,
        onClose: () => Get.back(),
      ),
      body: DialogBody(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Branch Context Header ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Branch: ${widget.branch.name.en} (${widget.branch.branchCode})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (currentPlan?.isExpired ?? false)
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (currentPlan?.isExpired ?? false) ? 'EXPIRED' : 'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: (currentPlan?.isExpired ?? false) ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── "Last Plan" vs "New Plan" Side-by-Side Comparison ─────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B),
                            const Color(0xFF0F172A),
                          ]
                        : [
                            const Color(0xFFF8FAFC),
                            const Color(0xFFF1F5F9),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.compare_arrows_rounded, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'PLAN RENEWAL TRACKING COMPARISON',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Last / Previous Plan
                        Expanded(
                          child: _buildComparisonCard(
                            context,
                            badgeText: 'LAST / PREVIOUS PLAN',
                            badgeColor: Colors.grey.shade600,
                            tierName: currentPlan?.note.isNotEmpty == true
                                ? currentPlan!.note
                                : 'Default / None',
                            users: '${currentPlan?.maxUsers ?? 0}',
                            pos: '${currentPlan?.maxPosDevices ?? 0}',
                            expiry: currentPlan?.formattedExpiry ?? 'Not Set',
                            assigned: currentPlan?.formattedAssignedAt ?? 'N/A',
                            isNew: false,
                          ),
                        ),

                        // Center Arrow Transition
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
                          child: Column(
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Renew',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: New Renewed Plan
                        Expanded(
                          child: _buildComparisonCard(
                            context,
                            badgeText: 'NEW RENEWAL PLAN',
                            badgeColor: const Color(0xFF10B981),
                            tierName: _noteController.text.trim().isNotEmpty
                                ? _noteController.text.trim()
                                : 'New Plan',
                            users: '$_parsedUsers',
                            pos: '$_parsedPos',
                            expiry: formattedNewExpiry,
                            assigned: 'Today (Active upon save)',
                            isNew: true,
                            userDelta: userDelta,
                            posDelta: posDelta,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Form Configuration Section ────────────────────────────────
              Text(
                'New Plan Configuration',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Plan Name / Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Plan Name / Note *',
                  hintText: 'e.g. Premium Plan, Enterprise Yearly Renewal',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Plan note is required' : null,
              ),

              const SizedBox(height: 12),

              // Quotas: Max Users & Max POS Devices
              Row(
                children: [
                  Expanded(
                    child: _buildCounterField(
                      controller: _usersController,
                      label: 'Max Users (Staff/Cashiers)',
                      icon: Icons.people_alt_rounded,
                      onIncrement: () => _usersController.text = '${_parsedUsers + 1}',
                      onDecrement: () {
                        if (_parsedUsers > 1) {
                          _usersController.text = '${_parsedUsers - 1}';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCounterField(
                      controller: _posController,
                      label: 'Max POS Devices (Terminals)',
                      icon: Icons.point_of_sale_rounded,
                      onIncrement: () => _posController.text = '${_parsedPos + 1}',
                      onDecrement: () {
                        if (_parsedPos > 1) {
                          _posController.text = '${_parsedPos - 1}';
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Validity Quick Selectors
              Text(
                'Plan Duration & Expiry Date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildDurationChip('+30 Days', 30),
                  _buildDurationChip('+90 Days', 90),
                  _buildDurationChip('+180 Days', 180),
                  _buildDurationChip('+365 Days (1 Yr)', 365),
                  ActionChip(
                    avatar: const Icon(Icons.date_range_rounded, size: 15),
                    label: Text(
                      'Custom: $formattedNewExpiry',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _pickCustomDate,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Alert Window (Push From Last Days)
              TextFormField(
                controller: _pushDaysController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Alert Window (Days before expiry to prompt renewal)',
                  hintText: '30',
                  prefixIcon: const Icon(Icons.notifications_active_outlined, size: 18),
                  suffixText: 'days prior',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed < 1) return 'Must be at least 1 day';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          border: Border(
            top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitRenewal,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _isSubmitting ? 'Renewing Plan...' : 'Confirm & Renew Plan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context, {
    required String badgeText,
    required Color badgeColor,
    required String tierName,
    required String users,
    required String pos,
    required String expiry,
    required String assigned,
    required bool isNew,
    int userDelta = 0,
    int posDelta = 0,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? (isNew ? const Color(0xFF064E3B).withValues(alpha: 0.3) : colorScheme.surface)
            : (isNew ? const Color(0xFFECFDF5) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isNew ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: badgeColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tierName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 12),
          _buildMetricRow(
            'Max Users',
            users,
            delta: isNew && userDelta != 0 ? (userDelta > 0 ? '+$userDelta' : '$userDelta') : null,
            deltaColor: userDelta >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 4),
          _buildMetricRow(
            'POS Terminals',
            pos,
            delta: isNew && posDelta != 0 ? (posDelta > 0 ? '+$posDelta' : '$posDelta') : null,
            deltaColor: posDelta >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 4),
          _buildMetricRow('Expires On', expiry),
          const SizedBox(height: 4),
          _buildMetricRow('Assigned', assigned),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {String? delta, Color? deltaColor}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        if (delta != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: (deltaColor ?? Colors.green).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              delta,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: deltaColor ?? Colors.green,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCounterField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              onPressed: onDecrement,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              onPressed: onIncrement,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: (v) {
        final parsed = int.tryParse(v?.trim() ?? '');
        if (parsed == null || parsed < 1) return 'Must be ≥ 1';
        return null;
      },
    );
  }

  Widget _buildDurationChip(String label, int days) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      onPressed: () => _applyDurationOffset(days),
    );
  }
}
