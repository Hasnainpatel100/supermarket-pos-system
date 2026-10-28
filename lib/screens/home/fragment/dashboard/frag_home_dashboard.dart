import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../enums/enum_main_menu.dart';
import '../../../../service/service_brand_context.dart';
import '../../controller_home.dart';
import '../item/controller_home_item.dart';
import 'controller_home_dashboard.dart';

// ────────────────────────────────────────────────────────
//  Dreams POS Color Palette & Theme Configuration
// ────────────────────────────────────────────────────────

class _DreamsTheme {
  // Brand accents matching Dreams POS screenshot
  static const orange = Color(0xFFFF9F43);
  static const darkOrange = Color(0xFFFF7A00);
  static const lightOrange = Color(0xFFFFF2E5);

  static const cyan = Color(0xFF00CFDE);
  static const lightCyan = Color(0xFFE0F9FB);

  static const navy = Color(0xFF1B2850);

  static const green = Color(0xFF28C76F);
  static const lightGreen = Color(0xFFE7F8EE);

  static const red = Color(0xFFEA5455);
  static const lightRed = Color(0xFFFFECEC);

  static const textMuted = Color(0xFF707E94);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121418)
          : const Color(0xFFF8F9FA);

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E222B)
          : Colors.white;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2E3544)
          : const Color(0xFFECEEF1);

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF2B3674);

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF707E94);
}

class FragHomeDashboard extends StatelessWidget {
  const FragHomeDashboard({super.key});

