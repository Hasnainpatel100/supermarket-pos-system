import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../model/entity_stock_transaction.dart';
import '../../../../model/stock_txn_type.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_voice.dart';
import '../../../../util/snackbar_util.dart';
import '../../screens/home/fragment/bills/dialog_bill_detail.dart';
import '../../screens/home/fragment/pos/controller_home_pos.dart';
import '../../screens/home/fragment/setting/controller_home_settings.dart';
import 'models/model_voice_invoice.dart';
import 'models/model_voice_item.dart';
import 'dialog_voice_settings.dart';
import 'services/service_ai_parser.dart';
import 'services/service_catalog_matcher.dart';
import 'services/service_voice_recorder.dart';

class ControllerVoiceBilling extends GetxController {
  final ServiceVoiceRecorder _recorder = ServiceVoiceRecorder();
  final ServiceAiParser _aiParser = ServiceAiParser();
  final ServiceCatalogMatcher _catalogMatcher = ServiceCatalogMatcher();

  late final Box<EntityItem> _boxItem;
  late final Box<EntityItemBatch> _boxBatch;
  late final Box<EntityBill> _boxBill;
  late final Box<EntityBillItem> _boxBillItem;
  late final Box<EntityCustomer> _boxCustomer;
  late final Box<EntityStockTransaction> _boxStockTxn;

  // Language: 'hi' (Hindi/Hinglish), 'en' (English), 'mr' (Marathi)
  final rxSelectedLanguage = 'hi'.obs;

  // Recording & AI State
  final rxIsRecording = false.obs;
  final rxIsAnalyzing = false.obs;
  final rxRecordingSeconds = 0.obs;
  Timer? _recordTimer;

  final rxLiveStatus = 'Keep the counter mic close and just speak.'.obs;
  final rxLastHeardText = ''.obs;

  // Current Invoice Data
  final rxInvoice = Rx<ModelVoiceInvoice>(ModelVoiceInvoice(items: []));
  final rxCartItems = <ModelVoiceItem>[].obs;

  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final notesController = TextEditingController();
  final rxPaymentMode = 'Cash'.obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxItem = ob.box<EntityItem>();
    _boxBatch = ob.box<EntityItemBatch>();
    _boxBill = ob.box<EntityBill>();
    _boxBillItem = ob.box<EntityBillItem>();
    _boxCustomer = ob.box<EntityCustomer>();
    _boxStockTxn = ob.box<EntityStockTransaction>();

    customerNameController.addListener(() {
      rxInvoice.value.customerName = customerNameController.text.trim();
    });

    customerPhoneController.addListener(() {
      rxInvoice.value.customerPhone = customerPhoneController.text.trim();
    });

