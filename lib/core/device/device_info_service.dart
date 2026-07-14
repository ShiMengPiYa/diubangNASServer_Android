/// 文件输入：MethodChannel（Android Build 信息）
/// 文件职责：获取 Android 设备信息（型号、品牌、系统版本、电量、充电状态）
/// 文件对外接口：DeviceInfoService
/// 文件包含：DeviceInfoService, DeviceInfo
import 'package:flutter/services.dart';

class DeviceInfoService {
  DeviceInfoService({
    MethodChannel? channel,
    String? localDeviceNameOverride,
    String? localDeviceIdOverride,
  }) : _channel =
           channel ??
           const MethodChannel('com.diubang.nasserver/device_info'),
       _localDeviceNameOverride = localDeviceNameOverride,
       _localDeviceIdOverride = localDeviceIdOverride;

  static const defaultProductServerName = '铥棒文件S';

  final MethodChannel _channel;
  final String? _localDeviceNameOverride;
  final String? _localDeviceIdOverride;

  Future<DeviceInfo> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      if (result != null) {
        return DeviceInfo(
          deviceId: result['deviceId'] as String? ?? 'unknown',
          deviceName: result['deviceName'] as String? ?? 'Unknown Device',
          model: result['model'] as String? ?? 'Unknown',
          brand: result['brand'] as String? ?? 'Unknown',
          manufacturer: result['manufacturer'] as String? ?? 'Unknown',
          systemVersion: result['systemVersion'] as String? ?? 'Unknown',
          batteryLevel: result['batteryLevel'] as int? ?? 1,
          batteryPercent: (result['batteryPercent'] as num?)?.toDouble() ?? 0.0,
          isCharging: result['isCharging'] as bool? ?? false,
        );
      }
    } catch (e) {
      // Fallback to basic info if platform channel fails
    }
    return DeviceInfo(
      deviceId: _localDeviceIdOverride ?? 'nas-server-001',
      deviceName: _resolveFallbackDeviceName(),
      model: 'Android Device',
      brand: 'Unknown',
      manufacturer: 'Unknown',
      systemVersion: 'Unknown',
      batteryLevel: 1,
      batteryPercent: 0.0,
      isCharging: false,
    );
  }

  Future<String> getDeviceId() async {
    final override = _localDeviceIdOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    try {
      final result = await _channel.invokeMethod<String>('getAndroidId');
      return result ?? 'nas-server-001';
    } catch (e) {
      return 'nas-server-001';
    }
  }

  Future<String> getModel() async {
    try {
      final result = await _channel.invokeMethod<String>('getModel');
      return result ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> getSystemVersion() async {
    try {
      final result = await _channel.invokeMethod<String>('getSystemVersion');
      return result ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _resolveFallbackDeviceName() {
    final override = _localDeviceNameOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return defaultProductServerName;
  }
}

class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String model;
  final String brand;
  final String manufacturer;
  final String systemVersion;
  final int batteryLevel;
  final double batteryPercent;
  final bool isCharging;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.model,
    required this.brand,
    required this.manufacturer,
    required this.systemVersion,
    required this.batteryLevel,
    required this.batteryPercent,
    required this.isCharging,
  });
}
