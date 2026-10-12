import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/model/model_registered_device.dart';

void main() {
  group('ModelRegisteredDevice Tests', () {
    test('Serializes to JSON and deserializes correctly', () {
      const device = ModelRegisteredDevice(
        deviceId: 'device_win_123',
        deviceName: 'Windows 11 (DESKTOP-POS-1)',
        registeredAt: '2026-10-12T10:00:00.000Z',
        ipAddress: '192.168.1.100',
      );

      final json = device.toJson();
      expect(json['deviceId'], 'device_win_123');
      expect(json['deviceName'], 'Windows 11 (DESKTOP-POS-1)');
      expect(json['registeredAt'], '2026-10-12T10:00:00.000Z');
      expect(json['ipAddress'], '192.168.1.100');

      final fromJson = ModelRegisteredDevice.fromJson(json);
      expect(fromJson.deviceId, device.deviceId);
      expect(fromJson.deviceName, device.deviceName);
      expect(fromJson.registeredAt, device.registeredAt);
      expect(fromJson.ipAddress, device.ipAddress);
    });

    test('Device equality is based on deviceId', () {
      const device1 = ModelRegisteredDevice(
        deviceId: 'unique_id_1',
        deviceName: 'Device A',
        registeredAt: '2026-10-12T10:00:00.000Z',
      );
      const device2 = ModelRegisteredDevice(
        deviceId: 'unique_id_1',
        deviceName: 'Device A Renamed',
        registeredAt: '2026-10-12T11:00:00.000Z',
      );
      const device3 = ModelRegisteredDevice(
        deviceId: 'unique_id_2',
        deviceName: 'Device B',
        registeredAt: '2026-10-12T10:00:00.000Z',
      );

      expect(device1 == device2, isTrue);
      expect(device1 == device3, isFalse);
    });

    test('Device limit enforcement logic simulation', () {
      const maxPosDevices = 2;
      final registered = <ModelRegisteredDevice>[
        const ModelRegisteredDevice(
          deviceId: 'dev_1',
          deviceName: 'POS Counter 1',
          registeredAt: '2026-10-01T00:00:00.000Z',
        ),
        const ModelRegisteredDevice(
          deviceId: 'dev_2',
          deviceName: 'POS Counter 2',
          registeredAt: '2026-10-02T00:00:00.000Z',
        ),
      ];

      // 1. Existing device check: 'dev_1' is already registered -> Allowed
      const currentDeviceId1 = 'dev_1';
      final isAlreadyRegistered = registered.any((d) => d.deviceId == currentDeviceId1);
      expect(isAlreadyRegistered, isTrue);

      // 2. New device 'dev_3' check: count is 2, max is 2 -> Blocked!
      const currentDeviceId2 = 'dev_3';
      final isDev3Registered = registered.any((d) => d.deviceId == currentDeviceId2);
      expect(isDev3Registered, isFalse);
      final canDev3Register = registered.length < maxPosDevices;
      expect(canDev3Register, isFalse); // Limit reached

      // 3. User removes 'dev_1' from registered devices:
      registered.removeWhere((d) => d.deviceId == 'dev_1');
      expect(registered.length, 1);

      // 4. Now 'dev_3' can register:
      final canDev3RegisterAfterRemoval = registered.length < maxPosDevices;
      expect(canDev3RegisterAfterRemoval, isTrue);

      registered.add(const ModelRegisteredDevice(
        deviceId: currentDeviceId2,
        deviceName: 'POS Counter 3',
        registeredAt: '2026-10-12T12:00:00.000Z',
      ));
      expect(registered.length, 2);
      expect(registered.any((d) => d.deviceId == 'dev_3'), isTrue);
    });
  });
}
