import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/features/api/handlers/dashboard_payload_builder.dart';

import '../../../support/system_status_test_support.dart';

void main() {
  group('DashboardPayloadBuilder', () {
    test('falls back to server ip when cache local ip is empty', () async {
      final cache = (await createTestSystemStatusCache())
        ..deviceId = 'device-1'
        ..model = 'Pixel 7'
        ..brand = 'google'
        ..systemVersion = '14'
        ..batteryLevel = 2
        ..batteryPercent = 88.5
        ..isCharging = true;

      final builder = DashboardPayloadBuilder(
        systemStatusCache: cache,
        port: 8080,
        startedAt: DateTime.utc(2026, 6, 5, 11),
        serverIpResolver: () => '192.168.1.50',
      );

      final payload = builder.build();

      expect(payload['network']['localIp'], '192.168.1.50');
    });
  });
}
