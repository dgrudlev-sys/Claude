import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/convert/currency_service.dart';
import 'package:scientific_calculator/theme/app_metrics.dart';

import 'test_helpers.dart';

String _table(String date, {double usd = 1.1}) => jsonEncode({
      'date': date,
      'rates': {'USD': usd, 'GBP': 0.85, 'BGN': 1.9558},
    });

void main() {
  tearDown(() {
    CurrencyService.instance = CurrencyService();
  });

  testWidgets('percentage 15% of 80 is 12', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'percentage');
    await tester.tap(find.byKey(const Key('percent-of')));
    await tester.pumpAndSettle();
    expect(find.textContaining('15 percent of 80 is 12'), findsOneWidget);
    await tester.tap(find.byKey(const Key('how-we-got-this')));
    await tester.pumpAndSettle();
    expect(find.textContaining('15/100'), findsWidgets);
    expect(find.textContaining('0.15'), findsWidgets);
    expect(find.text('Step 1'), findsNothing);
  });

  testWidgets('fractions 1/2 plus 1/3 is 5/6', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'fractions');
    expect(find.textContaining('1/2 plus 1/3 is 5/6'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('how-we-got-this'), skipOffstage: false),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('how-we-got-this')));
    await tester.pumpAndSettle();
    expect(find.textContaining('3/6'), findsWidgets);
    expect(find.textContaining('5/6'), findsWidgets);
    expect(find.textContaining('denominator'), findsWidgets);
  });

  testWidgets('fractions add a third term 1/2 + 1/3 + 1/6 is 1', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'fractions');
    await tester.scrollUntilVisible(
      find.byKey(const Key('fractions-add-term'), skipOffstage: false),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('fractions-add-term')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('frac-n3')), '1');
    await tester.enterText(find.byKey(const Key('frac-d3')), '6');
    await tester.pumpAndSettle();
    expect(find.textContaining('1/2 plus 1/3 plus 1/6 is'), findsOneWidget);
    final result = tester.widget<Text>(find.byKey(const Key('frac-result'))).data!;
    expect(
      result.contains(' is 1') || result.contains('1/1') || result.contains('6/6'),
      isTrue,
      reason: result,
    );
    final how = find.byKey(const Key('how-we-got-this'), skipOffstage: false);
    expect(how, findsOneWidget);
    await tester.ensureVisible(how);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('how-we-got-this')));
    await tester.pumpAndSettle();
    expect(find.textContaining('denominator'), findsWidgets);
    expect(find.textContaining('3/6'), findsWidgets);
    expect(find.textContaining('2/6'), findsWidgets);
    expect(find.textContaining('1/6'), findsWidgets);
    expect(find.text('Step 1'), findsNothing);
  });

  testWidgets('currency converter uses stub rates', (tester) async {
    CurrencyService.instance = CurrencyService(
      fetch: (uri) async {
        if (uri.path.endsWith('/latest')) return _table('2026-08-27', usd: 1.1);
        return _table('2026-08-26', usd: 1.05);
      },
    );
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-currency')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('convert-amount')), '10');
    await tester.pumpAndSettle();
    expect(find.textContaining('11'), findsWidgets);
    expect(find.textContaining('US dollar'), findsWidgets);
  });

  testWidgets('rate card shows before an amount is typed, with as-of date', (tester) async {
    CurrencyService.instance = CurrencyService(
      fetch: (uri) async {
        if (uri.path.endsWith('/latest')) return _table('2026-08-27', usd: 1.1645);
        return _table('2026-08-26', usd: 1.16);
      },
    );
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-currency')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('convert-amount')), '');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fx-rate-card')), findsOneWidget);
    expect(find.textContaining('1 Euro ='), findsOneWidget);
    expect(find.textContaining('as of 27 August 2026'), findsOneWidget);
    expect(find.textContaining('US dollar'), findsWidgets);
  });

  testWidgets('pair moved up shows a green up triangle', (tester) async {
    CurrencyService.instance = CurrencyService(
      fetch: (uri) async {
        if (uri.path.endsWith('/latest')) return _table('2026-08-27', usd: 1.2);
        return _table('2026-08-26', usd: 1.1);
      },
    );
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-currency')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fx-rate-card')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('fx-rate-card')),
        matching: find.byIcon(Icons.arrow_drop_up),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fx-move-up')), findsOneWidget);
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('fx-rate-card')),
        matching: find.byIcon(Icons.arrow_drop_up),
      ),
    );
    expect(icon.color, AppMetrics.fxUp);
  });

  testWidgets('pair moved down shows a red down triangle', (tester) async {
    CurrencyService.instance = CurrencyService(
      fetch: (uri) async {
        if (uri.path.endsWith('/latest')) return _table('2026-08-27', usd: 1.0);
        return _table('2026-08-26', usd: 1.1);
      },
    );
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-currency')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('fx-rate-card')),
        matching: find.byIcon(Icons.arrow_drop_down),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fx-move-down')), findsOneWidget);
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('fx-rate-card')),
        matching: find.byIcon(Icons.arrow_drop_down),
      ),
    );
    expect(icon.color, AppMetrics.fxDown);
  });

  testWidgets('unchanged pair shows a yellow square', (tester) async {
    CurrencyService.instance = CurrencyService(
      fetch: (uri) async {
        if (uri.path.endsWith('/latest')) return _table('2026-08-27', usd: 1.1);
        return _table('2026-08-26', usd: 1.1);
      },
    );
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-currency')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.square), findsOneWidget);
    expect(find.byKey(const Key('fx-move-unchanged')), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.square));
    expect(icon.color, AppMetrics.fxFlat);
  });
}
