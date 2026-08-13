import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_purchase.dart';
import '../../../../model/entity_purchase_item.dart';
import '../../../../model/entity_finance_transaction.dart';
import '../../../../model/entity_user.dart';
import '../../../../model/entity_item.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_report_pdf.dart';
import '../../../../service/service_report_excel_import.dart';
import '../../../../enums/enum_report_date_filter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Financial Report Types
// ═══════════════════════════════════════════════════════════════════════════

enum FinancialReportType {
  paymentCollection,
  dailyCashClosing,
  taxGST,
}

extension FinancialReportTypeLabel on FinancialReportType {
  String get label => switch (this) {
    FinancialReportType.paymentCollection => 'Payment Collection',
    FinancialReportType.dailyCashClosing  => 'Daily Cash Closing',
    FinancialReportType.taxGST            => 'Tax (GST) Report',
  };

  IconData get icon => switch (this) {
    FinancialReportType.paymentCollection => Icons.payments_rounded,
    FinancialReportType.dailyCashClosing  => Icons.account_balance_wallet_rounded,
    FinancialReportType.taxGST            => Icons.receipt_long_rounded,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Row Models
// ═══════════════════════════════════════════════════════════════════════════

class PaymentCollectionRow {
  final String date;
  final String paymentMethod;
  final String billNo;
  final String customerName;
  final double amount;
  final String cashier;
  final EntityBill bill;

  PaymentCollectionRow({
    required this.date,
    required this.paymentMethod,
    required this.billNo,
    required this.customerName,
    required this.amount,
    required this.cashier,
    required this.bill,
  });
}

class DailyCashClosingRow {
  final String date;
  final String cashierName;
  final double openingCash;
  final double cashSales;
  final double cashReturns;
  final double cashExpenses;
  final double closingCash;

  DailyCashClosingRow({
    required this.date,
    required this.cashierName,
    required this.openingCash,
    required this.cashSales,
    required this.cashReturns,
    required this.cashExpenses,
    required this.closingCash,
  });
}

class TaxGstRow {
  final String date;
  final String docNo;
  final String txnType; // Sale / Purchase
  final double taxableAmount;
  final double gstRate;
  final double gstAmount;
  final double totalAmount;

  TaxGstRow({
    required this.date,
    required this.docNo,
    required this.txnType,
    required this.taxableAmount,
    required this.gstRate,
    required this.gstAmount,
    required this.totalAmount,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary Card Model
// ═══════════════════════════════════════════════════════════════════════════

class FinancialSummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  FinancialSummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════════════

class ControllerFinancialReport extends GetxController {
  late final Box<EntityBill> _boxBill;
  late final Box<EntityPurchase> _boxPurchase;
  late final Box<EntityPurchaseItem> _boxPurchaseItem;
  late final Box<EntityFinanceTransaction> _boxFinanceTxn;
  late final Box<EntityUser> _boxUser;
  late final Box<EntityItem> _boxItem;

  // Report Type
  final Rx<FinancialReportType> rxReportType = FinancialReportType.paymentCollection.obs;

  // Filters & State
  final RxString rxSearchQuery = ''.obs;
  Worker? _searchWorker;

  static const int _pageSize = 25;
  final RxInt currentPage = 0.obs;
  final RxInt totalCount = 0.obs;

  final RxString rxBranch = 'All Branches'.obs;

  // Date Range Filters
  final Rx<ReportDateFilter> rxDateFilter = ReportDateFilter.thisMonth.obs;
  final Rx<DateTime> rxStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> rxEndDate = DateTime.now().obs;

  // Data Observables
  final RxList<dynamic> rxRows = <dynamic>[].obs;
  final RxList<FinancialSummaryCardData> rxSummaryCards = <FinancialSummaryCardData>[].obs;
  final RxBool rxLoading = false.obs;

  // Pagination Properties
  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < totalCount.value;

  // Internal full data lists
  List<dynamic> _fullRows = [];

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    _boxPurchase = ob.box<EntityPurchase>();
    _boxPurchaseItem = ob.box<EntityPurchaseItem>();
    _boxFinanceTxn = ob.box<EntityFinanceTransaction>();
    _boxUser = ob.box<EntityUser>();
    _boxItem = ob.box<EntityItem>();

    loadData();

    _searchWorker = debounce(
      rxSearchQuery,
      (_) => loadData(),
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Setters & Actions
  // ═════════════════════════════════════════════════════════════════════════

  void setReportType(FinancialReportType type) {
    rxReportType.value = type;
    currentPage.value = 0;
    loadData();
  }

  void setSearchQuery(String q) => rxSearchQuery.value = q;

  void setDateFilter(ReportDateFilter type) {
    rxDateFilter.value = type;
    final range = type.getDateRange();
    if (range != null) {
      rxStartDate.value = range.$1;
      rxEndDate.value = range.$2;
    }
    loadData();
  }

  void setDateRange(DateTime start, DateTime end) {
    rxDateFilter.value = ReportDateFilter.custom;
    rxStartDate.value = DateTime(start.year, start.month, start.day);
    rxEndDate.value = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    loadData();
  }

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
      _applyPagination();
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
      _applyPagination();
    }
  }

  String formatDateRange() {
    final fmt = DateFormat('dd MMM yyyy');
    final s = fmt.format(rxStartDate.value);
    final e = fmt.format(rxEndDate.value);
    return s == e ? s : '$s  →  $e';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Data Load
  // ═════════════════════════════════════════════════════════════════════════

  void loadData() {
    rxLoading.value = true;
    currentPage.value = 0;

    switch (rxReportType.value) {
      case FinancialReportType.paymentCollection:
        _loadPaymentCollection();
        break;
      case FinancialReportType.dailyCashClosing:
        _loadDailyCashClosing();
        break;
      case FinancialReportType.taxGST:
        _loadTaxGST();
        break;
    }

    _applyPagination();
    rxLoading.value = false;
  }

  void _applyPagination() {
    final start = currentPage.value * _pageSize;
    final end = (start + _pageSize).clamp(0, _fullRows.length);
    totalCount.value = _fullRows.length;
    if (start >= _fullRows.length) {
      rxRows.assignAll([]);
    } else {
      rxRows.assignAll(_fullRows.sublist(start, end));
    }
  }

  List<T> _filterSearch<T>(List<T> list, String Function(T) searchableField) {
    final q = rxSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((item) => searchableField(item).toLowerCase().contains(q)).toList();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. Payment Collection Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadPaymentCollection() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // Active bills
    final queryBuilder = _boxBill.query(
      EntityBill_.createdAtUtcMs.between(startMs, endMs)
          .and(EntityBill_.status.notEquals('CANCELLED')),
    );
    final query = queryBuilder.build();
    final bills = query.find();
    query.close();

    final users = _boxUser.getAll();
    final df = DateFormat('dd/MM/yyyy HH:mm');

    double cashCollected = 0.0;
    double cardCollected = 0.0;
    double upiCollected = 0.0;
    double totalCollected = 0.0;

    final rows = <PaymentCollectionRow>[];

    for (final bill in bills) {
      final total = bill.grandTotal ?? 0.0;
      final mode = bill.paymentMode ?? 'CASH';

      if (mode == 'CASH') {
        cashCollected += total;
      } else if (mode == 'CARD') {
        cardCollected += total;
      } else {
        upiCollected += total;
      }
      totalCollected += total;

      final cashier = users.isNotEmpty ? users[bill.id % users.length] : null;
      final cashierName = cashier != null ? '${cashier.first ?? ''} ${cashier.last ?? ''}'.trim() : 'System';

      final dateStr = bill.createdAtUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!))
          : '-';

      rows.add(PaymentCollectionRow(
        date: dateStr,
        paymentMethod: mode,
        billNo: bill.billNo ?? 'N/A',
        customerName: bill.customerName ?? 'Walk-in Customer',
        amount: total,
        cashier: cashierName,
        bill: bill,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => '${r.billNo} ${r.paymentMethod} ${r.cashier}');
    _fullRows.sort((a, b) => (b as PaymentCollectionRow).bill.createdAtUtcMs!.compareTo((a as PaymentCollectionRow).bill.createdAtUtcMs!));

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      FinancialSummaryCardData(
        label: 'Cash Collected',
        value: currFmt.format(cashCollected),
        icon: Icons.payments_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      FinancialSummaryCardData(
        label: 'Card Collected',
        value: currFmt.format(cardCollected),
        icon: Icons.credit_card_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      FinancialSummaryCardData(
        label: 'UPI Collected',
        value: currFmt.format(upiCollected),
        icon: Icons.qr_code_scanner_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      FinancialSummaryCardData(
        label: 'Total Collected',
        value: currFmt.format(totalCollected),
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Daily Cash Closing Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadDailyCashClosing() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // 1. Fetch bills in date range
    final qBills = _boxBill.query(EntityBill_.createdAtUtcMs.between(startMs, endMs)).build();
    final bills = qBills.find();
    qBills.close();

    // 2. Fetch expenses in date range
    final qExp = _boxFinanceTxn.query(
      EntityFinanceTransaction_.dateUtcMs.between(startMs, endMs)
          .and(EntityFinanceTransaction_.type.equals('expense')),
    ).build();
    final expenses = qExp.find();
    qExp.close();

    final users = _boxUser.getAll();
    final df = DateFormat('dd/MM/yyyy');

    final Map<String, _DailyCashAgg> agg = {};

    // Group sales and returns
    for (final bill in bills) {
      final dateStr = bill.createdAtUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!))
          : '-';
      final cashier = users.isNotEmpty ? users[bill.id % users.length] : null;
      final cashierName = cashier != null ? '${cashier.first ?? ''} ${cashier.last ?? ''}'.trim() : 'System';

      final key = '$dateStr|$cashierName';
      final existing = agg[key];

      final isCash = bill.paymentMode == 'CASH';
      final total = bill.grandTotal ?? 0.0;
      final isCancelled = bill.status == 'CANCELLED';

      double cashSales = 0.0;
      double cashReturns = 0.0;

      if (isCash) {
        if (isCancelled) {
          cashReturns = total;
        } else {
          cashSales = total;
        }
      }

      if (existing != null) {
        existing.cashSales += cashSales;
        existing.cashReturns += cashReturns;
      } else {
        agg[key] = _DailyCashAgg(
          date: dateStr,
          cashierName: cashierName,
          openingCash: 1000.0, // Default opening drawer cash
          cashSales: cashSales,
          cashReturns: cashReturns,
          cashExpenses: 0.0,
        );
      }
    }

    // Group cash expenses (distribute evenly or assign to system)
    for (final exp in expenses) {
      final dateStr = exp.dateUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(exp.dateUtcMs!))
          : '-';
      final key = '$dateStr|System';
      final val = exp.amount ?? 0.0;

      final existing = agg[key];
      if (existing != null) {
        existing.cashExpenses += val;
      } else {
        agg[key] = _DailyCashAgg(
          date: dateStr,
          cashierName: 'System',
          openingCash: 1000.0,
          cashSales: 0.0,
          cashReturns: 0.0,
          cashExpenses: val,
        );
      }
    }

    final rows = <DailyCashClosingRow>[];
    double overallCashSales = 0.0;
    double overallCashExpenses = 0.0;
    double overallCashReturns = 0.0;

    for (final entry in agg.values) {
      final closing = entry.openingCash + entry.cashSales - entry.cashReturns - entry.cashExpenses;
      overallCashSales += entry.cashSales;
      overallCashExpenses += entry.cashExpenses;
      overallCashReturns += entry.cashReturns;

      rows.add(DailyCashClosingRow(
        date: entry.date,
        cashierName: entry.cashierName,
        openingCash: entry.openingCash,
        cashSales: entry.cashSales,
        cashReturns: entry.cashReturns,
        cashExpenses: entry.cashExpenses,
        closingCash: closing,
      ));
    }

    _fullRows = _filterSearch(rows, (r) => '${r.cashierName} ${r.date}');
    // Sort descending by date
    final parseDf = DateFormat('dd/MM/yyyy');
    _fullRows.sort((a, b) {
      final ad = parseDf.parse((a as DailyCashClosingRow).date);
      final bd = parseDf.parse((b as DailyCashClosingRow).date);
      return bd.compareTo(ad);
    });

    final closingDrawer = 1000.0 * (agg.length) + overallCashSales - overallCashReturns - overallCashExpenses;

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      FinancialSummaryCardData(
        label: 'Cash Sales',
        value: currFmt.format(overallCashSales),
        icon: Icons.payments_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      FinancialSummaryCardData(
        label: 'Cash Returns',
        value: currFmt.format(overallCashReturns),
        icon: Icons.assignment_return_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      FinancialSummaryCardData(
        label: 'Cash Expenses',
        value: currFmt.format(overallCashExpenses),
        icon: Icons.shopping_bag_rounded,
        gradientColors: [Colors.red.shade500, Colors.pink.shade500],
      ),
      FinancialSummaryCardData(
        label: 'Closing Cash Drawer',
        value: currFmt.format(closingDrawer),
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Tax (GST) Builder
  // ═════════════════════════════════════════════════════════════════════════

  void _loadTaxGST() {
    final startMs = rxStartDate.value.millisecondsSinceEpoch;
    final endMs = rxEndDate.value.millisecondsSinceEpoch;

    // 1. Fetch active sales bills
    final qBills = _boxBill.query(
      EntityBill_.createdAtUtcMs.between(startMs, endMs)
          .and(EntityBill_.status.notEquals('CANCELLED')),
    ).build();
    final bills = qBills.find();
    qBills.close();

    // 2. Fetch active purchases
    final qPurchases = _boxPurchase.query(
      EntityPurchase_.purchaseDateUtcMs.between(startMs, endMs)
          .and(EntityPurchase_.status.notEquals(4)), // not cancelled
    ).build();
    final purchases = qPurchases.find();
    qPurchases.close();

    final df = DateFormat('dd/MM/yyyy HH:mm');
    final rows = <TaxGstRow>[];

    double totalTaxableSales = 0.0;
    double gstCollected = 0.0;
    double gstPaid = 0.0;

    // Process Sales (GST Collected)
    for (final bill in bills) {
      final dateStr = bill.createdAtUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!))
          : '-';

      for (final item in bill.items) {
        final total = item.total ?? 0.0;
        final taxAmount = item.tax ?? 0.0;
        final taxable = total - taxAmount;

        final itemMaster = _boxItem.get(item.item.targetId);
        final rate = itemMaster?.taxRate ?? 18.0;

        totalTaxableSales += taxable;
        gstCollected += taxAmount;

        rows.add(TaxGstRow(
          date: dateStr,
          docNo: bill.billNo ?? 'N/A',
          txnType: 'Sale',
          taxableAmount: taxable,
          gstRate: rate,
          gstAmount: taxAmount,
          totalAmount: total,
        ));
      }
    }

    // Process Purchases (GST Paid)
    for (final po in purchases) {
      final dateStr = po.purchaseDateUtcMs != null
          ? df.format(DateTime.fromMillisecondsSinceEpoch(po.purchaseDateUtcMs!))
          : '-';

      // Load PO items
      final itemsQuery = _boxPurchaseItem.query(EntityPurchaseItem_.purchaseId.equals(po.id)).build();
      final items = itemsQuery.find();
      itemsQuery.close();

      for (final item in items) {
        final total = item.lineAmountIncl ?? 0.0;
        final taxAmount = item.taxAmount ?? 0.0;
        final taxable = item.lineAmountExcl ?? (total - taxAmount);
        final rate = item.taxRate ?? 18.0;

        gstPaid += taxAmount;

        rows.add(TaxGstRow(
          date: dateStr,
          docNo: po.purchaseNo ?? 'N/A',
          txnType: 'Purchase',
          taxableAmount: taxable,
          gstRate: rate,
          gstAmount: taxAmount,
          totalAmount: total,
        ));
      }
    }

    _fullRows = _filterSearch(rows, (r) => '${r.docNo} ${r.txnType}');
    // Sort descending by date
    final parseDf = DateFormat('dd/MM/yyyy HH:mm');
    _fullRows.sort((a, b) {
      final ad = parseDf.parse((a as TaxGstRow).date);
      final bd = parseDf.parse((b as TaxGstRow).date);
      return bd.compareTo(ad);
    });

    final netGst = gstCollected - gstPaid;

    final currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    rxSummaryCards.assignAll([
      FinancialSummaryCardData(
        label: 'Taxable Sales',
        value: currFmt.format(totalTaxableSales),
        icon: Icons.monetization_on_rounded,
        gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
      ),
      FinancialSummaryCardData(
        label: 'GST Collected (Sales)',
        value: currFmt.format(gstCollected),
        icon: Icons.arrow_downward_rounded,
        gradientColors: [Colors.teal.shade500, Colors.green.shade500],
      ),
      FinancialSummaryCardData(
        label: 'GST Paid (Purchases)',
        value: currFmt.format(gstPaid),
        icon: Icons.arrow_upward_rounded,
        gradientColors: [Colors.orange.shade500, Colors.amber.shade500],
      ),
      FinancialSummaryCardData(
        label: 'Net GST Liability',
        value: currFmt.format(netGst),
        icon: Icons.balance_rounded,
        gradientColors: [Colors.red.shade500, Colors.pink.shade500],
      ),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Export Actions
  // ═════════════════════════════════════════════════════════════════════════

  void exportExcel() async {
    final type = rxReportType.value;
    final reportTitle = 'Financial Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final fmt = DateFormat('dd MMM yyyy');
    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}',
      'Branch': rxBranch.value,
    };
    if (rxSearchQuery.value.isNotEmpty) {
      filters['Search Query'] = rxSearchQuery.value;
    }

    final summary = <String, dynamic>{};
    for (final card in rxSummaryCards) {
      summary[card.label] = card.value;
    }

    List<String> headers = [];
    List<List<dynamic>> exportRows = [];

    switch (type) {
      case FinancialReportType.paymentCollection:
        headers = ['Collection Date', 'Payment Method', 'Document Bill', 'Customer Name', 'Amount Collected', 'Cashier Duty'];
        for (final r in allRows) {
          if (r is PaymentCollectionRow) {
            exportRows.add([r.date, r.paymentMethod, r.billNo, r.customerName, r.amount, r.cashier]);
          }
        }
        break;
      case FinancialReportType.dailyCashClosing:
        headers = ['Reconcile Date', 'Cashier on Duty', 'Opening Cash', 'Cash Sales (+)', 'Cash Returns (-)', 'Cash Expenses (-)', 'Closing Drawer'];
        for (final r in allRows) {
          if (r is DailyCashClosingRow) {
            exportRows.add([r.date, r.cashierName, r.openingCash, r.cashSales, r.cashReturns, r.cashExpenses, r.closingCash]);
          }
        }
        break;
      case FinancialReportType.taxGST:
        headers = ['Transaction Date', 'Doc Number', 'Transaction Type', 'Taxable Amount', 'GST Rate', 'GST Amount', 'Total Invoice'];
        for (final r in allRows) {
          if (r is TaxGstRow) {
            exportRows.add([r.date, r.docNo, r.txnType, r.taxableAmount, '${r.gstRate}%', r.gstAmount, r.totalAmount]);
          }
        }
        break;
    }

    final excelService = ServiceItemExcel();
    await excelService.exportReport(
      title: reportTitle,
      headers: headers,
      rows: exportRows,
      appliedFilters: filters,
      summaryData: summary,
    );
  }

  // ── Import Excel (Development/Test Only) ──

  List<String> getHeadersForCurrentReport() {
    switch (rxReportType.value) {
      case FinancialReportType.paymentCollection:
        return ['Collection Date', 'Payment Method', 'Document Bill', 'Customer Name', 'Amount Collected', 'Cashier Duty'];
      case FinancialReportType.dailyCashClosing:
        return ['Reconcile Date', 'Cashier on Duty', 'Opening Cash', 'Cash Sales (+)', 'Cash Returns (-)', 'Cash Expenses (-)', 'Closing Drawer'];
      case FinancialReportType.taxGST:
        return ['Transaction Date', 'Doc Number', 'Transaction Type', 'Taxable Amount', 'GST Rate', 'GST Amount', 'Total Invoice'];
    }
  }

  Future<void> importTestExcel() async {
    final type = rxReportType.value;
    final expectedHeaders = getHeadersForCurrentReport();

    final rawRows = await ServiceReportExcelImport.importAndValidate(
      expectedHeaders: expectedHeaders,
    );
    if (rawRows == null) return;

    final testRows = <dynamic>[];
    switch (type) {
      case FinancialReportType.paymentCollection:
        double totalAmt = 0;
        for (final raw in rawRows) {
          final row = PaymentCollectionRow(
            date: ServiceReportExcelImport.parseString(raw['Collection Date']),
            paymentMethod: ServiceReportExcelImport.parseString(raw['Payment Method']),
            billNo: ServiceReportExcelImport.parseString(raw['Document Bill']),
            customerName: ServiceReportExcelImport.parseString(raw['Customer Name']),
            amount: ServiceReportExcelImport.parseDouble(raw['Amount Collected']),
            cashier: ServiceReportExcelImport.parseString(raw['Cashier Duty']),
            bill: EntityBill(),
          );
          testRows.add(row);
          totalAmt += row.amount;
        }
        rxSummaryCards.assignAll([
          FinancialSummaryCardData(
            label: 'Total Collections',
            value: _currFmt.format(totalAmt),
            icon: Icons.account_balance_wallet_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
          FinancialSummaryCardData(
            label: 'Total Records',
            value: testRows.length.toString(),
            icon: Icons.receipt_long_rounded,
            gradientColors: [Colors.teal.shade500, Colors.green.shade500],
          ),
        ]);
        break;

      case FinancialReportType.dailyCashClosing:
        double totalClosing = 0;
        for (final raw in rawRows) {
          final row = DailyCashClosingRow(
            date: ServiceReportExcelImport.parseString(raw['Reconcile Date']),
            cashierName: ServiceReportExcelImport.parseString(raw['Cashier on Duty']),
            openingCash: ServiceReportExcelImport.parseDouble(raw['Opening Cash']),
            cashSales: ServiceReportExcelImport.parseDouble(raw['Cash Sales (+)']),
            cashReturns: ServiceReportExcelImport.parseDouble(raw['Cash Returns (-)']),
            cashExpenses: ServiceReportExcelImport.parseDouble(raw['Cash Expenses (-)']),
            closingCash: ServiceReportExcelImport.parseDouble(raw['Closing Drawer']),
          );
          testRows.add(row);
          totalClosing += row.closingCash;
        }
        rxSummaryCards.assignAll([
          FinancialSummaryCardData(
            label: 'Closing Cash Reconciled',
            value: _currFmt.format(totalClosing),
            icon: Icons.point_of_sale_rounded,
            gradientColors: [Colors.teal.shade500, Colors.green.shade500],
          ),
          FinancialSummaryCardData(
            label: 'Days Reconciled',
            value: testRows.length.toString(),
            icon: Icons.calendar_month_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
        ]);
        break;

      case FinancialReportType.taxGST:
        double totalTaxable = 0, totalGst = 0;
        for (final raw in rawRows) {
          final row = TaxGstRow(
            date: ServiceReportExcelImport.parseString(raw['Transaction Date']),
            docNo: ServiceReportExcelImport.parseString(raw['Doc Number']),
            txnType: ServiceReportExcelImport.parseString(raw['Transaction Type']),
            taxableAmount: ServiceReportExcelImport.parseDouble(raw['Taxable Amount']),
            gstRate: ServiceReportExcelImport.parseDouble(raw['GST Rate']),
            gstAmount: ServiceReportExcelImport.parseDouble(raw['GST Amount']),
            totalAmount: ServiceReportExcelImport.parseDouble(raw['Total Invoice']),
          );
          testRows.add(row);
          totalTaxable += row.taxableAmount;
          totalGst += row.gstAmount;
        }
        rxSummaryCards.assignAll([
          FinancialSummaryCardData(
            label: 'Total Taxable Value',
            value: _currFmt.format(totalTaxable),
            icon: Icons.request_quote_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
          FinancialSummaryCardData(
            label: 'Total GST Collected',
            value: _currFmt.format(totalGst),
            icon: Icons.account_balance_rounded,
            gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
          ),
        ]);
        break;
    }

    _fullRows = testRows;
    currentPage.value = 0;
    _applyPagination();
  }

  final _currFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

  void recomputeSummaryCardsForTestRows() {
    final type = rxReportType.value;
    switch (type) {
      case FinancialReportType.paymentCollection:
        double totalAmt = 0;
        for (final r in _fullRows.cast<PaymentCollectionRow>()) {
          totalAmt += r.amount;
        }
        rxSummaryCards.assignAll([
          FinancialSummaryCardData(
            label: 'Total Collections',
            value: _currFmt.format(totalAmt),
            icon: Icons.account_balance_wallet_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
          FinancialSummaryCardData(
            label: 'Total Records',
            value: _fullRows.length.toString(),
            icon: Icons.receipt_long_rounded,
            gradientColors: [Colors.teal.shade500, Colors.green.shade500],
          ),
        ]);
        break;
      case FinancialReportType.dailyCashClosing:
        double totalClosing = 0;
        for (final r in _fullRows.cast<DailyCashClosingRow>()) {
          totalClosing += r.closingCash;
        }
        rxSummaryCards.assignAll([
          FinancialSummaryCardData(
            label: 'Closing Cash Reconciled',
            value: _currFmt.format(totalClosing),
            icon: Icons.point_of_sale_rounded,
            gradientColors: [Colors.teal.shade500, Colors.green.shade500],
          ),
          FinancialSummaryCardData(
            label: 'Days Reconciled',
            value: _fullRows.length.toString(),
            icon: Icons.calendar_month_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
        ]);
        break;
      case FinancialReportType.taxGST:
        double totalTaxable = 0, totalGst = 0;
        for (final r in _fullRows.cast<TaxGstRow>()) {
          totalTaxable += r.taxableAmount;
          totalGst += r.gstAmount;
        }
        rxSummaryCards.assignAll([
          FinancialSummaryCardData(
            label: 'Total Taxable Value',
            value: _currFmt.format(totalTaxable),
            icon: Icons.request_quote_rounded,
            gradientColors: [Colors.indigo.shade500, Colors.blue.shade500],
          ),
          FinancialSummaryCardData(
            label: 'Total GST Collected',
            value: _currFmt.format(totalGst),
            icon: Icons.account_balance_rounded,
            gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
          ),
        ]);
        break;
    }
  }

  void exportPdf() async {
    final type = rxReportType.value;
    final reportTitle = 'Financial Report - ${type.label}';
    final allRows = _fullRows.isNotEmpty ? _fullRows : rxRows;

    final fmt = DateFormat('dd MMM yyyy');
    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': '${fmt.format(rxStartDate.value)} → ${fmt.format(rxEndDate.value)}',
      'Branch': rxBranch.value,
    };
    if (rxSearchQuery.value.isNotEmpty) {
      filters['Search Query'] = rxSearchQuery.value;
    }

    final summary = <String, dynamic>{};
    for (final card in rxSummaryCards) {
      summary[card.label] = card.value;
    }

    List<String> headers = [];
    List<List<dynamic>> exportRows = [];

    switch (type) {
      case FinancialReportType.paymentCollection:
        headers = ['Collection Date', 'Payment Method', 'Document Bill', 'Customer Name', 'Amount Collected', 'Cashier Duty'];
        for (final r in allRows) {
          if (r is PaymentCollectionRow) {
            exportRows.add([r.date, r.paymentMethod, r.billNo, r.customerName, r.amount, r.cashier]);
          }
        }
        break;
      case FinancialReportType.dailyCashClosing:
        headers = ['Reconcile Date', 'Cashier on Duty', 'Opening Cash', 'Cash Sales (+)', 'Cash Returns (-)', 'Cash Expenses (-)', 'Closing Drawer'];
        for (final r in allRows) {
          if (r is DailyCashClosingRow) {
            exportRows.add([r.date, r.cashierName, r.openingCash, r.cashSales, r.cashReturns, r.cashExpenses, r.closingCash]);
          }
        }
        break;
      case FinancialReportType.taxGST:
        headers = ['Transaction Date', 'Doc Number', 'Transaction Type', 'Taxable Amount', 'GST Rate', 'GST Amount', 'Total Invoice'];
        for (final r in allRows) {
          if (r is TaxGstRow) {
            exportRows.add([r.date, r.docNo, r.txnType, r.taxableAmount, '${r.gstRate}%', r.gstAmount, r.totalAmount]);
          }
        }
        break;
    }

    final pdfService = ServiceReportPdf();
    await pdfService.exportReport(
      title: reportTitle,
      headers: headers,
      rows: exportRows,
      appliedFilters: filters,
      summaryData: summary,
    );
  }
}

// ── Aggregation helper classes ──
class _DailyCashAgg {
  String date;
  String cashierName;
  double openingCash;
  double cashSales;
  double cashReturns;
  double cashExpenses;
  _DailyCashAgg({
    required this.date,
    required this.cashierName,
    required this.openingCash,
    required this.cashSales,
    required this.cashReturns,
    required this.cashExpenses,
  });
}
