/// 文件输入：permission_handler
/// 文件职责：封装 Android 权限申请逻辑，按 API 等级选择存储权限模型
/// 文件对外接口：PermissionService
/// 文件包含：PermissionService
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService();

  static const MethodChannel _deviceInfoChannel = MethodChannel(
    'com.diubang.nasserver/device_info',
  );

  /// Android 11 (API 30) introduces MANAGE_EXTERNAL_STORAGE.
  static const int _manageExternalStorageMinSdk = 30;

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final sdkInt = await _androidSdkInt();
    if (sdkInt >= _manageExternalStorageMinSdk) {
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      }
      if (manageStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }

    // Android 10 and below: classic READ/WRITE_EXTERNAL_STORAGE.
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return true;
    }
    if (storageStatus.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final sdkInt = await _androidSdkInt();
    if (sdkInt >= _manageExternalStorageMinSdk) {
      final manageStatus = await Permission.manageExternalStorage.status;
      return manageStatus.isGranted;
    }

    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  Future<bool> checkNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> requestAllPermissions() async {
    final locationGranted = await requestLocationPermission();
    final storageGranted = await requestStoragePermission();
    final notificationGranted = await requestNotificationPermission();
    return locationGranted && storageGranted && notificationGranted;
  }

  /// Falls back to 29 so we prefer classic storage permission when unknown.
  Future<int> _androidSdkInt() async {
    try {
      final result = await _deviceInfoChannel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      final sdk = result?['sdkInt'];
      if (sdk is int) {
        return sdk;
      }
      if (sdk is num) {
        return sdk.toInt();
      }
    } catch (_) {
      // Fall through to conservative default.
    }
    return 29;
  }
}
