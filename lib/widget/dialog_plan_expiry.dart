import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/model_branch.dart';
import '../repository/repo_branch.dart';
import '../repository/repo_storage.dart';
import '../service/service_brand_context.dart';
import '../util/snackbar_util.dart';
import 'app_dialog_components.dart';

/// Modal dialog displaying comprehensive Branch Subscription, Expiry details,
/// and full Plan History.
///
/// Features:
/// - Active plan status & quota limits.
/// - Full plan history timeline fetched via GET /api/branches/:id/plan-history.
/// - Expiry alarm configuration (days before expiry notification).
/// - Read-only view for users without renewal actions.
class DialogPlanExpiry extends StatefulWidget {
  final ModelBranch? branch;
  final bool isWarningOnly;
  final int initialTabIndex;

  const DialogPlanExpiry({
    super.key,
    this.branch,
    this.isWarningOnly = false,
    this.initialTabIndex = 0,
  });

  /// Displays the subscription plan details dialog (defaulting to the Active Plan tab).
  static void show(
    BuildContext context, {
    ModelBranch? branch,
    bool isWarningOnly = false,
  }) {
    Get.dialog(
      DialogPlanExpiry(
        branch: branch,
        isWarningOnly: isWarningOnly,
        initialTabIndex: 0,
      ),
      barrierDismissible: true,
    );
  }

  /// Displays the subscription plan dialog opened directly to the Plan History tab.
  static void showHistory(
    BuildContext context, {
    ModelBranch? branch,
  }) {
    Get.dialog(
      DialogPlanExpiry(
        branch: branch,
        initialTabIndex: 1,
      ),
      barrierDismissible: true,
    );
  }

  /// Automatically displays the dialog if the branch plan is expiring soon or already expired.
  static bool _hasShownPromptThisSession = false;

  static void showIfExpiringSoon(
    BuildContext context, {
    ModelBranch? branch,
    bool force = false,
  }) {
    if (_hasShownPromptThisSession && !force) return;

    final ServiceBrandContext brandCtx = Get.find();
    final activeBranch = branch ?? brandCtx.selectedBranch;
    final plan = activeBranch?.planDetails;

    if (plan == null) return;

    if (brandCtx.isPlanExpiringSoon || plan.isExpiringSoon || plan.isExpired) {
      _hasShownPromptThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          show(Get.context!, branch: activeBranch, isWarningOnly: true);
        }
      });
    }
  }

  @override
  State<DialogPlanExpiry> createState() => _DialogPlanExpiryState();
}

