import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../enums/enum_payement_mode.dart';
import '../../../../../model/entity_payment.dart';
import '../../../../../model/entity_purchase.dart';
import '../../../../../widget/my_card.dart';
import 'controller_home_purchase.dart';
import 'service_payment_receipt.dart'; // for export

/// Full ledger / running-balance statement for one supplier.
///
/// Pass supplierId (String) as Get.arguments.
/// The controller must expose:
///   - getPurchasesForSupplier(supplierId) → List<EntityPurchase>
///   - getPaymentsForPurchase(purchaseId) → List<EntityPayment>
class ScreenSupplierLedger extends StatefulWidget {
  const ScreenSupplierLedger({super.key});

  @override
  State<ScreenSupplierLedger> createState() => _ScreenSupplierLedgerState();
}

class _ScreenSupplierLedgerState extends State<ScreenSupplierLedger>
    with SingleTickerProviderStateMixin {
  late final ControllerHomePurchase _controller;
  late final int _supplierId;
  late final TabController _tabController;

  List<EntityPurchase> _purchases = [];
  List<_LedgerEntry> _ledgerEntries = [];

  // Filter state
  DateTimeRange? _dateFilter;
  _LedgerFilter _activeFilter = _LedgerFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = Get.isRegistered<ControllerHomePurchase>()
        ? Get.find<ControllerHomePurchase>()
        : Get.put(ControllerHomePurchase());
    _supplierId = Get.arguments as int;
    _buildLedger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Ledger construction ──────────────────────────────────
  void _buildLedger() {
    _purchases = _controller.getPurchasesForSupplier(_supplierId);

    final List<_LedgerEntry> entries = [];

    for (final purchase in _purchases) {
      // Debit: invoice
      entries.add(_LedgerEntry(
        date: purchase.createdAtUtcMs != null
            ? DateTime.fromMillisecondsSinceEpoch(purchase.createdAtUtcMs!,
            isUtc: true)
            : DateTime.now(),
        type: _EntryType.invoice,
        description:
        'Invoice – ${purchase.purchaseNo ?? ''}',
        debit: purchase.totalAmount ?? 0,
        credit: 0,
        purchaseNo: purchase.purchaseNo,
        purchaseId: purchase.id,
      ));

      // Credits: payments
      final payments = _controller.getPaymentsForPurchase(purchase.id);
      for (final payment in payments) {
        final mode = PaymentMode.values[payment.paymentMode ?? 0];
        entries.add(_LedgerEntry(
          date: payment.createdAtUtcMs != null
              ? DateTime.fromMillisecondsSinceEpoch(payment.createdAtUtcMs!,
              isUtc: true)
              : DateTime.now(),
          type: _EntryType.payment,
          description:
          'Payment – ${mode.label}${payment.referenceNo != null ? ' (${payment.referenceNo})' : ''}',
          debit: 0,
          credit: payment.amount ?? 0,
          purchaseNo: purchase.purchaseNo,
          purchaseId: purchase.id,
          paymentMode: mode,
        ));
      }
    }

    // Sort by date ascending
    entries.sort((a, b) => a.date.compareTo(b.date));

    // Compute running balance
    double running = 0;
    for (final e in entries) {
      running += e.debit - e.credit;
      e.runningBalance = running;
    }

    setState(() => _ledgerEntries = entries);
  }

  // ── filtered entries ─────────────────────────────────────
  List<_LedgerEntry> get _filtered {
    return _ledgerEntries.where((e) {
      if (_activeFilter == _LedgerFilter.invoices &&
          e.type != _EntryType.invoice) return false;
      if (_activeFilter == _LedgerFilter.payments &&
          e.type != _EntryType.payment) return false;
      if (_dateFilter != null) {
        if (e.date.isBefore(_dateFilter!.start) ||
            e.date.isAfter(_dateFilter!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ── computed totals ──────────────────────────────────────
  double get _totalInvoiced =>
      _ledgerEntries.fold(0, (s, e) => s + e.debit);

  double get _totalPaid =>
      _ledgerEntries.fold(0, (s, e) => s + e.credit);

  double get _balance => _totalInvoiced - _totalPaid;

  String get _supplierName =>
      _purchases.isNotEmpty ? (_purchases.first.supplierName ?? 'Supplier'.tr) : 'Supplier'.tr;

  // ── date filter ──────────────────────────────────────────
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFilter,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
                primary: Colors.green.shade700,
                onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateFilter = picked);
  }

  // ── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.indigo.shade500, Colors.indigo.shade800]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Supplier Ledger'.tr,
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              _supplierName,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ]),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo.shade700,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.indigo.shade700,
          tabs: [
            Tab(text: 'Ledger'.tr, icon: const Icon(Icons.list_alt_rounded, size: 18)),
            Tab(
                text: 'Summary'.tr,
                icon: const Icon(Icons.bar_chart_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLedgerTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  LEDGER TAB
  // ─────────────────────────────────────────────────────────

  Widget _buildLedgerTab() {
    final entries = _filtered;

    return Column(
      children: [
        // ── Toolbar: filter + date range ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              // Filter chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _LedgerFilter.values.map((f) {
                      final isActive = _activeFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.label.tr),
                          selected: isActive,
                          selectedColor: Colors.indigo.shade100,
                          checkmarkColor: Colors.indigo.shade700,
                          labelStyle: TextStyle(
                              color: isActive
                                  ? Colors.indigo.shade700
                                  : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          onSelected: (_) =>
                              setState(() => _activeFilter = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Date range filter
              IconButton(
                icon: Icon(
                  Icons.date_range_rounded,
                  color: _dateFilter != null
                      ? Colors.indigo.shade600
                      : Colors.grey.shade400,
                ),
                tooltip: 'Filter by date'.tr,
                onPressed: _pickDateRange,
              ),
              if (_dateFilter != null)
                IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: Colors.grey.shade400, size: 18),
                  tooltip: 'Clear date filter'.tr,
                  onPressed: () => setState(() => _dateFilter = null),
                ),
            ],
          ),
        ),

        if (_dateFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: Colors.indigo.shade400),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('dd MMM yy').format(_dateFilter!.start)} – '
                    '${DateFormat('dd MMM yy').format(_dateFilter!.end)}',
                style: TextStyle(
                    fontSize: 12, color: Colors.indigo.shade400),
              ),
            ]),
          ),

        // ── Ledger table header ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(children: [
            Expanded(
                flex: 2,
                child: _colHeader('Date'.tr)),
            Expanded(
                flex: 4,
                child: _colHeader('Description'.tr)),
            Expanded(
                flex: 2,
                child: _colHeader('Debit'.tr, align: TextAlign.right)),
            Expanded(
                flex: 2,
                child: _colHeader('Credit'.tr, align: TextAlign.right)),
            Expanded(
                flex: 2,
                child: _colHeader('Balance'.tr, align: TextAlign.right)),
          ]),
        ),

        // ── Entries ──
        Expanded(
          child: entries.isEmpty
              ? _buildEmptyState('No entries found.'.tr)
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: entries.length,
            itemBuilder: (ctx, i) => _buildLedgerRow(entries[i], i),
          ),
        ),

        // ── Footer totals ──
        _buildLedgerFooter(),
      ],
    );
  }

  Widget _buildLedgerRow(_LedgerEntry entry, int index) {
    final isInvoice = entry.type == _EntryType.invoice;
    final isEven = index.isEven;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey.shade50,
        border: Border(
          left: BorderSide(
              color: isInvoice
                  ? Colors.red.shade300
                  : Colors.green.shade400,
              width: 3),
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(children: [
        // Date
        Expanded(
          flex: 2,
          child: Text(
            DateFormat('dd MMM\nyyyy').format(entry.date.toLocal()),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ),
        // Description
        Expanded(
          flex: 4,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.description,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500)),
                if (entry.purchaseNo != null)
                  Text('PO: ${entry.purchaseNo}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade400)),
              ]),
        ),
        // Debit
        Expanded(
          flex: 2,
          child: Text(
            entry.debit > 0
                ? '₹${entry.debit.toStringAsFixed(2)}'
                : '-',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500),
          ),
        ),
        // Credit
        Expanded(
          flex: 2,
          child: Text(
            entry.credit > 0
                ? '₹${entry.credit.toStringAsFixed(2)}'
                : '-',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500),
          ),
        ),
        // Running balance
        Expanded(
          flex: 2,
          child: Text(
            '₹${entry.runningBalance.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: entry.runningBalance > 0
                    ? Colors.red.shade700
                    : Colors.green.shade700),
          ),
        ),
      ]),
    );
  }

  Widget _buildLedgerFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade800,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: Row(children: [
        Expanded(flex: 6, child: Text('TOTALS'.tr, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
        Expanded(
          flex: 2,
          child: Text(
            '₹${_totalInvoiced.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '₹${_totalPaid.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '₹${_balance.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: TextStyle(
                color: _balance > 0 ? Colors.redAccent : Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SUMMARY TAB
  // ─────────────────────────────────────────────────────────

  Widget _buildSummaryTab() {
    final totalPOs = _purchases.length;
    final unpaidPOs =
        _purchases.where((p) => p.outstandingAmount > 0.01).length;
    final fullyPaidPOs = totalPOs - unpaidPOs;
    final oldestUnpaid = _purchases
        .where((p) => p.outstandingAmount > 0.01)
        .map((p) => p.createdAtUtcMs ?? double.maxFinite.toInt())
        .fold<int?>(null, (oldest, ms) =>
    oldest == null || ms < oldest ? ms : oldest);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // ── Big balance card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.indigo.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: [
            Text('Outstanding Balance'.tr,
                style: TextStyle(
                    color: Colors.indigo.shade200, fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              '₹ ${_balance.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _balance <= 0
                  ? 'Account is clear ✓'.tr
                  : 'Amount owed to supplier'.tr,
              style: TextStyle(
                  color: _balance <= 0
                      ? Colors.greenAccent
                      : Colors.orange.shade200,
                  fontSize: 12),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Stat grid ──
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _statCard('Total Invoiced'.tr,
                '₹ ${_totalInvoiced.toStringAsFixed(2)}',
                Colors.red.shade600, Icons.receipt_long_rounded),
            _statCard('Total Paid'.tr,
                '₹ ${_totalPaid.toStringAsFixed(2)}',
                Colors.green.shade600, Icons.check_circle_outline_rounded),
            _statCard('Total POs'.tr, '$totalPOs',
                Colors.indigo.shade600, Icons.inventory_2_rounded),
            _statCard('Unpaid POs'.tr, '$unpaidPOs',
                unpaidPOs > 0
                    ? Colors.orange.shade600
                    : Colors.green.shade600,
                Icons.pending_rounded),
          ],
        ),

        const SizedBox(height: 16),

        // ── PO breakdown ──
        MyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                  'Purchase Orders'.tr, Icons.list_alt_rounded),
              const Divider(height: 20),
              ..._purchases.map((p) => _buildPOSummaryTile(p)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Oldest unpaid warning ──
        if (oldestUnpaid != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oldest unpaid invoice'.tr,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800)),
                      Text(
                        DateFormat('dd MMM yyyy').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                oldestUnpaid,
                                isUtc: true)
                                .toLocal()),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700),
                      ),
                    ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildPOSummaryTile(EntityPurchase p) {
    final outstanding = p.outstandingAmount;
    final isPaid = outstanding <= 0.01;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isPaid ? Colors.green.shade100 : Colors.red.shade100),
      ),
      child: Row(children: [
        Icon(
          isPaid
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isPaid ? Colors.green.shade500 : Colors.red.shade400,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.purchaseNo ?? '-',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                if (p.createdAtUtcMs != null)
                  Text(
                    DateFormat('dd MMM yyyy').format(
                        DateTime.fromMillisecondsSinceEpoch(p.createdAtUtcMs!,
                            isUtc: true)
                            .toLocal()),
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500),
                  ),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '₹ ${(p.totalAmount ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Text(
            isPaid
                ? 'Fully paid'.tr
                : '₹ ${outstanding.toStringAsFixed(2)} due',
            style: TextStyle(
                fontSize: 10,
                color: isPaid
                    ? Colors.green.shade600
                    : Colors.red.shade600,
                fontWeight: FontWeight.w500),
          ),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────

  Widget _statCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ]),
        ),
      ]),
    );
  }

  Widget _colHeader(String label, {TextAlign align = TextAlign.left}) {
    return Text(
      label,
      textAlign: align,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade700),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: Colors.indigo.shade600),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800)),
    ]);
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(msg,
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 14)),
          ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INTERNAL MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum _EntryType { invoice, payment }

enum _LedgerFilter {
  all('All'),
  invoices('Invoices'),
  payments('Payments');

  final String label;
  const _LedgerFilter(this.label);
}

class _LedgerEntry {
  final DateTime date;
  final _EntryType type;
  final String description;
  final double debit;
  final double credit;
  final String? purchaseNo;
  final int? purchaseId;
  final PaymentMode? paymentMode;
  double runningBalance = 0;

  _LedgerEntry({
    required this.date,
    required this.type,
    required this.description,
    required this.debit,
    required this.credit,
    this.purchaseNo,
    this.purchaseId,
    this.paymentMode,
  });
}
