import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_item_excel.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_report_pdf.dart';
import '../../../../service/service_report_excel_import.dart';

/// All available report types the user can select.
enum ReportType {
  daily,
  weekly,
  monthly,
  yearly,
  salesByCashier,
  customer,
  category,
  item,
  hourWise,
  paymentMethod,
}

/// Human-readable labels for each report type.
extension ReportTypeLabel on ReportType {
  String get label {
    switch (this) {
      case ReportType.daily:
        return 'Daily';
      case ReportType.weekly:
        return 'Weekly';
      case ReportType.monthly:
        return 'Monthly';
      case ReportType.yearly:
        return 'Yearly';
      case ReportType.salesByCashier:
        return 'Sales by Cashier';
      case ReportType.customer:
        return 'Customer';
      case ReportType.category:
        return 'Category';
      case ReportType.item:
        return 'Item';
      case ReportType.hourWise:
        return 'Hour-wise';
      case ReportType.paymentMethod:
        return 'Payment Method';
    }
  }
}

class ControllerHomeReports extends GetxController {
  late final Box<EntityBill> _boxBill;

  // ── Reactive state ──
  final rxReportType = ReportType.daily.obs;
  final rxStartDate = DateTime.now().obs;
  final rxEndDate = DateTime.now().obs;
  final rxIsLoading = false.obs;

  /// Rows for the data table. Each map key corresponds to a column key.
  final RxList<Map<String, dynamic>> rxRows = <Map<String, dynamic>>[].obs;