class _DialogPlanExpiryState extends State<DialogPlanExpiry>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RepoBranch _repoBranch = Get.find<RepoBranch>();

  ModelBranch? _activeBranch;
  List<ModelBranchPlanHistory> _historyList = [];
  bool _isLoadingHistory = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    final ServiceBrandContext brandCtx = Get.find();
    _activeBranch = widget.branch ?? brandCtx.selectedBranch;

    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final branchId = _activeBranch?.id;
    if (branchId == null || branchId.isEmpty) return;

    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final (history, success, message) =
          await _repoBranch.getBranchPlanHistory(branchId);
      if (mounted) {
        setState(() {
          if (success) {
            _historyList = history;
          } else {
            _historyError = message;
          }
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = 'Error loading history: $e';
          _isLoadingHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ServiceBrandContext brandCtx = Get.find();
    final branch = _activeBranch ?? brandCtx.selectedBranch;
    final activeBrand = brandCtx.selectedBrand;
    final plan = branch?.planDetails;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isExpired = plan?.isExpired ?? false;
    final bool isExpiringSoon = brandCtx.isPlanExpiringSoon || (plan?.isExpiringSoon ?? false);

    // Theme color based on expiration status
    final Color statusColor = isExpired
        ? const Color(0xFFEF4444) // Red
        : isExpiringSoon
            ? const Color(0xFFF59E0B) // Amber
            : const Color(0xFF10B981); // Emerald Green

    final IconData statusIcon = isExpired
        ? Icons.error_rounded
        : isExpiringSoon
            ? Icons.warning_amber_rounded
            : Icons.verified_user_rounded;

    return AppDialog(
      maxWidth: 640,
      maxHeight: 740,
      header: DialogHeader(
        title: 'Plan & Subscription Details',
        icon: statusIcon,
        iconColor: statusColor,
      ),
      body: Column(
        children: [
          // ── Tab Bar ───────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(
                  icon: Icon(Icons.credit_card_rounded, size: 18),
                  text: 'Current Plan',
                ),
                Tab(
                  icon: const Icon(Icons.history_edu_rounded, size: 18),
                  text: _historyList.isNotEmpty
                      ? 'Plan History (${_historyList.length})'
                      : 'Plan History',
                ),
              ],
            ),
          ),

          // ── Tab Views ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Current Plan Overview
                _buildCurrentPlanTab(
                  context,
                  branch: branch,
                  activeBrand: activeBrand,
                  plan: plan,
                  statusColor: statusColor,
                  statusIcon: statusIcon,
                  isExpired: isExpired,
                  isExpiringSoon: isExpiringSoon,
                ),

                // Tab 2: Plan History & Renewal Tracking
                _buildHistoryTab(
                  context,
                  branch: branch,
                  currentPlan: plan,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          border: Border(
            top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (branch?.contact.phones.primary.isNotEmpty == true)
              TextButton.icon(
                onPressed: () {
                  Get.snackbar(
                    'Branch Contact',
                    'Phone: ${branch!.contact.phones.primary}\nEmail: ${branch.contact.email}',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 4),
                  );
                },
                icon: const Icon(Icons.phone_in_talk_rounded, size: 15),
                label: const Text('Support Contact', style: TextStyle(fontSize: 12)),
              )
            else
              const SizedBox.shrink(),
            Row(
              children: [
                FilledButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Current Plan View ──────────────────────────────────────────────

  Widget _buildCurrentPlanTab(
    BuildContext context, {
    required ModelBranch? branch,
    required dynamic activeBrand,
    required BranchPlanDetails? plan,
    required Color statusColor,
    required IconData statusIcon,
    required bool isExpired,
    required bool isExpiringSoon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ServiceBrandContext brandCtx = Get.find<ServiceBrandContext>();
    final int? daysRemaining = plan?.daysRemaining;

    final String statusTitle = isExpired
        ? 'Subscription Expired'
        : isExpiringSoon
            ? 'Subscription Expiring Soon'
            : 'Active Subscription Plan';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Prominent Status Banner ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            statusTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              plan?.expiryStatusText.toUpperCase() ?? 'ACTIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isExpired
                            ? 'Your branch subscription plan expired on ${plan?.formattedExpiry ?? "N/A"}. Please contact customer care.'
                            : isExpiringSoon
                                ? 'This branch plan will expire on ${plan?.formattedExpiry ?? "N/A"} (${daysRemaining != null ? (daysRemaining == 0 ? "Expires today" : daysRemaining == 1 ? "1 day remaining" : "$daysRemaining days remaining") : ""}).'
                                : 'Your branch subscription is currently active and fully operational until ${plan?.formattedExpiry ?? "N/A"}.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Branch & Brand Context Summary ───────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.storefront_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${activeBrand?.name.en ?? "Brand"} › ${branch?.name.en ?? "Branch"} (${branch?.branchCode ?? ""})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Plan Quotas & Specifications Grid ─────────────────────────
          Text(
            'Plan Quotas & Limits',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildQuotaCard(
                  context,
                  title: 'Max Users',
                  value: '${plan?.maxUsers ?? 5}',
                  subtitle: 'Cashiers & Staff',
                  icon: Icons.people_alt_rounded,
                  accentColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuotaCard(
                  context,
                  title: 'Max POS Devices',
                  value: '${plan?.maxPosDevices ?? 2}',
                  subtitle: 'Active Terminals',
                  icon: Icons.point_of_sale_rounded,
                  accentColor: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildQuotaCard(
                  context,
                  title: 'Expiry Date',
                  value: plan?.formattedExpiry ?? 'Not Set',
                  subtitle: daysRemaining != null
                      ? (daysRemaining > 1
                          ? '$daysRemaining days left'
                          : daysRemaining == 1
                              ? '1 day left'
                              : daysRemaining == 0
                                  ? 'Expires today'
                                  : 'Expired')
                      : 'Lifetime',
                  icon: Icons.calendar_month_rounded,
                  accentColor: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuotaCard(
                  context,
                  title: 'Plan Tier',
                  value: plan?.note.isNotEmpty == true ? plan!.note : 'Default',
                  subtitle: 'Assigned: ${plan?.formattedAssignedAt ?? "N/A"}',
                  icon: Icons.card_membership_rounded,
                  accentColor: Colors.teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Expiry Alarm & Notification Configuration Card ─────────────
          _buildExpiryAlarmCard(context, brandCtx),

          const SizedBox(height: 14),

          // ── Quick History Callout ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Track historical subscription records and limits anytime under the "Plan History" tab.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View History', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Expiry Alarm Setting Widget ───────────────────────────────────────────

  Widget _buildExpiryAlarmCard(BuildContext context, ServiceBrandContext brandCtx) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final currentAlarmDays = brandCtx.expiryAlarmDays;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notification_important_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expiry Alarm Notification',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Set how many days before expiry you want to receive warning popups in POS',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$currentAlarmDays DAYS BEFORE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Quick preset chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [3, 7, 10, 15, 30].map((days) {
                final isSelected = currentAlarmDays == days;
                return ChoiceChip(
                  label: Text('$days Days'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFF59E0B),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                  ),
                  onSelected: (selected) async {
                    if (selected) {
                      brandCtx.setExpiryAlarmDays(days);
                      if (Get.isRegistered<RepoStorage>()) {
                        await Get.find<RepoStorage>().setExpiryAlarmDays(days);
                      }
                      SnackbarUtil.showSuccess('Expiry alarm set to $days days before plan expiry');
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Stepper for custom days
            Row(
              children: [
                Text(
                  'Custom Days Alarm:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: currentAlarmDays > 1
                      ? () async {
                          final newDays = currentAlarmDays - 1;
                          brandCtx.setExpiryAlarmDays(newDays);
                          if (Get.isRegistered<RepoStorage>()) {
                            await Get.find<RepoStorage>().setExpiryAlarmDays(newDays);
                          }
                        }
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$currentAlarmDays',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: currentAlarmDays < 90
                      ? () async {
                          final newDays = currentAlarmDays + 1;
                          brandCtx.setExpiryAlarmDays(newDays);
                          if (Get.isRegistered<RepoStorage>()) {
                            await Get.find<RepoStorage>().setExpiryAlarmDays(newDays);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Tab 2: Plan History & Renewal Tracking ────────────────────────────────

  Widget _buildHistoryTab(
    BuildContext context, {
    required ModelBranch? branch,
    required BranchPlanDetails? currentPlan,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingHistory) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 12),
            Text('Fetching branch plan history...'),
          ],
        ),
      );
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
              const SizedBox(height: 10),
              Text(
                _historyError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historyList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                'No Plan History Records Yet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Initial plan is active. When historical plan updates occur,\nall past subscription records will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine the "Last Plan" for renewal comparison.
    // If the latest history entry is currently active, the preceding entry is the last plan before renewal.
    final latestHistory = _historyList.first;
    final ModelBranchPlanHistory? previousHistory =
        _historyList.length > 1 ? _historyList[1] : null;

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── "Last Plan vs Current Plan" Renewal Tracking Card ───────────
          _buildRenewalComparisonBanner(
            context,
            currentPlan: currentPlan,
            latestHistory: latestHistory,
            previousHistory: previousHistory,
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // ── Timeline Section Header ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline_rounded, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Plan History Timeline (${_historyList.length} records)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Refresh History',
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: _loadHistory,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Chronological History Items ─────────────────────────────────
          ...List.generate(_historyList.length, (index) {
            final item = _historyList[index];
            final priorItem = index + 1 < _historyList.length ? _historyList[index + 1] : null;
            final isLatest = index == 0;

            return _buildTimelineItem(
              context,
              item: item,
              priorItem: priorItem,
              recordNumber: _historyList.length - index,
              isLatest: isLatest,
            );
          }),
        ],
      ),
    );
  }

  // ── Renewal Comparison Banner ─────────────────────────────────────────────

  Widget _buildRenewalComparisonBanner(
    BuildContext context, {
    required BranchPlanDetails? currentPlan,
    required ModelBranchPlanHistory latestHistory,
    required ModelBranchPlanHistory? previousHistory,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Compare new (current/latest) vs previous
    final String lastPlanNote = previousHistory?.note.isNotEmpty == true
        ? previousHistory!.note
        : 'Initial Plan';
    final int lastUsers = previousHistory?.maxUsers ?? 5;
    final int lastPos = previousHistory?.maxPosDevices ?? 2;
    final String lastExpiry = previousHistory?.formattedExpiry ?? 'Not Set';
    final String lastAssigned = previousHistory?.formattedAssignedAt ?? 'N/A';

    final String newPlanNote = currentPlan?.note.isNotEmpty == true
        ? currentPlan!.note
        : latestHistory.note;
    final int newUsers = currentPlan?.maxUsers ?? latestHistory.maxUsers;
    final int newPos = currentPlan?.maxPosDevices ?? latestHistory.maxPosDevices;
    final String newExpiry = currentPlan?.formattedExpiry ?? latestHistory.formattedExpiry;
    final String newAssigned = currentPlan?.formattedAssignedAt ?? latestHistory.formattedAssignedAt;

    final int userDiff = newUsers - lastUsers;
    final int posDiff = newPos - lastPos;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF0FDF4), const Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.published_with_changes_rounded, size: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SUBSCRIPTION PLAN COMPARISON',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TRACKED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Last / Previous Plan Card
              Expanded(
                child: _buildSideCard(
                  context,
                  badge: 'PREVIOUS PLAN',
                  badgeColor: Colors.blueGrey,
                  title: lastPlanNote,
                  users: '$lastUsers Users',
                  pos: '$lastPos Terminals',
                  expiry: lastExpiry,
                  assigned: lastAssigned,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(height: 2),
                    Text(
                      'Upgraded',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Current / New Renewed Plan Card
              Expanded(
                child: _buildSideCard(
                  context,
                  badge: 'CURRENT ACTIVE PLAN',
                  badgeColor: const Color(0xFF10B981),
                  title: newPlanNote,
                  users: '$newUsers Users',
                  pos: '$newPos Terminals',
                  expiry: newExpiry,
                  assigned: newAssigned,
                  userDelta: userDiff != 0 ? (userDiff > 0 ? '+$userDiff' : '$userDiff') : null,
                  posDelta: posDiff != 0 ? (posDiff > 0 ? '+$posDiff' : '$posDiff') : null,
                  isHighlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideCard(
    BuildContext context, {
    required String badge,
    required Color badgeColor,
    required String title,
    required String users,
    required String pos,
    required String expiry,
    required String assigned,
    String? userDelta,
    String? posDelta,
    bool isHighlight = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? (isHighlight ? const Color(0xFF064E3B).withValues(alpha: 0.25) : colorScheme.surface)
            : (isHighlight ? Colors.white : Colors.white.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 10),
          _buildMiniRow('Users:', users, delta: userDelta),
          _buildMiniRow('POS:', pos, delta: posDelta),
          _buildMiniRow('Expiry:', expiry),
          _buildMiniRow('Date:', assigned),
        ],
      ),
    );
  }

  Widget _buildMiniRow(String label, String value, {String? delta}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          if (delta != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                delta,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Timeline Item ─────────────────────────────────────────────────────────

  Widget _buildTimelineItem(
    BuildContext context, {
    required ModelBranchPlanHistory item,
    required ModelBranchPlanHistory? priorItem,
    required int recordNumber,
    required bool isLatest,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userDelta = priorItem != null ? item.maxUsers - priorItem.maxUsers : null;
    final posDelta = priorItem != null ? item.maxPosDevices - priorItem.maxPosDevices : null;

    final Color cardColor = isLatest
        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
        : (isDark ? colorScheme.surfaceContainer.withValues(alpha: 0.4) : colorScheme.surfaceContainerLow);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isLatest ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isLatest
                      ? const Color(0xFF10B981)
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLatest ? 'ACTIVE #$recordNumber' : 'RECORD #$recordNumber',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isLatest ? Colors.white : colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.note.isNotEmpty ? item.note : 'Plan Update',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (item.isExpired ? Colors.red : Colors.teal).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.expiryStatusText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: item.isExpired ? Colors.red : Colors.teal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Quotas chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildMetricChip(
                icon: Icons.people_alt_rounded,
                label: 'Users: ${item.maxUsers}',
                delta: userDelta != null && userDelta != 0
                    ? (userDelta > 0 ? '+$userDelta' : '$userDelta')
                    : null,
                color: Colors.blueAccent,
              ),
              _buildMetricChip(
                icon: Icons.point_of_sale_rounded,
                label: 'POS: ${item.maxPosDevices}',
                delta: posDelta != null && posDelta != 0
                    ? (posDelta > 0 ? '+$posDelta' : '$posDelta')
                    : null,
                color: Colors.deepPurpleAccent,
              ),
              _buildMetricChip(
                icon: Icons.calendar_today_rounded,
                label: 'Expires: ${item.formattedExpiry}',
                color: item.isExpired ? Colors.red : Colors.green,
              ),
              if (item.pushFromLastDays != null && item.pushFromLastDays! > 0)
                _buildMetricChip(
                  icon: Icons.notifications_active_outlined,
                  label: 'Alert: ${item.pushFromLastDays}d',
                  color: Colors.amber.shade800,
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Metadata row: assigned date & assigned by
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                'Assigned: ${item.formattedAssignedAt}',
                style: TextStyle(fontSize: 10.5, color: colorScheme.outline),
              ),
              if (item.assignedBy != null && item.assignedBy!.isNotEmpty) ...[
                const SizedBox(width: 10),
                Icon(Icons.person_outline_rounded, size: 12, color: colorScheme.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'By: ${item.assignedBy}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: colorScheme.outline),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    String? delta,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                delta,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
