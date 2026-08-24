import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../service/service_api_user.dart';
import '../../util/snackbar_util.dart';

class DialogApiUserConfig extends StatefulWidget {
  const DialogApiUserConfig({super.key});

  @override
  State<DialogApiUserConfig> createState() => _DialogApiUserConfigState();
}

class _DialogApiUserConfigState extends State<DialogApiUserConfig> {
  late final ServiceApiUser _apiService;
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;

  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _apiService = Get.find<ServiceApiUser>();
    _urlController = TextEditingController(text: _apiService.baseUrl);
    _tokenController = TextEditingController(text: _apiService.authToken ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final res = await _apiService.testConnection(_urlController.text.trim());

    setState(() {
      _isTesting = false;
      _testSuccess = res.success;
      _testResult = res.message;
    });
  }

  Future<void> _saveConfig() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();

    if (url.isEmpty) {
      SnackbarUtil.showError('Base URL cannot be empty');
      return;
    }

    await _apiService.setBaseUrl(url);
    await _apiService.setAuthToken(token);

    SnackbarUtil.showSuccess('API User configuration saved!');
    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.settings_remote_rounded, color: colorScheme.primary, size: 26),
                const SizedBox(width: 12),
                const Text(
                  'API Server Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Configure the base REST URL and Bearer Authorization token for API requests.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const Divider(height: 24),

            // Base URL input
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL *',
                hintText: 'http://172.19.112.1:8080',
                prefixIcon: Icon(Icons.link_rounded),
                border: OutlineInputBorder(),
                helperText: 'e.g. http://172.19.112.1:8080',
              ),
            ),
            const SizedBox(height: 16),

            // Auth Token input
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Authorization Bearer Token (Optional)',
                hintText: 'Paste JWT Token here...',
                prefixIcon: Icon(Icons.key_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Test Connection Feedback
            if (_testResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess ? Colors.green : Colors.red,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    color: _testSuccess ? Colors.green.shade800 : Colors.red.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check_rounded, size: 18),
                  label: const Text('Test Connection'),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _saveConfig,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Configuration'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
