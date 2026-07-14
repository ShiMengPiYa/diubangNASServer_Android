/// 文件输入：MethodChannel
/// 文件职责：封装 NsdManager 原生平台的 mDNS 服务注册/注销调用
/// 文件对外接口：NsdManagerPlugin
/// 文件包含：NsdManagerPlugin
import 'package:flutter/services.dart';

import 'broadcast_display_name_policy.dart';

class NsdManagerPlugin {
  static const MethodChannel _channel = MethodChannel(
    'com.diubang.nasserver/nsd',
  );

  static Future<Map<String, dynamic>> registerService({
    required String serviceName,
    String serviceType = '_webdavs._tcp.',
    required int port,
    Map<String, String> txtRecords = const {},
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'registerService',
        {
          'serviceName': serviceName,
          'serviceType': serviceType,
          'port': port,
          'txtRecords': txtRecords,
        },
      );
      return {
        'success': true,
        'serviceName': result?['serviceName'] ?? serviceName,
      };
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> registerServiceWithDisambiguation({
    required String serviceName,
    required String physicalDeviceId,
    String serviceType = '_webdavs._tcp.',
    required int port,
    Map<String, String> txtRecords = const {},
  }) async {
    final firstAttempt = await registerService(
      serviceName: serviceName,
      serviceType: serviceType,
      port: port,
      txtRecords: txtRecords,
    );
    if (firstAttempt['success'] == true) {
      return firstAttempt;
    }
    if (!_shouldRetryWithSuffix(firstAttempt)) {
      return firstAttempt;
    }

    final disambiguated = BroadcastDisplayNamePolicy.disambiguate(
      serviceName,
      physicalDeviceId,
    );
    if (disambiguated == serviceName) {
      return firstAttempt;
    }

    await unregisterService();
    return registerService(
      serviceName: disambiguated,
      serviceType: serviceType,
      port: port,
      txtRecords: txtRecords,
    );
  }

  static bool _shouldRetryWithSuffix(Map<String, dynamic> result) {
    if (result['success'] == true) {
      return false;
    }
    final error = '${result['error'] ?? ''}'.toLowerCase();
    return error.contains('冲突') ||
        error.contains('already exists') ||
        error.contains('registration_failed') ||
        error.contains('namealreadyexists');
  }

  static Future<Map<String, dynamic>> unregisterService() async {
    try {
      await _channel.invokeMethod('unregisterService');
      return {'success': true};
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}
