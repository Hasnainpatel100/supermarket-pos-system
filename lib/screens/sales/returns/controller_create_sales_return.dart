import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_bill.dart';
import '../../../model/entity_item.dart';
import '../../../model/entity_sales_return.dart';
import '../../../model/entity_sales_return_item.dart';
import '../../../model/entity_stock_transaction.dart';
import '../../../model/stock_txn_type.dart';
import '../../../objectbox.g.dart';
import '../../../service/service_object_box.dart';
import '../invoice/controller_create_sales_invoice.dart';

class ControllerCreateSalesReturn extends GetxController {
  final EntityBill? linkedBill;
  final EntitySalesReturn? editingReturn;

  ControllerCreateSalesReturn({this.linkedBill, this.editingReturn});

  late final Box<EntitySalesReturn> _boxReturn;
  late final Box<EntitySalesReturnItem> _boxReturnItem;
  late final Box<EntityBill> _boxBill;
  late final Box<EntityItem> _boxItem;
  late final Box<EntityStockTransaction> _boxStockTxn;

  final prefixCtrl = TextEditingController(text: 'KI/26-27/');
  final returnNoCtrl = TextEditingController();
  final returnDateCtrl = TextEditingController();
  final originalBillNoCtrl = TextEditingController();

  final customerNameCtrl = TextEditingController();
  final customerPhoneCtrl = TextEditingController();
  final customerAddressCtrl = TextEditingController();
  final customerGstinCtrl = TextEditingController();

  final RxList<InvoiceItemRow> rxRows = <InvoiceItemRow>[].obs;
  final RxList<EntityBill> rxAvailableBills = <EntityBill>[].obs;
  final RxList<EntityItem> rxAvailableItems = <EntityItem>[].obs;

  final returnReasonCtrl = TextEditingController(text: 'Customer Request');
  final notesCtrl = TextEditingController();
  final termsCtrl = TextEditingController(text: '1. Goods returned in acceptable condition.\n2. Refund issued per store policy.');

  final RxString rxRefundMode = 'Cash'.obs;
  final RxDouble rxSubtotal = 0.0.obs;
  final RxDouble rxTaxAmount = 0.0.obs;
  final RxDouble rxRefundTotal = 0.0.obs;
  final RxBool isSaving = false.obs;

  static String normalizeRefundMode(String? mode) {
    if (mode == null || mode.trim().isEmpty) return 'Cash';
    final m = mode.trim().toUpperCase();
    switch (m) {
      case 'CASH':
        return 'Cash';
      case 'UPI':
        return 'UPI';
      case 'CARD':
        return 'Card';
      case 'STORE CREDIT':
      case 'CREDIT':
      case 'CREDIT_NOTE':
        return 'Store Credit';
      default:
        return 'Cash';
    }
  }

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxReturn = ob.box<EntitySalesReturn>();
    _boxReturnItem = ob.box<EntitySalesReturnItem>();
    _boxBill = ob.box<EntityBill>();
    _boxItem = ob.box<EntityItem>();
    _boxStockTxn = ob.box<EntityStockTransaction>();

    rxAvailableBills.assignAll(_boxBill.getAll());
    rxAvailableItems.assignAll(_boxItem.getAll());

    final now = DateTime.now();
    returnDateCtrl.text = DateFormat('dd MMM yyyy').format(now);

    if (editingReturn != null) {
      _loadExistingReturn(editingReturn!);
    } else if (linkedBill != null) {
      returnNoCtrl.text = _generateNextReturnNo();
      onBillSelected(linkedBill!);
    } else {
      returnNoCtrl.text = _generateNextReturnNo();
      addRow();
    }

    // Auto-sanitize scanner forward slashes ('/') into hyphens ('-') immediately
    originalBillNoCtrl.addListener(() {
      final text = originalBillNoCtrl.text;
      if (text.contains('/')) {
        final sanitized = text.replaceAll('/', '-');
        originalBillNoCtrl.value = originalBillNoCtrl.value.copyWith(
          text: sanitized,
          selection: TextSelection.collapsed(offset: sanitized.length),
        );
      }
    });

