import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../util/snackbar_util.dart';
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
  late final TextEditingController _keyController;
  bool _isTesting = false;
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: _parser.savedApiKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _keyController.text = data.text!.trim();
      SnackbarUtil.showSuccess('Pasted API key from clipboard');
    }
  }

  Future<void> _testConnection() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      SnackbarUtil.showError('Please enter a Gemini API Key to test');
      return;
    }

    setState(() => _isTesting = true);
    await _parser.saveApiKey(key);

    try {
      final res = await _parser.parseTextWithFallback('Customer Ramesh, 2 kg sugar, cash');
      if (res.items.isNotEmpty) {
        SnackbarUtil.showSuccess('AI Connected! Parsed ${res.items.length} items successfully');
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
    await _parser.saveApiKey(_keyController.text.trim());
    SnackbarUtil.showSuccess('Voice AI key saved successfully');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
        width: 490,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time voice recognition uses Google Gemini 1.5/2.0 Flash to transcribe and parse Hindi, Marathi, Hinglish, and English audio.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Google Gemini API Key (Required for live mic)',
                hintText: 'AIzaSy...',
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                      tooltip: _obscure ? 'Show Key' : 'Hide Key',
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    IconButton(
                      icon: const Icon(Icons.paste_rounded, size: 18),
                      tooltip: 'Paste from Clipboard',
                      onPressed: _pasteFromClipboard,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _keyController.clear(),
                    ),
                  ],
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                helperText: 'Free from Google AI Studio: 1,500 free requests per day.',
              ),
            ),
            const SizedBox(height: 14),
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
                  label: const Text('Get Free Key (Google AI Studio)', style: TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Google AI Studio offers 1,500 free requests per day (no credit card required).',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
