import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tenderatrack/data/models/product.dart';
import 'package:tenderatrack/presentation/widgets/inventory/product_edit_dialog.dart';

void main() {
  final product = Product(
    id: 'p1',
    name: 'Coffee',
    price: 12.5,
    stockQuantity: 8,
    threshold: 2,
    createdAt: DateTime(2026),
  );

  testWidgets('edits product details without changing stock', (tester) async {
    Product? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showProductEditDialog(context, product);
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'Premium Coffee');
    await tester.enterText(fields.at(1), '15.75');
    await tester.enterText(fields.at(2), '3');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(result?.name, 'Premium Coffee');
    expect(result?.price, 15.75);
    expect(result?.threshold, 3);
    expect(result?.stockQuantity, 8);
  });

  testWidgets('keeps editor open when required values are invalid',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showProductEditDialog(context, product),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(find.text('Product name is required.'), findsOneWidget);
    expect(find.text('Edit product'), findsOneWidget);
  });
}
