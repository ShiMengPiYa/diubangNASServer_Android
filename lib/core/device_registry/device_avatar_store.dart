import 'dart:io';

import 'package:path/path.dart' as p;

import '../debug/avatar_diag_log.dart';
import '../profile/device_avatar_constraints.dart';
import '../storage/share_internal_paths.dart';

class DeviceAvatarStore {
  DeviceAvatarStore({required String avatarDirectoryPath})
    : _avatarDirectoryPath = avatarDirectoryPath;

  static const maxAvatarBytes = DeviceAvatarConstraints.maxStoredBytes;

  final String _avatarDirectoryPath;

  Directory get avatarDirectory => Directory(_avatarDirectoryPath);

  String avatarFilePath(String deviceId) {
    return p.join(_avatarDirectoryPath, '${deviceId.trim()}.jpg');
  }

  Future<DateTime?> readUpdatedAt(String deviceId) async {
    final file = File(avatarFilePath(deviceId));
    if (!await file.exists()) {
      return null;
    }
    return (await file.lastModified()).toUtc();
  }

  DateTime? readUpdatedAtSync(String deviceId) {
    final file = File(avatarFilePath(deviceId));
    if (!file.existsSync()) {
      return null;
    }
    return file.lastModifiedSync().toUtc();
  }

  Future<bool> hasAvatar(String deviceId) async {
    return File(avatarFilePath(deviceId)).exists();
  }

  Future<List<int>?> readAvatarBytes(String deviceId) async {
    final normalized = deviceId.trim();
    final file = File(avatarFilePath(normalized));
    try {
      if (!await file.exists()) {
        logAvatarDiag('read miss deviceId=$normalized path=${file.path}');
        return null;
      }
      final bytes = await file.readAsBytes();
      final mtime = (await file.lastModified()).toUtc();
      logAvatarDiag(
        'read hit deviceId=$normalized bytes=${bytes.length} '
        'mtime=${mtime.toIso8601String()} path=${file.path}',
      );
      return bytes;
    } on FileSystemException catch (error, stackTrace) {
      logAvatarDiag(
        'read FAIL deviceId=$normalized type=${error.runtimeType} '
        'osError=${error.osError} message=${error.message} path=${error.path}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<DateTime> saveAvatar({
    required String deviceId,
    required List<int> bytes,
  }) async {
    final normalized = deviceId.trim();
    if (bytes.isEmpty) {
      throw ArgumentError('Avatar bytes must not be empty');
    }
    if (bytes.length > maxAvatarBytes) {
      throw ArgumentError(
        'Avatar exceeds maximum size of ${maxAvatarBytes ~/ 1024}KB',
      );
    }
    final directory = avatarDirectory;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File(avatarFilePath(normalized));
    DateTime? priorMtime;
    try {
      if (await file.exists()) {
        priorMtime = (await file.lastModified()).toUtc();
      }
      final sw = Stopwatch()..start();
      await file.writeAsBytes(bytes, flush: true);
      sw.stop();
      final rawMtime = (await file.lastModified()).toUtc();
      final advanced =
          priorMtime == null || rawMtime.isAfter(priorMtime);
      logAvatarDiag(
        'save deviceId=$normalized bytes=${bytes.length} '
        'writeMs=${sw.elapsedMilliseconds} '
        'priorMtime=${priorMtime?.toIso8601String() ?? 'null'} '
        'rawMtime=${rawMtime.toIso8601String()} '
        'returned=${rawMtime.toIso8601String()} advanced=$advanced '
        'path=${file.path}',
      );
      return rawMtime;
    } on FileSystemException catch (error, stackTrace) {
      logAvatarDiag(
        'save FAIL deviceId=$normalized bytes=${bytes.length} '
        'type=${error.runtimeType} osError=${error.osError} '
        'message=${error.message} path=${error.path}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteAvatar(String deviceId) async {
    final normalized = deviceId.trim();
    final file = File(avatarFilePath(normalized));
    try {
      if (await file.exists()) {
        await file.delete();
        logAvatarDiag('delete ok deviceId=$normalized path=${file.path}');
      } else {
        logAvatarDiag('delete miss deviceId=$normalized path=${file.path}');
      }
    } on FileSystemException catch (error, stackTrace) {
      logAvatarDiag(
        'delete FAIL deviceId=$normalized type=${error.runtimeType} '
        'osError=${error.osError} message=${error.message} path=${error.path}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> migrateFromLegacyStorageRoot(String legacyStorageRoot) async {
    final legacyDirectory = Directory(
      p.join(legacyStorageRoot, deviceAvatarLegacyFolderName),
    );
    if (!await legacyDirectory.exists()) {
      return;
    }

    if (!await avatarDirectory.exists()) {
      await avatarDirectory.create(recursive: true);
    }

    await for (final entity in legacyDirectory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final fileName = p.basename(entity.path);
      if (!fileName.toLowerCase().endsWith('.jpg')) {
        continue;
      }
      final targetFile = File(p.join(_avatarDirectoryPath, fileName));
      if (await targetFile.exists()) {
        continue;
      }
      await entity.copy(targetFile.path);
    }

    await for (final entity in legacyDirectory.list(followLinks: false)) {
      if (entity is File) {
        await entity.delete();
      }
    }
    if (await legacyDirectory.exists()) {
      await legacyDirectory.delete(recursive: true);
    }
  }
}

