import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../service/service_currency.dart';
import '../../../../util/snackbar_util.dart';
import 'activity_voice_sales_history.dart';
import 'controller_voice_billing.dart';
import 'dialog_voice_settings.dart';
import 'models/model_voice_item.dart';

class ActivityVoiceBilling extends StatefulWidget {
  const ActivityVoiceBilling({super.key});

  @override
  State<ActivityVoiceBilling> createState() => _ActivityVoiceBillingState();
}

class _ActivityVoiceBillingState extends State<ActivityVoiceBilling>
    with TickerProviderStateMixin {
  late final ControllerVoiceBilling controller;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _outerWaveAnimation;
  late final AnimationController _waveBarsController;
  final TextEditingController _manualTextController = TextEditingController();

  String get _currencySymbol =>
      Get.isRegistered<ServiceCurrency>() ? Get.find<ServiceCurrency>().rxCurrency.value : '₹';

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ControllerVoiceBilling>()
        ? Get.find<ControllerVoiceBilling>()
        : Get.put(ControllerVoiceBilling());
    controller.refreshVoiceBillsCount();
    controller.refreshSettings();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _outerWaveAnimation = Tween<double>(begin: 1.1, end: 1.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    _waveBarsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _manualTextController.dispose();
    _pulseController.dispose();
    _waveBarsController.dispose();
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
          /// ── LEFT PANEL: AUDIO VOICE MIC & ASSISTANT (42%) ──
          Expanded(
            flex: 42,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStockSafeBanner(isDark),
                    const SizedBox(height: 12),
                    _buildLanguageSelector(cs, isDark),
                    const SizedBox(height: 14),
                    _buildApiKeyWarningBanner(context, cs),
                    _buildSpeakingCounterHeader(cs),
                    const SizedBox(height: 24),
                    _buildMicCenterButton(cs, isDark),
                    const SizedBox(height: 24),
                    _buildWhatIHeardSection(cs, isDark),
                    const SizedBox(height: 18),
                    _buildQuickDemoChips(cs, isDark),
                  ],
                ),
              ),
            ),
          ),

          /// ── RIGHT PANEL: CAPTURED ITEMS & BILL GENERATION (58%) ──
          Expanded(
            flex: 58,
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Voice Billing Assistant',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
              ),
              Row(
                children: [
                  Text(
                    'Real-time Speech-to-Invoice',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => Text(
                    controller.activeProviderName,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  )),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        // ── LIVE VOICE SALES TRACKER BUTTON ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Tooltip(
            message: 'View all bills sold through Voice Assistant (Stock is safe and untouched)',
            child: FilledButton.tonalIcon(
              onPressed: () => Get.to(() => const ActivityVoiceSalesHistory()),
              icon: const Icon(Icons.analytics_rounded, size: 18),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('AI Sales Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Obx(() => Text(
                      '${controller.rxVoiceBillsCount.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    )),
                  ),
                ],
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFECFDF5),
                foregroundColor: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Settings Button
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Configure Gemini API Key & Audio',
          onPressed: () => DialogVoiceSettings.show(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStockSafeBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF064E3B).withValues(alpha: 0.6), const Color(0xFF022C22).withValues(alpha: 0.8)]
              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock-Safe Mode Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                  ),
                ),
                Text(
                  'Voice sales are tracked in AI Sales Records and NEVER decrement inventory stock.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(ColorScheme cs, bool isDark) {
    return Obx(() {
      final current = controller.rxSelectedLanguage.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            _buildLangChip(cs, '🇮🇳 हिन्दी (Hindi)', 'hi', current == 'hi'),
            _buildLangChip(cs, '🌐 English', 'en', current == 'en'),
            _buildLangChip(cs, '🚩 मराठी (Marathi)', 'mr', current == 'mr'),
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
            borderRadius: BorderRadius.circular(9),
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
              fontSize: 12,
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
          'Keep counter mic close and just speak',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Obx(() {
          final isRecording = controller.rxIsRecording.value;
          final isAnalyzing = controller.rxIsAnalyzing.value;

          return Text(
            controller.rxLiveStatus.value,
            style: TextStyle(
              fontSize: 12,
              color: isRecording
                  ? Colors.red.shade600
                  : isAnalyzing
                      ? Colors.amber.shade700
                      : cs.onSurfaceVariant,
              fontWeight: isRecording || isAnalyzing ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          );
        }),
      ],
    );
  }

  Widget _buildMicCenterButton(ColorScheme cs, bool isDark) {
    return Obx(() {
      final isRecording = controller.rxIsRecording.value;
      final isAnalyzing = controller.rxIsAnalyzing.value;
      final seconds = controller.rxRecordingSeconds.value;

      return Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring (when recording)
                if (isRecording)
                  AnimatedBuilder(
                    animation: _outerWaveAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 110 * _outerWaveAnimation.value,
                        height: 110 * _outerWaveAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(
                            alpha: ((1.5 - _outerWaveAnimation.value) * 0.35).clamp(0.0, 0.4),
                          ),
                        ),
                      );
                    },
                  ),

                // Inner Pulse Ring (when recording)
                if (isRecording)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 110 * _pulseAnimation.value,
                        height: 110 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(
                            alpha: ((1.3 - _pulseAnimation.value) * 0.45).clamp(0.0, 0.5),
                          ),
                        ),
                      );
                    },
                  ),

                // Core Mic Button
                GestureDetector(
                  onTap: isAnalyzing ? null : () => controller.toggleRecording(),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isRecording
                            ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                            : [const Color(0xFFF59E0B), const Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isRecording ? Colors.red : const Color(0xFFF59E0B))
                              .withValues(alpha: isRecording ? 0.5 : 0.35),
                          blurRadius: isRecording ? 24 : 16,
                          spreadRadius: isRecording ? 4 : 2,
                          offset: const Offset(0, 4),
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
                              size: 46,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Status & Audio Waveform Pill
          if (isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade400, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Listening... 00:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildAnimatedWaveBars(),
                ],
              ),
            )
          else
            Text(
              isAnalyzing ? '⚡ Parsing speech with AI...' : 'Tap Mic to Start Speaking',
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

  Widget _buildAnimatedWaveBars() {
    return AnimatedBuilder(
      animation: _waveBarsController,
      builder: (context, _) {
        final val = _waveBarsController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(6 + val * 8),
            const SizedBox(width: 2),
            _bar(12 - val * 7),
            const SizedBox(width: 2),
            _bar(7 + val * 9),
            const SizedBox(width: 2),
            _bar(14 - val * 9),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2.5,
      height: height.clamp(4.0, 16.0),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildWhatIHeardSection(ColorScheme cs, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.graphic_eq_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'LIVE TRANSCRIPT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              // Copy Button
              Obx(() {
                final heard = controller.rxLastHeardText.value;
                if (heard.isEmpty) return const SizedBox.shrink();
                return InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: heard));
                    SnackbarUtil.showSuccess('Transcript copied to clipboard');
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final heard = controller.rxLastHeardText.value;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Text(
                heard.isNotEmpty
                    ? '"$heard"'
                    : 'Speak into your microphone or click demo prompts below.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: heard.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                  color: heard.isNotEmpty ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: heard.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _manualTextController,
                    decoration: InputDecoration(
                      hintText: 'Type speech transcript to test...',
                      hintStyle: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        controller.processText(val);
                        _manualTextController.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final text = _manualTextController.text.trim();
                  if (text.isNotEmpty) {
                    controller.processText(text);
                    _manualTextController.clear();
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Parse', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyWarningBanner(BuildContext context, ColorScheme cs) {
    return Obx(() {
      if (!controller.rxHasApiKey.value) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade700, width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.key_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Free Gemini API Key Active',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Setup your key in settings to enable live voice recognition.',
                      style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => DialogVoiceSettings.show(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Setup Key', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildQuickDemoChips(ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              'Quick Demo Prompts (Click to Test):',
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
              isDark,
              '🛒 Hindi: सत्यम के नाम से 2 किलो चीनी, 1 पैकेट दूध, कैश',
              'सत्यम के नाम से 2 किलो चीनी, 1 पैकेट दूध, कैश',
              'hi',
            ),
            _buildDemoChip(
              cs,
              isDark,
              '🚩 Marathi: रमेशच्या नावाने 2 किलो साखर, 1 लिटर तेल, कॅश',
              'रमेशच्या नावाने 2 किलो साखर, 1 लिटर तेल, कॅश',
              'mr',
            ),
            _buildDemoChip(
              cs,
              isDark,
              '☕ English: Alex, 2 coffees at 100 each, 1 sandwich at 150, UPI',
              'Alex, two coffees at 100 each, one sandwich at 150, UPI payment',
              'en',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoChip(ColorScheme cs, bool isDark, String label, String transcript, String lang) {
    return InkWell(
      onTap: () {
        controller.setLanguage(lang);
        controller.processText(transcript);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller.customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name (Spoken or Typed)',
                hintText: 'e.g. Satyam / Ramesh',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: cs.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Bill Items Captured Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                '1. Tap microphone and speak customer order',
                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
              ),
              Text(
                '2. Example: "2 kg sugar, 1 milk, cash"',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Index & Stock Match Status Icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: item.isMatched
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.isMatched ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
              color: item.isMatched ? const Color(0xFF10B981) : const Color(0xFFD97706),
              size: 18,
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.unit,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.isMatched ? '• In Inventory' : '• Custom Voice Item',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.isMatched ? const Color(0xFF10B981) : const Color(0xFFD97706),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  onPressed: () => controller.decrementQty(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  tooltip: 'Decrease quantity',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  onPressed: () => controller.incrementQty(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  tooltip: 'Increase quantity',
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Unit Price & Tax
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_currencySymbol ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  item.taxRate > 0 ? 'Tax ${item.taxRate.toStringAsFixed(0)}%' : 'Tax 0%',
                  style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Line Total
          Text(
            '$_currencySymbol ${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 10),

          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            onPressed: () => controller.removeItem(index),
            tooltip: 'Remove item',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBillingBar(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Payment Modes & Totals
          Row(
            children: [
              // Payment modes pills
              Expanded(
                child: Obx(() {
                  final current = controller.rxPaymentMode.value;
                  return Row(
                    children: [
                      _paymentChip(cs, 'Cash', Icons.payments_rounded, current == 'Cash'),
                      _paymentChip(cs, 'UPI', Icons.qr_code_rounded, current == 'UPI'),
                      _paymentChip(cs, 'Card', Icons.credit_card_rounded, current == 'Card'),
                      _paymentChip(cs, 'Credit', Icons.account_balance_wallet_rounded, current == 'Credit'),
                    ],
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
                          'Subtotal: $_currencySymbol ${inv.subTotal.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                        ),
                        if (inv.taxTotal > 0)
                          Text(
                            'Tax: $_currencySymbol ${inv.taxTotal.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$_currencySymbol ${inv.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
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
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: controller.pushToPosCart,
                icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                label: const Text('Send to POS Cart'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => controller.generateAndSettleBill(context),
                icon: const Icon(Icons.bolt_rounded, size: 20),
                label: const Text(
                  '⚡ Generate Bill & Print',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentChip(ColorScheme cs, String mode, IconData icon, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => controller.rxPaymentMode.value = mode,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? cs.onPrimary : cs.onSurface),
              const SizedBox(width: 4),
              Text(
                mode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
