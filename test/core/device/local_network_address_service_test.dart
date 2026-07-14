import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/core/device/local_network_address_service.dart';
import 'package:diubang_nasserver/core/device/local_network_resolution.dart';
import 'package:diubang_nasserver/core/device/network_info_helper.dart';
import 'package:diubang_nasserver/core/device/network_interface_candidate.dart';
import 'package:diubang_nasserver/core/storage/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalNetworkAddressService', () {
    late KeyValueStore keyValueStore;
    late _FakeNetworkInfoHelper networkInfoHelper;
    late LocalNetworkAddressService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      keyValueStore = KeyValueStore(sharedPreferences: prefs);
      networkInfoHelper = _FakeNetworkInfoHelper();
      service = LocalNetworkAddressService(
        keyValueStore: keyValueStore,
        networkInfoHelper: networkInfoHelper,
      );
    });

    test('multiple candidates without saved ip needs selection', () async {
      networkInfoHelper.candidates = const [
        NetworkInterfaceCandidate(
          address: '192.168.1.10',
          interfaceName: 'wlan0',
          isPrivate: true,
        ),
        NetworkInterfaceCandidate(
          address: '10.8.0.2',
          interfaceName: 'tun0',
          isPrivate: true,
        ),
      ];

      final resolution = await service.resolveForServerStart();

      expect(resolution, isA<LocalNetworkNeedsSelection>());
      final needsSelection = resolution as LocalNetworkNeedsSelection;
      expect(needsSelection.candidates, hasLength(2));
    });

    test('multiple candidates with valid saved ip resolves', () async {
      await keyValueStore.setString(
        LocalNetworkAddressService.preferredLocalIpv4Key,
        '10.8.0.2',
      );
      await service.initialize();

      networkInfoHelper.candidates = const [
        NetworkInterfaceCandidate(
          address: '192.168.1.10',
          interfaceName: 'wlan0',
          isPrivate: true,
        ),
        NetworkInterfaceCandidate(
          address: '10.8.0.2',
          interfaceName: 'tun0',
          isPrivate: true,
        ),
      ];

      final resolution = await service.resolveForServerStart();

      expect(resolution, isA<LocalNetworkResolved>());
      expect((resolution as LocalNetworkResolved).ip, '10.8.0.2');
    });

    test('single candidate auto selects and persists', () async {
      networkInfoHelper.candidates = const [
        NetworkInterfaceCandidate(
          address: '192.168.1.10',
          interfaceName: 'wlan0',
          isPrivate: true,
        ),
      ];

      final resolution = await service.resolveForServerStart();

      expect(resolution, isA<LocalNetworkResolved>());
      expect((resolution as LocalNetworkResolved).ip, '192.168.1.10');
      expect(service.effectiveIp, '192.168.1.10');
      expect(
        keyValueStore.getString(LocalNetworkAddressService.preferredLocalIpv4Key),
        '192.168.1.10',
      );
    });

    test('saved ip missing from refreshed list needs selection', () async {
      await keyValueStore.setString(
        LocalNetworkAddressService.preferredLocalIpv4Key,
        '172.16.0.5',
      );
      await service.initialize();

      networkInfoHelper.candidates = const [
        NetworkInterfaceCandidate(
          address: '192.168.1.10',
          interfaceName: 'wlan0',
          isPrivate: true,
        ),
      ];

      final resolution = await service.resolveForServerStart();

      expect(resolution, isA<LocalNetworkNeedsSelection>());
      expect(service.isSavedIpStillAvailable(), isFalse);
    });

    test('setSelectedIp notifies listeners', () async {
      var notifications = 0;
      service.addListener(() {
        notifications += 1;
      });

      await service.setSelectedIp('192.168.1.20');

      expect(service.effectiveIp, '192.168.1.20');
      expect(notifications, 1);
    });
  });
}

class _FakeNetworkInfoHelper extends NetworkInfoHelper {
  List<NetworkInterfaceCandidate> candidates = const [];

  @override
  Future<List<NetworkInterfaceCandidate>> listIpv4Candidates() async {
    return candidates;
  }
}
