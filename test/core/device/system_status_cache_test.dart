import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/core/device/system_status_cache.dart';
import 'package:diubang_nasserver/core/runtime/runtime_presence_bridge.dart';

import '../../support/system_status_test_support.dart';

void main() {
  group('SystemStatusCache', () {
    test('refresh reports zero connected clients when server is not running',
        () async {
      await RuntimePresenceBridge.instance.publish(
        onlineDeviceIds: const ['tablet-01'],
        connectedCount: 1,
      );

      final cache = await createTestSystemStatusCache();

      await cache.refresh();

      expect(cache.connectedClients, 0);
    });
  });
}