    notesController.addListener(() {
      rxInvoice.value.notes = notesController.text.trim();
    });
  }

  @override
  void onClose() {
    _recordTimer?.cancel();
    _recorder.dispose();
    customerNameController.dispose();
    customerPhoneController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void setLanguage(String lang) {
    rxSelectedLanguage.value = lang;
  }

  bool get hasApiKey => _aiParser.savedApiKey.isNotEmpty;

  // ─── Recording & Voice Processing ──────────────────────────────────────────

  Future<void> toggleRecording() async {
    if (rxIsRecording.value) {
      await stopAndProcess();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (!hasApiKey) {
      rxLiveStatus.value = 'Please configure your Gemini API Key first.';
      if (Get.context != null) {
        DialogVoiceSettings.show(Get.context!);
      }
      return;
    }

    try {
      final path = await _recorder.start();
      if (path != null) {
        rxIsRecording.value = true;
        rxRecordingSeconds.value = 0;
        rxLiveStatus.value = 'Listening... Speak items, quantities, or customer name.';
        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          rxRecordingSeconds.value++;
          if (rxRecordingSeconds.value >= 25) {
            // Auto stop after 25s safety ceiling
            stopAndProcess();
          }
        });
      } else {
        SnackbarUtil.showError('Could not start microphone. Check microphone connection.');
      }
    } catch (e) {
      SnackbarUtil.showError('Microphone error: $e');
    }
  }

  Future<void> stopAndProcess() async {
    if (!rxIsRecording.value && !rxIsAnalyzing.value) return;
    _recordTimer?.cancel();
    rxIsRecording.value = false;
    rxIsAnalyzing.value = true;
    rxLiveStatus.value = 'AI is analyzing speech and matching store items...';

    try {
      final audioPath = await _recorder.stop();
      if (audioPath != null) {
        final parsed = await _aiParser.parseAudioFile(
          audioPath,
          language: rxSelectedLanguage.value,
        );
        if (parsed.transcript != null && parsed.transcript!.isNotEmpty) {
          rxLastHeardText.value = parsed.transcript!;
        }
        await _applyParsedInvoice(parsed);
      }
    } catch (e) {
      debugPrint('Voice parsing error: $e');
      final errStr = e.toString().replaceAll('Exception:', '').trim();
      if (errStr.contains('GEMINI_API_KEY_MISSING')) {
        rxLiveStatus.value = 'Gemini API Key required for live mic listening.';
        rxLastHeardText.value = 'API key missing! Click the Settings gear icon (⚙️) on top right to add your free Gemini Key.';
        if (Get.context != null) {
          DialogVoiceSettings.show(Get.context!);
        }
      } else {
        SnackbarUtil.showError(errStr);
        rxLiveStatus.value = 'Error: $errStr';
        rxLastHeardText.value = 'Recognition error: $errStr';
      }
    } finally {
      rxIsAnalyzing.value = false;
    }
  }

  /// Processes text speech directly (used by quick demo buttons and typing)
  Future<void> processText(String transcript) async {
    if (transcript.trim().isEmpty) return;
    rxIsAnalyzing.value = true;
    rxLastHeardText.value = transcript;
    rxLiveStatus.value = 'Processing voice transcript...';

    try {
      final parsed = await _aiParser.parseTextWithFallback(
        transcript,
        language: rxSelectedLanguage.value,
      );
      await _applyParsedInvoice(parsed);
    } catch (e) {
      SnackbarUtil.showError('Processing error: $e');
    } finally {
      rxIsAnalyzing.value = false;
    }
  }

  Future<void> _applyParsedInvoice(ModelVoiceInvoice parsed) async {
    if (parsed.transcript != null && parsed.transcript!.isNotEmpty) {
      rxLastHeardText.value = parsed.transcript!;
    }

    // Match against local database
    await _catalogMatcher.matchInvoice(parsed);

    // Update customer info if provided
    if (parsed.customerName != null && parsed.customerName!.isNotEmpty) {
      customerNameController.text = parsed.customerName!;
    }
    if (parsed.customerPhone != null && parsed.customerPhone!.isNotEmpty) {
      customerPhoneController.text = parsed.customerPhone!;
    }
    if (parsed.paymentMode.isNotEmpty) {
      rxPaymentMode.value = parsed.paymentMode;
    }

    // Merge or append items
    for (final newItem in parsed.items) {
      final existingIndex = rxCartItems.indexWhere(
        (it) => it.itemName.toLowerCase() == newItem.itemName.toLowerCase(),
      );
      if (existingIndex >= 0) {
        rxCartItems[existingIndex].quantity += newItem.quantity;
        rxCartItems[existingIndex].recalculate();
      } else {
        rxCartItems.add(newItem);
      }
    }

    _refreshInvoiceTotals();
    rxLiveStatus.value = 'Added ${parsed.items.length} item(s) from voice order.';
  }

  void _refreshInvoiceTotals() {
    final inv = rxInvoice.value;
    inv.items = rxCartItems.toList();
    inv.paymentMode = rxPaymentMode.value;
    inv.customerName = customerNameController.text.trim();
    inv.customerPhone = customerPhoneController.text.trim();
    inv.recalculate();
    rxInvoice.refresh();
  }

  // ─── Item Editing ──────────────────────────────────────────────────────────

  void incrementQty(int index) {
    if (index >= 0 && index < rxCartItems.length) {
      rxCartItems[index].quantity += 1.0;
      rxCartItems[index].recalculate();
      rxCartItems.refresh();
      _refreshInvoiceTotals();
    }
  }

  void decrementQty(int index) {
    if (index >= 0 && index < rxCartItems.length) {
      if (rxCartItems[index].quantity > 1.0) {
        rxCartItems[index].quantity -= 1.0;
        rxCartItems[index].recalculate();
        rxCartItems.refresh();
      } else {
        rxCartItems.removeAt(index);
      }
      _refreshInvoiceTotals();
    }
  }

  void updateItemPrice(int index, double newPrice) {
    if (index >= 0 && index < rxCartItems.length) {
      rxCartItems[index].price = newPrice;
      rxCartItems[index].recalculate();
      rxCartItems.refresh();
      _refreshInvoiceTotals();
    }
  }

  void updateItemTax(int index, double newTaxRate) {
    if (index >= 0 && index < rxCartItems.length) {
      rxCartItems[index].taxRate = newTaxRate;
      rxCartItems[index].recalculate();
      rxCartItems.refresh();
      _refreshInvoiceTotals();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < rxCartItems.length) {
      rxCartItems.removeAt(index);
      _refreshInvoiceTotals();
    }
  }

  void clearInvoice() {
    rxCartItems.clear();
    customerNameController.clear();
    customerPhoneController.clear();
    notesController.clear();
    rxLastHeardText.value = '';
    rxPaymentMode.value = 'Cash';
    rxLiveStatus.value = 'Ready. Speak items to create a new invoice.';
    _refreshInvoiceTotals();
  }

  // ─── Generate Bill Directly in ObjectBox ───────────────────────────────────

  Future<void> generateAndSettleBill(BuildContext context) async {
    if (rxCartItems.isEmpty) {
      SnackbarUtil.showError('No items in the voice invoice to generate bill');
      return;
    }

    _refreshInvoiceTotals();
    final inv = rxInvoice.value;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dateStr = DateTime.now().toIso8601String().split('T').first;

    // Create or find customer
    EntityCustomer? linkedCustomer;
    final custName = customerNameController.text.trim();
    final custPhone = customerPhoneController.text.trim();

    if (custName.isNotEmpty || custPhone.isNotEmpty) {
      final q = _boxCustomer.query(
        EntityCustomer_.phone.equals(custPhone).or(EntityCustomer_.name.equals(custName, caseSensitive: false)),
      ).build();
      linkedCustomer = q.findFirst();
      q.close();

      if (linkedCustomer == null) {
        linkedCustomer = EntityCustomer(
          name: custName.isNotEmpty ? custName : 'Walk-in',
          phone: custPhone,
          createdAtUtcMs: now,
          updatedAtUtcMs: now,
        );
        final cid = _boxCustomer.put(linkedCustomer);
        linkedCustomer = _boxCustomer.get(cid);
      }
    }

    final billNo = 'BIL-$now';

    final bill = EntityBill(
      billNo: billNo,
      customerName: custName.isNotEmpty ? custName : (linkedCustomer?.name ?? 'Walk-in Customer'),
      customerPhone: custPhone.isNotEmpty ? custPhone : linkedCustomer?.phone,
      totalAmount: inv.subTotal,
      discount: inv.discountTotal,
      tax: inv.taxTotal,
      grandTotal: inv.grandTotal,
      status: 'PAID',
      paymentMode: rxPaymentMode.value,
      amountReceived: inv.grandTotal,
      changeReturned: 0.0,
      dueAmount: 0.0,
      billDate: dateStr,
      note: 'Voice Invoiced: ${notesController.text.trim()}',
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );

    final billItemsToSave = <EntityBillItem>[];
    final stockTxnsToSave = <EntityStockTransaction>[];

    for (final vi in rxCartItems) {
      final billItem = EntityBillItem(
        itemName: vi.itemName,
        itemBarcode: vi.matchedBarcode,
        hsnCode: vi.hsnCode,
        unit: vi.unit,
        price: vi.price,
        mrp: vi.mrp,
        qty: vi.quantity.toInt() <= 0 ? 1 : vi.quantity.toInt(),
        taxRate: vi.taxRate,
        tax: vi.taxAmount,
        discount: vi.discount,
        total: vi.total,
        batchNo: vi.entityBatch?.batchNo,
        batchId: vi.entityBatch?.id,
      );

      if (vi.entityItem != null) {
        billItem.item.target = vi.entityItem;

        // Deduct inventory stock
        final stockItem = vi.entityItem!;
        final currentStock = stockItem.totalQty ?? 0;
        stockItem.totalQty = (currentStock - billItem.qty!).clamp(0, 99999999);
        _boxItem.put(stockItem);

        // Deduct batch stock if applicable
        if (vi.entityBatch?.id != null && vi.entityBatch!.id! > 0) {
          final b = _boxBatch.get(vi.entityBatch!.id!);
          if (b != null) {
            b.quantity = ((b.quantity ?? 0) - billItem.qty!).clamp(0, 99999999);
            _boxBatch.put(b);
          }
        }

        stockTxnsToSave.add(EntityStockTransaction(
          itemId: stockItem.id ?? 0,
          type: StockTxnType.sell.index,
          quantity: -billItem.qty!,
          referenceType: 'sell',
          referenceId: stockItem.name ?? '',
          remarks: 'Sold via Voice Billing POS',
          createdAtUtcMs: now,
        ));
      }

      billItemsToSave.add(billItem);
    }

    // Atomic ObjectBox Transaction
    final ob = Get.find<ServiceObjectBox>();
    late EntityBill savedBill;
    ob.store.runInTransaction(TxMode.write, () {
      final bId = _boxBill.put(bill);
      savedBill = _boxBill.get(bId)!;

      for (var bi in billItemsToSave) {
        bi.bill.target = savedBill;
      }
      _boxBillItem.putMany(billItemsToSave);

      if (stockTxnsToSave.isNotEmpty) {
        _boxStockTxn.putMany(stockTxnsToSave);
      }
    });

    // Voice soundbox announcement
    final settings = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>()
        : Get.put(ControllerHomeSettings());

    if (settings.rxVoiceAnnouncement.value) {
      ServiceVoice.announcePayment(
        amount: savedBill.grandTotal ?? 0.0,
        paymentMode: savedBill.paymentMode ?? 'Cash',
        storeName: settings.rxStoreName.value,
      );
    }

    // Refresh POS controller if open
    if (Get.isRegistered<ControllerHomePos>()) {
      Get.find<ControllerHomePos>().loadItems();
    }

    SnackbarUtil.showSuccess('Bill #${savedBill.billNo} generated successfully!');
    clearInvoice();

    // Open detail dialog
    Get.dialog(DialogBillDetail(bill: savedBill), barrierDismissible: false);
  }

  // ─── Transfer to POS Screen Cart ──────────────────────────────────────────

  void pushToPosCart() {
    if (rxCartItems.isEmpty) {
      SnackbarUtil.showError('No items in the voice invoice to push to POS');
      return;
    }

    if (!Get.isRegistered<ControllerHomePos>()) {
      SnackbarUtil.showError('POS screen is not active');
      return;
    }

    final posCtrl = Get.find<ControllerHomePos>();
    final session = posCtrl.activeSession;

    for (final vi in rxCartItems) {
      final billItem = EntityBillItem(
        itemName: vi.itemName,
        itemBarcode: vi.matchedBarcode,
        hsnCode: vi.hsnCode,
        unit: vi.unit,
        price: vi.price,
        mrp: vi.mrp,
        qty: vi.quantity.toInt() <= 0 ? 1 : vi.quantity.toInt(),
        taxRate: vi.taxRate,
        tax: vi.taxAmount,
        discount: vi.discount,
        total: vi.total,
        batchNo: vi.entityBatch?.batchNo,
        batchId: vi.entityBatch?.id,
      );

      if (vi.entityItem != null) {
        billItem.item.target = vi.entityItem;
      }

      session.rxCartItems.add(billItem);
    }

    // Customer
    final cName = customerNameController.text.trim();
    final cPhone = customerPhoneController.text.trim();
    if (cName.isNotEmpty) {
      session.rxQuickCustomerName.value = cName;
    }
    if (cPhone.isNotEmpty) {
      session.rxQuickCustomerPhone.value = cPhone;
    }
    session.rxPaymentMode.value = rxPaymentMode.value;

    posCtrl.calculateTotals();

    SnackbarUtil.showSuccess('Pushed ${rxCartItems.length} voice items directly into POS cart!');
    Get.back(); // Return to POS screen
  }
}
