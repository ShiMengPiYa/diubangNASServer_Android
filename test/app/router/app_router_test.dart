import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/app/router/app_router.dart';
import 'package:diubang_nasserver/app/router/route_names.dart';

void main() {
  testWidgets('resolves the server management route', (tester) async {
    final router = AppRouter(
      serverManagementPageBuilder: (_) =>
          const SizedBox(key: Key('server-page')),
    );

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: RouteNames.serverManagement,
        onGenerateRoute: router.generateRoute,
      ),
    );

    expect(find.byKey(const Key('server-page')), findsOneWidget);
  });
}
