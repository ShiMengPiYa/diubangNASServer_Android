import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../../core/device/system_status_cache.dart';
import 'dashboard_payload_builder.dart';

class DashboardHandler {
  DashboardHandler({
    DashboardPayloadBuilder? payloadBuilder,
    SystemStatusCache? systemStatusCache,
    int? port,
    DateTime? startedAt,
  }) : _payloadBuilder =
           payloadBuilder ??
           DashboardPayloadBuilder(
             systemStatusCache: systemStatusCache!,
             port: port!,
             startedAt: startedAt!,
           ),
       _systemStatusCache = systemStatusCache;

  final DashboardPayloadBuilder _payloadBuilder;
  final SystemStatusCache? _systemStatusCache;

  Handler get handler {
    return (Request request) async {
      final cache = _systemStatusCache;
      if (cache != null && !cache.isInitialized.value) {
        return Response(
          503,
          body: jsonEncode({
            'code': 'DASHBOARD_NOT_READY',
            'message': 'Dashboard metrics are still initializing',
            'details': {},
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (cache != null) {
        await cache.refresh();
      }

      return Response.ok(
        jsonEncode(_payloadBuilder.build()),
        headers: {'Content-Type': 'application/json'},
      );
    };
  }
}
