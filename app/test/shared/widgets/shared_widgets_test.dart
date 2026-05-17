import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spent/core/theme/app_theme.dart';
import 'package:spent/shared/widgets/amount_display.dart';
import 'package:spent/shared/widgets/app_card.dart';
import 'package:spent/shared/widgets/app_input.dart';
import 'package:spent/shared/widgets/budget_progress_bar.dart';
import 'package:spent/shared/widgets/category_chip.dart';
import 'package:spent/shared/widgets/primary_button.dart';
import 'package:spent/shared/widgets/section_header.dart';
import 'package:spent/shared/widgets/transaction_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: SafeArea(child: child)),
    );

void main() {
  testWidgets('AppCard renders child without overflow', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppCard(child: Text('hello')),
    ));
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('AppInput renders without overflow', (tester) async {
    await tester.pumpWidget(_wrap(
      const AppInput(hint: 'Enter amount'),
    ));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('PrimaryButton renders and is tappable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PrimaryButton(label: 'Save', onPressed: () => tapped = true),
    ));
    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(tapped, isTrue);
  });

  testWidgets('CategoryChip renders all categories without overflow', (tester) async {
    const categories = [
      'food', 'transport', 'shopping', 'bills',
      'entertainment', 'health', 'education', 'travel', 'others',
    ];
    for (final cat in categories) {
      await tester.pumpWidget(_wrap(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CategoryChip(category: cat),
        ),
      ));
      expect(find.byType(CategoryChip), findsOneWidget);
    }
  });

  testWidgets('AmountDisplay renders formatted amount', (tester) async {
    await tester.pumpWidget(_wrap(
      const AmountDisplay(amount: 1250.50),
    ));
    expect(find.textContaining('1,250'), findsOneWidget);
  });

  testWidgets('SectionHeader renders title and optional trailing', (tester) async {
    await tester.pumpWidget(_wrap(
      const SectionHeader(title: 'Recent', trailing: Icon(Icons.arrow_forward)),
    ));
    expect(find.text('Recent'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });

  testWidgets('BudgetProgressBar renders at all thresholds without overflow', (tester) async {
    for (final pct in [0.0, 0.5, 0.8, 1.0, 1.2]) {
      await tester.pumpWidget(_wrap(
        BudgetProgressBar(percentage: pct),
      ));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    }
  });

  testWidgets('TransactionTile renders amount, category, date without overflow', (tester) async {
    final date = DateTime(2025, 5, 17);
    await tester.pumpWidget(_wrap(
      TransactionTile(
        amount: 450.0,
        category: 'food',
        note: 'Lunch at cafe',
        date: date,
      ),
    ));
    expect(find.byType(TransactionTile), findsOneWidget);
    expect(find.textContaining('450'), findsOneWidget);
    expect(find.text('Lunch at cafe'), findsOneWidget);
  });

  testWidgets('TransactionTile renders without note', (tester) async {
    await tester.pumpWidget(_wrap(
      TransactionTile(
        amount: 200.0,
        category: 'transport',
        date: DateTime(2025, 5, 10),
      ),
    ));
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  testWidgets('TransactionTile falls back gracefully for unknown category', (tester) async {
    await tester.pumpWidget(_wrap(
      TransactionTile(
        amount: 100.0,
        category: 'unknown',
        date: DateTime(2025, 1, 1),
      ),
    ));
    expect(find.byType(TransactionTile), findsOneWidget);
  });
}
