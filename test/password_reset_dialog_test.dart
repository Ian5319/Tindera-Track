import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tenderatrack/presentation/screens/auth/login_screen.dart';

void main() {
  testWidgets('shows reset errors in the dialog and allows retrying', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordResetDialog(
            initialValue: '',
            sendPasswordReset: (identifier) async {
              attempts++;
              expect(identifier, 'owner@example.com');
              return 'Unable to send the reset link.';
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField),
      'owner@example.com',
    );
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(find.text('Unable to send the reset link.'), findsOneWidget);
    expect(find.text('Send link'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'other@example.com');
    await tester.pump();

    expect(find.text('Unable to send the reset link.'), findsNothing);
  });

  testWidgets('blocks duplicate sends and closes only after success', (
    tester,
  ) async {
    final request = Completer<String?>();
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => PasswordResetDialog(
                    initialValue: 'owner@example.com',
                    sendPasswordReset: (_) {
                      attempts++;
                      return request.future;
                    },
                  ),
                );
              },
              child: const Text('Open reset'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send link'));
    await tester.pump();

    expect(attempts, 1);
    expect(find.text('Sending…'), findsOneWidget);

    await tester.tap(find.text('Sending…'));
    await tester.pump();
    expect(attempts, 1);

    request.complete(null);
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsNothing);
    expect(find.text('Open reset'), findsOneWidget);
  });
}
