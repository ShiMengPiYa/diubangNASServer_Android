// 文件输入：Android MethodChannel power_management
// 文件职责：查询和申请 Android 电池优化豁免，保证后台/熄屏时服务可用
// 文件对外接口：BatteryOptimizationService
// 文件包含：BatteryOptimizationService
import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const _channel = MethodChannel(
    'com.diubang.nasserver/power_management',
  );

  const BatteryOptimizationService();

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimizations',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> openAppManagementSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openAppManagementSettings',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
