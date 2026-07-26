// ignore_for_file: avoid_print

import 'dart:developer' as developer;

/// Temporary avatar diagnostics for flutter run terminals.
/// Search logs with the `[avatar]` prefix.
void logAvatarDiag(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  final timestamp = DateTime.now().toUtc().toIso8601String();
  final line = '[$timestamp] [avatar] $message';
  print(line);
  if (error != null || stackTrace != null) {
    developer.log(
      line,
      name: 'diubang_nasserver.avatar',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
