import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../core/storage/token_storage.dart';
import '../model/model_branch.dart';
import '../model/model_registered_device.dart';
import '../util/util_device.dart';
import 'app_dialog_components.dart';

/// Hard-blocking modal dialog displayed when the branch has reached its
/// maximum allowed registered POS devices (`maxPosDevices`).
///
/// Prevents the terminal from logging in without an available device slot.
/// Allows the user to view all registered devices and remove one to free up a slot.
class DialogDeviceLimit extends StatefulWidget {
  final ModelBranch? branch;
  final int maxPosDevices;
  final String currentDeviceId;
  final String currentDeviceName;
  final VoidCallback onDeviceActivated;
  final VoidCallback onCancel;

  const DialogDeviceLimit({
    super.key,
    this.branch,
    required this.maxPosDevices,
    required this.currentDeviceId,
    required this.currentDeviceName,
    required this.onDeviceActivated,
    required this.onCancel,
  });

  /// Displays the blocking device limit dialog.
  /// Cannot be dismissed by tapping outside or pressing Back.
  static Future<void> show(
    BuildContext context, {
    ModelBranch? branch,
    required int maxPosDevices,
    required String currentDeviceId,
    required String currentDeviceName,
    required VoidCallback onDeviceActivated,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: DialogDeviceLimit(
          branch: branch,
          maxPosDevices: maxPosDevices,
          currentDeviceId: currentDeviceId,
          currentDeviceName: currentDeviceName,
          onDeviceActivated: onDeviceActivated,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  State<DialogDeviceLimit> createState() => _DialogDeviceLimitState();
}

class _DialogDeviceLimitState extends State<DialogDeviceLimit> {
  late TokenStorage _tokenStorage;
  String? _branchId;
  List<ModelRegisteredDevice> _devices = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tokenStorage = Get.find<TokenStorage>();
    _branchId = widget.branch?.id ?? widget.branch?.remoteId;
    _loadDevices();
  }

  void _loadDevices() {
    setState(() {
      _devices = _tokenStorage.getRegisteredDevices(_branchId);
    });
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'Unknown date';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  IconData _getDeviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('win') || lower.contains('desktop') || lower.contains('pc')) {
      return Icons.desktop_windows_rounded;
    }
    if (lower.contains('mac') || lower.contains('apple')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('android') || lower.contains('ios') || lower.contains('phone')) {
      return Icons.phone_android_rounded;
    }
    if (lower.contains('linux')) {
      return Icons.terminal_rounded;
    }
    return Icons.devices_other_rounded;
  }

  Future<void> _removeDevice(ModelRegisteredDevice device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Remove Terminal?'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${device.deviceName}"? '
          'This terminal will lose access to this branch until re-registered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    await _tokenStorage.removeRegisteredDevice(device.deviceId, _branchId);
    _loadDevices();
    setState(() => _isProcessing = false);
  }

  Future<void> _replaceWithCurrentDevice(ModelRegisteredDevice oldDevice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Text('Replace Terminal?'),
          ],
        ),
        content: Text(
          'Replace "${oldDevice.deviceName}" with this device ("${widget.currentDeviceName}") and proceed to login?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Replace & Login'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      // 1. Remove old device
      await _tokenStorage.removeRegisteredDevice(oldDevice.deviceId, _branchId);

      // 2. Register current device
      final updatedList = _tokenStorage.getRegisteredDevices(_branchId);
      final currentDevice = ModelRegisteredDevice(
        deviceId: widget.currentDeviceId,
        deviceName: widget.currentDeviceName,
        registeredAt: DateTime.now().toIso8601String(),
        ipAddress: await UtilDevice.getIpAddress(),
      );
      await _tokenStorage.saveRegisteredDevices([...updatedList, currentDevice], _branchId);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDeviceActivated();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _activateCurrentDevice() async {
    if (_devices.length >= widget.maxPosDevices) {
      Get.snackbar(
        'Device Limit Reached',
        'Please remove a device first before activating this terminal.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final currentDevice = ModelRegisteredDevice(
        deviceId: widget.currentDeviceId,
        deviceName: widget.currentDeviceName,
        registeredAt: DateTime.now().toIso8601String(),
        ipAddress: await UtilDevice.getIpAddress(),
      );
      await _tokenStorage.saveRegisteredDevices([..._devices, currentDevice], _branchId);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDeviceActivated();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final branchName = widget.branch?.name.en ?? 'Branch';
    final branchCode = widget.branch?.branchCode ?? '';
    final hasSlotAvailable = _devices.length < widget.maxPosDevices;

    return AppDialog(
      maxWidth: 620,
      maxHeight: 680,
      hasUnsavedChanges: () => true, // Block escape key pop without handling
      header: DialogHeader(
        title: 'POS Device Limit Reached',
        icon: Icons.devices_other_rounded,
        iconColor: const Color(0xFFF59E0B),
        onClose: _handleCancel,
      ),
      body: DialogBody(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Warning Card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.45 : 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.screen_lock_portrait_rounded,
                      color: Color(0xFFD97706),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maximum Terminals Reached',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your branch plan allows a maximum of ${widget.maxPosDevices} POS terminal(s). '
                          'To use this terminal (${widget.currentDeviceName}), you must de-register an active device below.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Branch & Limit Stats ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2530) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Branch: $branchName ${branchCode.isNotEmpty ? "($branchCode)" : ""}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current Device: ${widget.currentDeviceName}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasSlotAvailable
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasSlotAvailable
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${_devices.length} / ${widget.maxPosDevices} Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasSlotAvailable
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Registered Devices Section Header ─────────────────
            Row(
              children: [
                Icon(
                  Icons.devices_rounded,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Registered Devices',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Registered Devices List ───────────────────────────
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Text(
                        'No devices currently registered.',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _devices.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isThisDevice = device.deviceId == widget.currentDeviceId;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? (isThisDevice ? const Color(0xFF1E3A5F) : const Color(0xFF18202F))
                                : (isThisDevice ? const Color(0xFFEFF6FF) : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isThisDevice
                                  ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getDeviceIcon(device.deviceName),
                                  size: 20,
                                  color: isDark ? Colors.blue.shade300 : const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            device.deviceName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: isDark ? Colors.white : Colors.grey.shade900,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isThisDevice) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Current',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF3B82F6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Registered: ${_formatDate(device.registeredAt)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Replace button
                              FilledButton.tonal(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _replaceWithCurrentDevice(device),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Replace',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Remove icon button
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                iconSize: 20,
                                splashRadius: 18,
                                tooltip: 'Remove Terminal',
                                onPressed: _isProcessing ? null : () => _removeDevice(device),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? (theme.cardTheme.color ?? theme.cardColor) : Colors.grey.shade50,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _handleCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text(
                'Cancel & Back',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            if (hasSlotAvailable)
              FilledButton.icon(
                onPressed: _isProcessing ? null : _activateCurrentDevice,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text(
                  'Activate This Terminal',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
