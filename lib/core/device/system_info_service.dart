/// 文件输入：dart:io, method_channel
/// 文件职责：获取设备真实系统数据（存储、内存、CPU温度）
/// 文件对外接口：SystemInfoService
/// 文件包含：SystemInfoService, SystemStats
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class SystemInfoService {
  static const MethodChannel _channel = MethodChannel(
    'com.diubang.nasserver/system_info',
  );

  Future<SystemStats> getSystemStats() async {
    final results = await Future.wait([
      queryStorageUsage(),
      queryMemoryUsage(),
      queryCpuTemperature(),
    ]);

    return SystemStats(
      storageUsage: results[0] as StorageUsage,
      memoryUsage: results[1] as MemoryUsage,
      cpuTemperatureLevel: results[2] as CpuTemperatureLevel,
    );
  }

  Future<StorageUsage> queryStorageUsage() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('getStorageInfo');
        if (result != null) {
          return StorageUsage(
            totalBytes: result['totalBytes'] as int,
            usedBytes: result['usedBytes'] as int,
            usagePercent: result['usagePercent'] as double,
          );
        }
      }

      final stat = await Process.run('df', ['/sdcard']);
      final lines = stat.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final total = int.tryParse(parts[1]) ?? 0;
          final used = int.tryParse(parts[2]) ?? 0;
          final usagePercent = total > 0 ? (used / total) * 100 : 0.0;
          return StorageUsage(
            totalBytes: total * 1024,
            usedBytes: used * 1024,
            usagePercent: usagePercent,
          );
        }
      }
    } catch (e) {
      // ignore
    }

    return const StorageUsage(totalBytes: 0, usedBytes: 0, usagePercent: 0);
  }

  Future<MemoryUsage> queryMemoryUsage() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('getMemoryInfo');
        if (result != null) {
          return MemoryUsage(
            totalBytes: result['totalBytes'] as int,
            usedBytes: result['usedBytes'] as int,
            usagePercent: result['usagePercent'] as double,
          );
        }
      }

      final stat = await Process.run('cat', ['/proc/meminfo']);
      final lines = stat.stdout.toString().split('\n');
      int memTotal = 0;
      int memFree = 0;
      int buffers = 0;
      int cached = 0;

      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          memTotal = _parseMemValue(line);
        } else if (line.startsWith('MemFree:')) {
          memFree = _parseMemValue(line);
        } else if (line.startsWith('Buffers:')) {
          buffers = _parseMemValue(line);
        } else if (line.startsWith('Cached:')) {
          cached = _parseMemValue(line);
        }
      }

      final memAvailable = memFree + buffers + cached;
      final usedBytes = memTotal - memAvailable;
      final usagePercent = memTotal > 0 ? (usedBytes / memTotal) * 100 : 0.0;

      return MemoryUsage(
        totalBytes: memTotal * 1024,
        usedBytes: usedBytes * 1024,
        usagePercent: usagePercent,
      );
    } catch (e) {
      return const MemoryUsage(totalBytes: 0, usedBytes: 0, usagePercent: 0);
    }
  }

  int _parseMemValue(String line) {
    final match = RegExp(r'(\d+)').firstMatch(line);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<CpuTemperatureLevel> queryCpuTemperature() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('getCpuTemperature');
        if (result != null) {
          final temp = (result['temperature'] as num).toDouble();
          return CpuTemperatureLevel.fromTemperature(temp);
        }
      }

      final thermalDir = Directory('/sys/class/thermal');
      if (await thermalDir.exists()) {
        final zones = await thermalDir.list().toList();
        for (final zone in zones) {
          if (zone is Directory && zone.path.contains('thermal_zone')) {
            final tempFile = File('${zone.path}/temp');
            if (await tempFile.exists()) {
              final content = await tempFile.readAsString();
              final temp = int.tryParse(content.trim());
              if (temp != null) {
                return CpuTemperatureLevel.fromTemperature(temp / 1000.0);
              }
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }

    return CpuTemperatureLevel.unknown;
  }

  Duration getUptime() {
    try {
      final stat = File('/proc/uptime');
      if (stat.existsSync()) {
        final content = stat.readAsStringSync().split(' ')[0];
        final seconds = double.tryParse(content);
        if (seconds != null) {
          return Duration(seconds: seconds.toInt());
        }
      }
    } catch (e) {
      // ignore
    }
    return Duration.zero;
  }
}

class SystemStats {
  final StorageUsage storageUsage;
  final MemoryUsage memoryUsage;
  final CpuTemperatureLevel cpuTemperatureLevel;

  const SystemStats({
    required this.storageUsage,
    required this.memoryUsage,
    required this.cpuTemperatureLevel,
  });
}

class StorageUsage {
  final int totalBytes;
  final int usedBytes;
  final double usagePercent;

  const StorageUsage({
    required this.totalBytes,
    required this.usedBytes,
    required this.usagePercent,
  });
}

class MemoryUsage {
  final int totalBytes;
  final int usedBytes;
  final double usagePercent;

  const MemoryUsage({
    required this.totalBytes,
    required this.usedBytes,
    required this.usagePercent,
  });
}

enum CpuTemperatureLevel {
  low,
  normal,
  high,
  unknown;

  static CpuTemperatureLevel fromTemperature(double temp) {
    if (temp <= 0) return unknown;
    if (temp < 40) return low;
    if (temp < 60) return normal;
    return high;
  }

  String get displayName {
    switch (this) {
      case CpuTemperatureLevel.low:
        return '低';
      case CpuTemperatureLevel.normal:
        return '正常';
      case CpuTemperatureLevel.high:
        return '高';
      case CpuTemperatureLevel.unknown:
        return '未知';
    }
  }
}
