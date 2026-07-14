import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/core/device/device_info_service.dart';

void main() {
  group('DeviceInfoService', () {
    test('getDeviceId uses localDeviceIdOverride', () async {
      final service = DeviceInfoService(localDeviceIdOverride: 'android-test-id');

      expect(await service.getDeviceId(), 'android-test-id');
    });

    test('defaultProductServerName matches app brand fallback', () {
      expect(DeviceInfoService.defaultProductServerName, '铥棒文件S');
    });
  });
}
