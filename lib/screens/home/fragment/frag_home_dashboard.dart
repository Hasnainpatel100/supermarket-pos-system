import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'controller_home_dashboard.dart';

class FragHomeDashboard extends StatelessWidget {
  const FragHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerHomeDashboard>()
        ? Get.find<ControllerHomeDashboard>()
        : Get.put(ControllerHomeDashboard());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final currencyFmt = NumberFormat.simpleCurrency(locale: 'en_IN');
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async => controller.loadData(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.dashboard_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Today — ${DateFormat('EEE, dd MMM yyyy').format(DateTime.now())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: controller.loadData,
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Stats Cards ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Today Sales',
                          value: currencyFmt.format(
                            controller.todaySales.value,
                          ),
                          icon: Icons.attach_money_rounded,
                          gradient: [
                            Colors.green.shade500,
                            Colors.teal.shade400,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Orders',
                          value: '${controller.todayOrders.value}',
                          icon: Icons.receipt_long_rounded,
                          gradient: [
                            Colors.blue.shade500,
                            Colors.indigo.shade400,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Avg Bill',
                          value: currencyFmt.format(
                            controller.averageBill.value,
                          ),
                          icon: Icons.trending_up_rounded,
                          gradient: [
                            Colors.orange.shade500,
                            Colors.deepOrange.shade400,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Line Chart: Weekly Sales ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ChartCard(
                    title: 'Sales — Last 7 Days',
                    icon: Icons.show_chart_rounded,
                    iconColor: Colors.blue.shade600,
                    child: _WeeklySalesChart(
                      sales: controller.weeklySales.toList(),
                      labels: controller.weekLabels.toList(),
                      lineColor: colorScheme.primary,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Pie Chart: Payment Breakdown ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ChartCard(
                    title: 'Payment Mode (Today)',
                    icon: Icons.pie_chart_rounded,
                    iconColor: Colors.purple.shade600,
                    child: controller.paymentBreakdown.isEmpty
                        ? _emptyState('No transactions today')
                        : _PaymentPieChart(
                            breakdown: Map<String, double>.from(
                              controller.paymentBreakdown,
                            ),
                          ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      }),
    );
  }

  Widget _emptyState(String msg) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(msg, style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chart Card Wrapper ──
class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ── Weekly Sales Line Chart ──
class _WeeklySalesChart extends StatelessWidget {
  final List<double> sales;
  final List<String> labels;
  final Color lineColor;
  final bool isDark;

  const _WeeklySalesChart({
    required this.sales,
    required this.labels,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = sales.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1000.0 : maxVal * 1.25;

    final spots = List.generate(
      sales.length,
      (i) => FlSpot(i.toDouble(), sales[i]),
    );

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
            getDrawingHorizontalLine: (v) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.withValues(alpha: 0.12),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (val, _) => Text(
                  _formatCompact(val),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
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
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) =>
                  lineColor.withValues(alpha: 0.85),
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '₹${_formatCompact(s.y)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: lineColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.25),
                    lineColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompact(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}

// ── Payment Pie Chart ──
class _PaymentPieChart extends StatelessWidget {
  final Map<String, double> breakdown;

  const _PaymentPieChart({required this.breakdown});

  static const List<Color> _palette = [
    Color(0xFF4CAF50), // green – CASH
    Color(0xFF2196F3), // blue  – CARD
    Color(0xFFFF9800), // amber – UPI
    Color(0xFF9C27B0), // purple– other
    Color(0xFFF44336), // red
  ];

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final entries = breakdown.entries.toList();

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42,
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final pct = total > 0 ? e.value / total * 100 : 0;
                  final color = _palette[i % _palette.length];
                  return PieChartSectionData(
                    color: color,
                    value: e.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 52,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(entries.length, (i) {
            final e = entries[i];
            final color = _palette[i % _palette.length];
            final pct = total > 0 ? e.value / total * 100 : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
