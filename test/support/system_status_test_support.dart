import 'package:diubang_nasserver/core/device/device_info_service.dart';
import 'package:diubang_nasserver/core/device/local_network_address_service.dart';
import 'package:diubang_nasserver/core/device/network_info_helper.dart';
import 'package:diubang_nasserver/core/device/system_info_service.dart';
import 'package:diubang_nasserver/core/device/system_status_cache.dart';
import 'package:diubang_nasserver/core/storage/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalNetworkAddressService> createTestLocalNetworkAddressService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return LocalNetworkAddressService(
    keyValueStore: KeyValueStore(sharedPreferences: prefs),
    networkInfoHelper: NetworkInfoHelper(),
  );
}

Future<SystemStatusCache> createTestSystemStatusCache() async {
  return SystemStatusCache(
    deviceInfoService: DeviceInfoService(),
    systemInfoService: SystemInfoService(),
    localNetworkAddressService: await createTestLocalNetworkAddressService(),
  );
}
