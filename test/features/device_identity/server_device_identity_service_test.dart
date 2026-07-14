import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/core/device/device_info_service.dart';
import 'package:diubang_nasserver/core/device_registry/device_avatar_store.dart';
import 'package:diubang_nasserver/core/device_registry/device_store.dart';
import 'package:diubang_nasserver/core/profile/device_identity_store.dart';
import 'package:diubang_nasserver/core/storage/key_value_store.dart';
import 'package:diubang_nasserver/features/device_identity/domain/server_device_identity_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_support/device_store_harness.dart';

class _StubDeviceInfoService extends DeviceInfoService {
  _StubDeviceInfoService({
    required String deviceId,
    this.deviceName = 'My Android Phone',
  }) : _deviceId = deviceId,
       super(
         localDeviceIdOverride: deviceId,
         localDeviceNameOverride: deviceName,
       );

  final String _deviceId;
  final String deviceName;

  @override
  Future<String> getDeviceId() async => _deviceId;

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    return DeviceInfo(
      deviceId: _deviceId,
      deviceName: deviceName,
      model: deviceName,
      brand: 'google',
      manufacturer: 'google',
      systemVersion: '14',
      batteryLevel: 3,
      batteryPercent: 80,
      isCharging: false,
    );
  }
}

Future<({ServerDeviceIdentityService service, DeviceStore deviceStore})>
_createFixture({
  required TestDeviceStoreHarness harness,
  required String hostPhysicalId,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final deviceStore = harness.createDeviceStore();
  await deviceStore.initialize();
  final tempDir = await Directory.systemTemp.createTemp('identity_test_');
  final service = ServerDeviceIdentityService(
    deviceStore: deviceStore,
    avatarStore: DeviceAvatarStore(
      avatarDirectoryPath: p.join(tempDir.path, 'device_avatars'),
    ),
    identityStore: DeviceIdentityStore(
      keyValueStore: KeyValueStore(sharedPreferences: prefs),
    ),
    deviceInfoService: _StubDeviceInfoService(deviceId: hostPhysicalId),
  );
  return (service: service, deviceStore: deviceStore);
}

void main() {
  group('ServerDeviceIdentityService.listEnrolledClientDevices', () {
    test('excludes host when host and clients are enrolled', () async {
      final harness = await TestDeviceStoreHarness.create();
      addTearDown(harness.dispose);
      final fixture = await _createFixture(
        harness: harness,
        hostPhysicalId: 'host-physical-01',
      );

      await fixture.deviceStore.enrollDevice(
        deviceId: 'host-physical-01',
        deviceName: 'NAS Host',
        physicalDeviceId: 'host-physical-01',
      );
      await fixture.deviceStore.enrollDevice(
        deviceId: 'phone-01',
        deviceName: 'Phone One',
        physicalDeviceId: 'phone-physical-01',
      );
      await fixture.deviceStore.enrollDevice(
        deviceId: 'tablet-01',
        deviceName: 'Tablet One',
        physicalDeviceId: 'tablet-physical-01',
      );

      final clients = await fixture.service.listEnrolledClientDevices();

      expect(clients.length, 2);
      expect(
        clients.map((device) => device.deviceId).toList(),
        containsAll(['phone-01', 'tablet-01']),
      );
    });

    test('returns all devices when host is not enrolled', () async {
      final harness = await TestDeviceStoreHarness.create();
      addTearDown(harness.dispose);
      final fixture = await _createFixture(
        harness: harness,
        hostPhysicalId: 'host-physical-01',
      );

      await fixture.deviceStore.enrollDevice(
        deviceId: 'phone-01',
        deviceName: 'Phone One',
        physicalDeviceId: 'phone-physical-01',
      );
      await fixture.deviceStore.enrollDevice(
        deviceId: 'tablet-01',
        deviceName: 'Tablet One',
        physicalDeviceId: 'tablet-physical-01',
      );

      final clients = await fixture.service.listEnrolledClientDevices();
      final allDevices = await fixture.deviceStore.listDevices();

      expect(clients.length, allDevices.length);
      expect(
        clients.map((device) => device.deviceId).toList(),
        containsAll(allDevices.map((device) => device.deviceId)),
      );
    });
  });

  group('ServerDeviceIdentityService.resolveDisplayName', () {
    test('prefers system device name over stale brand-default host record',
        () async {
      final harness = await TestDeviceStoreHarness.create();
      addTearDown(harness.dispose);
      final fixture = await _createFixture(
        harness: harness,
        hostPhysicalId: 'host-physical-01',
      );

      await fixture.deviceStore.enrollDevice(
        deviceId: 'host-physical-01',
        deviceName: ServerDeviceIdentityService.kDefaultProductServerName,
        physicalDeviceId: 'host-physical-01',
      );

      final name = await fixture.service.resolveDisplayName();

      expect(name, 'My Android Phone');
    });

    test('migrates stale host device_name during syncFromHostRecord', () async {
      final harness = await TestDeviceStoreHarness.create();
      addTearDown(harness.dispose);
      final fixture = await _createFixture(
        harness: harness,
        hostPhysicalId: 'host-physical-01',
      );

      await fixture.deviceStore.enrollDevice(
        deviceId: 'host-physical-01',
        deviceName: ServerDeviceIdentityService.kDefaultProductServerName,
        physicalDeviceId: 'host-physical-01',
      );

      await fixture.service.syncFromHostRecord();

      final host = await fixture.deviceStore.findDeviceByPhysicalId(
        'host-physical-01',
      );
      expect(host?.deviceName, 'My Android Phone');
    });

    test('registers host lazily when updating alias before server start',
        () async {
      final harness = await TestDeviceStoreHarness.create();
      addTearDown(harness.dispose);
      final fixture = await _createFixture(
        harness: harness,
        hostPhysicalId: 'host-physical-01',
      );

      await fixture.service.updateDisplayAlias('客厅 NAS');

      final host = await fixture.deviceStore.findDeviceByPhysicalId(
        'host-physical-01',
      );
      expect(host, isNotNull);
      expect(host!.label, '客厅 NAS');
      expect(host.deviceName, 'My Android Phone');
    });
  });
}
