/// 文件输入：dart:io, network_info_plus
/// 文件职责：枚举局域网 IPv4 候选地址，并获取 WiFi 名称
/// 文件对外接口：NetworkInfoHelper
/// 文件包含：NetworkInfoHelper
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

import 'network_interface_candidate.dart';

class NetworkInfoHelper {
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<List<NetworkInterfaceCandidate>> listIpv4Candidates() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      final candidates = <NetworkInterfaceCandidate>[];
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type != InternetAddressType.IPv4 || address.isLoopback) {
            continue;
          }
          candidates.add(
            NetworkInterfaceCandidate(
              address: address.address,
              interfaceName: interface.name,
              isPrivate: _isPrivateIpv4(address.address),
            ),
          );
        }
      }

      candidates.sort((a, b) {
        final nameCompare = a.interfaceName.compareTo(b.interfaceName);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return a.address.compareTo(b.address);
      });

      return candidates;
    } catch (_) {
      return const [];
    }
  }

  @Deprecated('Use LocalNetworkAddressService instead.')
  Future<String?> getLocalIpv4Address() async {
    final candidates = await listIpv4Candidates();
    if (candidates.isEmpty) {
      return null;
    }
    for (final candidate in candidates) {
      if (candidate.isPrivate) {
        return candidate.address;
      }
    }
    return candidates.first.address;
  }

  Future<String?> getWifiName() async {
    try {
      final name = await _networkInfo.getWifiName();
      return name?.replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }

  bool _isPrivateIpv4(String address) {
    return address.startsWith('10.') ||
        address.startsWith('192.168.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(address);
  }
}
