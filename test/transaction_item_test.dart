import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tenderatrack/data/models/utang_transaction.dart';
import 'package:tenderatrack/presentation/widgets/utang/transaction_item.dart';

void main() {
  testWidgets('opens attached Utang photo evidence', (tester) async {
    final transaction = UtangTransaction(
      id: 't1',
      customerId: 'c1',
      amount: 125,
      type: UtangType.credit,
      photoUrl: 'https://example.com/evidence.jpg',
      note: 'Rice and canned goods',
      createdAt: DateTime(2026, 10, 26),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionItem(transaction: transaction),
        ),
      ),
    );

    expect(find.byTooltip('View attached photo'), findsOneWidget);
    await tester.tap(find.byTooltip('View attached photo'));
    await tester.pump();

    expect(find.text('Utang photo evidence'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
  });
}
