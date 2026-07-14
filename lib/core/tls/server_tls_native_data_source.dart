import 'package:flutter/services.dart';

class ServerTlsNativeMaterialRecord {
  const ServerTlsNativeMaterialRecord({
    required this.hostLabel,
    required this.rootCaPem,
    required this.leafCertificatePem,
    required this.leafPrivateKeyPem,
  });

  final String hostLabel;
  final String rootCaPem;
  final String leafCertificatePem;
  final String leafPrivateKeyPem;

  factory ServerTlsNativeMaterialRecord.fromMap(Map<dynamic, dynamic> map) {
    return ServerTlsNativeMaterialRecord(
      hostLabel: map['hostLabel'] as String? ?? '',
      rootCaPem: map['rootCaPem'] as String? ?? '',
      leafCertificatePem: map['leafCertificatePem'] as String? ?? '',
      leafPrivateKeyPem: map['leafPrivateKeyPem'] as String? ?? '',
    );
  }
}

abstract class ServerTlsNativeDataSource {
  Future<ServerTlsNativeMaterialRecord> ensureMaterial({
    required String serverId,
    required String hostLabel,
    required String localIp,
  });
}

class MethodChannelServerTlsNativeDataSource
    implements ServerTlsNativeDataSource {
  MethodChannelServerTlsNativeDataSource({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('com.diubang.nasserver/tls');

  final MethodChannel _channel;

  @override
  Future<ServerTlsNativeMaterialRecord> ensureMaterial({
    required String serverId,
    required String hostLabel,
    required String localIp,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'ensureTlsMaterial',
      <String, dynamic>{
        'serverId': serverId,
        'hostLabel': hostLabel,
        'localIp': localIp,
      },
    );
    if (result == null) {
      throw const FormatException('Native TLS material response was empty');
    }
    return ServerTlsNativeMaterialRecord.fromMap(result);
  }
}
