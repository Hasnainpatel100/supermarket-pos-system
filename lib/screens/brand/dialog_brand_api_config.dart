import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/dio_client.dart';
import '../../service/service_api_user.dart';
import '../../service/service_branch_api.dart';
import '../../service/service_brand_api.dart';
import '../../util/snackbar_util.dart';
import '../../widget/app_dialog_components.dart';

class DialogBrandApiConfig extends StatefulWidget {
  const DialogBrandApiConfig({super.key});

  @override
  State<DialogBrandApiConfig> createState() => _DialogBrandApiConfigState();
}

class _DialogBrandApiConfigState extends State<DialogBrandApiConfig> {
  final ServiceBrandApi _api = Get.find<ServiceBrandApi>();
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;

  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _api.baseUrl);
    _tokenController = TextEditingController(text: _api.authToken ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      SnackbarUtil.showWarning('Please enter a server base URL');
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final token = _tokenController.text.trim();
    final res = await _api.testConnection(url, token);

    setState(() {
      _isTesting = false;
      _testSuccess = res.success;
      _testResult = res.message;
    });
  }

  Future<void> _saveConfig() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      SnackbarUtil.showWarning('Server URL cannot be empty');
      return;
    }

    final token = _tokenController.text.trim();

    await _api.setBaseUrl(url);
    await _api.setAuthToken(token);

    if (Get.isRegistered<ServiceBranchApi>()) {
      await Get.find<ServiceBranchApi>().setBaseUrl(url);
      await Get.find<ServiceBranchApi>().setAuthToken(token);
    }
    if (Get.isRegistered<ServiceApiUser>()) {
      await Get.find<ServiceApiUser>().setBaseUrl(url);
      await Get.find<ServiceApiUser>().setAuthToken(token);
    }
    if (Get.isRegistered<DioClient>()) {
      Get.find<DioClient>().setBaseUrl(url);
    }

    SnackbarUtil.showSuccess('API Server configuration saved');
    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      maxWidth: 550,
      maxHeight: 520,
      header: DialogHeader(
        title: 'Brand API Server Settings',
        icon: Icons.dns_rounded,
        iconColor: colorScheme.primary,
      ),
      body: DialogBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Configure the backend REST API endpoint for creating and syncing brands (e.g. POST {{baseUrl}}/api/brands).',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _urlController,
              label: 'API Base URL *',
              hint: 'http://localhost:5000 or https://api.myserver.com',
              prefixIcon: Icons.cloud_queue_rounded,
              required: true,
            ),
            const SizedBox(height: 16),

            AppTextField(
              controller: _tokenController,
              label: 'Bearer Auth Token (Optional)',
              hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
              prefixIcon: Icons.key_rounded,
              obscure: _obscureToken,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureToken ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    tooltip: _obscureToken ? 'Show token' : 'Hide token',
                    onPressed: () => setState(() => _obscureToken = !_obscureToken),
                  ),
                  if (_tokenController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      tooltip: 'Clear token',
                      onPressed: () => setState(() => _tokenController.clear()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tip: Redundant "Bearer " prefixes and surrounding quotes are automatically stripped.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // Test Connection button
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check_rounded, size: 18),
              label: Text(_isTesting ? 'Testing connection...' : 'Test Server Connection'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_testSuccess == true ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_testSuccess == true ? Colors.green : Colors.red).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess == true
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      color: _testSuccess == true ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess == true ? Colors.green.shade900 : Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Get.back(),
        onSave: _saveConfig,
        saveLabel: 'Save Settings',
      ),
    );
  }
}
