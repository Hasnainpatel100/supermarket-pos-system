import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UtilDevice {
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