  bool _isPlanBannerActive(ControllerHomeDashboard ctrl) {
    if (ctrl.isPlanExpiryDismissed.value) return false;
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
      backgroundColor: _DreamsTheme.background(context),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _DreamsTheme.darkOrange),
          );
        }

        final hasBanner = _isPlanBannerActive(ctrl);
        final hasExpAlert = (ctrl.expiringItemCount.value > 0 || ctrl.expiredItemCount.value > 0) &&
            !ctrl.isItemExpiryDismissed.value;

        return RefreshIndicator(
          color: _DreamsTheme.darkOrange,
          backgroundColor: _DreamsTheme.cardBg(context),
          onRefresh: () async => ctrl.loadData(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLarge = constraints.maxWidth >= 1300;
              final hPadding = isLarge ? 24.0 : 16.0;
              final gap = isLarge ? 18.0 : 14.0;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Dreams POS Top Action / Greeting Header ──
                    _buildTopHeader(context, ctrl, isLarge),
                    SizedBox(height: gap),

                    // ── Alerts if any ──
                    if (hasBanner) ...[
                      _buildPlanExpiryBanner(context, ctrl, isLarge),
                      SizedBox(height: gap),
                    ],
                    if (hasExpAlert) ...[
                      _buildItemExpiryBanner(context, ctrl, isLarge),
                      SizedBox(height: gap),
                    ],

                    // ── ROW 1: 4 KPI Cards with circular pill badges ──
                    _buildRow1KPICards(context, ctrl, isLarge),
                    SizedBox(height: gap),

                    // ── ROW 2: 4 Solid Colored Block Cards ──
                    _buildRow2SolidCards(context, ctrl, isLarge),
                    SizedBox(height: gap),

                    // ── ROW 3: Purchase & Sales Chart + Recently Added Products ──
                    _buildRow3ChartAndRecent(context, ctrl, isLarge),
                    SizedBox(height: gap),

                    // ── ROW 4: Expired / Low Stock Materials Table ──
                    _buildRow4InventoryWatch(context, ctrl, isLarge),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // ────────────────────────────────────────────────────────
  //  Dreams Top Header (Greeting, Date Badge, Refresh)
  // ────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    return Row(
      children: [
        // Brand / Greeting Pill
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 16 : 12,
            vertical: isLarge ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: _DreamsTheme.cardBg(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _DreamsTheme.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _DreamsTheme.lightOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: _DreamsTheme.darkOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Obx(() => Text(
                ctrl.greetingText.value,
                style: TextStyle(
                  fontSize: isLarge ? 15 : 13.5,
                  fontWeight: FontWeight.bold,
                  color: _DreamsTheme.textPrimary(context),
                ),
              )),
            ],
          ),
        ),
        const Spacer(),

        // Current Date Tag
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 14 : 10,
            vertical: isLarge ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: _DreamsTheme.cardBg(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _DreamsTheme.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: _DreamsTheme.darkOrange,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  color: _DreamsTheme.textPrimary(context),
                  fontSize: isLarge ? 13 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Refresh Button
        InkWell(
          onTap: ctrl.loadData,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLarge ? 14 : 10,
              vertical: isLarge ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: _DreamsTheme.cardBg(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _DreamsTheme.border(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: _DreamsTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'refresh'.tr,
                  style: TextStyle(
                    fontSize: isLarge ? 12.5 : 11.5,
                    fontWeight: FontWeight.w600,
                    color: _DreamsTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  //  Row 1: Top 4 KPI Cards with circular colored icon badges
  // ────────────────────────────────────────────────────────
  Widget _buildRow1KPICards(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      final cardWidth = isNarrow
          ? (constraints.maxWidth - 12) / 2
          : (constraints.maxWidth - 36) / 4;

      final cards = [
        _DreamsKpiCard(
          title: 'Total Purchase Due',
          amount: currency.format(ctrl.totalPurchaseDue.value),
          icon: Icons.receipt_long_rounded,
          iconBg: _DreamsTheme.lightOrange,
          iconColor: _DreamsTheme.darkOrange,
          isLarge: isLarge,
        ),
        _DreamsKpiCard(
          title: 'Total Sales Due',
          amount: currency.format(ctrl.totalSalesDue.value),
          icon: Icons.account_balance_wallet_outlined,
          iconBg: _DreamsTheme.lightGreen,
          iconColor: _DreamsTheme.green,
          isLarge: isLarge,
        ),
        _DreamsKpiCard(
          title: 'Total Sale Amount',
          amount: currency.format(ctrl.totalSaleAmount.value),
          icon: Icons.arrow_downward_rounded,
          iconBg: _DreamsTheme.lightCyan,
          iconColor: _DreamsTheme.cyan,
          isLarge: isLarge,
        ),
        _DreamsKpiCard(
          title: 'Total Expense Amount',
          amount: currency.format(ctrl.totalExpenseAmount.value),
          icon: Icons.arrow_upward_rounded,
          iconBg: _DreamsTheme.lightRed,
          iconColor: _DreamsTheme.red,
          isLarge: isLarge,
        ),
      ];

      if (isNarrow) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
        );
      }

      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
          const SizedBox(width: 12),
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ],
      );
    });
  }

  // ────────────────────────────────────────────────────────
  //  Row 2: 4 Bold Solid Colored Block Cards
  // ────────────────────────────────────────────────────────
  Widget _buildRow2SolidCards(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      final cardWidth = isNarrow
          ? (constraints.maxWidth - 12) / 2
          : (constraints.maxWidth - 36) / 4;

      final cards = [
        _DreamsSolidCard(
          count: '${ctrl.totalCustomers.value}',
          label: 'Customers',
          backgroundColor: _DreamsTheme.orange,
          icon: Icons.person_rounded,
          isLarge: isLarge,
          onTap: () {
            if (Get.isRegistered<ControllerHome>()) {
              Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.customer;
            }
          },
        ),
        _DreamsSolidCard(
          count: '${ctrl.totalSuppliers.value}',
          label: 'Suppliers',
          backgroundColor: _DreamsTheme.cyan,
          icon: Icons.person_add_alt_1_rounded,
          isLarge: isLarge,
          onTap: () {
            if (Get.isRegistered<ControllerHome>()) {
              Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.supplier;
            }
          },
        ),
        _DreamsSolidCard(
          count: '${ctrl.totalPurchaseInvoices.value}',
          label: 'Purchase Invoice',
          backgroundColor: _DreamsTheme.navy,
          icon: Icons.receipt_rounded,
          isLarge: isLarge,
          onTap: () {
            if (Get.isRegistered<ControllerHome>()) {
              Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.purchase;
            }
          },
        ),
        _DreamsSolidCard(
          count: '${ctrl.totalSalesInvoices.value}',
          label: 'Sales Invoice',
          backgroundColor: _DreamsTheme.green,
          icon: Icons.description_rounded,
          isLarge: isLarge,
          onTap: () {
            if (Get.isRegistered<ControllerHome>()) {
              Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.pos;
            }
          },
        ),
      ];

      if (isNarrow) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
        );
      }

      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
          const SizedBox(width: 12),
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ],
      );
    });
  }

  // ────────────────────────────────────────────────────────
  //  Row 3: Dual-bar "Purchase & Sales" Chart + Recently Added
  // ────────────────────────────────────────────────────────
  Widget _buildRow3ChartAndRecent(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    return LayoutBuilder(builder: (context, constraints) {
      final isStacked = constraints.maxWidth < 1000;

      final chartCard = _buildPurchaseSalesChartCard(context, ctrl, isLarge);
      final recentProductsCard = _buildRecentlyAddedProductsCard(context, ctrl, isLarge);

      if (isStacked) {
        return Column(
          children: [
            chartCard,
            const SizedBox(height: 14),
            recentProductsCard,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 62, child: chartCard),
          const SizedBox(width: 14),
          Expanded(flex: 38, child: recentProductsCard),
        ],
      );
    });
  }

  Widget _buildPurchaseSalesChartCard(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    final currentYear = DateTime.now().year.toString();

    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: _DreamsTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DreamsTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Text(
                'Purchase & Sales',
                style: TextStyle(
                  fontSize: isLarge ? 17 : 15,
                  fontWeight: FontWeight.bold,
                  color: _DreamsTheme.textPrimary(context),
                ),
              ),
              const Spacer(),
              // Legends
              _buildLegendDot(_DreamsTheme.green, 'Sales'),
              const SizedBox(width: 14),
              _buildLegendDot(_DreamsTheme.red, 'Purchase'),
              const SizedBox(width: 16),
              // Year Filter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _DreamsTheme.background(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _DreamsTheme.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentYear,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _DreamsTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _DreamsTheme.textMuted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Area
          SizedBox(
            height: isLarge ? 280 : 240,
            child: Obx(() {
              final labels = ctrl.monthLabels;
              final sales = ctrl.monthlySales;
              final purchases = ctrl.monthlyPurchases;

              if (labels.isEmpty) {
                return const Center(child: Text('No transaction history yet'));
              }

              // Compute dynamic scale
              double maxVal = 1000;
              for (final s in sales) {
                if (s > maxVal) maxVal = s;
              }
              for (final p in purchases) {
                if (p > maxVal) maxVal = p;
              }
              final maxY = maxVal * 1.25;

              final groups = List.generate(labels.length, (i) {
                final sVal = (i < sales.length) ? sales[i] : 0.0;
                final pVal = (i < purchases.length) ? purchases[i] : 0.0;

                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: sVal > 0 ? sVal : 0.001,
                      color: _DreamsTheme.green,
                      width: isLarge ? 10 : 8,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    BarChartRodData(
                      toY: pVal > 0 ? pVal : 0.001,
                      color: _DreamsTheme.red,
                      width: isLarge ? 10 : 8,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                );
              });

              return BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  barGroups: groups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: _DreamsTheme.border(context),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          final compact = NumberFormat.compact(locale: 'en_IN').format(val);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              compact,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: _DreamsTheme.textSecondary(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[idx],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _DreamsTheme.textSecondary(context),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _DreamsTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyAddedProductsCard(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      height: isLarge ? 362 : 322,
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: _DreamsTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DreamsTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recently Added Products',
                style: TextStyle(
                  fontSize: isLarge ? 17 : 15,
                  fontWeight: FontWeight.bold,
                  color: _DreamsTheme.textPrimary(context),
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_vert_rounded, size: 20, color: _DreamsTheme.textMuted),
            ],
          ),
          const SizedBox(height: 14),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _DreamsTheme.background(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 36,
                  child: Text('Sno', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _DreamsTheme.textMuted)),
                ),
                const Expanded(
                  child: Text('Products', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _DreamsTheme.textMuted)),
                ),
                Text('Price', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _DreamsTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Table Rows
          Expanded(
            child: Obx(() {
              final items = ctrl.recentlyAddedProducts;
              if (items.isEmpty) {
                return const Center(child: Text('No products added yet', style: TextStyle(fontSize: 12, color: _DreamsTheme.textMuted)));
              }

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length.clamp(0, 5),
                separatorBuilder: (context, index) => Divider(height: 1, color: _DreamsTheme.border(context)),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(fontSize: 12, color: _DreamsTheme.textSecondary(context)),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: _DreamsTheme.lightOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, size: 16, color: _DreamsTheme.darkOrange),
                        ),
                        Expanded(
                          child: Text(
                            item.name ?? 'Item #${item.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _DreamsTheme.textPrimary(context),
                            ),
                          ),
                        ),
                        Text(
                          currency.format(item.sellingPrice ?? 0),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _DreamsTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  //  Row 4: Bottom Table (Expired / Low Stock Materials Watch)
  // ────────────────────────────────────────────────────────
  Widget _buildRow4InventoryWatch(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: _DreamsTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DreamsTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Inventory Alert & Material Watch',
                style: TextStyle(
                  fontSize: isLarge ? 17 : 15,
                  fontWeight: FontWeight.bold,
                  color: _DreamsTheme.textPrimary(context),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _DreamsTheme.lightRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Watchlist',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _DreamsTheme.red,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  if (Get.isRegistered<ControllerHome>()) {
                    Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.item;
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: _DreamsTheme.darkOrange),
                label: const Text('View All Inventory', style: TextStyle(color: _DreamsTheme.darkOrange, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _DreamsTheme.background(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(width: 44, child: Text('SNo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _DreamsTheme.textMuted))),
                SizedBox(width: 130, child: Text('Product Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _DreamsTheme.textMuted))),
                Expanded(flex: 3, child: Text('Product Name / Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _DreamsTheme.textMuted))),
                Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _DreamsTheme.textMuted))),
                SizedBox(width: 120, child: Text('Stock Status', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _DreamsTheme.textMuted))),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Table Body
          Obx(() {
            final items = ctrl.inventoryAlertProducts;
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('All yard stock levels are healthy! 🎉', style: TextStyle(color: _DreamsTheme.textMuted)),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length.clamp(0, 6),
              separatorBuilder: (context, index) => Divider(height: 1, color: _DreamsTheme.border(context)),
              itemBuilder: (context, idx) {
                final item = items[idx];
                final qty = item.totalQty ?? 0;
                final isOutOfStock = qty <= 0;
                final isLow = qty > 0 && qty < 10;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text('${idx + 1}', style: TextStyle(fontSize: 12.5, color: _DreamsTheme.textSecondary(context))),
                      ),
                      SizedBox(
                        width: 130,
                        child: Text(
                          item.barcode ?? (item.sku ?? 'IT${1000 + item.id!}'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _DreamsTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _DreamsTheme.lightOrange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.architecture_rounded, size: 14, color: _DreamsTheme.darkOrange),
                            ),
                            Expanded(
                              child: Text(
                                item.name ?? 'Steel Item',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _DreamsTheme.textPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.category ?? 'Structural Steel',
                          style: TextStyle(fontSize: 12.5, color: _DreamsTheme.textSecondary(context)),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? _DreamsTheme.lightRed
                                  : isLow
                                      ? _DreamsTheme.lightOrange
                                      : _DreamsTheme.lightGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOutOfStock
                                  ? 'Out of Stock'
                                  : '$qty ${item.unit ?? "Pcs"} Left',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOutOfStock
                                    ? _DreamsTheme.red
                                    : isLow
                                        ? _DreamsTheme.darkOrange
                                        : _DreamsTheme.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  //  Alert Banners (Subscription / Item Expiry)
  // ────────────────────────────────────────────────────────
  Widget _buildPlanExpiryBanner(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    if (!Get.isRegistered<ServiceBrandContext>()) return const SizedBox.shrink();
    final ServiceBrandContext brandCtx = Get.find();
    final branch = brandCtx.rxSelectedBranch.value;
    final plan = branch?.planDetails;
    if (plan == null) return const SizedBox.shrink();

    final isExpired = plan.isExpired;
    final color = isExpired ? _DreamsTheme.red : _DreamsTheme.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpired
                  ? 'Your subscription has expired! Please renew immediately.'
                  : 'Subscription expiring soon on ${plan.formattedExpiry}.',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          OutlinedButton(
            onPressed: () => ctrl.dismissPlanExpiryBanner(),
            child: const Text('Dismiss (24h)'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemExpiryBanner(BuildContext context, ControllerHomeDashboard ctrl, bool isLarge) {
    final expired = ctrl.expiredItemCount.value;
    final expiring = ctrl.expiringItemCount.value;
    final color = expired > 0 ? _DreamsTheme.red : _DreamsTheme.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expired > 0
                  ? '$expired batches expired! Review inventory.'
                  : '$expiring batches expiring soon.',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          FilledButton.tonal(
            onPressed: () {
              if (Get.isRegistered<ControllerHome>()) {
                Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.item;
              }
              if (Get.isRegistered<ControllerHomeItem>()) {
                Get.find<ControllerHomeItem>().setExpiryFilter(
                  expired > 0 ? ExpiryFilter.expired : ExpiryFilter.expiring,
                );
              }
            },
            child: const Text('View Items'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
//  Row 1: Individual KPI Card
// ────────────────────────────────────────────────────────
class _DreamsKpiCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool isLarge;

  const _DreamsKpiCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.isLarge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 18 : 14,
        vertical: isLarge ? 18 : 14,
      ),
      decoration: BoxDecoration(
        color: _DreamsTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DreamsTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Icon Pill
          Container(
            width: isLarge ? 48 : 42,
            height: isLarge ? 48 : 42,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: isLarge ? 22 : 20),
          ),
          SizedBox(width: isLarge ? 14 : 10),
          // Amount + Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isLarge ? 19 : 17,
                    fontWeight: FontWeight.w800,
                    color: _DreamsTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isLarge ? 12 : 11,
                    fontWeight: FontWeight.w500,
                    color: _DreamsTheme.textSecondary(context),
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

// ────────────────────────────────────────────────────────
//  Row 2: Individual Solid Colored Block Card
// ────────────────────────────────────────────────────────
class _DreamsSolidCard extends StatelessWidget {
  final String count;
  final String label;
  final Color backgroundColor;
  final IconData icon;
  final bool isLarge;
  final VoidCallback onTap;

  const _DreamsSolidCard({
    required this.count,
    required this.label,
    required this.backgroundColor,
    required this.icon,
    required this.isLarge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 22 : 16,
          vertical: isLarge ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: isLarge ? 26 : 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isLarge ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            Icon(
              icon,
              size: isLarge ? 38 : 32,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
