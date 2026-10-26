import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_currency.dart';

enum VoiceHistoryDateFilter { today, yesterday, thisWeek, thisMonth, allTime }

class ControllerVoiceSalesHistory extends GetxController {
  late final Box<EntityBill> _boxBill;

  final rxDateFilter = VoiceHistoryDateFilter.allTime.obs;
  final rxSearchQuery = ''.obs;
  final searchController = TextEditingController();

  final rxAllVoiceBills = <EntityBill>[].obs;
  final rxFilteredBills = <EntityBill>[].obs;

  // Analytics Metrics
  final rxTotalRevenue = 0.0.obs;
  final rxTotalBillsCount = 0.obs;
  final rxTotalItemsCount = 0.obs;
  final rxAvgBillValue = 0.0.obs;
  final rxCashRevenue = 0.0.obs;
  final rxUpiRevenue = 0.0.obs;
  final rxCardRevenue = 0.0.obs;

  String get currencySymbol =>
      Get.isRegistered<ServiceCurrency>() ? Get.find<ServiceCurrency>().rxCurrency.value : '₹';

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();

    searchController.addListener(() {
      rxSearchQuery.value = searchController.text.trim();
      _applyFilters();
    });

    loadVoiceBills();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void setDateFilter(VoiceHistoryDateFilter filter) {
    rxDateFilter.value = filter;
    _applyFilters();
  }

  void loadVoiceBills() {
    // Query all bills created via AI Voice Billing
    final query = _boxBill.query(
      EntityBill_.poNo.equals('AI_VOICE')
          .or(EntityBill_.note.contains('[AI_VOICE]'))
          .or(EntityBill_.billNo.startsWith('VOICE-')),
    ).order(EntityBill_.createdAtUtcMs, flags: Order.descending).build();

    final bills = query.find();
    query.close();

    rxAllVoiceBills.assignAll(bills);
    _applyFilters();
  }

  void _applyFilters() {
    final now = DateTime.now();
    final query = rxSearchQuery.value.toLowerCase();
    final filter = rxDateFilter.value;

    DateTime? filterStart;
    DateTime? filterEnd;

    switch (filter) {
      case VoiceHistoryDateFilter.today:
        filterStart = DateTime(now.year, now.month, now.day);
        filterEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case VoiceHistoryDateFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        filterStart = DateTime(y.year, y.month, y.day);
        filterEnd = DateTime(y.year, y.month, y.day, 23, 59, 59);
        break;
      case VoiceHistoryDateFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filterStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        filterEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case VoiceHistoryDateFilter.thisMonth:
        filterStart = DateTime(now.year, now.month, 1);
        filterEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case VoiceHistoryDateFilter.allTime:
        filterStart = null;
        filterEnd = null;
        break;
    }

    final filtered = rxAllVoiceBills.where((b) {
      // Date Check
      if (filterStart != null && b.createdAtUtcMs != null) {
        final billTime = DateTime.fromMillisecondsSinceEpoch(b.createdAtUtcMs!);
        if (billTime.isBefore(filterStart) || (filterEnd != null && billTime.isAfter(filterEnd))) {
          return false;
        }
      }

      // Search Query Check
      if (query.isNotEmpty) {
        final bNo = (b.billNo ?? '').toLowerCase();
        final cName = (b.customerName ?? '').toLowerCase();
        final cPhone = (b.customerPhone ?? '').toLowerCase();
        final note = (b.note ?? '').toLowerCase();
        final hasItem = b.items.any((it) => (it.itemName ?? '').toLowerCase().contains(query));

        if (!bNo.contains(query) &&
            !cName.contains(query) &&
            !cPhone.contains(query) &&
            !note.contains(query) &&
            !hasItem) {
          return false;
        }
      }

      return true;
    }).toList();

    rxFilteredBills.assignAll(filtered);
    _calculateMetrics(filtered);
  }

  void _calculateMetrics(List<EntityBill> list) {
    double revenue = 0.0;
    int items = 0;
    double cash = 0.0;
    double upi = 0.0;
    double card = 0.0;

    for (final b in list) {
      final total = b.grandTotal ?? 0.0;
      revenue += total;

      for (final it in b.items) {
        items += it.qty ?? 1;
      }

      final mode = (b.paymentMode ?? '').toUpperCase();
      if (mode.contains('CASH')) {
        cash += total;
      } else if (mode.contains('UPI')) {
        upi += total;
      } else if (mode.contains('CARD')) {
        card += total;
      }
    }

    rxTotalRevenue.value = revenue;
    rxTotalBillsCount.value = list.length;
    rxTotalItemsCount.value = items;
    rxAvgBillValue.value = list.isNotEmpty ? (revenue / list.length) : 0.0;
    rxCashRevenue.value = cash;
    rxUpiRevenue.value = upi;
    rxCardRevenue.value = card;
  }

  String extractTranscript(EntityBill bill) {
    final note = bill.note ?? '';
    final match = RegExp(r'Transcript:\s*"([^"]+)"').firstMatch(note);
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }
    return note.replaceAll('[AI_VOICE]', '').replaceAll(RegExp(r'\|.*'), '').trim();
  }

  String extractLanguage(EntityBill bill) {
    final note = bill.note ?? '';
    final match = RegExp(r'Lang:\s*([a-zA-Z]+)').firstMatch(note);
    if (match != null && match.group(1) != null) {
      final code = match.group(1)!.toLowerCase();
      if (code == 'hi') return 'Hindi / Hinglish';
      if (code == 'mr') return 'Marathi';
      if (code == 'en') return 'English';
      return code.toUpperCase();
    }
    return 'Voice Invoiced';
  }

  String formatBillDate(EntityBill bill) {
    if (bill.createdAtUtcMs != null && bill.createdAtUtcMs! > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(bill.createdAtUtcMs!);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    }
    return bill.billDate ?? '';
  }
}
