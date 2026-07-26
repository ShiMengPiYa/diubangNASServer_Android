import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/auth/account_models.dart';
import '../../../core/auth/auth_session_store.dart';
import '../../../core/auth/request_authorization.dart';
import '../../../core/debug/avatar_diag_log.dart';
import '../../../core/device_registry/device_avatar_store.dart';
import '../../../core/device_registry/device_label_constraints.dart';
import '../../../core/device_registry/device_models.dart';
import '../../../core/device_registry/device_store.dart';

class DeviceProfileApiHandler {
  DeviceProfileApiHandler({
    required DeviceStore deviceStore,
    required DeviceAvatarStore avatarStore,
    void Function()? onProfileChanged,
  }) : _deviceStore = deviceStore,
       _avatarStore = avatarStore,
       _onProfileChanged = onProfileChanged;

  final DeviceStore _deviceStore;
  final DeviceAvatarStore _avatarStore;
  final void Function()? _onProfileChanged;

  Handler get handler {
    final router = Router();

    router.get('/device-profile', getMyProfile);
    router.patch('/device-profile', patchMyProfile);
    router.put('/device-profile/avatar', putMyAvatar);
    router.delete('/device-profile/avatar', deleteMyAvatar);

    return router.call;
  }

  Future<Response> getMyProfile(Request request) async {
    final authError = _deviceContextError(request);
    if (authError != null) {
      return authError;
    }
    final authContext = _requireDeviceContext(request)!;

    final device = await _deviceStore.findDeviceById(authContext.deviceId!);
    if (device == null) {
      return _error(404, 'DEVICE_NOT_FOUND', 'Device was not found');
    }

    return Response.ok(
      jsonEncode(await _profileJson(device)),
      headers: _jsonHeaders(),
    );
  }

  Future<Response> patchMyProfile(Request request) async {
    final authError = _deviceContextError(request);
    if (authError != null) {
      return authError;
    }
    final authContext = _requireDeviceContext(request)!;

    try {
      final payload = jsonDecode(await request.readAsString());
      if (payload is! Map) {
        return _error(400, 'INVALID_BODY', 'Request body must be JSON');
      }
      if (!payload.containsKey('label')) {
        return _error(
          400,
          'INVALID_PARAMS',
          'Provide label to update device profile',
        );
      }

      final rawLabel = payload['label'];
      final label = rawLabel is String ? rawLabel.trim() : '';
      final labelError = DeviceLabelConstraints.validate(label);
      if (labelError != null) {
        return _error(400, 'INVALID_LABEL', labelError);
      }
      final updated = await _deviceStore.updateDeviceLabel(
        deviceId: authContext.deviceId!,
        label: label,
      );

      return Response.ok(
        jsonEncode(await _profileJson(updated)),
        headers: _jsonHeaders(),
      );
    } on StateError catch (error) {
      return _error(404, 'DEVICE_NOT_FOUND', error.message);
    } on ArgumentError catch (error) {
      return _error(400, 'INVALID_LABEL', error.message?.toString() ?? 'Invalid label');
    } on FormatException catch (error) {
      return _error(400, 'INVALID_BODY', error.message);
    }
  }