  // ── Summary totals ──
  final rxTotalBills = 0.obs;
  final rxTotalQty = 0.obs;
  final rxGrossAmount = 0.0.obs;
  final rxDiscount = 0.0.obs;
  final rxTax = 0.0.obs;
  final rxNetAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
  }

  // ── Column definitions per report type ──

  /// Returns a list of (key, label) pairs for the current report type.
  List<MapEntry<String, String>> get columns {
    switch (rxReportType.value) {
      case ReportType.daily:
        return [
          const MapEntry('date', 'Date'),
          const MapEntry('bills', 'Bills'),
          const MapEntry('qty', 'Qty'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('tax', 'Tax'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.weekly:
        return [
          const MapEntry('week', 'Week'),
          const MapEntry('bills', 'Bills'),
          const MapEntry('qty', 'Qty'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('tax', 'Tax'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.monthly:
        return [
          const MapEntry('month', 'Month'),
          const MapEntry('bills', 'Bills'),
          const MapEntry('qty', 'Qty'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('tax', 'Tax'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.yearly:
        return [
          const MapEntry('year', 'Year'),
          const MapEntry('bills', 'Bills'),
          const MapEntry('qty', 'Qty'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('tax', 'Tax'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.salesByCashier:
        return [
          const MapEntry('cashier', 'Cashier'),
          const MapEntry('bills', 'Bills'),
          const MapEntry('qty', 'Qty'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('tax', 'Tax'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.customer:
        return [
          const MapEntry('customer', 'Customer'),
          const MapEntry('phone', 'Phone'),
          const MapEntry('bills', 'Bills'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.category:
        return [
          const MapEntry('category', 'Category'),
          const MapEntry('itemsSold', 'Items Sold'),
          const MapEntry('qty', 'Qty'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.item:
        return [
          const MapEntry('item', 'Item'),
          const MapEntry('barcode', 'Barcode'),
          const MapEntry('qty', 'Qty'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('tax', 'Tax'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.hourWise:
        return [
          const MapEntry('hour', 'Hour'),
          const MapEntry('bills', 'Bills'),
          const MapEntry('qty', 'Qty'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('discount', 'Discount'),
          const MapEntry('tax', 'Tax'),
          const MapEntry('net', 'Net Amount'),
        ];
      case ReportType.paymentMethod:
        return [
          const MapEntry('method', 'Method'),
          const MapEntry('bills', 'Bills'),
          const MapEntry('gross', 'Gross Amount'),
          const MapEntry('net', 'Net Amount'),
        ];
    }
  }

  // ── Data query helpers ──

  /// Build the list of all date-strings (d/MM/yyyy) between start and end.
  List<String> _buildDateStrings(DateTime start, DateTime end) {
    final fmt = DateFormat('d/MM/yyyy');
    final dates = <String>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDay)) {
      dates.add(fmt.format(current));
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  /// Fetch all non-cancelled bills in date range.
  List<EntityBill> _fetchBills() {
    final dateStrings = _buildDateStrings(rxStartDate.value, rxEndDate.value);
    if (dateStrings.isEmpty) return [];

    Condition<EntityBill> dateCond;
    if (dateStrings.length == 1) {
      dateCond = EntityBill_.billDate.equals(dateStrings.first);
    } else {
      dateCond = EntityBill_.billDate.oneOf(dateStrings);
    }

    // Exclude cancelled bills from reports
    final condition = dateCond.and(
      EntityBill_.status.notEquals('CANCELLED'),
    );

    final qb = _boxBill.query(condition)
      ..order(EntityBill_.id, flags: Order.descending);
    final q = qb.build();
    final bills = q.find();
    q.close();
    return bills;
  }

  /// Count total item quantity for a bill.
  int _totalQtyForBill(EntityBill bill) {
    int total = 0;
    for (final bi in bill.items) {
      total += bi.qty ?? 0;
    }
    return total;
  }

  // ── Generate report ──

  void generateReport() {
    rxIsLoading.value = true;
    rxRows.clear();

    try {
      final bills = _fetchBills();

      switch (rxReportType.value) {
        case ReportType.daily:
          _generateDaily(bills);
          break;
        case ReportType.weekly:
          _generateWeekly(bills);
          break;
        case ReportType.monthly:
          _generateMonthly(bills);
          break;
        case ReportType.yearly:
          _generateYearly(bills);
          break;
        case ReportType.salesByCashier:
          _generateByCashier(bills);
          break;
        case ReportType.customer:
          _generateByCustomer(bills);
          break;
        case ReportType.category:
          _generateByCategory(bills);
          break;
        case ReportType.item:
          _generateByItem(bills);
          break;
        case ReportType.hourWise:
          _generateHourWise(bills);
          break;
        case ReportType.paymentMethod:
          _generateByPaymentMethod(bills);
          break;
      }

      _computeSummary();
    } catch (e) {
      debugPrint('Report generation error: $e');
    } finally {
      rxIsLoading.value = false;
    }
  }

  void _computeSummary() {
    int totalBills = 0;
    int totalQty = 0;
    double gross = 0;
    double disc = 0;
    double tax = 0;
    double net = 0;

    for (final row in rxRows) {
      totalBills += (row['bills'] as int? ?? 0);
      totalQty += (row['qty'] as int? ?? row['itemsSold'] as int? ?? 0);
      gross += (row['gross'] as double? ?? 0);
      disc += (row['discount'] as double? ?? 0);
      tax += (row['tax'] as double? ?? 0);
      net += (row['net'] as double? ?? 0);
    }

    rxTotalBills.value = totalBills;
    rxTotalQty.value = totalQty;
    rxGrossAmount.value = gross;
    rxDiscount.value = disc;
    rxTax.value = tax;
    rxNetAmount.value = net;
  }

  // ── Aggregation helpers ──

  /// Generic grouping: groups bills by a key function and produces rows.
  void _groupBills(
    List<EntityBill> bills,
    String keyField,
    String Function(EntityBill) keyFn,
  ) {
    final Map<String, _Agg> map = {};
    for (final b in bills) {
      final key = keyFn(b);
      final agg = map.putIfAbsent(key, () => _Agg());
      agg.bills++;
      agg.qty += _totalQtyForBill(b);
      agg.gross += b.totalAmount ?? 0;
      agg.discount += b.discount ?? 0;
      agg.tax += b.tax ?? 0;
      agg.net += b.grandTotal ?? 0;
    }

    final rows = <Map<String, dynamic>>[];
    for (final e in map.entries) {
      rows.add({
        keyField: e.key,
        'bills': e.value.bills,
        'qty': e.value.qty,
        'gross': e.value.gross,
        'discount': e.value.discount,
        'tax': e.value.tax,
        'net': e.value.net,
      });
    }
    rxRows.assignAll(rows);
  }

  void _generateDaily(List<EntityBill> bills) {
    _groupBills(bills, 'date', (b) => b.billDate ?? 'Unknown');
  }

  void _generateWeekly(List<EntityBill> bills) {
    final fmt = DateFormat('d/MM/yyyy');
    _groupBills(bills, 'week', (b) {
      try {
        final dt = fmt.parse(b.billDate ?? '');
        final weekNum = _weekNumber(dt);
        return 'W$weekNum ${dt.year}';
      } catch (_) {
        return 'Unknown';
      }
    });
  }

  int _weekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final days = date.difference(jan1).inDays;
    return ((days + jan1.weekday) / 7).ceil();
  }

  void _generateMonthly(List<EntityBill> bills) {
    final fmt = DateFormat('d/MM/yyyy');
    _groupBills(bills, 'month', (b) {
      try {
        final dt = fmt.parse(b.billDate ?? '');
        return DateFormat('MMM yyyy').format(dt);
      } catch (_) {
        return 'Unknown';
      }
    });
  }

  void _generateYearly(List<EntityBill> bills) {
    final fmt = DateFormat('d/MM/yyyy');
    _groupBills(bills, 'year', (b) {
      try {
        final dt = fmt.parse(b.billDate ?? '');
        return '${dt.year}';
      } catch (_) {
        return 'Unknown';
      }
    });
  }

  void _generateByCashier(List<EntityBill> bills) {
    // Bills don't store cashier explicitly — use note or default to 'Staff'
    _groupBills(bills, 'cashier', (b) => b.note ?? 'Staff');
  }

  void _generateByCustomer(List<EntityBill> bills) {
    final Map<String, _CustAgg> map = {};
    for (final b in bills) {
      final name = b.customerName ?? 'Walk-in Customer';
      final phone = b.customerPhone ?? '-';
      final key = '$name||$phone';
      final agg = map.putIfAbsent(key, () => _CustAgg(name, phone));
      agg.bills++;
      agg.gross += b.totalAmount ?? 0;
      agg.discount += b.discount ?? 0;
      agg.net += b.grandTotal ?? 0;
    }

    final rows = <Map<String, dynamic>>[];
    for (final e in map.values) {
      rows.add({
        'customer': e.name,
        'phone': e.phone,
        'bills': e.bills,
        'gross': e.gross,
        'discount': e.discount,
        'net': e.net,
      });
    }
    rxRows.assignAll(rows);
  }

  void _generateByCategory(List<EntityBill> bills) {
    final Map<String, _CatAgg> map = {};
    for (final b in bills) {
      for (final bi in b.items) {
        // Attempt to get category from related item entity
        final cat = bi.item.target?.category ?? 'Uncategorised';
        final agg = map.putIfAbsent(cat, () => _CatAgg());
        agg.itemsSold++;
        agg.qty += bi.qty ?? 0;
        agg.gross += (bi.price ?? 0) * (bi.qty ?? 0);
        agg.discount += bi.discount ?? 0;
        agg.net += bi.total ?? 0;
      }
    }

    final rows = <Map<String, dynamic>>[];
    for (final e in map.entries) {
      rows.add({
        'category': e.key,
        'itemsSold': e.value.itemsSold,
        'qty': e.value.qty,
        'gross': e.value.gross,
        'discount': e.value.discount,
        'net': e.value.net,
      });
    }
    rxRows.assignAll(rows);
  }

  void _generateByItem(List<EntityBill> bills) {
    final Map<String, _ItemAgg> map = {};
    for (final b in bills) {
      for (final bi in b.items) {
        final name = bi.itemName ?? 'Unknown';
        final barcode = bi.itemBarcode ?? '-';
        final key = '$name||$barcode';
        final agg = map.putIfAbsent(key, () => _ItemAgg(name, barcode));
        agg.qty += bi.qty ?? 0;
        agg.gross += (bi.price ?? 0) * (bi.qty ?? 0);
        agg.discount += bi.discount ?? 0;
        agg.tax += bi.tax ?? 0;
        agg.net += bi.total ?? 0;
      }
    }

    final rows = <Map<String, dynamic>>[];
    for (final e in map.values) {
      rows.add({
        'item': e.name,
        'barcode': e.barcode,
        'qty': e.qty,
        'gross': e.gross,
        'discount': e.discount,
        'tax': e.tax,
        'net': e.net,
      });
    }
    rxRows.assignAll(rows);
  }

  void _generateHourWise(List<EntityBill> bills) {
    final Map<int, _Agg> map = {};
    for (final b in bills) {
      int hour = 0;
      if (b.createdAtUtcMs != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(b.createdAtUtcMs!, isUtc: true).toLocal();
        hour = dt.hour;
      }
      final agg = map.putIfAbsent(hour, () => _Agg());
      agg.bills++;
      agg.qty += _totalQtyForBill(b);
      agg.gross += b.totalAmount ?? 0;
      agg.discount += b.discount ?? 0;
      agg.tax += b.tax ?? 0;
      agg.net += b.grandTotal ?? 0;
    }

    final rows = <Map<String, dynamic>>[];
    final sortedKeys = map.keys.toList()..sort();
    for (final hour in sortedKeys) {
      final e = map[hour]!;
      final label = '${hour.toString().padLeft(2, '0')}:00 – ${(hour + 1).toString().padLeft(2, '0')}:00';
      rows.add({
        'hour': label,
        'bills': e.bills,
        'qty': e.qty,
        'gross': e.gross,
        'discount': e.discount,
        'tax': e.tax,
        'net': e.net,
      });
    }
    rxRows.assignAll(rows);
  }

  void _generateByPaymentMethod(List<EntityBill> bills) {
    final Map<String, _PayAgg> map = {};
    for (final b in bills) {
      final method = b.paymentMode ?? 'Unknown';
      final agg = map.putIfAbsent(method, () => _PayAgg());
      agg.bills++;
      agg.gross += b.totalAmount ?? 0;
      agg.net += b.grandTotal ?? 0;
    }

    final rows = <Map<String, dynamic>>[];
    for (final e in map.entries) {
      rows.add({
        'method': e.key,
        'bills': e.value.bills,
        'gross': e.value.gross,
        'net': e.value.net,
      });
    }
    rxRows.assignAll(rows);
  }

  // ── Reset ──

  void resetFilters() {
    rxReportType.value = ReportType.daily;
    rxStartDate.value = DateTime.now();
    rxEndDate.value = DateTime.now();
    rxRows.clear();
    rxTotalBills.value = 0;
    rxTotalQty.value = 0;
    rxGrossAmount.value = 0;
    rxDiscount.value = 0;
    rxTax.value = 0;
    rxNetAmount.value = 0;
  }

  // ── Date helpers ──

  String formatDateRange() {
    final fmt = DateFormat('dd MMM yyyy');
    final start = fmt.format(rxStartDate.value);
    final end = fmt.format(rxEndDate.value);
    if (start == end) return start;
    return '$start  →  $end';
  }

  // ── Export PDF ──

  Future<void> exportPdf() async {
    final type = rxReportType.value;
    final reportTitle = 'Report - ${type.label}';

    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': formatDateRange(),
    };

    final summary = <String, dynamic>{
      'Total Bills': rxTotalBills.value,
      'Total Qty': rxTotalQty.value,
      'Gross Amount': rxGrossAmount.value,
      'Discount': rxDiscount.value,
      'Tax': rxTax.value,
      'Net Amount': rxNetAmount.value,
    };

    final cols = columns;
    final headers = cols.map((c) => c.value).toList();
    final exportRows = <List<dynamic>>[];

    for (final row in rxRows) {
      final formattedRow = <dynamic>[];
      for (final col in cols) {
        formattedRow.add(row[col.key] ?? '-');
      }
      exportRows.add(formattedRow);
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

  // ── Export Excel ──

  Future<void> exportExcel() async {
    final type = rxReportType.value;
    final reportTitle = 'Report - ${type.label}';

    final filters = <String, String>{
      'Report Type': type.label,
      'Date Range': formatDateRange(),
    };

    final summary = <String, dynamic>{
      'Total Bills': rxTotalBills.value,
      'Total Qty': rxTotalQty.value,
      'Gross Amount': rxGrossAmount.value,
      'Discount': rxDiscount.value,
      'Tax': rxTax.value,
      'Net Amount': rxNetAmount.value,
    };

    final cols = columns;
    final headers = cols.map((c) => c.value).toList();
    final exportRows = <List<dynamic>>[];

    for (final row in rxRows) {
      final formattedRow = <dynamic>[];
      for (final col in cols) {
        formattedRow.add(row[col.key] ?? '-');
      }
      exportRows.add(formattedRow);
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

  Future<void> importTestExcel() async {
    final cols = columns;
    final expectedHeaders = cols.map((c) => c.value).toList();

    final rawRows = await ServiceReportExcelImport.importAndValidate(
      expectedHeaders: expectedHeaders,
    );
    if (rawRows == null) return;

    final labelToKey = <String, String>{
      for (final c in cols) c.value.trim().toLowerCase(): c.key,
    };

    final convertedRows = <Map<String, dynamic>>[];
    for (final raw in rawRows) {
      final rowMap = <String, dynamic>{};
      raw.forEach((header, val) {
        final key = labelToKey[header.toString().trim().toLowerCase()];
        if (key != null) {
          final strVal = val.toString().trim();
          if (key == 'bills' || key == 'qty' || key == 'itemsSold') {
            rowMap[key] = int.tryParse(strVal) ?? (double.tryParse(strVal)?.toInt() ?? 0);
          } else if (key == 'gross' || key == 'discount' || key == 'tax' || key == 'net') {
            rowMap[key] = double.tryParse(strVal) ?? 0.0;
          } else {
            rowMap[key] = strVal;
          }
        }
      });
      convertedRows.add(rowMap);
    }

    rxRows.assignAll(convertedRows);
    _computeSummary();
  }

  // ── Print ──

  Future<void> printReport() async {
    if (rxRows.isEmpty) {
      Get.snackbar('No Data', 'Generate a report first',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final pdf = pw.Document();
    final cols = columns;
    final currFmt = NumberFormat.simpleCurrency(locale: 'en_IN');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        maxPages: 10000,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('${rxReportType.value.label} Sales Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Period: ${formatDateRange()}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: cols.map((c) => c.value).toList(),
            data: rxRows.map((row) {
              return cols.map((c) {
                final val = row[c.key];
                if (val is double) return currFmt.format(val);
                return val?.toString() ?? '-';
              }).toList();
            }).toList(),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) => Uint8List.fromList(bytes));
  }
}

// ── Private aggregation helpers ──

class _Agg {
  int bills = 0;
  int qty = 0;
  double gross = 0;
  double discount = 0;
  double tax = 0;
  double net = 0;
}

class _CustAgg {
  final String name;
  final String phone;
  int bills = 0;
  double gross = 0;
  double discount = 0;
  double net = 0;
  _CustAgg(this.name, this.phone);
}

class _CatAgg {
  int itemsSold = 0;
  int qty = 0;
  double gross = 0;
  double discount = 0;
  double net = 0;
}

class _ItemAgg {
  final String name;
  final String barcode;
  int qty = 0;
  double gross = 0;
  double discount = 0;
  double tax = 0;
  double net = 0;
  _ItemAgg(this.name, this.barcode);
}

class _PayAgg {
  int bills = 0;
  double gross = 0;
  double net = 0;
}
