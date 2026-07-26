// 文件输入：连接注册表、事件总线、dashboard payload builder、presence repository
// 文件职责：周期性广播 dashboard/server 状态，并在连接变化时推送 presence.changed
// 文件对外接口：RealtimeStatusPublisher
// 文件包含：RealtimeStatusPublisher
import 'dart:async';

import '../../../core/debug/avatar_diag_log.dart';
import '../../../core/runtime/runtime_presence_bridge.dart';
import '../../api/handlers/dashboard_payload_builder.dart';
import '../realtime_contract.dart';
import 'realtime_connection_registry.dart';
import 'realtime_event_hub.dart';
import 'realtime_presence_repository.dart';

typedef RealtimeStatusClock = DateTime Function();

typedef EnrolledDeviceIdsProvider = Future<List<String>> Function();

class RealtimeStatusPublisher {
  RealtimeStatusPublisher({
    required RealtimeConnectionRegistry connectionRegistry,
    required RealtimeEventHub eventHub,
    required DashboardPayloadBuilder dashboardPayloadBuilder,
    required RealtimePresenceRepository presenceRepository,
    EnrolledDeviceIdsProvider? enrolledDeviceIdsProvider,
    Duration publishInterval = const Duration(seconds: 5),
    Duration inactivityTimeout = realtimeHeartbeatTimeout,
    RealtimeStatusClock? clock,
  }) : _connectionRegistry = connectionRegistry,
       _eventHub = eventHub,
       _dashboardPayloadBuilder = dashboardPayloadBuilder,
       _presenceRepository = presenceRepository,
       _enrolledDeviceIdsProvider = enrolledDeviceIdsProvider,
       _publishInterval = publishInterval,
       _inactivityTimeout = inactivityTimeout,
       _clock = clock ?? DateTime.now;

  final RealtimeConnectionRegistry _connectionRegistry;
  final RealtimeEventHub _eventHub;
  final DashboardPayloadBuilder _dashboardPayloadBuilder;
  final RealtimePresenceRepository _presenceRepository;
  final EnrolledDeviceIdsProvider? _enrolledDeviceIdsProvider;
  final Duration _publishInterval;
  final Duration _inactivityTimeout;
  final RealtimeStatusClock _clock;

  Timer? _publishTimer;

  void start() {
    _publishTimer?.cancel();
    _publishTimer = Timer.periodic(_publishInterval, (_) {
      publishStatusTick();
    });
  }

  void publishStatusTick() {
    final timedOutConnections = _cleanupTimedOutConnections();
    if (timedOutConnections.isNotEmpty && _connectionRegistry.hasConnections) {
      publishPresenceChanged();
    }

    if (!_connectionRegistry.hasConnections) {
      return;
    }

    final dashboardPayload = _dashboardPayloadBuilder.build();
    _eventHub.broadcast(
      type: RealtimeMessageType.dashboardUpdated,
      payload: dashboardPayload,
    );
    _eventHub.broadcast(
      type: RealtimeMessageType.serverStateChanged,
      payload: {
        'server': dashboardPayload['server'],
        'network': dashboardPayload['network'],
        'updatedAt': dashboardPayload['updatedAt'],
      },
    );
  }

  void publishPresenceChanged() {
    unawaited(_publishPresenceChangedAsync());
  }

  Future<void> _publishPresenceChangedAsync() async {
    unawaited(
      RuntimePresenceBridge.instance.publishFromRuntime(
        presenceRepository: _presenceRepository,
        connectionRegistry: _connectionRegistry,
      ),
    );

    final connectionCount = _connectionRegistry.connections.length;
    if (!_connectionRegistry.hasConnections) {
      logAvatarDiag(
        'presence.changed skip reason=no_connections '
        'connectionCount=$connectionCount',
      );
      return;
    }

    final clients = _presenceRepository.snapshot();
    final payload = <String, dynamic>{
      'clients': clients,
    };
    final enrolledIds = await _loadEnrolledDeviceIds();
    if (enrolledIds != null) {
      payload['enrolledDeviceIds'] = enrolledIds;
    }

    final avatarSummary = clients
        .map((client) {
          final deviceId = '${client['deviceId'] ?? ''}'.trim();
          if (deviceId.isEmpty) {
            return null;
          }
          final updatedAt = client['avatarUpdatedAt'];
          return '$deviceId.avatarUpdatedAt=${updatedAt ?? 'null'}';
        })
        .whereType<String>()
        .join(' ');
    logAvatarDiag(
      'presence.changed broadcast connections=$connectionCount '
      'clients=${clients.length} '
      '${avatarSummary.isEmpty ? 'avatars=none' : avatarSummary}',
    );

    _eventHub.broadcast(
      type: RealtimeMessageType.presenceChanged,
      payload: payload,
    );
  }

  Future<List<String>?> _loadEnrolledDeviceIds() async {
    final provider = _enrolledDeviceIdsProvider;
    if (provider == null) {
      return null;
    }
    try {
      return await provider();
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _publishTimer?.cancel();
    _publishTimer = null;
  }

  List<RealtimeConnection> _cleanupTimedOutConnections() {
    final now = _clock().toUtc();
    final timedOutConnections = _connectionRegistry
        .findTimedOut(now, _inactivityTimeout)
        .toList(growable: false);

    for (final connection in timedOutConnections) {
      _connectionRegistry.unregister(connection.connectionId);
      _presenceRepository.markOffline(
        clientId: connection.clientId,
        connectionId: connection.connectionId,
      );
      unawaited(
        connection.channel.sink.close(
          realtimeCloseCodeHeartbeatTimeout,
          'heartbeat timeout',
        ),
      );
    }

    return timedOutConnections;
  }
}
