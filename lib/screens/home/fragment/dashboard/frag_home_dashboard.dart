import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../service/service_brand_context.dart';
import '../../../../widget/dialog_plan_expiry.dart';
import 'controller_home_dashboard.dart';

// ────────────────────────────────────────────────────────
//  Theme Helpers & Dynamic Colors
// ────────────────────────────────────────────────────────

class _DashboardTheme {
  // Vibrant accents that look good on both light/dark
  static const purple = Color(0xFF8B5CF6);
  static const teal = Color(0xFF06B6D4);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
  static const lightPurple = Color(0xFFBDA5F7);
  static const lightTeal = Color(0xFF67E8F9);

  // Derived colors
  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLowest;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3);

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color chartGrid(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2);
}

class FragHomeDashboard extends StatelessWidget {
  const FragHomeDashboard({super.key});

  bool _isPlanBannerActive() {
    if (!Get.isRegistered<ServiceBrandContext>()) return false;
    final ServiceBrandContext brandCtx = Get.find();
    final branch = brandCtx.rxSelectedBranch.value;
    final plan = branch?.planDetails;
    if (plan == null) return false;
    return plan.isExpiringSoon || plan.isExpired;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<ControllerHomeDashboard>()
        ? Get.find<ControllerHomeDashboard>()
        : Get.put(ControllerHomeDashboard());

    return Scaffold(
      backgroundColor: _DashboardTheme.background(context),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _DashboardTheme.purple),
          );
        }

        final hasBanner = _isPlanBannerActive();

        return RefreshIndicator(
          color: _DashboardTheme.purple,
          backgroundColor: _DashboardTheme.cardBg(context),
          onRefresh: () async => ctrl.loadData(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final hasBoundedHeight = constraints.hasBoundedHeight;
              final availableHeight =
                  hasBoundedHeight ? constraints.maxHeight : 720.0;

              // Responsive scaling criteria:
              // 14-inch display: ~1000-1280px wide & 650-750px tall
              // 22-inch display: ~1680-1920px wide & 900-1080px tall
              final isLarge = availableWidth >= 1400 || availableHeight >= 850;
              final horizontalPadding = isLarge ? 24.0 : 16.0;
              final sectionGap = isLarge ? 16.0 : 12.0;

              // Estimate height consumed by fixed elements
              final headerHeight = isLarge ? 72.0 : 62.0;
              final bannerHeight = hasBanner ? (isLarge ? 68.0 : 58.0) : 0.0;
              final statCardsHeight = isLarge ? 106.0 : 88.0;
              final bottomPadding = isLarge ? 20.0 : 14.0;

              // Total vertical gap spacing
              final totalGaps =
                  (hasBanner ? sectionGap : 0.0) + (sectionGap * 3) + bottomPadding;
              final fixedConsumed =
                  headerHeight + bannerHeight + statCardsHeight + totalGaps;

              // Calculate available height for the two chart rows
              final remainingForRows = availableHeight - fixedConsumed;

              // Row 2 takes ~54% of remaining space, Row 3 takes ~46%
              // Clamped to sensible minimums and maximums so it never breaks on small windows
              final row2Height = (remainingForRows * 0.54).clamp(240.0, 500.0);
              final row3Height = (remainingForRows * 0.46).clamp(190.0, 420.0);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: availableHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header ──
                        _buildHeader(context, ctrl, isLarge, horizontalPadding),

                        // ── Plan Expiry Alert Banner ──
                        if (hasBanner) ...[
                          _buildPlanExpiryBanner(
                              context, isLarge, horizontalPadding),
                          SizedBox(height: sectionGap),
                        ],

                        // ── Top Stat Cards ──
                        _buildStatCards(
                            context, ctrl, isLarge, horizontalPadding),

                        SizedBox(height: sectionGap),

                        // ── Row 2: Total Sales line chart | CashFlow bar chart ──
                        _buildRow2(context, ctrl, isLarge, horizontalPadding,
                            row2Height),

                        SizedBox(height: sectionGap),

                        // ── Row 3: Top Selling Items | Weekly Overview | Payment Mode ──
                        _buildRow3(context, ctrl, isLarge, horizontalPadding,
                            row3Height),

                        SizedBox(height: bottomPadding),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // ──────────────────────────────────────────────────────
  //  Plan Expiry Alert Banner
  // ──────────────────────────────────────────────────────
  Widget _buildPlanExpiryBanner(
      BuildContext context, bool isLarge, double horizontalPadding) {
    if (!Get.isRegistered<ServiceBrandContext>()) return const SizedBox.shrink();
    final ServiceBrandContext brandCtx = Get.find();

    return Obx(() {
      final branch = brandCtx.rxSelectedBranch.value;
      final plan = branch?.planDetails;
      if (plan == null) return const SizedBox.shrink();

      if (!plan.isExpiringSoon && !plan.isExpired) {
        return const SizedBox.shrink();
      }

      final isExpired = plan.isExpired;
      final color = isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
      final icon =
          isExpired ? Icons.error_outline_rounded : Icons.warning_amber_rounded;
      final branchName = branch?.name.en ?? 'Branch';

      return Container(
        margin: EdgeInsets.fromLTRB(
            horizontalPadding, 0, horizontalPadding, isLarge ? 12 : 10),
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 20 : 16,
          vertical: isLarge ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(isLarge ? 14 : 12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isLarge ? 10 : 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: isLarge ? 22 : 20),
            ),
            SizedBox(width: isLarge ? 14 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isExpired
                        ? 'Plan Expired for $branchName'
                        : 'Plan Expiring Soon: ${plan.expiryStatusText}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isLarge ? 14 : 13,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isExpired
                        ? 'Your subscription expired on ${plan.formattedExpiry}. Contact administrator to renew.'
                        : 'Your branch subscription will expire on ${plan.formattedExpiry}. Please renew in advance.',
                    style: TextStyle(
                      fontSize: isLarge ? 12.5 : 11.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => DialogPlanExpiry.show(context, branch: branch),
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                padding: EdgeInsets.symmetric(
                  horizontal: isLarge ? 16 : 12,
                  vertical: isLarge ? 10 : 8,
                ),
              ),
              child: Text(
                'View Plan',
                style: TextStyle(
                  fontSize: isLarge ? 13 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ──────────────────────────────────────────────────────
  //  Header
  // ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, ControllerHomeDashboard ctrl,
      bool isLarge, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isLarge ? 18 : 14,
        horizontalPadding,
        isLarge ? 12 : 8,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLarge ? 12 : 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_DashboardTheme.purple, _DashboardTheme.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isLarge ? 14 : 12),
            ),
            child: Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: isLarge ? 22 : 20,
            ),
          ),
          SizedBox(width: isLarge ? 14 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'dashboard'.tr,
                style: TextStyle(
                  color: _DashboardTheme.textPrimary(context),
                  fontSize: isLarge ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  color: _DashboardTheme.textSecondary(context),
                  fontSize: isLarge ? 13 : 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          _PillButton(
            label: 'refresh'.tr,
            icon: Icons.refresh_rounded,
            onTap: ctrl.loadData,
            isLarge: isLarge,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  Top Stat Cards
  // ──────────────────────────────────────────────────────
  Widget _buildStatCards(BuildContext context, ControllerHomeDashboard ctrl,
      bool isLarge, double horizontalPadding) {
    final fmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    final cardGap = isLarge ? 14.0 : 10.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          _StatCard(
            title: 'todays_sales'.tr,
            value: fmt.format(ctrl.todaySales.value),
            subtitle: '${ctrl.todayOrders.value} ${'orders'.tr}',
            isLarge: isLarge,
          ),
          SizedBox(width: cardGap),
          _StatCard(
            title: 'todays_orders'.tr,
            value: '${ctrl.todayOrders.value}',
            subtitle: 'bills_today'.tr,
            isLarge: isLarge,
          ),
          SizedBox(width: cardGap),
          _StatCard(
            title: 'avg_bill'.tr,
            value: fmt.format(ctrl.averageBill.value),
            subtitle: 'per_order'.tr,
            isLarge: isLarge,
          ),
          SizedBox(width: cardGap),
          _StatCard(
            title: 'total_items'.tr,
            value: '${ctrl.totalItems.value}',
            subtitle: 'in_system'.tr,
            isLarge: isLarge,
          ),
          SizedBox(width: cardGap),
          _StatCard(
            title: 'total_customers'.tr,
            value: '${ctrl.totalCustomers.value}',
            subtitle: 'total'.tr,
            isGreenBadge: true,
            isLarge: isLarge,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  Row 2: Total Sales (line) + CashFlow (stacked bar)
  // ──────────────────────────────────────────────────────
  Widget _buildRow2(BuildContext context, ControllerHomeDashboard ctrl,
      bool isLarge, double horizontalPadding, double rowHeight) {
    final cardGap = isLarge ? 18.0 : 14.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Sales line chart
          Expanded(
            flex: 55,
            child: _DashCard(
              height: rowHeight,
              isLarge: isLarge,
              title: 'total_sales'.tr,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Legend(
                    color: _DashboardTheme.textPrimary(context),
                    label: 'this_week'.tr,
                    isLarge: isLarge,
                  ),
                  SizedBox(width: isLarge ? 16 : 12),
                  _Legend(
                    color: _DashboardTheme.lightTeal,
                    label: 'last_week'.tr,
                    isLarge: isLarge,
                  ),
                ],
              ),
              child: _TotalSalesChart(
                thisWeek: ctrl.thisWeekSales.toList(),
                lastWeek: ctrl.lastWeekSales.toList(),
                labels: ctrl.weekLabels.toList(),
                isLarge: isLarge,
              ),
            ),
          ),
          SizedBox(width: cardGap),
          // CashFlow stacked bar chart
          Expanded(
            flex: 45,
            child: _DashCard(
              height: rowHeight,
              isLarge: isLarge,
              title: 'cashflow'.tr,
              trailing: _PillButton(
                label: 'weekly'.tr,
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: () {},
                isLarge: isLarge,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _CashFlowChart(
                      inflow: ctrl.cashInflow.toList(),
                      outflow: ctrl.cashOutflow.toList(),
                      labels: ctrl.cashflowLabels.toList(),
                      isLarge: isLarge,
                    ),
                  ),
                  SizedBox(height: isLarge ? 10 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _Legend(
                        color: _DashboardTheme.lightPurple,
                        label: 'inflow'.tr,
                        isLarge: isLarge,
                      ),
                      SizedBox(width: isLarge ? 20 : 16),
                      _Legend(
                        color: _DashboardTheme.blue,
                        label: 'outflow'.tr,
                        isLarge: isLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  Row 3: Top Selling | Weekly Overview | Payment Mode
  // ──────────────────────────────────────────────────────
  Widget _buildRow3(BuildContext context, ControllerHomeDashboard ctrl,
      bool isLarge, double horizontalPadding, double rowHeight) {
    final cardGap = isLarge ? 18.0 : 14.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Selling Items donut
          Expanded(
            flex: 33,
            child: _DashCard(
              height: rowHeight,
              isLarge: isLarge,
              title: 'top_selling_items'.tr,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PillButton(
                    label: 'today'.tr,
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () {},
                    isLarge: isLarge,
                  ),
                  SizedBox(width: isLarge ? 8 : 6),
                  _PillButton(
                    label: 'limit_5'.tr,
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () {},
                    isLarge: isLarge,
                  ),
                ],
              ),
              child: _TopItemsDonut(
                items: ctrl.topSellingItems.toList(),
                isLarge: isLarge,
              ),
            ),
          ),
          SizedBox(width: cardGap),
          // Weekly overview bar chart
          Expanded(
            flex: 34,
            child: _DashCard(
              height: rowHeight,
              isLarge: isLarge,
              title: 'dashboard_overview'.tr,
              trailing: _PillButton(
                label: 'weekly'.tr,
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: () {},
                isLarge: isLarge,
              ),
              child: _WeeklyOverviewChart(
                values: ctrl.weeklyOverview.toList(),
                labels: ctrl.overviewLabels.toList(),
                isLarge: isLarge,
              ),
            ),
          ),
          SizedBox(width: cardGap),
          // Payment Mode donut
          Expanded(
            flex: 33,
            child: _DashCard(
              height: rowHeight,
              isLarge: isLarge,
              title: 'payment_mode'.tr,
              child: _PaymentDonut(
                breakdown: Map<String, double>.from(ctrl.paymentBreakdown),
                isLarge: isLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
//  Reusable Widgets
// ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final bool isGreenBadge;
  final bool isLarge;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.isGreenBadge = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 18 : 14,
          vertical: isLarge ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: _DashboardTheme.cardBg(context),
          borderRadius: BorderRadius.circular(isLarge ? 14 : 12),
          border: Border.all(color: _DashboardTheme.cardBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: _DashboardTheme.textSecondary(context),
                      fontSize: isLarge ? 14 : 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isGreenBadge)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLarge ? 10 : 8,
                      vertical: isLarge ? 4 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6DE899),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'today'.tr,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                        fontSize: isLarge ? 11 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(isLarge ? 6 : 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF333742),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: _DashboardTheme.purple,
                      size: isLarge ? 16 : 14,
                    ),
                  ),
              ],
            ),
            SizedBox(height: isLarge ? 12 : 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: _DashboardTheme.textPrimary(context),
                        fontSize: isLarge ? 26 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: _DashboardTheme.textSecondary(context),
                      fontSize: isLarge ? 12 : 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final double? height;
  final bool isLarge;

  const _DashCard({
    required this.title,
    required this.child,
    this.trailing,
    this.height,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: _DashboardTheme.cardBg(context),
        borderRadius: BorderRadius.circular(isLarge ? 16 : 14),
        border: Border.all(color: _DashboardTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _DashboardTheme.textPrimary(context),
                  fontSize: isLarge ? 15.5 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: isLarge ? 14 : 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isLarge;

  const _PillButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 12 : 10,
          vertical: isLarge ? 6 : 5,
        ),
        decoration: BoxDecoration(
          color: _DashboardTheme.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _DashboardTheme.green.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _DashboardTheme.green,
                fontSize: isLarge ? 12 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 2),
              Icon(icon, color: _DashboardTheme.green, size: isLarge ? 16 : 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLarge;

  const _Legend({
    required this.color,
    required this.label,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLarge ? 10 : 8,
          height: isLarge ? 10 : 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: isLarge ? 6 : 5),
        Text(
          label,
          style: TextStyle(
            color: _DashboardTheme.textSecondary(context),
            fontSize: isLarge ? 12 : 11,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────
//  Total Sales: This Week vs Last Week (line chart)
// ────────────────────────────────────────────────────────
class _TotalSalesChart extends StatelessWidget {
  final List<double> thisWeek;
  final List<double> lastWeek;
  final List<String> labels;
  final bool isLarge;

  const _TotalSalesChart({
    required this.thisWeek,
    required this.lastWeek,
    required this.labels,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we have data; use 7 points
    final tw = List.generate(7, (i) => i < thisWeek.length ? thisWeek[i] : 0.0);
    final lw = List.generate(7, (i) => i < lastWeek.length ? lastWeek[i] : 0.0);
    final lbl = List.generate(7, (i) => i < labels.length ? labels[i] : '');

    final allValues = [...tw, ...lw];
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1000.0 : maxVal * 1.3;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: _DashboardTheme.chartGrid(context),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isLarge ? 50 : 44,
              getTitlesWidget: (val, _) => Text(
                _compact(val),
                style: TextStyle(
                  fontSize: isLarge ? 10.5 : 9,
                  color: _DashboardTheme.textSecondary(context),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= lbl.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    lbl[idx],
                    style: TextStyle(
                      fontSize: isLarge ? 11 : 10,
                      color: _DashboardTheme.textSecondary(context),
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => _DashboardTheme.cardBg(context),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '₹${_compact(s.y)}',
                      TextStyle(
                        color: s.barIndex == 0
                            ? _DashboardTheme.textPrimary(context)
                            : _DashboardTheme.lightTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: isLarge ? 12 : 11,
                      ),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          // This week – solid
          LineChartBarData(
            spots: List.generate(7, (i) => FlSpot(i.toDouble(), tw[i])),
            isCurved: true,
            curveSmoothness: 0.4,
            color: _DashboardTheme.textPrimary(context),
            barWidth: isLarge ? 3.0 : 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _DashboardTheme.textPrimary(context).withValues(alpha: 0.12),
                  _DashboardTheme.textPrimary(context).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Last week – dashed teal
          LineChartBarData(
            spots: List.generate(7, (i) => FlSpot(i.toDouble(), lw[i])),
            isCurved: true,
            curveSmoothness: 0.4,
            color: _DashboardTheme.lightTeal,
            barWidth: isLarge ? 2.5 : 2,
            isStrokeCapRound: true,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ────────────────────────────────────────────────────────
//  CashFlow: Stacked bar (Inflow purple | Outflow blue)
// ────────────────────────────────────────────────────────
class _CashFlowChart extends StatelessWidget {
  final List<double> inflow;
  final List<double> outflow;
  final List<String> labels;
  final bool isLarge;

  const _CashFlowChart({
    required this.inflow,
    required this.outflow,
    required this.labels,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final allVals = [...inflow, ...outflow];
    final maxVal = allVals.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1000.0 : maxVal * 1.3;

    final groups = List.generate(inflow.length, (i) {
      final inF = inflow[i];
      final outF = outflow[i];
      final total = inF + outF;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total > 0 ? total : 0.001,
            color: _DashboardTheme.lightPurple,
            width: isLarge ? 24 : 18,
            borderRadius: BorderRadius.circular(4),
            rodStackItems: [
              if (outF > 0)
                BarChartRodStackItem(0, outF, _DashboardTheme.blue),
              if (inF > 0)
                BarChartRodStackItem(outF, total, _DashboardTheme.lightPurple),
            ],
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: _DashboardTheme.chartGrid(context),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isLarge ? 48 : 40,
              getTitlesWidget: (val, _) => Text(
                _compact(val),
                style: TextStyle(
                  fontSize: isLarge ? 10.5 : 9,
                  color: _DashboardTheme.textSecondary(context),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    style: TextStyle(
                      fontSize: isLarge ? 11 : 10,
                      color: _DashboardTheme.textSecondary(context),
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _DashboardTheme.cardBg(context),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${_compact(rod.toY)}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isLarge ? 12 : 11,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ────────────────────────────────────────────────────────
//  Top Selling Items: Donut + legend
// ────────────────────────────────────────────────────────
class _TopItemsDonut extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isLarge;

  static const _palette = [
    _DashboardTheme.purple,
    _DashboardTheme.blue,
    _DashboardTheme.green,
    _DashboardTheme.amber,
    _DashboardTheme.lightTeal,
  ];

  const _TopItemsDonut({
    required this.items,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              color: _DashboardTheme.chartGrid(context),
              size: isLarge ? 56 : 48,
            ),
            SizedBox(height: isLarge ? 10 : 8),
            Text(
              'No sales data',
              style: TextStyle(
                color: _DashboardTheme.textSecondary(context),
                fontSize: isLarge ? 13 : 12,
              ),
            ),
          ],
        ),
      );
    }

    final totalQty =
        items.fold<int>(0, (sum, m) => sum + (m['qty'] as int? ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final donutSize = (constraints.maxHeight * 0.90).clamp(130.0, 220.0);
        final centerSpaceRadius = (donutSize * 0.24).clamp(32.0, 52.0);
        final sectionRadius = (donutSize * 0.26).clamp(36.0, 58.0);
        final titleFontSize = (donutSize * 0.065).clamp(9.0, 12.0);

        return Row(
          children: [
            // Donut
            SizedBox(
              width: donutSize,
              height: donutSize,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: centerSpaceRadius,
                  sections: List.generate(items.length, (i) {
                    final qty = (items[i]['qty'] as int? ?? 0).toDouble();
                    final pct = totalQty > 0 ? qty / totalQty * 100 : 0;
                    return PieChartSectionData(
                      color: _palette[i % _palette.length],
                      value: qty,
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: sectionRadius,
                      titleStyle: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(width: isLarge ? 14 : 10),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) {
                  final name = items[i]['name'] as String;
                  final qty = items[i]['qty'] as int? ?? 0;
                  final color = _palette[i % _palette.length];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: isLarge ? 6 : 4),
                    child: Row(
                      children: [
                        Container(
                          width: isLarge ? 11 : 10,
                          height: isLarge ? 11 : 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: isLarge ? 8 : 6),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: _DashboardTheme.textPrimary(context),
                              fontSize: isLarge ? 12.5 : 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$qty',
                          style: TextStyle(
                            color: _DashboardTheme.textPrimary(context),
                            fontSize: isLarge ? 13 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────
//  Weekly Overview: solid purple bar chart
// ────────────────────────────────────────────────────────
class _WeeklyOverviewChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final bool isLarge;

  const _WeeklyOverviewChart({
    required this.values,
    required this.labels,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty
        ? 1000.0
        : values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1000.0 : maxVal * 1.3;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: List.generate(values.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i] > 0 ? values[i] : 0.001,
                color: _DashboardTheme.lightPurple,
                width: isLarge ? 28 : 22,
                borderRadius: BorderRadius.circular(isLarge ? 6 : 5),
              ),
            ],
          );
        }),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: _DashboardTheme.chartGrid(context),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    style: TextStyle(
                      fontSize: isLarge ? 11 : 10,
                      color: _DashboardTheme.textSecondary(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _DashboardTheme.cardBg(context),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${_compact(rod.toY)}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isLarge ? 12 : 11,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ────────────────────────────────────────────────────────
//  Payment Mode: Donut chart
// ────────────────────────────────────────────────────────
class _PaymentDonut extends StatelessWidget {
  final Map<String, double> breakdown;
  final bool isLarge;

  static const _palette = [
    _DashboardTheme.blue,
    _DashboardTheme.teal,
    _DashboardTheme.green,
    _DashboardTheme.amber,
    _DashboardTheme.purple,
    _DashboardTheme.red,
  ];

  const _PaymentDonut({
    required this.breakdown,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              color: _DashboardTheme.cardBorder(context),
              size: isLarge ? 56 : 48,
            ),
            SizedBox(height: isLarge ? 10 : 8),
            Text(
              'No data today',
              style: TextStyle(
                color: _DashboardTheme.textSecondary(context),
                fontSize: isLarge ? 13 : 12,
              ),
            ),
          ],
        ),
      );
    }

    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final entries = breakdown.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final donutSize = (constraints.maxHeight * 0.90).clamp(130.0, 220.0);
        final centerSpaceRadius = (donutSize * 0.24).clamp(32.0, 50.0);
        final sectionRadius = (donutSize * 0.26).clamp(36.0, 56.0);

        return Row(
          children: [
            // Donut
            SizedBox(
              width: donutSize,
              height: donutSize,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: centerSpaceRadius,
                  sections: List.generate(entries.length, (i) {
                    final color = _palette[i % _palette.length];
                    return PieChartSectionData(
                      color: color,
                      value: entries[i].value,
                      title: '',
                      radius: sectionRadius,
                    );
                  }),
                ),
              ),
            ),
            SizedBox(width: isLarge ? 12 : 8),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final color = _palette[i % _palette.length];
                  final pct = total > 0 ? e.value / total * 100 : 0;
                  final label = _modeLabel(e.key);
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: isLarge ? 6 : 5),
                    child: Row(
                      children: [
                        Container(
                          width: isLarge ? 11 : 10,
                          height: isLarge ? 11 : 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: isLarge ? 8 : 6),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: _DashboardTheme.textPrimary(context),
                              fontSize: isLarge ? 12 : 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_compactDouble(e.value)} (${pct.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            color: _DashboardTheme.textPrimary(context),
                            fontSize: isLarge ? 13 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  String _compactDouble(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _modeLabel(String key) {
    switch (key.toUpperCase()) {
      case 'CASH':
        return 'Cash';
      case 'CARD':
        return 'Card';
      case 'UPI':
        return 'UPI / GPay';
      case 'SPLIT':
        return 'Split';
      case 'NETBANKING':
        return 'Net Banking';
      case 'DUE':
        return 'Due';
      default:
        return key;
    }
  }
}
