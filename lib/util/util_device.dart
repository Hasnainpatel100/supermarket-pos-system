import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../service/service_storage.dart';

class UtilDevice {
  /// Returns a stable unique hardware identifier for the current device.
  /// Persisted in [ServiceStorage] so it remains constant across app sessions.
  static Future<String> getDeviceId() async {
    try {
      if (Get.isRegistered<ServiceStorage>()) {
        final storage = Get.find<ServiceStorage>();
        final existingId = storage.readString('app_unique_device_id');
        if (existingId != null && existingId.trim().isNotEmpty) {
          return existingId.trim();
        }
      }

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? id;

      if (GetPlatform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        id = android.id;
      } else if (GetPlatform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        id = ios.identifierForVendor;
      } else if (GetPlatform.isWindows) {
        final windows = await deviceInfo.windowsInfo;
        id = windows.deviceId;
      } else if (GetPlatform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        id = mac.systemGUID;
      } else if (GetPlatform.isLinux) {
        final linux = await deviceInfo.linuxInfo;
        id = linux.machineId;
      } else if (GetPlatform.isWeb) {
        final web = await deviceInfo.webBrowserInfo;
        id = 'web_${web.userAgent.hashCode.toRadixString(16)}_${web.platform.hashCode.toRadixString(16)}';
      }

      if (id == null || id.trim().isEmpty) {
        final randomPart = Random().nextInt(999999).toString().padLeft(6, '0');
        id = 'device_${DateTime.now().millisecondsSinceEpoch}_$randomPart';
      }

      id = id.trim();

      if (Get.isRegistered<ServiceStorage>()) {
        await Get.find<ServiceStorage>().writeString('app_unique_device_id', id);
      }

      return id;
    } catch (e) {
      debugPrint("Error getting device ID: $e");
      final fallback = 'dev_${DateTime.now().millisecondsSinceEpoch}';
      try {
        if (Get.isRegistered<ServiceStorage>()) {
          await Get.find<ServiceStorage>().writeString('app_unique_device_id', fallback);
        }
      } catch (_) {}
      return fallback;
    }
  }

  static Future<String> getDeviceName() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (GetPlatform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return 'Android ${android.model} (SDK ${android.version.sdkInt})';
      }

      if (GetPlatform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return 'iOS ${ios.utsname.machine} (${ios.systemVersion})';
      }

      if (GetPlatform.isWindows) {
        final windows = await deviceInfo.windowsInfo;
        return 'Windows ${windows.majorVersion}.${windows.minorVersion} (${windows.computerName})';
      }

      if (GetPlatform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        return 'macOS ${mac.model} (${mac.osRelease})';
      }

      if (GetPlatform.isLinux) {
        final linux = await deviceInfo.linuxInfo;
        return 'Linux ${linux.prettyName} (${linux.machineId})';
      }

      if (GetPlatform.isWeb) {
        return 'Web Browser';
      }

      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  static Future<String> getIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var address in interface.addresses) {
          // Filter for IPv4 and ignore loopback (127.0.0.1)
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            return address.address;
          }
        }
      }
    } catch (e) {
      debugPrint("Error getting IP: $e");
    }
    return '0.0.0.0'; // Fallback
  }
}

