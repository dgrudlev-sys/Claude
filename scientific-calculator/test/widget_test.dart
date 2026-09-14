import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/theme/app_theme.dart';
import 'package:scientific_calculator/widgets/calculator_button.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('5 + 3 = evaluates to 8', (WidgetTester tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    await tester.tap(find.text('5'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('calculator-display'))).data, '8');

    await tester.tap(find.byKey(const Key('how-we-got-this')));
    await tester.pumpAndSettle();
    expect(find.textContaining('5 + 3 = 8'), findsWidgets);
    expect(find.textContaining('Adding 5 and 3'), findsOneWidget);
    expect(find.text('Step 1'), findsNothing);
  });

  testWidgets('AC arrows backspace and speak sit on the top row', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    final ac = tester.getCenter(find.byKey(const Key('key-ac')));
    final five = tester.getCenter(find.text('5'));
    expect(ac.dy, lessThan(five.dy));
    expect(tester.getCenter(find.byKey(const Key('key-left'))).dy, closeTo(ac.dy, 8));
    expect(tester.getCenter(find.byKey(const Key('key-right'))).dy, closeTo(ac.dy, 8));
    expect(tester.getCenter(find.byKey(const Key('key-backspace'))).dy, closeTo(ac.dy, 8));
    expect(tester.getCenter(find.byKey(const Key('key-speak'))).dy, closeTo(ac.dy, 8));
  });

  testWidgets('large text does not overflow the keypad', (tester) async {
    final settings = await pumpApp(tester);
    await settings.setTextScale(1.5);
    await tester.pumpAndSettle();
    await chooseMode(tester, 'calculator');
    expect(tester.takeException(), isNull);
    expect(find.text('AC'), findsOneWidget);
  });

  testWidgets('AC key uses the red clear role', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');
    final button = tester.widget<CalculatorButton>(find.widgetWithText(CalculatorButton, 'AC'));
    expect(button.role, ButtonRole.clear);
  });

  testWidgets('AC clears the display', (WidgetTester tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    await tester.tap(find.text('7'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('calculator-display'))).data, '7');

    await tester.tap(find.text('AC'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('calculator-display'))).data, '0');
  });

  testWidgets('backspace and arrows rewrite an equation', (WidgetTester tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    await tester.tap(find.text('5'));
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('◀'));
    await tester.pump();
    await tester.tap(find.text('⌫'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('calculator-display'))).data, '37');
  });

  testWidgets('history pin hide and delete live behind the History button', (WidgetTester tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    await tester.tap(find.text('1'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-button')), findsOneWidget);
    expect(find.byKey(const Key('history-compact')), findsOneWidget);
    expect(find.byKey(const Key('history-list')), findsNothing);

    await tester.tap(find.byKey(const Key('history-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-list')), findsOneWidget);
    expect(find.textContaining('1+1'), findsWidgets);
    expect(find.textContaining('= 2'), findsWidgets);

    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();
    expect(find.text('Unpin'), findsOneWidget);

    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1+1'), findsNothing);
  });

  testWidgets('empty history says no calculations yet', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');
    await tester.tap(find.byKey(const Key('history-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-empty')), findsOneWidget);
    expect(find.text('No calculations yet.'), findsOneWidget);
  });
}