  Future<Response> putMyAvatar(Request request) async {
    final authError = _deviceContextError(request);
    if (authError != null) {
      return authError;
    }
    final authContext = _requireDeviceContext(request)!;
    final deviceId = authContext.deviceId!;
    final contentLength = request.headers['content-length'];

    final bytes = await request.read().expand((chunk) => chunk).toList();
    final priorUpdatedAt = await _avatarStore.readUpdatedAt(deviceId);
    logAvatarDiag(
      'PUT begin deviceId=$deviceId contentLength=${contentLength ?? 'null'} '
      'bodyBytes=${bytes.length} looksLikeImage=${_looksLikeImage(bytes)} '
      'priorUpdatedAt=${priorUpdatedAt?.toIso8601String() ?? 'null'} '
      'onProfileChangedWired=${_onProfileChanged != null}',
    );
    if (bytes.isEmpty) {
      logAvatarDiag('PUT reject deviceId=$deviceId reason=empty_body');
      return _error(400, 'INVALID_BODY', 'Avatar body must not be empty');
    }
    if (!_looksLikeImage(bytes)) {
      logAvatarDiag('PUT reject deviceId=$deviceId reason=not_image');
      return _error(
        400,
        'INVALID_AVATAR',
        'Avatar must be JPEG or PNG image data',
      );
    }

    try {
      final updatedAt = await _avatarStore.saveAvatar(
        deviceId: deviceId,
        bytes: bytes,
      );
      final advanced =
          priorUpdatedAt == null || updatedAt.isAfter(priorUpdatedAt);
      final willNotify = _onProfileChanged != null;
      _onProfileChanged?.call();
      logAvatarDiag(
        'PUT ok deviceId=$deviceId avatarUpdatedAt=${updatedAt.toIso8601String()} '
        'advanced=$advanced onProfileChanged=$willNotify',
      );
      return Response.ok(
        jsonEncode({
          'deviceId': deviceId,
          'avatarUpdatedAt': updatedAt.toIso8601String(),
        }),
        headers: _jsonHeaders(),
      );
    } on ArgumentError catch (error) {
      logAvatarDiag(
        'PUT reject deviceId=$deviceId type=ArgumentError '
        'message=${error.message}',
        error: error,
      );
      return _error(400, 'INVALID_AVATAR', error.message?.toString() ?? 'Invalid avatar');
    } catch (error, stackTrace) {
      // Behavior unchanged: still rethrow so we can confirm connection aborts.
      logAvatarDiag(
        'PUT FAIL deviceId=$deviceId type=${error.runtimeType} error=$error',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Response> deleteMyAvatar(Request request) async {
    final authError = _deviceContextError(request);
    if (authError != null) {
      return authError;
    }
    final authContext = _requireDeviceContext(request)!;
    final deviceId = authContext.deviceId!;

    try {
      logAvatarDiag(
        'DELETE begin deviceId=$deviceId '
        'onProfileChangedWired=${_onProfileChanged != null}',
      );
      await _avatarStore.deleteAvatar(deviceId);
      final willNotify = _onProfileChanged != null;
      _onProfileChanged?.call();
      logAvatarDiag(
        'DELETE ok deviceId=$deviceId onProfileChanged=$willNotify',
      );
      return Response(204, headers: _jsonHeaders());
    } catch (error, stackTrace) {
      logAvatarDiag(
        'DELETE FAIL deviceId=$deviceId type=${error.runtimeType} error=$error',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  AuthenticatedRequestContext? _requireDeviceContext(Request request) {
    final authError = ensureRequestHasAnyRole(
      request,
      allowedRoles: {AccountRole.device},
      message: 'Only authenticated devices can manage their profile',
    );
    if (authError != null) {
      return null;
    }

    final authContext = requireAuthenticatedRequestContext(request);
    final deviceId = authContext?.deviceId?.trim();
    if (deviceId == null || deviceId.isEmpty) {
      return null;
    }
    return authContext;
  }

  Response? _deviceContextError(Request request) {
    final authError = ensureRequestHasAnyRole(
      request,
      allowedRoles: {AccountRole.device},
      message: 'Only authenticated devices can manage their profile',
    );
    if (authError != null) {
      return authError;
    }

    final authContext = requireAuthenticatedRequestContext(request);
    final deviceId = authContext?.deviceId?.trim();
    if (deviceId == null || deviceId.isEmpty) {
      return _error(
        403,
        'DEVICE_ID_REQUIRED',
        'Authenticated device context is missing deviceId',
      );
    }
    return null;
  }

  Future<Map<String, dynamic>> _profileJson(StoredDeviceRecord device) async {
    final avatarUpdatedAt = await _avatarStore.readUpdatedAt(device.deviceId);
    return {
      'deviceId': device.deviceId,
      'physicalDeviceId': device.physicalDeviceId,
      'deviceName': device.deviceName,
      'label': device.label,
      'platform': device.platform,
      'brand': device.brand,
      'model': device.model,
      if (avatarUpdatedAt != null)
        'avatarUpdatedAt': avatarUpdatedAt.toIso8601String(),
    };
  }

  bool _looksLikeImage(List<int> bytes) {
    if (bytes.length < 4) {
      return false;
    }
    final header = Uint8List.fromList(bytes.take(4).toList());
    final isJpeg = header[0] == 0xFF && header[1] == 0xD8;
    final isPng = header[0] == 0x89 &&
        header[1] == 0x50 &&
        header[2] == 0x4E &&
        header[3] == 0x47;
    return isJpeg || isPng;
  }

  String _contentTypeForBytes(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    return 'image/png';
  }

  Map<String, String> _jsonHeaders() => const {
    'Content-Type': 'application/json',
  };

  Response _error(int statusCode, String code, String message) {
    return Response(
      statusCode,
      headers: _jsonHeaders(),
      body: jsonEncode({'code': code, 'message': message, 'details': {}}),
    );
  }
}
