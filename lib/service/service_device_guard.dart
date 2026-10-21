import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../model/model_branch.dart';
import 'service_license.dart';
import 'service_storage.dart';

/// Information regarding a registered POS terminal.
class PosDeviceInfo {
  final String machineId;
  final String deviceName;
  final DateTime registeredAt;
  final DateTime lastActiveAt;

  PosDeviceInfo({
    required this.machineId,
    required this.deviceName,
    required this.registeredAt,
    required this.lastActiveAt,
  });

  factory PosDeviceInfo.fromJson(Map<String, dynamic> json) {
    return PosDeviceInfo(
      machineId: json['machineId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? 'POS Terminal',
      registeredAt: DateTime.tryParse(json['registeredAt']?.toString() ?? '') ?? DateTime.now(),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'machineId': machineId,
        'deviceName': deviceName,
        'registeredAt': registeredAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };
}

/// Result of checking device terminal authorization against branch plan.
class DeviceAuthResult {
  final bool isAuthorized;
  final bool isNewlyRegistered;
  final int maxAllowed;
  final List<PosDeviceInfo> registeredDevices;
  final String? message;

  DeviceAuthResult({
    required this.isAuthorized,
    this.isNewlyRegistered = false,
    required this.maxAllowed,
    this.registeredDevices = const [],
    this.message,
  });

  factory DeviceAuthResult.authorized({bool isNewlyRegistered = false, int maxAllowed = 2}) {
    return DeviceAuthResult(
      isAuthorized: true,
      isNewlyRegistered: isNewlyRegistered,
      maxAllowed: maxAllowed,
    );
  }

  factory DeviceAuthResult.limitExceeded({
    required int maxAllowed,
    required List<PosDeviceInfo> registeredDevices,
  }) {
    return DeviceAuthResult(
      isAuthorized: false,
      maxAllowed: maxAllowed,
      registeredDevices: registeredDevices,
      message: 'Terminal limit reached: max $maxAllowed devices allowed.',
    );
  }
}

/// Service that enforces `maxPosDevices` terminal quota per branch.
/// Identifies the machine via [ServiceLicense.rxMachineId] and validates against
/// the branch's registered device slots.
class ServiceDeviceGuard extends GetxService {
  final ServiceStorage _storage;
  final ServiceLicense _licenseService;

  final rxIsDeviceAuthorized = true.obs;
  final rxRegisteredDevices = <PosDeviceInfo>[].obs;
  final rxMaxDevices = 2.obs;

  ServiceDeviceGuard({
    required ServiceStorage storage,
    required ServiceLicense licenseService,
  })  : _storage = storage,
        _licenseService = licenseService;

  String _storageKey(String branchId) => 'pref_branch_devices_$branchId';

  /// Loads registered terminals for a given branch ID.
  List<PosDeviceInfo> getRegisteredDevices(String branchId) {
    if (branchId.isEmpty) return [];
    final raw = _storage.readString(_storageKey(branchId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => PosDeviceInfo.fromJson(m))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ [ServiceDeviceGuard] Error parsing devices: $e');
    }
    return [];
  }

  /// Saves the registered terminals list for a given branch ID.
  Future<void> _saveRegisteredDevices(String branchId, List<PosDeviceInfo> list) async {
    final encoded = jsonEncode(list.map((d) => d.toJson()).toList());
    await _storage.writeString(_storageKey(branchId), encoded);
    rxRegisteredDevices.assignAll(list);
  }

  /// Verifies whether this physical machine is authorized to run the POS for [branch].
  ///
  /// 1. If this machine is already registered, updates its heartbeat and authorizes.
  /// 2. If new machine and registeredCount < maxPosDevices, automatically registers it.
  /// 3. If new machine and registeredCount >= maxPosDevices, returns limit exceeded.
  Future<DeviceAuthResult> verifyDevice(ModelBranch branch) async {
    final branchId = branch.id ?? '';
    final maxAllowed = branch.planDetails?.maxPosDevices ?? 2;
    rxMaxDevices.value = maxAllowed;

    final currentMachineId = _licenseService.rxMachineId.value;
    final currentDevices = getRegisteredDevices(branchId);
    rxRegisteredDevices.assignAll(currentDevices);

    // 1. Check if this machine is already registered
    final existingIndex = currentDevices.indexWhere((d) => d.machineId == currentMachineId);
    if (existingIndex >= 0) {
      // Refresh last active timestamp
      final updated = PosDeviceInfo(
        machineId: currentMachineId,
        deviceName: currentDevices[existingIndex].deviceName,
        registeredAt: currentDevices[existingIndex].registeredAt,
        lastActiveAt: DateTime.now(),
      );
      currentDevices[existingIndex] = updated;
      await _saveRegisteredDevices(branchId, currentDevices);

      rxIsDeviceAuthorized.value = true;
      return DeviceAuthResult.authorized(maxAllowed: maxAllowed);
    }

    // 2. New machine: Is there an available slot under maxPosDevices?
    if (currentDevices.length < maxAllowed) {
      final counterNumber = currentDevices.length + 1;
      final osName = Platform.operatingSystem.toUpperCase();
      final deviceName = 'Counter $counterNumber ($osName)';

      final newDevice = PosDeviceInfo(
        machineId: currentMachineId,
        deviceName: deviceName,
        registeredAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      currentDevices.add(newDevice);
      await _saveRegisteredDevices(branchId, currentDevices);

      debugPrint('✅ [ServiceDeviceGuard] Registered new terminal: $deviceName (Slot $counterNumber/$maxAllowed)');
      rxIsDeviceAuthorized.value = true;
      return DeviceAuthResult.authorized(isNewlyRegistered: true, maxAllowed: maxAllowed);
    }

    // 3. Quota full: Exceeded maxPosDevices limit
    debugPrint('🚫 [ServiceDeviceGuard] Terminal limit exceeded: ${currentDevices.length}/$maxAllowed devices registered');
    rxIsDeviceAuthorized.value = false;
    return DeviceAuthResult.limitExceeded(
      maxAllowed: maxAllowed,
      registeredDevices: currentDevices,
    );
  }

  /// Deregisters an old terminal from the branch, freeing up a slot.
  Future<bool> deregisterDevice(String branchId, String machineIdToRemove) async {
    final devices = getRegisteredDevices(branchId);
    final initialLen = devices.length;
    devices.removeWhere((d) => d.machineId == machineIdToRemove);

    if (devices.length < initialLen) {
      await _saveRegisteredDevices(branchId, devices);
      debugPrint('🗑️ [ServiceDeviceGuard] Deregistered device: $machineIdToRemove');
      return true;
    }
    return false;
  }

  /// Replaces a selected registered device with the current machine.
  Future<bool> replaceDeviceWithCurrent(String branchId, String oldMachineId) async {
    final removed = await deregisterDevice(branchId, oldMachineId);
    if (!removed) return false;

    final currentMachineId = _licenseService.rxMachineId.value;
    final devices = getRegisteredDevices(branchId);
    final counterNumber = devices.length + 1;
    final osName = Platform.operatingSystem.toUpperCase();

    final newDevice = PosDeviceInfo(
      machineId: currentMachineId,
      deviceName: 'Counter $counterNumber ($osName)',
      registeredAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    devices.add(newDevice);
    await _saveRegisteredDevices(branchId, devices);
    rxIsDeviceAuthorized.value = true;
    return true;
  }
}
