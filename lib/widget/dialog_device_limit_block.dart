import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../features/authentication/data/auth_repository.dart';
import '../model/model_branch.dart';
import '../repository/repo_storage.dart';
import '../service/service_device_guard.dart';
import '../util/app_route.dart';
import 'app_dialog_components.dart';
import 'dialog_renew_plan.dart';

/// Non-dismissible blocking dialog displayed when this machine cannot run POS
/// because the branch plan's maxPosDevices limit has been reached.
class DialogDeviceLimitBlock extends StatefulWidget {
  final ModelBranch branch;
  final DeviceAuthResult result;

  const DialogDeviceLimitBlock({
    super.key,
    required this.branch,
    required this.result,
  });

  /// Displays the blocking terminal limit modal dialog.
  /// Cannot be dismissed by tapping outside.
  static Future<void> show(
    BuildContext context, {
    required ModelBranch branch,
    required DeviceAuthResult result,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: DialogDeviceLimitBlock(
          branch: branch,
          result: result,
        ),
      ),
    );
  }

  @override
  State<DialogDeviceLimitBlock> createState() => _DialogDeviceLimitBlockState();
}

class _DialogDeviceLimitBlockState extends State<DialogDeviceLimitBlock> {
  bool _isSwitching = false;

  Future<void> _handleReplaceDevice(PosDeviceInfo oldDevice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deregister Old Terminal?'),
        content: Text(
          'Are you sure you want to remove "${oldDevice.deviceName}" and register this computer in its place?\n\nThe old machine will no longer have access to this branch until re-authorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Deregister & Authorize This PC'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSwitching = true);

    final guard = Get.find<ServiceDeviceGuard>();
    final success = await guard.replaceDeviceWithCurrent(
      widget.branch.id ?? '',
      oldDevice.machineId,
    );

    if (mounted) {
      setState(() => _isSwitching = false);
      if (success) {
        Navigator.of(context).pop();
        Get.snackbar(
          'Device Authorized',
          'This terminal has successfully been registered for ${widget.branch.name.en}.',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Action Failed',
          'Could not deregister the selected device. Please try again.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    if (Get.isRegistered<AuthRepository>()) {
      await Get.find<AuthRepository>().logout();
    }
    if (Get.isRegistered<RepoStorage>()) {
      await Get.find<RepoStorage>().logout();
    }
    Get.offAllNamed(AppRoute.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final maxAllowed = widget.result.maxAllowed;
    final registeredDevices = widget.result.registeredDevices;
    final branchName = widget.branch.name.en;

    return AppDialog(
      maxWidth: 540,
      maxHeight: 640,
      header: const DialogHeader(
        title: 'POS Terminal Limit Reached',
        icon: Icons.desktop_access_disabled_rounded,
        iconColor: Color(0xFFEF4444),
      ),
      body: DialogBody(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Red Warning Card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.45 : 0.35),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.devices_rounded,
                      color: Color(0xFFEF4444),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All $maxAllowed POS Device Slots Occupied',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$branchName is licensed for $maxAllowed concurrent POS counters.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Active Registered Terminals:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 8),

            // ── List of Currently Registered Devices ──────────────────────
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: registeredDevices.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final dev = registeredDevices[index];
                  final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(dev.lastActiveAt);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.computer_rounded, size: 20, color: Colors.blueGrey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dev.deviceName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Last active: $formattedDate',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _isSwitching ? null : () => _handleReplaceDevice(dev),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: const Text('Replace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'To use this computer, either replace one of the decommissioned counters above or upgrade your subscription plan.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),

            // ── Footer Action Buttons ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      DialogRenewPlan.show(context, branch: widget.branch);
                    },
                    icon: const Icon(Icons.upgrade_rounded, size: 16),
                    label: const Text('Upgrade Plan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
