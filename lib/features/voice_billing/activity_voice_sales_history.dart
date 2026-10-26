import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../model/entity_bill.dart';
import '../../enums/enum_main_menu.dart';
import '../../screens/home/controller_home.dart';
import '../../screens/home/fragment/bills/dialog_bill_detail.dart';
import 'controller_voice_sales_history.dart';

class ActivityVoiceSalesHistory extends StatefulWidget {
  const ActivityVoiceSalesHistory({super.key});

  @override
  State<ActivityVoiceSalesHistory> createState() => _ActivityVoiceSalesHistoryState();
}

class _ActivityVoiceSalesHistoryState extends State<ActivityVoiceSalesHistory> {
  late final ControllerVoiceSalesHistory controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ControllerVoiceSalesHistory>()) {
      Get.delete<ControllerVoiceSalesHistory>(force: true);
    }
    controller = Get.put(ControllerVoiceSalesHistory());
  }

  @override
  void dispose() {
    if (Get.isRegistered<ControllerVoiceSalesHistory>()) {
      Get.delete<ControllerVoiceSalesHistory>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, cs, isDark),
      body: Column(
        children: [
          _buildMetricsBanner(cs, isDark),
          _buildFilterAndSearchBar(cs, isDark),
          Expanded(child: _buildBillsList(cs, isDark)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme cs, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Get.back();
          } else if (Get.isRegistered<ControllerHome>()) {
            Get.find<ControllerHome>().selectedMainMenu.value = EnumMainMenu.voiceBilling;
          }
        },
        tooltip: 'Back',
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Voice Sales Tracker',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              Text(
                'Live records of all invoices created via AI Speech',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh Records',
          onPressed: () => controller.loadVoiceBills(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMetricsBanner(ColorScheme cs, bool isDark) {
    return Obx(() {
      final rev = controller.rxTotalRevenue.value;
      final bills = controller.rxTotalBillsCount.value;
      final items = controller.rxTotalItemsCount.value;
      final avg = controller.rxAvgBillValue.value;
      final curr = controller.currencySymbol;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top 4 KPI Cards
            Row(
              children: [
                _buildKpiCard(
                  cs,
                  title: 'Total AI Sales',
                  value: '$curr ${rev.toStringAsFixed(2)}',
                  icon: Icons.payments_rounded,
                  gradient: const [Color(0xFF10B981), Color(0xFF047857)],
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  cs,
                  title: 'Bills Generated',
                  value: '$bills Bills',
                  icon: Icons.receipt_long_rounded,
                  gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  cs,
                  title: 'Items Sold via AI',
                  value: '$items Units',
                  icon: Icons.shopping_basket_rounded,
                  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  cs,
                  title: 'Avg. Bill Value',
                  value: '$curr ${avg.toStringAsFixed(1)}',
                  icon: Icons.insights_rounded,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Payment Mode Pill Summary
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                const Text(
                  'Inventory Stock Status: Untouched (Zero stock decrement for voice orders)',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                _buildPaymentPill(cs, 'Cash', controller.rxCashRevenue.value, curr, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildPaymentPill(cs, 'UPI', controller.rxUpiRevenue.value, curr, const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                _buildPaymentPill(cs, 'Card', controller.rxCardRevenue.value, curr, const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildKpiCard(
    ColorScheme cs, {
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: gradient.first.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gradient.first.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: gradient.last,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentPill(ColorScheme cs, String label, double amount, String curr, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $curr ${amount.toStringAsFixed(0)}',
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildFilterAndSearchBar(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Date Filter Segment
          Obx(() {
            final current = controller.rxDateFilter.value;
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  _buildDateChip(cs, 'All Time', VoiceHistoryDateFilter.allTime, current),
                  _buildDateChip(cs, 'Today', VoiceHistoryDateFilter.today, current),
                  _buildDateChip(cs, 'Yesterday', VoiceHistoryDateFilter.yesterday, current),
                  _buildDateChip(cs, 'This Week', VoiceHistoryDateFilter.thisWeek, current),
                  _buildDateChip(cs, 'This Month', VoiceHistoryDateFilter.thisMonth, current),
                ],
              ),
            );
          }),
          const SizedBox(width: 14),

          // Search Field
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Customer, Bill No, Item, or Spoken Words...',
                  hintStyle: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: Obx(() {
                    if (controller.rxSearchQuery.value.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => controller.searchController.clear(),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(
    ColorScheme cs,
    String label,
    VoiceHistoryDateFilter filter,
    VoiceHistoryDateFilter current,
  ) {
    final isSelected = filter == current;
    return GestureDetector(
      onTap: () => controller.setDateFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildBillsList(ColorScheme cs, bool isDark) {
    return Obx(() {
      final bills = controller.rxFilteredBills;

      if (bills.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  size: 54,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No AI Voice Sales Found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Invoices created by speaking into the microphone will be tracked right here.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          return _buildVoiceBillCard(context, bill, cs, isDark);
        },
      );
    });
  }

  Widget _buildVoiceBillCard(BuildContext context, EntityBill bill, ColorScheme cs, bool isDark) {
    final transcript = controller.extractTranscript(bill);
    final language = controller.extractLanguage(bill);
    final dateStr = controller.formatBillDate(bill);
    final curr = controller.currencySymbol;
    final total = bill.grandTotal ?? 0.0;
    final itemsCount = bill.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Bill No, Date, Payment Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bill.billNo ?? 'VOICE-BILL',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                // Payment Mode Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bill.paymentMode ?? 'Cash',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                // Language Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    language,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer & Transcript
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: cs.primary.withValues(alpha: 0.15),
                            child: Icon(Icons.person_rounded, size: 18, color: cs.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.customerName ?? 'Walk-in Customer',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty)
                                  Text(
                                    bill.customerPhone!,
                                    style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Speech Transcript Card
                    if (transcript.isNotEmpty)
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  transcript,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Items Chips Summary
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: bill.items.map((it) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${it.itemName ?? "Item"} x${it.qty ?? 1} ($curr${(it.total ?? 0).toStringAsFixed(0)})',
                        style: TextStyle(fontSize: 11, color: cs.onSurface),
                      ),
                    );
                  }).toList(),
                ),

                const Divider(height: 24),

                // Bottom Line: Items Count, Grand Total, Actions
                Row(
                  children: [
                    Text(
                      '$itemsCount item${itemsCount > 1 ? "s" : ""}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                        Text(
                          '$curr ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Get.dialog(DialogBillDetail(bill: bill));
                      },
                      icon: const Icon(Icons.receipt_rounded, size: 16),
                      label: const Text('View Bill'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
