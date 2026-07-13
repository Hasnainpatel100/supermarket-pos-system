import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
        return RefreshIndicator(
          color: _DashboardTheme.purple,
          backgroundColor: _DashboardTheme.cardBg(context),
          onRefresh: () async => ctrl.loadData(),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Top Stat Cards ──
              SliverToBoxAdapter(child: _buildStatCards(context, ctrl)),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Row 2: Total Sales line chart | CashFlow bar chart ──
              SliverToBoxAdapter(child: _buildRow2(context, ctrl)),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Row 3: Top Selling Items | Weekly Overview | Payment Mode ──
              SliverToBoxAdapter(child: _buildRow3(context, ctrl)),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      }),
    );
  }



  // ──────────────────────────────────────────────────────
  //  Top Stat Cards
  // ──────────────────────────────────────────────────────
  Widget _buildStatCards(BuildContext context, ControllerHomeDashboard ctrl) {
    final fmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            title: "Today's Sales",
            value: fmt.format(ctrl.todaySales.value),
            subtitle: '${ctrl.todayOrders.value} orders',
          ),
          const SizedBox(width: 10),
          _StatCard(
            title: "Today's Orders",
            value: '${ctrl.todayOrders.value}',
            subtitle: 'bills today',
          ),
          const SizedBox(width: 10),
          _StatCard(
            title: 'Avg Bill',
            value: fmt.format(ctrl.averageBill.value),
            subtitle: 'per order',
          ),
          const SizedBox(width: 10),
          _StatCard(
            title: 'Total Items',
            value: '${ctrl.totalItems.value}',
            subtitle: 'in system',
          ),
          const SizedBox(width: 10),
          _StatCard(
            title: 'Customers',
            value: '${ctrl.totalCustomers.value}',
            subtitle: 'total',
            isGreenBadge: true,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  Row 2: Total Sales (line) + CashFlow (stacked bar)
  // ──────────────────────────────────────────────────────
  Widget _buildRow2(BuildContext context, ControllerHomeDashboard ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Sales line chart
          Expanded(
            flex: 55,
            child: _DashCard(
              title: 'Total Sales',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Legend(color: _DashboardTheme.textPrimary(context), label: 'This Week'),
                  const SizedBox(width: 12),
                  _Legend(color: _DashboardTheme.lightTeal, label: 'Last week'),
                ],
              ),
              child: _TotalSalesChart(
                thisWeek: ctrl.thisWeekSales.toList(),
                lastWeek: ctrl.lastWeekSales.toList(),
                labels: ctrl.weekLabels.toList(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // CashFlow stacked bar chart
          Expanded(
            flex: 45,
            child: _DashCard(
              title: 'CashFlow',
              trailing: _PillButton(
                label: 'Weekly',
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: () {},
              ),
              child: Column(
                children: [
                  _CashFlowChart(
                    inflow: ctrl.cashInflow.toList(),
                    outflow: ctrl.cashOutflow.toList(),
                    labels: ctrl.cashflowLabels.toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _Legend(color: _DashboardTheme.lightPurple, label: 'Inflow'),
                      const SizedBox(width: 16),
                      _Legend(color: _DashboardTheme.blue, label: 'Outflow'),
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
  Widget _buildRow3(BuildContext context, ControllerHomeDashboard ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Selling Items donut
          Expanded(
            flex: 33,
            child: _DashCard(
              title: 'Top Selling Items',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PillButton(label: 'Today', icon: Icons.keyboard_arrow_down_rounded, onTap: () {}),
                  const SizedBox(width: 6),
                  _PillButton(label: 'Limit: 5', icon: Icons.keyboard_arrow_down_rounded, onTap: () {}),
                ],
              ),
              child: _TopItemsDonut(items: ctrl.topSellingItems.toList()),
            ),
          ),
          const SizedBox(width: 14),
          // Weekly overview bar chart
          Expanded(
            flex: 34,
            child: _DashCard(
              title: 'Dashboard Overview',
              trailing: _PillButton(
                label: 'Weekly',
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: () {},
              ),
              child: _WeeklyOverviewChart(
                values: ctrl.weeklyOverview.toList(),
                labels: ctrl.overviewLabels.toList(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Payment Mode donut
          Expanded(
            flex: 33,
            child: _DashCard(
              title: 'Payment Mode',
              child: _PaymentDonut(
                breakdown: Map<String, double>.from(ctrl.paymentBreakdown),
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

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.isGreenBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _DashboardTheme.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _DashboardTheme.cardBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: _DashboardTheme.textSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isGreenBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6DE899),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF333742),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: _DashboardTheme.purple,
                      size: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: _DashboardTheme.textPrimary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: _DashboardTheme.textSecondary(context),
                      fontSize: 11,
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

  const _DashCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DashboardTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              style: const TextStyle(
                color: _DashboardTheme.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 2),
              Icon(icon, color: _DashboardTheme.green, size: 14),
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

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: _DashboardTheme.textSecondary(context), fontSize: 11),
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

  const _TotalSalesChart({
    required this.thisWeek,
    required this.lastWeek,
    required this.labels,
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

    return SizedBox(
      height: 200,
      child: LineChart(
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
                reservedSize: 44,
                getTitlesWidget: (val, _) => Text(
                  _compact(val),
                  style: TextStyle(
                    fontSize: 9,
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
                        fontSize: 10,
                        color: _DashboardTheme.textSecondary(context),
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => _DashboardTheme.cardBg(context),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '₹${_compact(s.y)}',
                        TextStyle(
                          color: s.barIndex == 0 ? _DashboardTheme.textPrimary(context) : _DashboardTheme.lightTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            // This week – solid white
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), tw[i])),
              isCurved: true,
              curveSmoothness: 0.4,
              color: _DashboardTheme.textPrimary(context),
              barWidth: 2.5,
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
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
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
//  CashFlow: Stacked bar (Inflow purple | Outflow teal)
// ────────────────────────────────────────────────────────
class _CashFlowChart extends StatelessWidget {
  final List<double> inflow;
  final List<double> outflow;
  final List<String> labels;

  const _CashFlowChart({
    required this.inflow,
    required this.outflow,
    required this.labels,
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
            width: 18,
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

    return SizedBox(
      height: 200,
      child: BarChart(
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
                reservedSize: 40,
                getTitlesWidget: (val, _) => Text(
                  _compact(val),
                  style: TextStyle(
                    fontSize: 9,
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
                        fontSize: 10,
                        color: _DashboardTheme.textSecondary(context),
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => _DashboardTheme.cardBg(context),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '₹${_compact(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              },
            ),
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

  static const _palette = [
    _DashboardTheme.purple,
    _DashboardTheme.blue,
    _DashboardTheme.green,
    _DashboardTheme.amber,
    _DashboardTheme.lightTeal,
  ];

  const _TopItemsDonut({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(Icons.pie_chart_outline, color: _DashboardTheme.chartGrid(context), size: 48),
              SizedBox(height: 8),
              Text('No sales data', style: TextStyle(color: _DashboardTheme.textSecondary(context), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final totalQty =
        items.fold<int>(0, (sum, m) => sum + (m['qty'] as int? ?? 0));

    return Row(
      children: [
        // Donut
        SizedBox(
          width: 140,
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 38,
              sections: List.generate(items.length, (i) {
                final qty = (items[i]['qty'] as int? ?? 0).toDouble();
                final pct = totalQty > 0 ? qty / totalQty * 100 : 0;
                return PieChartSectionData(
                  color: _palette[i % _palette.length],
                  value: qty,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 42,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Legend
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(items.length, (i) {
              final name = items[i]['name'] as String;
              final qty = items[i]['qty'] as int? ?? 0;
              final color = _palette[i % _palette.length];
              final displayName =
                  name.length > 14 ? '${name.substring(0, 12)}..' : name;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: _DashboardTheme.textPrimary(context),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$qty',
                      style: TextStyle(
                        color: _DashboardTheme.textPrimary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
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
  }
}

// ────────────────────────────────────────────────────────
//  Weekly Overview: solid purple bar chart
// ────────────────────────────────────────────────────────
class _WeeklyOverviewChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _WeeklyOverviewChart({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty
        ? 1000.0
        : values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1000.0 : maxVal * 1.3;

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: List.generate(values.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i] > 0 ? values[i] : 0.001,
                  color: _DashboardTheme.lightPurple, // Solid light purple
                  width: 22,
                  borderRadius: BorderRadius.circular(5),
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
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
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
                        fontSize: 10,
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
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              },
            ),
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

  static const _palette = [
    _DashboardTheme.blue,
    _DashboardTheme.teal,
    _DashboardTheme.green,
    _DashboardTheme.amber,
    _DashboardTheme.purple,
    _DashboardTheme.red,
  ];

  const _PaymentDonut({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline, color: _DashboardTheme.cardBorder(context), size: 48),
              const SizedBox(height: 8),
              Text('No data today', style: TextStyle(color: _DashboardTheme.textSecondary(context), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final entries = breakdown.entries.toList();

    return Row(
      children: [
        // Donut
        SizedBox(
          width: 130,
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: List.generate(entries.length, (i) {
                final color = _palette[i % _palette.length];
                return PieChartSectionData(
                  color: color,
                  value: entries[i].value,
                  title: '',
                  radius: 40,
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
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
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: _DashboardTheme.textPrimary(context),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _compactDouble(e.value),
                      style: TextStyle(
                        color: _DashboardTheme.textPrimary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
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
