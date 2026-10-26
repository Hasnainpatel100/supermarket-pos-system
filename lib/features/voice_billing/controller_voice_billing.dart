import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../model/entity_bill_item.dart';
import '../../../../model/entity_customer.dart';
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
import 'services/service_gemini_live.dart';
import 'services/service_hinglish_transliteration.dart';
import 'services/service_voice_recorder.dart';

class ControllerVoiceBilling extends GetxController {
  final ServiceVoiceRecorder _recorder = ServiceVoiceRecorder();
  final ServiceAiParser _aiParser = ServiceAiParser();
  final ServiceCatalogMatcher _catalogMatcher = ServiceCatalogMatcher();
  final ServiceGeminiLiveTranscribe _geminiLive = ServiceGeminiLiveTranscribe();

  late final Box<EntityBill> _boxBill;
  late final Box<EntityBillItem> _boxBillItem;
  late final Box<EntityCustomer> _boxCustomer;

  // Language: 'hinglish' (Hinglish), 'en' (English), 'mr' (Marathi)
  final rxSelectedLanguage = 'hinglish'.obs;

  // Recording & AI State
  final rxIsRecording = false.obs;
  final rxIsAnalyzing = false.obs;
  final rxIsLiveTranscribing = false.obs;
  final rxRecordingSeconds = 0.obs;
  Timer? _recordTimer;

  final rxLiveStatus = 'Keep the counter mic close and just speak.'.obs;
  final rxLastHeardText = ''.obs;
  final rxInterimText = ''.obs;

  // Current Invoice Data
  final rxInvoice = Rx<ModelVoiceInvoice>(ModelVoiceInvoice(items: []));
  final rxCartItems = <ModelVoiceItem>[].obs;

  late final TextEditingController customerNameController;
  late final TextEditingController customerPhoneController;
  late final TextEditingController notesController;
  final rxPaymentMode = 'Cash'.obs;

  final rxHasApiKey = false.obs;
  final rxActiveProvider = ''.obs;
  final rxVoiceBillsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    _boxBillItem = ob.box<EntityBillItem>();
    _boxCustomer = ob.box<EntityCustomer>();

    customerNameController = TextEditingController();
    customerPhoneController = TextEditingController();
    notesController = TextEditingController();

    rxHasApiKey.value = _aiParser.hasValidApiKey;
    rxActiveProvider.value = _aiParser.activeProvider;
    refreshVoiceBillsCount();

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
    _geminiLive.dispose();
    _recorder.dispose();
    customerNameController.dispose();
    customerPhoneController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void refreshSettings() {
    rxHasApiKey.value = _aiParser.hasValidApiKey;
    rxActiveProvider.value = _aiParser.activeProvider;
  }

  void setLanguage(String lang) {
    rxSelectedLanguage.value = lang;
  }

  bool get hasApiKey => rxHasApiKey.value;
  String get activeProviderName => rxActiveProvider.value == 'groq' ? 'Groq Whisper' : 'Gemini 3.5 Live';

  int get voiceBillsCount => rxVoiceBillsCount.value;

