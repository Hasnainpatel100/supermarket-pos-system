import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../service/service_currency.dart';
import 'controller_voice_billing.dart';
import 'dialog_voice_settings.dart';
import 'models/model_voice_item.dart';

class ActivityVoiceBilling extends StatefulWidget {
  const ActivityVoiceBilling({super.key});

  @override
  State<ActivityVoiceBilling> createState() => _ActivityVoiceBillingState();
}

class _ActivityVoiceBillingState extends State<ActivityVoiceBilling>
    with SingleTickerProviderStateMixin {
  late final ControllerVoiceBilling controller;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final ServiceCurrency _currency = Get.find<ServiceCurrency>();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ControllerVoiceBilling>()
        ? Get.find<ControllerVoiceBilling>()
        : Get.put(ControllerVoiceBilling());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, cs, isDark),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ── LEFT PANEL: AUDIO SPEAKING COUNTER & MIC (40%) ──
          Expanded(
            flex: 42,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLanguageSelector(cs),
                    const SizedBox(height: 24),
                    _buildSpeakingCounterHeader(cs),
                    const SizedBox(height: 28),
                    _buildMicCenterButton(cs),
                    const SizedBox(height: 28),
                    _buildWhatIHeardSection(cs, isDark),
                    const SizedBox(height: 20),
                    _buildQuickDemoChips(cs),
                  ],
                ),
              ),
            ),
          ),

          /// ── RIGHT PANEL: CAPTURED ITEMS & BILL GENERATION (58%) ──
          Expanded(
            flex: 58,
            child: Column(
              children: [
                _buildCustomerCard(cs, isDark),
                Expanded(
                  child: _buildItemsList(cs, isDark),
                ),
                _buildBottomBillingBar(cs, isDark),
              ],
            ),
          ),
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
        tooltip: 'Back to POS Screen',
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Voice Billing Assistant',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              Text(
                'Multilingual Real-time Speech-to-Invoice',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700, width: 0.8),
            ),
            child: Text(
              'Gemini Flash AI',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Configure Gemini API Key & Audio',
          onPressed: () => DialogVoiceSettings.show(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLanguageSelector(ColorScheme cs) {
    return Obx(() {
      final current = controller.rxSelectedLanguage.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            _buildLangChip(cs, 'Hindi / Hinglish', 'hi', current == 'hi'),
            _buildLangChip(cs, 'English', 'en', current == 'en'),
            _buildLangChip(cs, 'मराठी (Marathi)', 'mr', current == 'mr'),
          ],
        ),
      );
    });
  }

  Widget _buildLangChip(ColorScheme cs, String label, String code, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setLanguage(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakingCounterHeader(ColorScheme cs) {
    return Column(
      children: [
        Text(
          'Keep the counter mic close and just speak',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Obx(() {
          return Text(
            controller.rxLiveStatus.value,
            style: TextStyle(
              fontSize: 12.5,
              color: controller.rxIsRecording.value ? Colors.red.shade600 : cs.onSurfaceVariant,
              fontWeight: controller.rxIsRecording.value ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          );
        }),
      ],
    );
  }

  Widget _buildMicCenterButton(ColorScheme cs) {
    return Obx(() {
      final isRecording = controller.rxIsRecording.value;
      final isAnalyzing = controller.rxIsAnalyzing.value;
      final seconds = controller.rxRecordingSeconds.value;

      return Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = isRecording ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: isAnalyzing ? null : () => controller.toggleRecording(),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isRecording
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [const Color(0xFFF59E0B), const Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isRecording ? Colors.red : const Color(0xFFF59E0B))
                              .withValues(alpha: isRecording ? 0.45 : 0.25),
                          blurRadius: isRecording ? 28 : 16,
                          spreadRadius: isRecording ? 4 : 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isAnalyzing
                          ? const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.5),
                            )
                          : Icon(
                              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          if (isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade400, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Listening... 00:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              isAnalyzing ? 'Analyzing with AI...' : 'Tap Mic to Start Speaking',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      );
    });
  }

  Widget _buildWhatIHeardSection(ColorScheme cs, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hearing_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'WHAT I HEARD',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final heard = controller.rxLastHeardText.value;
            return Text(
              heard.isNotEmpty
                  ? heard
                  : 'Speak into your microphone or try a demo example below.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: heard.isNotEmpty ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontStyle: heard.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickDemoChips(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              'Quick Demo Voice Prompts (Click to Test):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildDemoChip(
              cs,
              'Hindi: सत्यम के नाम से 2 किलो चीनी, 1 पैकेट दूध, कैश',
              'सत्यम के नाम से 2 किलो चीनी, 1 पैकेट दूध, कैश',
              'hi',
            ),
            _buildDemoChip(
              cs,
              'Marathi: रमेशच्या नावाने 2 किलो साखर, 1 लिटर तेल, कॅश',
              'रमेशच्या नावाने 2 किलो साखर, 1 लिटर तेल, कॅश',
              'mr',
            ),
            _buildDemoChip(
              cs,
              'English: Alex, 2 coffees at 100 each, 1 sandwich at 150, UPI',
              'Alex, two coffees at 100 each, one sandwich at 150, UPI payment',
              'en',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoChip(ColorScheme cs, String label, String transcript, String lang) {
    return InkWell(
      onTap: () {
        controller.setLanguage(lang);
        controller.processText(transcript);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.5, color: cs.onSurface),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name (Spoken or Typed)',
                hintText: 'e.g. Satyam / Ramesh',
                prefixIcon: const Icon(Icons.person_rounded, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller.customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: 'e.g. 9876543210',
                prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ColorScheme cs, bool isDark) {
    return Obx(() {
      final items = controller.rxCartItems;

      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No items captured yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the microphone and speak your customer order.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildItemRow(cs, isDark, item, index);
        },
      );
    });
  }

  Widget _buildItemRow(ColorScheme cs, bool isDark, ModelVoiceItem item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Index & Stock Status
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.isMatched
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              item.isMatched ? Icons.check_circle_rounded : Icons.help_outline_rounded,
              color: item.isMatched ? Colors.green : Colors.amber.shade800,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),

          // Item Name & Unit
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Unit: ${item.unit} ${item.isMatched ? "• In Inventory" : "• Manual Item"}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => controller.decrementQty(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => controller.incrementQty(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 18),

          // Price & Tax
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_currency.rxCurrency.value} ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  item.taxRate > 0 ? 'Tax: ${item.taxRate.toStringAsFixed(0)}%' : 'Tax: 0%',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Line Total
          Text(
            '${_currency.rxCurrency.value} ${item.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),

          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            onPressed: () => controller.removeItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBillingBar(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          // Payment Modes & Totals
          Row(
            children: [
              // Payment modes
              Expanded(
                child: Obx(() {
                  final current = controller.rxPaymentMode.value;
                  return Row(
                    children: ['Cash', 'UPI', 'Card', 'Credit'].map((mode) {
                      final isSelected = current.toLowerCase() == mode.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(mode, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) => controller.rxPaymentMode.value = mode,
                          selectedColor: cs.primaryContainer,
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),

              // Total display
              Obx(() {
                final inv = controller.rxInvoice.value;
                return Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Subtotal: ${_currency.rxCurrency.value} ${inv.subTotal.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                        ),
                        if (inv.taxTotal > 0)
                          Text(
                            'Tax: ${_currency.rxCurrency.value} ${inv.taxTotal.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_currency.rxCurrency.value} ${inv.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.clearInvoice,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: controller.pushToPosCart,
                icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                label: const Text('Send to POS Cart'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => controller.generateAndSettleBill(context),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text(
                  '⚡ Generate Bill & Print',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
