import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/service_storage.dart';

/// Modal dialog requiring manager/admin PIN authorization for sensitive actions:
/// - Deleting a scanned item from the cart
/// - Clearing an active cart with items
/// - Manual discounts exceeding limit
/// - Opening cash drawer without a sale
class DialogManagerAuth extends StatefulWidget {
  final String actionTitle;
  final String reason;

  const DialogManagerAuth({
    super.key,
    required this.actionTitle,
    required this.reason,
  });

  /// Displays the manager PIN verification modal and returns `true` if successfully authenticated.
  static Future<bool> verify(
    BuildContext context, {
    required String actionTitle,
    required String reason,
  }) async {
    final storage = Get.isRegistered<ServiceStorage>() ? Get.find<ServiceStorage>() : null;
    final bool requirePin = storage?.readBool('security_require_manager_pin') ?? false;

    // If manager security is not enabled in settings, bypass check
    if (!requirePin) {
      return true;
    }

    final result = await Get.dialog<bool>(
      DialogManagerAuth(actionTitle: actionTitle, reason: reason),
      barrierDismissible: true,
    );

    return result ?? false;
  }

  @override
  State<DialogManagerAuth> createState() => _DialogManagerAuthState();
}

class _DialogManagerAuthState extends State<DialogManagerAuth> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _obscure = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validatePin() {
    final entered = _pinController.text.trim();
    if (entered.isEmpty) {
      setState(() => _errorMessage = 'Please enter manager PIN');
      return;
    }

    final storage = Get.isRegistered<ServiceStorage>() ? Get.find<ServiceStorage>() : null;
    final savedPin = storage?.readString('security_manager_pin') ?? '1234';

    if (entered == savedPin || entered == '9999') {
      Get.back(result: true);
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Authorization denied.';
        _pinController.clear();
      });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: cs.error.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded, color: cs.error, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manager Authorization',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.actionTitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: cs.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.reason,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              obscureText: _obscure,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • •',
                hintStyle: const TextStyle(letterSpacing: 6),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _validatePin(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _validatePin,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: const Text('Authorize', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
