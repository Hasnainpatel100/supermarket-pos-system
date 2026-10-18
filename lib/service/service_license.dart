import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'service_storage.dart';

enum LicenseStatus {
  trial,
  active,
  expired,
}

/// Software Licensing & Anti-Piracy Service for commercial supermarket distribution.
/// Generates hardware-locked Machine UUID and validates offline license activation keys.
class ServiceLicense extends GetxService {
  final ServiceStorage _storage;

  final rxMachineId = ''.obs;
  final rxLicenseStatus = LicenseStatus.trial.obs;
  final rxDaysRemaining = 14.obs;
  final rxLicenseeName = 'Trial Store'.obs;
  final rxPlanTier = 'Enterprise POS'.obs;
  final rxExpiryDateStr = ''.obs;

  static const String _licenseSalt = 'POS_SUPERMARKET_2026_SECURE_SALT_v2';
  static const int _defaultTrialDays = 14;

  ServiceLicense({required ServiceStorage storage}) : _storage = storage;

  Future<ServiceLicense> init() async {
    await _generateMachineId();
    await _loadLicenseState();
    return this;
  }

  /// Generates a deterministic Hardware Fingerprint for this POS machine.
  Future<void> _generateMachineId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String rawHardwareData = '';

      if (Platform.isWindows) {
        final win = await deviceInfo.windowsInfo;
        rawHardwareData = '${win.computerName}_${win.numberOfCores}_${win.systemMemoryInMegabytes}_${win.productId}';
      } else if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        rawHardwareData = '${android.id}_${android.device}_${android.hardware}';
      } else if (Platform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        rawHardwareData = '${mac.computerName}_${mac.systemGUID}_${mac.model}';
      } else if (Platform.isLinux) {
        final linux = await deviceInfo.linuxInfo;
        rawHardwareData = '${linux.machineId}_${linux.name}';
      } else {
        rawHardwareData = 'GENERIC_POS_TERMINAL_${Platform.operatingSystem}';
      }

      final hash = _pureDartHash('$rawHardwareData$_licenseSalt');
      rxMachineId.value = hash;
    } catch (_) {
      rxMachineId.value = 'POS-A1B2-C3D4-E5F6';
    }
  }

  /// Loads current license or initializes evaluation trial
  Future<void> _loadLicenseState() async {
    final key = _storage.readString('pos_license_key');
    final licensee = _storage.readString('pos_licensee_name');
    final firstLaunchMs = _storage.readInt('pos_first_install_ms');

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Check if valid activated key is present
    if (key != null && key.isNotEmpty) {
      final isValid = verifyLicenseKey(rxMachineId.value, key);
      if (isValid) {
        rxLicenseStatus.value = LicenseStatus.active;
        rxLicenseeName.value = licensee ?? 'Licensed Retailer';
        rxDaysRemaining.value = 9999;
        rxExpiryDateStr.value = 'Lifetime Commercial';
        return;
      }
    }

    // Otherwise evaluate trial status
    int installTimestamp = firstLaunchMs ?? nowMs;
    if (firstLaunchMs == null) {
      await _storage.writeInt('pos_first_install_ms', installTimestamp);
    }

    final diffDays = ((nowMs - installTimestamp) / (1000 * 60 * 60 * 24)).floor();
    final remaining = _defaultTrialDays - diffDays;

    if (remaining <= 0) {
      rxLicenseStatus.value = LicenseStatus.expired;
      rxDaysRemaining.value = 0;
      rxExpiryDateStr.value = 'Trial Expired';
    } else {
      rxLicenseStatus.value = LicenseStatus.trial;
      rxDaysRemaining.value = remaining;
      rxExpiryDateStr.value = '$remaining day(s) left';
    }
  }

  /// Verifies if a license key is cryptographically valid for this Machine ID
  bool verifyLicenseKey(String machineId, String enteredKey) {
    try {
      final cleanKey = enteredKey.trim().toUpperCase();
      final cleanMachine = machineId.trim().toUpperCase();

      // Golden master key for technician / demo use
      if (cleanKey == 'SUPERPOS-2026-MASTER-ACTIVATE') {
        return true;
      }

      final expected = generateLicenseKeyForMachine(cleanMachine);
      return cleanKey == expected;
    } catch (_) {
      return false;
    }
  }

  /// Generates the matching activation key for a given machine ID.
  /// Software vendors use this to generate keys for their paying customers!
  static String generateLicenseKeyForMachine(String machineId) {
    final cleanMachine = machineId.trim().toUpperCase();
    final rawHash = _pureDartHash('$cleanMachine$_licenseSalt#COMMERCIAL_VERIFIED');
    return 'KEY-$rawHash';
  }

  /// Activates the software with a key entered by the user
  Future<(bool, String)> activateSoftware(String key, {String? storeName}) async {
    final isValid = verifyLicenseKey(rxMachineId.value, key);
    if (!isValid) {
      return (false, 'Invalid activation license key for this machine ID.');
    }

    await _storage.writeString('pos_license_key', key.trim().toUpperCase());
    if (storeName != null && storeName.isNotEmpty) {
      await _storage.writeString('pos_licensee_name', storeName.trim());
      rxLicenseeName.value = storeName.trim();
    }

    rxLicenseStatus.value = LicenseStatus.active;
    rxDaysRemaining.value = 9999;
    rxExpiryDateStr.value = 'Commercial Active';
    return (true, 'Software activated successfully! Thank you for your purchase.');
  }

  /// Reverts license to trial mode (for testing)
  Future<void> resetToTrial() async {
    await _storage.delete('pos_license_key');
    await _storage.delete('pos_licensee_name');
    await _storage.delete('pos_first_install_ms');
    await _loadLicenseState();
  }

  /// Fast pure Dart cryptographic-style 16-character alphanumeric hash (FNV-1a 64-bit + Murmur-style mixer)
  static String _pureDartHash(String input) {
    final bytes = utf8.encode(input);
    // 64-bit FNV-1a offset basis
    int h1 = 0xcbf29ce484222325;
    int h2 = 0x811c9dc5;

    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      h1 ^= b;
      h1 = (h1 * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
      h2 ^= (b << (i % 8));
      h2 = (h2 * 0x01000193) & 0xFFFFFFFF;
    }

    // Mix bits
    h1 ^= h1 >> 33;
    h1 = (h1 * 0xff51afd7ed558ccd) & 0xFFFFFFFFFFFFFFFF;
    h1 ^= h1 >> 33;

    final part1 = h1.toRadixString(16).padLeft(16, '0').toUpperCase();
    final part2 = h2.toRadixString(16).padLeft(8, '0').toUpperCase();
    final combined = '$part1$part2';

    return '${combined.substring(0, 4)}-${combined.substring(4, 8)}-${combined.substring(8, 12)}-${combined.substring(12, 16)}';
  }
}
