import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../features/authentication/data/auth_repository.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_day_session.dart';
import '../../../../model/entity_drawer_movement.dart';
import '../../../../model/entity_finance_transaction.dart';
import '../../../../model/entity_shift_session.dart';
import '../../../../model/entity_user.dart';
import '../../../../objectbox.g.dart';
import '../../../../repository/repo_storage.dart';
import '../../../../service/service_brand_context.dart';
import '../../../../service/service_object_box.dart';
import '../../../../util/app_route.dart';
import '../../../../util/snackbar_util.dart';
import '../../../../util/util_device.dart';
import '../../controller_home.dart';

class ControllerHomeAccount extends GetxController {
  late final Box<EntityDaySession> _boxDay;
  late final Box<EntityShiftSession> _boxShift;
  late final Box<EntityDrawerMovement> _boxMovement;
  late final Box<EntityBill> _boxBill;
  late final Box<EntityFinanceTransaction> _boxFinance;

  final rxActiveDay = Rx<EntityDaySession?>(null);
  final rxActiveShift = Rx<EntityShiftSession?>(null);
  final rxPreviousDay = Rx<EntityDaySession?>(null);

  // Summary Metrics
  final rxOpeningBalance = 0.0.obs;
  final rxOpeningTxnCount = 0.obs;

  final rxCashInTotal = 0.0.obs;
  final rxCashInTxnCount = 0.obs;

  final rxSalesCashTotal = 0.0.obs;
  final rxSalesCashTxnCount = 0.obs;

  final rxCashOutTotal = 0.0.obs;
  final rxCashOutTxnCount = 0.obs;

  final rxExpensesCashTotal = 0.0.obs;
  final rxExpensesCashTxnCount = 0.obs;

  final rxClosingBalance = 0.0.obs;
  final rxClosingTxnCount = 0.obs;

  // Payment modes breakdown for current shift
  final rxPaymentModes = <String, double>{
    'Cash': 0.0,
    'UPI': 0.0,
    'Phonepe': 0.0,
    'Card': 0.0,
  }.obs;

  // Order statistics for current shift
  final rxFulfilledOrders = 0.obs;
  final rxCancelledOrders = 0.obs;
  final rxComplimentaryOrders = 0.obs;

  // Shift History (all shifts ordered newest first)
  final rxShiftHistory = <EntityShiftSession>[].obs;

  // Most recently closed shift (for opening shift reference)
  final rxPreviousShift = Rx<EntityShiftSession?>(null);

  // Outlet & Device Details
  final rxIpAddress = '127.0.0.1'.obs;
  final rxOutletPhone = ''.obs;
  final rxOutletAddress = ''.obs;
  final rxOutletName = 'RH POS FOODs'.obs;
  final rxUserId = '0'.obs;
  final rxUsername = ''.obs;
  final rxUserRole = ''.obs;

  bool get isDayOpen => rxActiveDay.value != null && rxActiveDay.value!.isOpen;
  bool get isShiftOpen =>
      rxActiveShift.value != null && rxActiveShift.value!.isOpen;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxDay = ob.box<EntityDaySession>();
    _boxShift = ob.box<EntityShiftSession>();
    _boxMovement = ob.box<EntityDrawerMovement>();
    _boxBill = ob.box<EntityBill>();
    _boxFinance = ob.box<EntityFinanceTransaction>();

