import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_sales_return.dart';
import '../../../objectbox.g.dart';
import '../../../service/service_object_box.dart';
import '../preview/activity_document_view.dart';
import '../preview/service_gst_pdf.dart';
import 'activity_create_sales_return.dart';

class ControllerSalesReturns extends GetxController {
  late final Box<EntitySalesReturn> _boxReturn;

  final RxList<EntitySalesReturn> rxReturns = <EntitySalesReturn>[].obs;
  final RxString rxSearchQuery = ''.obs;
  final searchController = TextEditingController();
  final RxDouble rxTotalRefunded = 0.0.obs;
  final RxInt rxTotalCount = 0.obs;
  final RxBool rxLoading = false.obs;

  // Pagination
  static const int _pageSize = 20;
  final RxInt currentPage = 0.obs;

  bool get hasPrev => currentPage.value > 0;
  bool get hasNext => (currentPage.value + 1) * _pageSize < rxReturns.length;

  List<EntitySalesReturn> get pagedReturns {
    final start = currentPage.value * _pageSize;
    if (start >= rxReturns.length) return [];
    final end = (start + _pageSize).clamp(0, rxReturns.length);
    return rxReturns.sublist(start, end);
  }

  void nextPage() {
    if (hasNext) {
      currentPage.value++;
    }
  }

  void prevPage() {
    if (hasPrev) {
      currentPage.value--;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxReturn = ob.box<EntitySalesReturn>();
    loadReturns();
  }

  void loadReturns() {
    rxLoading.value = true;
    try {
      final all = _boxReturn.query().order(EntitySalesReturn_.id, flags: Order.descending).build().find();
      final q = rxSearchQuery.value.trim().toLowerCase();

      final filtered = all.where((r) {
        if (q.isNotEmpty) {
          final noMatch = (r.returnNo ?? '').toLowerCase().contains(q);
          final billMatch = (r.originalBillNo ?? '').toLowerCase().contains(q);
          final partyMatch = (r.customerName ?? '').toLowerCase().contains(q);
          if (!noMatch && !billMatch && !partyMatch) return false;
        }
        return true;
      }).toList();

      rxReturns.assignAll(filtered);
      if (currentPage.value * _pageSize >= filtered.length && filtered.isNotEmpty) {
        currentPage.value = 0;
      }

      double total = 0.0;
      for (var r in all) {
        total += (r.refundAmount ?? 0.0);
      }
      rxTotalRefunded.value = total;
      rxTotalCount.value = all.length;
    } finally {
      rxLoading.value = false;
    }
  }

  void updateSearch(String q) {
    rxSearchQuery.value = q;
    currentPage.value = 0;
    loadReturns();
  }

  void clearSearch() {
    searchController.clear();
    rxSearchQuery.value = '';
    currentPage.value = 0;
    loadReturns();
  }

  void setSearch(String q) {
    updateSearch(q);
  }

  void openCreateReturn({EntitySalesReturn? editReturn}) async {
    await Get.dialog(
      ActivityCreateSalesReturn(editingReturn: editReturn),
      barrierDismissible: false,
    );
    loadReturns();
  }

  void openDocumentView(EntitySalesReturn ret) {
    final List<GstPdfItem> pdfItems = [];
    int idx = 1;
    for (var item in ret.items) {
      pdfItems.add(GstPdfItem(
        sNo: idx++,
        name: item.itemName ?? 'Returned Item',
        hsn: item.hsnCode ?? '',
        qty: item.qty ?? 1,
        unit: item.unit ?? 'Pcs',
        mrp: item.price ?? 0.0,
        rate: item.price ?? 0.0,
        discount: 0.0,
        taxPercent: 0.0,
        taxAmount: item.tax ?? 0.0,
        total: item.total ?? 0.0,
      ));
    }

    final docModel = DocumentViewModel(
      type: DocumentType.salesReturn,
      title: 'Credit Note / Sales Return',
      docNumber: ret.returnNo ?? '${ret.id}',
      docDate: ret.returnDate ?? DateFormat('dd/MM/yyyy').format(DateTime.now()),
      status: ret.status ?? 'Paid',
      partyName: ret.customerName ?? 'Cash Customer',
      partyPhone: ret.customerPhone,
      partyAddress: ret.customerAddress,
      partyGstin: ret.customerGstin,
      items: pdfItems,
      subtotal: ret.subtotal ?? (ret.refundAmount ?? 0.0),
      discount: 0.0,
      taxAmount: ret.tax ?? 0.0,
      grandTotal: ret.refundAmount ?? 0.0,
      paymentMode: ret.paymentMode,
      notes: 'Original Bill: #${ret.originalBillNo ?? "N/A"}. Reason: ${ret.returnReason ?? "Return"}',
      termsConditions: ret.termsConditions,
    );

    Get.to(() => ActivityDocumentView(model: docModel));
  }

  void deleteReturn(EntitySalesReturn ret) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Return Record'),
        content: Text('Delete sales return #${ret.returnNo}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _boxReturn.remove(ret.id);
              Get.back();
              loadReturns();
              Get.snackbar('Deleted', 'Sales return record removed.', backgroundColor: Colors.red, colorText: Colors.white);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
