import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/features/device_identity/presentation/widgets/server_device_identity_card.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog<String?>(
                    context: context,
                    builder: (context) => const DisplayAliasDialog(),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('canceling DisplayAliasDialog closes without framework errors',
      (tester) async {
    final errors = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exception);
      previousOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await openDialog(tester);
    expect(find.text('设置名称'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('设置名称'), findsNothing);
    expect(errors, isEmpty);
  });

  testWidgets('saving DisplayAliasDialog returns entered alias', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String?>(
                    context: context,
                    builder: (context) => const DisplayAliasDialog(),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '客厅 NAS');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(result, '客厅 NAS');
  });

  testWidgets('rejects unsafe characters without closing dialog', (tester) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '客厅/NAS');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('设置名称'), findsOneWidget);
    expect(find.textContaining('不能包含'), findsOneWidget);
  });
}