  void refreshVoiceBillsCount() {
    try {
      final q = _boxBill.query(
        EntityBill_.poNo.equals('AI_VOICE')
            .or(EntityBill_.note.contains('[AI_VOICE]'))
            .or(EntityBill_.billNo.startsWith('VOICE-')),
      ).build();
      rxVoiceBillsCount.value = q.count();
      q.close();
    } catch (_) {
      rxVoiceBillsCount.value = 0;
    }
  }

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
      rxLiveStatus.value = 'Please configure your Groq or Gemini API Key first.';
      if (Get.context != null) {
        DialogVoiceSettings.show(Get.context!);
      }
      return;
    }

    rxInterimText.value = '';
    rxRecordingSeconds.value = 0;

    // Check if Gemini Live Transcription can be used
    final isGemini = rxActiveProvider.value == 'gemini' || _aiParser.savedGeminiKey.isNotEmpty;
    if (isGemini && _aiParser.savedGeminiKey.isNotEmpty) {
      try {
        rxLiveStatus.value = 'Connecting to Gemini 3.5 Transcribe Live...';

        _geminiLive.onInterimTranscript = (interim) {
          rxInterimText.value = interim;
          rxLiveStatus.value = '⚡ [Live]: "$interim"';
        };

        _geminiLive.onFinalTranscript = (finalText) {
          rxLastHeardText.value = _geminiLive.finalTranscript;
          rxInterimText.value = '';
        };

        _geminiLive.onStatusChange = (status) {
          rxLiveStatus.value = status;
        };

        _geminiLive.onError = (err) {
          debugPrint('Gemini Live WebSocket note: $err');
        };

        final currentLang = rxSelectedLanguage.value;
        final isHinglish = currentLang == 'hinglish' || currentLang == 'hi';
        final langCodes = isHinglish
            ? ['en', 'hi'] // Bilingual audio capture, Romanized to Hinglish live
            : currentLang == 'mr'
                ? ['mr', 'en']
                : ['en'];

        final connected = await _geminiLive.startSession(
          apiKey: _aiParser.savedGeminiKey,
          model: 'gemini-3.5-transcribe-live',
          languageCodes: langCodes,
          mode: 'SMART',
        );

        if (connected) {
          final streamed = await _recorder.startStreaming(
            onChunk: (chunk) {
              _geminiLive.sendAudioChunk(chunk);
            },
          );

          if (streamed) {
            rxIsRecording.value = true;
            rxIsLiveTranscribing.value = true;
            rxLiveStatus.value = isHinglish
                ? '⚡ Gemini Live (Hinglish): Listening... Speak items (e.g. "basmati chawal 1 kilo 100rs")'
                : '⚡ Gemini Live: Listening... Speak items or customer.';
            _recordTimer?.cancel();
            _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              rxRecordingSeconds.value++;
              if (rxRecordingSeconds.value >= 25) {
                stopAndProcess();
              }
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Gemini live stream setup error: $e, falling back to standard recorder');
      }
    }

    // Fallback or Groq provider: standard WAV recording
    try {
      final path = await _recorder.start();
      if (path != null) {
        rxIsRecording.value = true;
        rxIsLiveTranscribing.value = false;
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
      if (rxIsLiveTranscribing.value) {
        rxIsLiveTranscribing.value = false;
        rxLiveStatus.value = 'Finalizing Gemini Live transcription...';

        final audioPath = await _recorder.stop();
        final liveTranscript = await _geminiLive.stopSession();
        rxInterimText.value = '';

        if (liveTranscript.trim().isNotEmpty) {
          rxLastHeardText.value = liveTranscript;
          rxLiveStatus.value = 'Matching store items and creating bill...';
          final parsed = await _aiParser.parseTextWithFallback(
            liveTranscript,
            language: rxSelectedLanguage.value,
          );
          parsed.transcript = liveTranscript;
          await _applyParsedInvoice(parsed);
          return;
        }

        // Fallback to audio file analysis if live transcript yielded nothing
        if (audioPath != null) {
          rxLiveStatus.value = 'Analyzing audio recording fallback...';
          final parsed = await _aiParser.parseAudioFile(
            audioPath,
            language: rxSelectedLanguage.value,
          );
          if (parsed.transcript != null && parsed.transcript!.isNotEmpty) {
            rxLastHeardText.value = parsed.transcript!;
          }
          await _applyParsedInvoice(parsed);
          return;
        }
      }

      // Standard non-streaming recording flow
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
      if (errStr.contains('API_KEY_MISSING') || errStr.contains('GEMINI_API_KEY_MISSING')) {
        rxLiveStatus.value = 'Free API Key required for live mic listening.';
        rxLastHeardText.value = 'API key missing! Click the Settings gear icon (⚙️) on top right to add your free Groq or Gemini Key.';
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
      rxIsLiveTranscribing.value = false;
      rxInterimText.value = '';
    }
  }

  /// Processes text speech directly (used by quick demo buttons and typing)
  Future<void> processText(String transcript) async {
    if (transcript.trim().isEmpty) return;
    final hinglishTranscript = HinglishTransliteration.toHinglish(transcript);
    rxIsAnalyzing.value = true;
    rxLastHeardText.value = hinglishTranscript;
    rxLiveStatus.value = 'Processing voice transcript...';

    try {
      final parsed = await _aiParser.parseTextWithFallback(
        hinglishTranscript,
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

    final billNo = 'VOICE-$now';

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
      billDate: DateFormat('d/MM/yyyy').format(DateTime.now()),
      poNo: 'AI_VOICE',
      note: '[AI_VOICE] | Lang: ${rxSelectedLanguage.value} | Transcript: "${rxLastHeardText.value}"${notesController.text.trim().isNotEmpty ? " | Notes: ${notesController.text.trim()}" : ""}',
      createdAtUtcMs: now,
      updatedAtUtcMs: now,
    );

    final billItemsToSave = <EntityBillItem>[];

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
        // User requested: Do NOT decrement existing stock for voice billing
      }

      billItemsToSave.add(billItem);
    }

    // Atomic ObjectBox Transaction: save voice bill without touching inventory stock
    final ob = Get.find<ServiceObjectBox>();
    late EntityBill savedBill;
    ob.store.runInTransaction(TxMode.write, () {
      final bId = _boxBill.put(bill);
      savedBill = _boxBill.get(bId)!;

      for (var bi in billItemsToSave) {
        bi.bill.target = savedBill;
      }
      _boxBillItem.putMany(billItemsToSave);
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

    refreshVoiceBillsCount();
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
