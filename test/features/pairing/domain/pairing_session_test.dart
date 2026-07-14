import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/features/pairing/domain/pairing_session.dart';

void main() {
  test('isExpired compares expiresAt using UTC', () {
    final session = PairingSession(
      serverId: 'server-1',
      privateKey: Uint8List(32),
      publicKey: Uint8List(32),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );

    expect(session.isExpired, isFalse);
  });

  test('isExpired is true when expiresAt is in the past', () {
    final session = PairingSession(
      serverId: 'server-1',
      privateKey: Uint8List(32),
      publicKey: Uint8List(32),
      expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );

    expect(session.isExpired, isTrue);
  });
}
