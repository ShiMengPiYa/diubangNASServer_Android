import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/features/api/handlers/dashboard_handler.dart';
import 'package:diubang_nasserver/features/api/handlers/dashboard_payload_builder.dart';
import 'package:shelf/shelf.dart';

import '../../../support/system_status_test_support.dart';

void main() {
  group('DashboardHandler', () {
    test('returns contract fields for battery, uptime, memory and build info', () async {
      final cache = await createTestSystemStatusCache();
      cache.deviceId = 'device-1';
      cache.model = 'Pixel 7';
      cache.brand = 'google';
      cache.systemVersion = '14';
      cache.batteryLevel = 2;
      cache.batteryPercent = 88.5;
      cache.isCharging = true;
      cache.totalStorage = 128000;
      cache.usedStorage = 64000;
      cache.totalMemory = 8192;
      cache.usedMemory = 4096;
      cache.cpuTemperature = 42.5;
      cache.localIp = '192.168.1.10';
      cache.lastUpdated = DateTime.utc(2024, 3, 24, 12);
      cache.isInitialized.value = true;

      final startedAt = DateTime.now().subtract(const Duration(minutes: 2));
      final handler = DashboardHandler(
        payloadBuilder: DashboardPayloadBuilder(
          systemStatusCache: cache,
          port: 9090,
          startedAt: startedAt,
        ),
      );

      final response = await handler.handler(
        Request('GET', Uri.parse('http://localhost/api/v1/dashboard')),
      );
      final payload =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(payload['device']['brand'], 'google');
      expect(payload['device']['model'], 'Pixel 7');
      expect(payload['device']['batteryLevel'], 2);
      expect(payload['device']['batteryPercent'], 88.5);
      expect(payload['network']['localIp'], '192.168.1.10');
      expect(payload['system']['memory']['totalBytes'], 8192);
      expect(payload['system']['uptime'], greaterThanOrEqualTo(120));
      expect(payload['server']['build']['appVersion'], isNotEmpty);
      expect(payload['server']['build']['buildSha'], isNotEmpty);
      expect(payload['server']['build']['buildTime'], isNotEmpty);
    });

    test('returns 503 when dashboard cache is not initialized', () async {
      final cache = await createTestSystemStatusCache();
      final handler = DashboardHandler(
        systemStatusCache: cache,
        port: 9090,
        startedAt: DateTime.utc(2026, 6, 5),
      );

      final response = await handler.handler(
        Request('GET', Uri.parse('http://localhost/api/v1/dashboard')),
      );
      final payload =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 503);
      expect(payload['code'], 'DASHBOARD_NOT_READY');
    });

    test('returns populated device and network fields after initialize', () async {
      final cache = (await createTestSystemStatusCache())
        ..deviceId = 'android-device-001'
        ..model = 'SM-G988U'
        ..brand = 'samsung'
        ..systemVersion = '13'
        ..batteryLevel = 2
        ..batteryPercent = 85.0
        ..isCharging = true
        ..localIp = '192.168.1.100'
        ..totalStorage = 64000000000
        ..usedStorage = 32000000000
        ..totalMemory = 8000000000
        ..usedMemory = 4000000000
        ..lastUpdated = DateTime.utc(2026, 6, 5, 12)
        ..isInitialized.value = true;

      final handler = DashboardHandler(
        payloadBuilder: DashboardPayloadBuilder(
          systemStatusCache: cache,
          port: 8080,
          startedAt: DateTime.utc(2026, 6, 5, 11),
        ),
      );

      final response = await handler.handler(
        Request('GET', Uri.parse('http://localhost/api/v1/dashboard')),
      );
      final payload =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(payload['device']['brand'], isNotEmpty);
      expect(payload['device']['model'], isNotEmpty);
      expect(payload['device']['batteryPercent'], greaterThan(0));
      expect(payload['network']['localIp'], isNot(''));
      expect(payload['network']['port'], 8080);
    });
  });
}
