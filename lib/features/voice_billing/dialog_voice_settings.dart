import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../util/snackbar_util.dart';
import 'controller_voice_billing.dart';
import 'services/service_ai_parser.dart';

class DialogVoiceSettings extends StatefulWidget {
  const DialogVoiceSettings({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const DialogVoiceSettings(),
    );
  }

  @override
  State<DialogVoiceSettings> createState() => _DialogVoiceSettingsState();
}

class _DialogVoiceSettingsState extends State<DialogVoiceSettings> {
  final ServiceAiParser _parser = ServiceAiParser();
  late String _selectedProvider;
  late final TextEditingController _groqController;
  late final TextEditingController _geminiController;

  bool _isTesting = false;
  bool _obscureGroq = false;
  bool _obscureGemini = false;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _parser.activeProvider;
    _groqController = TextEditingController(text: _parser.savedGroqKey);
    _geminiController = TextEditingController(text: _parser.savedGeminiKey);
  }

  @override
  void dispose() {
    _groqController.dispose();
    _geminiController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      controller.text = data.text!.trim();
      SnackbarUtil.showSuccess('Pasted key from clipboard');
    }
  }

  Future<void> _testConnection() async {
    final isGroq = _selectedProvider == 'groq';
    final key = isGroq ? _groqController.text.trim() : _geminiController.text.trim();

    if (key.isEmpty) {
      SnackbarUtil.showError('Please enter a ${isGroq ? "Groq" : "Gemini"} API Key to test');
      return;
    }

    setState(() => _isTesting = true);

    await _parser.saveSettings(
      provider: _selectedProvider,
      groqKey: _groqController.text.trim(),
      geminiKey: _geminiController.text.trim(),
    );
    if (Get.isRegistered<ControllerVoiceBilling>()) {
      Get.find<ControllerVoiceBilling>().refreshSettings();
    }

    try {
      final res = await _parser.parseTextWithFallback('Customer Ramesh, 2 kg sugar, cash payment');
      if (res.items.isNotEmpty) {
        SnackbarUtil.showSuccess('${isGroq ? "Groq (Whisper + LLaMA)" : "Gemini"} connected! Parsed ${res.items.length} items successfully');
      } else {
        SnackbarUtil.showSuccess('API key is valid');
      }
    } catch (e) {
      SnackbarUtil.showError('Connection test failed: $e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _saveAndClose() async {
    await _parser.saveSettings(
      provider: _selectedProvider,
      groqKey: _groqController.text.trim(),
      geminiKey: _geminiController.text.trim(),
    );
    if (Get.isRegistered<ControllerVoiceBilling>()) {
      Get.find<ControllerVoiceBilling>().refreshSettings();
    }
    SnackbarUtil.showSuccess('Voice AI settings saved successfully');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGroq = _selectedProvider == 'groq';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.settings_voice_rounded, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          const Text('Voice AI Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your free Cloud Speech Recognition provider for live microphone billing:',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),

              // Provider selector tabs
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedProvider = 'groq'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isGroq ? const Color(0xFFF55036).withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isGroq ? Border.all(color: const Color(0xFFF55036), width: 1.5) : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt_rounded, size: 18, color: isGroq ? const Color(0xFFF55036) : cs.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                'Groq Cloud (Fastest)',
                                style: TextStyle(
                                  fontWeight: isGroq ? FontWeight.bold : FontWeight.w500,
                                  color: isGroq ? const Color(0xFFF55036) : cs.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedProvider = 'gemini'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isGroq ? Colors.blue.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: !isGroq ? Border.all(color: Colors.blue, width: 1.5) : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 16, color: !isGroq ? Colors.blue : cs.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                'Google Gemini Flash',
                                style: TextStyle(
                                  fontWeight: !isGroq ? FontWeight.bold : FontWeight.w500,
                                  color: !isGroq ? Colors.blue : cs.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (isGroq) ...[
                // Groq Key Section
                TextField(
                  controller: _groqController,
                  obscureText: _obscureGroq,
                  decoration: InputDecoration(
                    labelText: 'Groq API Key (gsk_...)',
                    hintText: 'gsk_...',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_obscureGroq ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setState(() => _obscureGroq = !_obscureGroq),
                        ),
                        IconButton(
                          icon: const Icon(Icons.paste_rounded, size: 18),
                          tooltip: 'Paste',
                          onPressed: () => _pasteFromClipboard(_groqController),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _groqController.clear(),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    helperText: '100% Free: Whisper speech-to-text + LLaMA 3.3 in ~200ms.',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://console.groq.com/keys');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Get Free Groq Key (console.groq.com)', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ] else ...[
                // Gemini Key Section
                TextField(
                  controller: _geminiController,
                  obscureText: _obscureGemini,
                  decoration: InputDecoration(
                    labelText: 'Google Gemini API Key (AIzaSy...)',
                    hintText: 'AIzaSy...',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_obscureGemini ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setState(() => _obscureGemini = !_obscureGemini),
                        ),
                        IconButton(
                          icon: const Icon(Icons.paste_rounded, size: 18),
                          tooltip: 'Paste',
                          onPressed: () => _pasteFromClipboard(_geminiController),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _geminiController.clear(),
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    helperText: 'Free from Google AI Studio: 1,500 requests per day.',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://aistudio.google.com/app/apikey');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Get Free Gemini Key (aistudio.google.com)', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveAndClose,
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}
