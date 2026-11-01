import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/entity_customer.dart';
import '../../../../service/service_object_box.dart';
import '../../../../util/snackbar_util.dart';
import '../../../../widget/app_dialog_components.dart';

/// Compact customer card for the POS billing screen.
///
/// Presented as a modal bottom sheet so the cashier never leaves the billing
/// screen. On save it persists the customer and pops the created
/// [EntityCustomer] back to the caller, which selects it on the active bill.
class PosCustomerSheet extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;

  const PosCustomerSheet({
    super.key,
    this.initialName,
    this.initialPhone,
  });

  @override
  State<PosCustomerSheet> createState() => _PosCustomerSheetState();
}

class _PosCustomerSheetState extends State<PosCustomerSheet> {
  static const double _maxCardWidth = 560;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;

  bool _isVip = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _phoneCtrl = TextEditingController(text: widget.initialPhone ?? '');
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final int now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final EntityCustomer customer = EntityCustomer(
        isActive: true,
        createdAtUtcMs: now,
      )
        ..name = _nameCtrl.text.trim()
        ..phone = _phoneCtrl.text.trim()
        ..email = _emailCtrl.text.trim()
        ..address = _addressCtrl.text.trim()
        ..isVip = _isVip
        ..updatedAtUtcMs = now;

      final box = Get.find<ServiceObjectBox>().box<EntityCustomer>();
      customer.id = box.put(customer);

      Navigator.of(context).pop(customer);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      SnackbarUtil.showError('Failed to save customer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _maxCardWidth,
            maxHeight: maxHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGrabber(cs),
                  _buildHeader(cs),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _nameCtrl,
                              label: 'Customer Name',
                              hint: 'Name to appear on the bill',
                              required: true,
                              prefixIcon: Icons.person_rounded,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _phoneCtrl,
                                    label: 'Phone',
                                    hint: '10-digit number',
                                    prefixIcon: Icons.call_rounded,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    controller: _emailCtrl,
                                    label: 'Email (optional)',
                                    hint: 'name@example.com',
                                    prefixIcon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _addressCtrl,
                              label: 'Address (optional)',
                              hint: 'Street, area, city',
                              prefixIcon: Icons.location_on_outlined,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            _buildVipToggle(cs),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(cs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrabber(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: cs.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_add_alt_1_rounded, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Customer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saved to the customer master and attached to this bill',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildVipToggle(ColorScheme cs) {
    final Color accent = Colors.amber.shade800;

    return InkWell(
      onTap: () => setState(() => _isVip = !_isVip),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: _isVip
              ? Colors.amber.withValues(alpha: 0.10)
              : cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isVip
                ? Colors.amber.shade700.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 18,
              color: _isVip ? accent : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isVip ? 'VIP customer' : 'Mark as VIP customer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _isVip ? FontWeight.bold : FontWeight.w500,
                  color: _isVip ? accent : cs.onSurface,
                ),
              ),
            ),
            Switch(
              value: _isVip,
              onChanged: (bool value) => setState(() => _isVip = value),
              activeTrackColor: Colors.amber.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              icon: Icons.close_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: 'Save & Select',
              onPressed: _save,
              isLoading: _isSaving,
              icon: Icons.check_rounded,
              backgroundColor: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