    calculateTotals();
  }

  /// Auto-link invoice when exact scanned barcode or bill number is typed/scanned
  void onInvoiceInputChanged(String val) {
    final clean = val.trim().replaceAll('/', '-');
    if (clean.isEmpty) return;
    final exact = rxAvailableBills.firstWhereOrNull((b) =>
        (b.billNo ?? '').trim().toLowerCase() == clean.toLowerCase());
    if (exact != null) {
      onBillSelected(exact);
    }
  }

  /// Handle Enter key from barcode scanner machine when scanning invoice barcode
  void onInvoiceInputSubmitted(String val) {
    final clean = val.trim().replaceAll('/', '-');
    if (clean.isEmpty) return;
    EntityBill? exact = rxAvailableBills.firstWhereOrNull((b) =>
        (b.billNo ?? '').trim().toLowerCase() == clean.toLowerCase() ||
        '${b.id}' == clean);
    exact ??= _boxBill
        .query(EntityBill_.billNo.equals(clean, caseSensitive: false))
        .build()
        .findFirst();
    if (exact != null) {
      onBillSelected(exact);
    }
  }

  void _loadExistingReturn(EntitySalesReturn ret) {
    prefixCtrl.text = ret.prefix ?? 'KI/26-27/';
    final fullNo = ret.returnNo ?? '${ret.id}';
    final pfx = prefixCtrl.text.trim();
    if (pfx.isNotEmpty && fullNo.startsWith(pfx)) {
      returnNoCtrl.text = fullNo.substring(pfx.length);
    } else {
      returnNoCtrl.text = fullNo;
    }
    returnDateCtrl.text = ret.returnDate ?? '';
    originalBillNoCtrl.text = ret.originalBillNo ?? '';

    customerNameCtrl.text = ret.customerName ?? '';
    customerPhoneCtrl.text = ret.customerPhone ?? '';
    customerAddressCtrl.text = ret.customerAddress ?? '';
    customerGstinCtrl.text = ret.customerGstin ?? '';

    returnReasonCtrl.text = ret.returnReason ?? 'Customer Request';
    rxRefundMode.value = normalizeRefundMode(ret.paymentMode);
    notesCtrl.text = ret.note ?? '';
    if (ret.termsConditions != null) termsCtrl.text = ret.termsConditions!;

    rxRows.clear();
    for (var it in ret.items) {
      final row = InvoiceItemRow();
      row.nameCtrl.text = it.itemName ?? '';
      row.hsnCtrl.text = it.hsnCode ?? '';
      row.priceCtrl.text = '${it.price ?? 0}';
      row.qtyCtrl.text = '${it.qty ?? 1}';
      row.taxRateCtrl.text = '0';
      row.selectedItem = it.item.target;
      row.calculate();
      rxRows.add(row);
    }
    if (rxRows.isEmpty) addRow();
    calculateTotals();
  }

  String _generateNextReturnNo() {
    final all = _boxReturn.getAll();
    if (all.isEmpty) return '1';

    final prefix = prefixCtrl.text.trim();
    int maxNum = 0;
    for (var r in all) {
      final no = (r.returnNo ?? '').trim();
      if (no.isEmpty) continue;

      String numPart = no;
      if (prefix.isNotEmpty && numPart.startsWith(prefix)) {
        numPart = numPart.substring(prefix.length);
      }

      final parsed = int.tryParse(numPart);
      if (parsed != null && parsed > maxNum) {
        maxNum = parsed;
      } else {
        final digits = RegExp(r'\d+').allMatches(no);
        if (digits.isNotEmpty) {
          final lastDigit = int.tryParse(digits.last.group(0) ?? '') ?? 0;
          if (lastDigit > maxNum) maxNum = lastDigit;
        }
      }
      if (r.id > maxNum) maxNum = r.id;
    }

    int candidate = maxNum + 1;
    while (true) {
      final testNo = prefix.isNotEmpty ? '$prefix$candidate' : '$candidate';
      final exists = _boxReturn
          .query(EntitySalesReturn_.returnNo.equals(testNo))
          .build()
          .findFirst();
      if (exists == null) {
        return '$candidate';
      }
      candidate++;
    }
  }

  void onBillSelected(EntityBill bill) {
    originalBillNoCtrl.text = bill.billNo ?? '${bill.id}';
    customerNameCtrl.text = bill.customerName ?? '';
    customerPhoneCtrl.text = bill.customerPhone ?? '';
    customerAddressCtrl.text = bill.customerAddress ?? '';
    customerGstinCtrl.text = bill.customerGstin ?? '';

    rxRows.clear();
    for (var it in bill.items) {
      final row = InvoiceItemRow();
      row.nameCtrl.text = it.itemName ?? '';
      row.hsnCtrl.text = it.hsnCode ?? '';
      row.priceCtrl.text = '${it.price ?? 0}';
      row.qtyCtrl.text = '${it.qty ?? 1}';
      row.taxRateCtrl.text = '${it.taxRate ?? 0}';
      row.selectedItem = it.item.target;
      row.calculate();
      rxRows.add(row);
    }
    if (rxRows.isEmpty) addRow();
    calculateTotals();
  }

  void addRow() {
    rxRows.add(InvoiceItemRow());
    calculateTotals();
  }

  void removeRow(int index) {
    if (rxRows.length > 1) {
      rxRows.removeAt(index);
      calculateTotals();
    }
  }

  void onItemPicked(InvoiceItemRow row, EntityItem item) {
    row.selectedItem = item;
    row.nameCtrl.text = item.name ?? '';
    row.hsnCtrl.text = item.hsnCode ?? '';
    row.priceCtrl.text = '${item.sellingPrice ?? 0}';
    row.taxRateCtrl.text = '${item.taxRate ?? 0}';
    row.calculate();
    calculateTotals();
  }

  void calculateTotals() {
    double sub = 0.0;
    double tax = 0.0;

    for (var r in rxRows) {
      r.calculate();
      final q = int.tryParse(r.qtyCtrl.text) ?? 1;
      final p = double.tryParse(r.priceCtrl.text) ?? 0.0;
      sub += (q * p);
      tax += r.lineTaxAmount;
    }

    rxSubtotal.value = sub;
    rxTaxAmount.value = tax;
    rxRefundTotal.value = sub + tax;
    rxRows.refresh();
  }

  Future<bool> saveReturn() async {
    if (isSaving.value) return false;

    if (returnNoCtrl.text.trim().isEmpty) {
      Get.snackbar('Error'.tr, 'Please enter Return Number'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    final validRows = rxRows.where((r) => r.nameCtrl.text.trim().isNotEmpty).toList();
    if (validRows.isEmpty) {
      Get.snackbar('Error'.tr, 'Please add at least one item to return'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    final rawNo = returnNoCtrl.text.trim();
    final prefix = prefixCtrl.text.trim();
    final finalReturnNo = (prefix.isNotEmpty && !rawNo.startsWith(prefix))
        ? '$prefix$rawNo'
        : rawNo;

    // Check duplicate return number before ObjectBox throws UniqueViolationException
    final targetId = editingReturn?.id ?? 0;
    final existingWithSameNo = _boxReturn
        .query(EntitySalesReturn_.returnNo.equals(finalReturnNo))
        .build()
        .findFirst();

    if (existingWithSameNo != null && existingWithSameNo.id != targetId) {
      Get.snackbar(
        'Duplicate Return Number'.tr,
        'Return number "$finalReturnNo" already exists. Please choose a different number.'.tr,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    isSaving.value = true;
    calculateTotals();

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final ret = editingReturn ?? EntitySalesReturn();
      ret.prefix = prefix;
      ret.returnNo = finalReturnNo;
      ret.returnDate = returnDateCtrl.text.trim();
      ret.originalBillNo = originalBillNoCtrl.text.trim().replaceAll('/', '-');
      ret.customerName = customerNameCtrl.text.trim().isEmpty ? 'Walk-in Customer' : customerNameCtrl.text.trim();
      ret.customerPhone = customerPhoneCtrl.text.trim();
      ret.customerAddress = customerAddressCtrl.text.trim();
      ret.customerGstin = customerGstinCtrl.text.trim();
      ret.returnReason = returnReasonCtrl.text.trim();
      ret.paymentMode = rxRefundMode.value.toUpperCase();
      ret.subtotal = rxSubtotal.value;
      ret.tax = rxTaxAmount.value;
      ret.refundAmount = rxRefundTotal.value;
      ret.status = ret.status ?? 'Paid';
      ret.note = notesCtrl.text.trim();
      ret.termsConditions = termsCtrl.text.trim();
      ret.createdAtUtcMs ??= now;
      ret.updatedAtUtcMs = now;

      final retId = _boxReturn.put(ret);
      final savedRet = _boxReturn.get(retId)!;

      // Clean up previous items if editing
      if (savedRet.items.isNotEmpty) {
        final oldItemIds = savedRet.items.map((i) => i.id).toList();
        _boxReturnItem.removeMany(oldItemIds);
        savedRet.items.clear();
      }

      // Add stock back into inventory if new return
      for (var r in validRows) {
        final returnQty = int.tryParse(r.qtyCtrl.text) ?? 1;
        final price = double.tryParse(r.priceCtrl.text) ?? 0.0;

        final retItem = EntitySalesReturnItem(
          itemName: r.nameCtrl.text.trim(),
          hsnCode: r.hsnCtrl.text.trim(),
          itemBarcode: r.selectedItem?.barcode ?? '',
          unit: r.selectedItem?.unit ?? 'Pcs',
          price: price,
          qty: returnQty,
          tax: r.lineTaxAmount,
          total: r.lineTotal,
        );

        retItem.salesReturn.target = savedRet;
        if (r.selectedItem != null) {
          retItem.item.target = r.selectedItem;

          // RESTOCK INVENTORY only if new return
          if (editingReturn == null) {
            final stockItem = r.selectedItem!;
            stockItem.totalQty = (stockItem.totalQty ?? 0) + returnQty;
            stockItem.updatedAtUtcMs = now;
            _boxItem.put(stockItem);

            _boxStockTxn.put(EntityStockTransaction(
              itemId: stockItem.id ?? 0,
              type: StockTxnType.returnStock.index,
              quantity: returnQty,
              referenceType: 'sales_return',
              referenceId: savedRet.returnNo ?? '',
              remarks: 'Restocked from Sales Return #${savedRet.returnNo}',
              createdAtUtcMs: now,
            ));
          }
        }

        _boxReturnItem.put(retItem);
      }

      return true;
    } on UniqueViolationException catch (_) {
      Get.snackbar(
        'Duplicate Return Number'.tr,
        'Return number "$finalReturnNo" already exists. Please choose a different number.'.tr,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Failed to process return: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