    loadDeviceAndOutletDetails();
    refreshAll();
  }

  Future<void> loadDeviceAndOutletDetails() async {
    try {
      final ip = await UtilDevice.getIpAddress();
      if (ip.isNotEmpty) {
        rxIpAddress.value = ip;
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<ServiceBrandContext>()) {
        final brandCtx = Get.find<ServiceBrandContext>();
        final branch = brandCtx.selectedBranch;
        final brand = brandCtx.selectedBrand;
        if (brand != null && brand.name.en.isNotEmpty) {
          rxOutletName.value = brand.name.en;
        } else if (branch != null && branch.name.en.isNotEmpty) {
          rxOutletName.value = branch.name.en;
        }
        if (branch != null) {
          final phone = branch.contact.phones.primary.isNotEmpty
              ? branch.contact.phones.primary
              : branch.contact.phones.alternate;
          if (phone.isNotEmpty) {
            rxOutletPhone.value = phone;
          }
          final addr = [
            branch.address.full,
            branch.address.city,
            branch.address.state,
            branch.address.country,
          ].where((s) => s.trim().isNotEmpty).join(', ');
          if (addr.isNotEmpty) {
            rxOutletAddress.value = addr;
          }
        }
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<RepoStorage>()) {
        final str = await Get.find<RepoStorage>().getUser();
        if (str.isNotEmpty) {
          final map = json.decode(str);
          final user = EntityUser.fromMap(map);
          rxUsername.value = user.username ?? user.first ?? 'Cashier';
          rxUserId.value = '${user.id}';
          rxUserRole.value = user.role ?? 'MASTER_POS';
        }
      }
    } catch (_) {}
  }

  void refreshAll() {
    // 1. Fetch active Day session
    final activeDays = _boxDay
        .query(EntityDaySession_.isOpen.equals(true))
        .order(EntityDaySession_.id, flags: Order.descending)
        .build()
        .find();
    rxActiveDay.value = activeDays.isNotEmpty ? activeDays.first : null;

    // 2. Fetch active Shift session
    final activeShifts = _boxShift
        .query(EntityShiftSession_.isOpen.equals(true))
        .order(EntityShiftSession_.id, flags: Order.descending)
        .build()
        .find();
    rxActiveShift.value = activeShifts.isNotEmpty ? activeShifts.first : null;

    // 3. Fetch previous closed Day session
    final closedDays = _boxDay
        .query(EntityDaySession_.isOpen.equals(false))
        .order(EntityDaySession_.id, flags: Order.descending)
        .build()
        .find();
    rxPreviousDay.value = closedDays.isNotEmpty ? closedDays.first : null;

    // 4. Load all shifts for history (newest first, limit 20)
    final allShifts = _boxShift
        .query()
        .order(EntityShiftSession_.id, flags: Order.descending)
        .build()
        .find();
    rxShiftHistory.value = allShifts.take(20).toList();

    // 5. Most recently closed shift (for opening shift reference)
    final closedShifts = _boxShift
        .query(EntityShiftSession_.isOpen.equals(false))
        .order(EntityShiftSession_.id, flags: Order.descending)
        .build()
        .find();
    rxPreviousShift.value = closedShifts.isNotEmpty ? closedShifts.first : null;

    _computeMetrics();
  }

  void _computeMetrics() {
    final activeShift = rxActiveShift.value;
    final activeDay = rxActiveDay.value;

    final now = DateTime.now();
    final todayStartMs = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final int startTimeMs = activeShift?.startTimestampMs ??
        activeDay?.startTimestampMs ??
        todayStartMs;

    // ── 1. Opening Balance ──
    rxOpeningBalance.value = activeShift?.openingCash ?? activeDay?.openingCash ?? 0.0;
    rxOpeningTxnCount.value = 0;

    // ── 2. Cash In Movements ──
    final cashInQuery = _boxMovement
        .query(
          EntityDrawerMovement_.type.equals('CASH_IN')
              .and(EntityDrawerMovement_.timestampMs.greaterOrEqual(startTimeMs)),
        )
        .build();
    final cashIns = cashInQuery.find();
    rxCashInTotal.value =
        cashIns.fold(0.0, (sum, m) => sum + (m.amount));
    rxCashInTxnCount.value = cashIns.length;

    // ── 3. Cash Out Movements ──
    final cashOutQuery = _boxMovement
        .query(
          EntityDrawerMovement_.type.equals('CASH_OUT')
              .and(EntityDrawerMovement_.timestampMs.greaterOrEqual(startTimeMs)),
        )
        .build();
    final cashOuts = cashOutQuery.find();
    rxCashOutTotal.value =
        cashOuts.fold(0.0, (sum, m) => sum + (m.amount));
    rxCashOutTxnCount.value = cashOuts.length;

    // ── 4. Expenses (Drawer Movements + Local Finance Txns) ──
    final expenseMovements = _boxMovement
        .query(
          EntityDrawerMovement_.type.equals('EXPENSE')
              .and(EntityDrawerMovement_.timestampMs.greaterOrEqual(startTimeMs)),
        )
        .build()
        .find();
    final financeExpenses = _boxFinance
        .query(
          EntityFinanceTransaction_.type.equals('expense')
              .and(EntityFinanceTransaction_.dateUtcMs.greaterOrEqual(startTimeMs)),
        )
        .build()
        .find();

    double expenseTotal = 0.0;
    int expenseCount = expenseMovements.length + financeExpenses.length;
    for (final m in expenseMovements) {
      expenseTotal += m.amount;
    }
    for (final f in financeExpenses) {
      expenseTotal += (f.amount ?? 0.0);
    }
    rxExpensesCashTotal.value = expenseTotal;
    rxExpensesCashTxnCount.value = expenseCount;

    // ── 5. Sales & Payment Modes (from Bills) ──
    final bills = _boxBill
        .query(EntityBill_.createdAtUtcMs.greaterOrEqual(startTimeMs))
        .build()
        .find();

    double cashSales = 0.0;
    int cashSalesCount = 0;
    double upiSales = 0.0;
    double phonepeSales = 0.0;
    double cardSales = 0.0;

    int fulfilled = 0;
    int cancelled = 0;
    int complimentary = 0;

    for (final bill in bills) {
      final status = (bill.status ?? '').toUpperCase();
      if (status == 'CANCELLED') {
        cancelled++;
        continue;
      }
      fulfilled++;

      final mode = (bill.paymentMode ?? 'CASH').toUpperCase();
      final total = bill.grandTotal ?? 0.0;
      final discount = bill.discount ?? 0.0;
      final origTotal = bill.totalAmount ?? 0.0;

      if (origTotal > 0 && discount >= origTotal) {
        complimentary++;
      }

      if (mode == 'CASH') {
        cashSales += total;
        cashSalesCount++;
      } else if (mode == 'SPLIT') {
        final splitCash = bill.splitCash ?? 0.0;
        final splitOnline = bill.splitOnline ?? 0.0;
        if (splitCash > 0) {
          cashSales += splitCash;
          cashSalesCount++;
        }
        if (splitOnline > 0) {
          upiSales += splitOnline;
        }
      } else if (mode.contains('PHONEPE')) {
        phonepeSales += total;
      } else if (mode == 'UPI' || mode.contains('GPAY') || mode.contains('PAYTM')) {
        upiSales += total;
      } else if (mode == 'CARD' || mode.contains('DEBIT') || mode.contains('CREDIT')) {
        cardSales += total;
      } else {
        // default fallback to cash if unspecified
        cashSales += total;
        cashSalesCount++;
      }
    }

    rxSalesCashTotal.value = cashSales;
    rxSalesCashTxnCount.value = cashSalesCount;

    rxPaymentModes.value = {
      'Cash': cashSales,
      'UPI': upiSales,
      'Phonepe': phonepeSales,
      'Card': cardSales,
    };

    rxFulfilledOrders.value = fulfilled;
    rxCancelledOrders.value = cancelled;
    rxComplimentaryOrders.value = complimentary;

    // ── 6. Closing Balance Calculation ──
    // Closing = Opening + Cash In + Cash Sales - Cash Out - Expenses
    final calculatedClosing = rxOpeningBalance.value +
        rxCashInTotal.value +
        rxSalesCashTotal.value -
        rxCashOutTotal.value -
        rxExpensesCashTotal.value;
    rxClosingBalance.value = calculatedClosing < 0 ? 0.0 : calculatedClosing;
    rxClosingTxnCount.value = 0;
  }

  /// Start Day & Shift together
  Future<void> startDayAndShift({
    required double openingCash,
    required Map<int, int> denominations,
    String? comments,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final denomJson = jsonEncode(
      denominations.map((k, v) => MapEntry(k.toString(), v)),
    );

    String? branchId;
    String? brandId;
    if (Get.isRegistered<ServiceBrandContext>()) {
      final brandCtx = Get.find<ServiceBrandContext>();
      branchId = brandCtx.selectedBranchId;
      brandId = brandCtx.selectedBrandId;
    }

    // 1. Create Day Session
    final daySession = EntityDaySession(
      startTimestampMs: nowMs,
      isOpen: true,
      openingCash: openingCash,
      closingCash: 0.0,
      startedByUserId: rxUserId.value,
      startedByUsername: rxUsername.value,
      openingComment: comments,
      branchId: branchId,
      brandId: brandId,
      openingDenominationsJson: denomJson,
      createdAtUtcMs: nowMs,
    );
    final dayId = _boxDay.put(daySession);
    daySession.id = dayId;
    rxActiveDay.value = daySession;

    // 2. Create Shift Session linked to this day
    final shiftSession = EntityShiftSession(
      daySessionId: dayId,
      startTimestampMs: nowMs,
      isOpen: true,
      openingCash: openingCash,
      closingCash: 0.0,
      startedByUserId: rxUserId.value,
      startedByUsername: rxUsername.value,
      comments: comments,
      branchId: branchId,
      brandId: brandId,
      openingDenominationsJson: denomJson,
      createdAtUtcMs: nowMs,
    );
    final shiftId = _boxShift.put(shiftSession);
    shiftSession.id = shiftId;
    rxActiveShift.value = shiftSession;

    refreshAll();
    SnackbarUtil.showSuccess('Day & Shift started successfully');
  }

  /// Start Shift only (when day is already open)
  Future<void> startShiftOnly({
    required double openingCash,
    required Map<int, int> denominations,
    String? comments,
  }) async {
    if (!isDayOpen) {
      await startDayAndShift(
        openingCash: openingCash,
        denominations: denominations,
        comments: comments,
      );
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final denomJson = jsonEncode(
      denominations.map((k, v) => MapEntry(k.toString(), v)),
    );

    String? branchId;
    String? brandId;
    if (Get.isRegistered<ServiceBrandContext>()) {
      final brandCtx = Get.find<ServiceBrandContext>();
      branchId = brandCtx.selectedBranchId;
      brandId = brandCtx.selectedBrandId;
    }

    final shiftSession = EntityShiftSession(
      daySessionId: rxActiveDay.value!.id,
      startTimestampMs: nowMs,
      isOpen: true,
      openingCash: openingCash,
      closingCash: 0.0,
      startedByUserId: rxUserId.value,
      startedByUsername: rxUsername.value,
      comments: comments,
      branchId: branchId,
      brandId: brandId,
      openingDenominationsJson: denomJson,
      createdAtUtcMs: nowMs,
    );
    final shiftId = _boxShift.put(shiftSession);
    shiftSession.id = shiftId;
    rxActiveShift.value = shiftSession;

    refreshAll();
    SnackbarUtil.showSuccess('Shift started successfully');
  }

  /// Close Shift — saves data and then logs out to login screen
  Future<void> closeShift({
    required Map<int, int> denominations,
    required double countedTotal,
    String? comments,
  }) async {
    final shift = rxActiveShift.value;
    if (shift == null) {
      SnackbarUtil.showError('No active shift to close');
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final denomJson = jsonEncode(
      denominations.map((k, v) => MapEntry(k.toString(), v)),
    );

    shift.isOpen = false;
    shift.endTimestampMs = nowMs;
    shift.closingCash = countedTotal;
    shift.cashIn = rxCashInTotal.value;
    shift.cashOut = rxCashOutTotal.value;
    shift.salesCash = rxSalesCashTotal.value;
    shift.expensesCash = rxExpensesCashTotal.value;
    shift.closedByUserId = rxUserId.value;
    shift.closedByUsername = rxUsername.value;
    shift.comments = comments;
    shift.closingDenominationsJson = denomJson;
    shift.paymentModesJson = jsonEncode(rxPaymentModes);
    shift.fulfilledOrders = rxFulfilledOrders.value;
    shift.cancelledOrders = rxCancelledOrders.value;
    shift.complimentaryOrders = rxComplimentaryOrders.value;

    _boxShift.put(shift);
    rxActiveShift.value = null;

    refreshAll();
    SnackbarUtil.showSuccess('Shift closed successfully. Logging out...');

    // Logout and redirect to login screen after shift is closed
    await Future.delayed(const Duration(milliseconds: 800));
    if (Get.isRegistered<ControllerHome>()) {
      Get.delete<ControllerHome>(force: true);
    }
    if (Get.isRegistered<AuthRepository>()) {
      await Get.find<AuthRepository>().logout();
    }
    Get.offAllNamed(AppRoute.login);
  }

  /// Close Day — saves data and then navigates to login screen
  Future<void> closeDay({String? comments}) async {
    final day = rxActiveDay.value;
    if (day == null) {
      SnackbarUtil.showError('No active day to close');
      return;
    }

    // Auto-close shift if still active
    if (isShiftOpen) {
      final shift = rxActiveShift.value!;
      shift.isOpen = false;
      shift.endTimestampMs = DateTime.now().millisecondsSinceEpoch;
      shift.closingCash = rxClosingBalance.value;
      shift.cashIn = rxCashInTotal.value;
      shift.cashOut = rxCashOutTotal.value;
      shift.salesCash = rxSalesCashTotal.value;
      shift.expensesCash = rxExpensesCashTotal.value;
      shift.closedByUserId = rxUserId.value;
      shift.closedByUsername = rxUsername.value;
      shift.comments = comments;
      shift.paymentModesJson = jsonEncode(rxPaymentModes);
      shift.fulfilledOrders = rxFulfilledOrders.value;
      shift.cancelledOrders = rxCancelledOrders.value;
      shift.complimentaryOrders = rxComplimentaryOrders.value;
      _boxShift.put(shift);
      rxActiveShift.value = null;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    day.isOpen = false;
    day.endTimestampMs = nowMs;
    day.closingCash = rxClosingBalance.value;
    day.closedByUserId = rxUserId.value;
    day.closedByUsername = rxUsername.value;
    day.closingComment = comments;

    _boxDay.put(day);
    rxActiveDay.value = null;

    refreshAll();
    SnackbarUtil.showSuccess('Day closed successfully. Redirecting to login...');

    // Navigate to login screen after closing the day
    await Future.delayed(const Duration(milliseconds: 800));
    if (Get.isRegistered<ControllerHome>()) {
      Get.delete<ControllerHome>(force: true);
    }
    if (Get.isRegistered<AuthRepository>()) {
      await Get.find<AuthRepository>().logout();
    }
    Get.offAllNamed(AppRoute.login);
  }

  /// Record Cash In
  Future<void> recordCashIn({required double amount, required String reason}) async {
    if (amount <= 0) {
      SnackbarUtil.showError('Please enter a valid amount');
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final movement = EntityDrawerMovement(
      shiftSessionId: rxActiveShift.value?.id ?? 0,
      daySessionId: rxActiveDay.value?.id ?? 0,
      type: 'CASH_IN',
      amount: amount,
      reason: reason,
      timestampMs: nowMs,
      userId: rxUserId.value,
      username: rxUsername.value,
      createdAtUtcMs: nowMs,
    );
    _boxMovement.put(movement);
    refreshAll();
    SnackbarUtil.showSuccess('Cash In recorded: ₹${amount.toStringAsFixed(2)}');
  }

  /// Record Cash Out
  Future<void> recordCashOut({required double amount, required String reason}) async {
    if (amount <= 0) {
      SnackbarUtil.showError('Please enter a valid amount');
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final movement = EntityDrawerMovement(
      shiftSessionId: rxActiveShift.value?.id ?? 0,
      daySessionId: rxActiveDay.value?.id ?? 0,
      type: 'CASH_OUT',
      amount: amount,
      reason: reason,
      timestampMs: nowMs,
      userId: rxUserId.value,
      username: rxUsername.value,
      createdAtUtcMs: nowMs,
    );
    _boxMovement.put(movement);
    refreshAll();
    SnackbarUtil.showSuccess('Cash Out recorded: ₹${amount.toStringAsFixed(2)}');
  }

  String formatTimestamp(int? ms) {
    if (ms == null || ms == 0) return 'Not Started';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('yyyy-MM-dd hh:mm a').format(dt);
  }

  String formatTimestampSeconds(int? ms) {
    if (ms == null || ms == 0) return 'Not Started';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('dd/MM/yyyy hh:mm:ss a').format(dt);
  }
}
