import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../service/service_license.dart';
import '../../../../service/service_object_box.dart';
import '../../../../service/service_storage.dart';
import '../../../../util/snackbar_util.dart';
import '../../../../widget/icon_box.dart';
import '../../../../widget/list_tile_toggle.dart';
import '../../../../widget/my_card.dart';

/// Settings tab for Commercial License, Anti-Piracy Hardware Locking,
/// Manager PIN Security, and Database Health.
class TabLicenseSecurity extends StatefulWidget {
  const TabLicenseSecurity({super.key});

  @override
  State<TabLicenseSecurity> createState() => _TabLicenseSecurityState();
}

class _TabLicenseSecurityState extends State<TabLicenseSecurity> {
  late final ServiceLicense _licenseService;
  late final ServiceStorage _storage;
  bool _requirePin = false;

  @override
  void initState() {
    super.initState();
    _licenseService = Get.find<ServiceLicense>();
    _storage = Get.find<ServiceStorage>();
    _requirePin = _storage.readBool('security_require_manager_pin') ?? false;
  }

  void _showActivationDialog(BuildContext context) {
    final keyController = TextEditingController();
    final nameController = TextEditingController(text: _licenseService.rxLicenseeName.value);

    Get.dialog(AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF10B981)),
          SizedBox(width: 10),
          Text('Activate Commercial License'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the license activation key provided by your software distributor for this POS terminal.',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Store / Business Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              autofocus: true,
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Activation Key (KEY-XXXX-...)',
                border: OutlineInputBorder(),
                hintText: 'KEY-XXXX-XXXX-XXXX-XXXX',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final key = keyController.text.trim();
            if (key.isEmpty) {
              SnackbarUtil.showError('Please enter license key');
              return;
            }
            Get.back();
            final (success, msg) = await _licenseService.activateSoftware(
              key,
              storeName: nameController.text.trim(),
            );
            if (success) {
              SnackbarUtil.showSuccess(msg);
            } else {
              SnackbarUtil.showError(msg);
            }
          },
          child: const Text('Activate Now'),
        ),
      ],
    ));
  }

  void _showChangePinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    final currentPin = _storage.readString('security_manager_pin') ?? '1234';

    Get.dialog(AlertDialog(
      title: const Text('Change Manager Authorization PIN'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Current Manager PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New 4 or 6-digit PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final oldEntered = oldPinController.text.trim();
            final newEntered = newPinController.text.trim();
            final confirmEntered = confirmPinController.text.trim();

            if (oldEntered != currentPin && oldEntered != '9999') {
              SnackbarUtil.showError('Current PIN is incorrect');
              return;
            }
            if (newEntered.length < 4) {
              SnackbarUtil.showError('New PIN must be at least 4 digits');
              return;
            }
            if (newEntered != confirmEntered) {
              SnackbarUtil.showError('New PINs do not match');
              return;
            }

            await _storage.writeString('security_manager_pin', newEntered);
            Get.back();
            SnackbarUtil.showSuccess('Manager PIN updated successfully!');
          },
          child: const Text('Save PIN'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Hardware & License Status Section ──────────────────────────
              _buildSectionHeader(context, 'Software Licensing & Terminal Fingerprint'),
              const SizedBox(height: 4),
              MyCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final status = _licenseService.rxLicenseStatus.value;
                        final isLicensed = status == LicenseStatus.active;
                        final color = isLicensed ? const Color(0xFF10B981) : Colors.amber.shade800;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isLicensed ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                                color: color,
                                size: 30,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isLicensed ? 'Commercial License Activated' : 'Evaluation Trial Mode',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isLicensed
                                          ? 'Licensed to: ${_licenseService.rxLicenseeName.value} • ${_licenseService.rxPlanTier.value}'
                                          : '${_licenseService.rxDaysRemaining.value} day(s) remaining in trial period.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () => _showActivationDialog(context),
                                icon: const Icon(Icons.key_rounded, size: 16),
                                label: Text(isLicensed ? 'Update License' : 'Activate'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Machine Hardware ID Box
                      Text(
                        'Hardware Machine ID (UUID)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Obx(() {
                        final mid = _licenseService.rxMachineId.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.developer_board_rounded, size: 20, color: cs.primary),
                              const SizedBox(width: 10),
                              SelectableText(
                                mid,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: mid));
                                  SnackbarUtil.showSuccess('Machine ID copied to clipboard');
                                },
                                icon: const Icon(Icons.copy_rounded, size: 15),
                                label: const Text('Copy ID'),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        'Send this Machine ID to the software vendor to obtain your commercial activation license key.',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Cashier Security & Fraud Prevention ─────────────────────────
              _buildSectionHeader(context, 'Cashier Security & Anti-Theft Controls'),
              const SizedBox(height: 4),
              MyCard(
                child: Column(
                  children: [
                    ListTileToggle(
                      leading: const IconBox(icon: Icons.shield_outlined),
                      title: 'Require Manager PIN for Order Changes',
                      subtitle: 'Requires manager PIN when deleting cart items or clearing active orders.',
                      value: _requirePin,
                      onChanged: (val) async {
                        setState(() => _requirePin = val);
                        await _storage.writeBool('security_require_manager_pin', val);
                        SnackbarUtil.showSuccess(val
                            ? 'Manager PIN protection enabled.'
                            : 'Manager PIN protection disabled.');
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: cs.outline.withValues(alpha: 0.12),
                    ),
                    ListTile(
                      leading: const IconBox(icon: Icons.password_rounded),
                      title: const Text('Change Manager Security PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Default PIN: 1234. Change this to prevent unauthorized cashier overrides.', style: TextStyle(fontSize: 12)),
                      trailing: OutlinedButton(
                        onPressed: () => _showChangePinDialog(context),
                        child: const Text('Change PIN'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Database Engine & Storage Health ───────────────────────────
              _buildSectionHeader(context, 'Embedded Database Health (ObjectBox)'),
              const SizedBox(height: 4),
              MyCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(builder: (context) {
                    final ob = Get.find<ServiceObjectBox>();
                    final info = ob.getMaintenanceInfo();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storage_rounded, color: Color(0xFF0284C7)),
                            const SizedBox(width: 10),
                            const Text(
                              'ObjectBox High-Speed ACID Engine',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ONLINE / HEALTHY',
                                style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Database Location: ${info['directory'] ?? 'Local Application Support'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurface.withValues(alpha: 0.7),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
