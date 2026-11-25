import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/theme/app_metrics.dart';
import 'package:scientific_calculator/theme/app_theme.dart';
import 'package:scientific_calculator/widgets/calculator_button.dart';
import 'package:scientific_calculator/widgets/keypad.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('app opens on the basic calculator, not the chooser', (tester) async {
    final settings = await pumpApp(tester);
    expect(settings.openLastMode, isFalse);
    expect(find.byKey(const Key('calculator-display')), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('AC'), findsNothing);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('Choose a calculator'), findsNothing);
    expect(find.text('sin'), findsNothing);
    expect(find.byKey(const Key('mode-finance')), findsNothing);
  });

  testWidgets('Ans on the editor bar inserts the last result', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('key-ans')), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('key-ans')));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('calculator-display'))).data, '8');
  });

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

  testWidgets('C sits at the top-left of the number pad', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    final c = tester.getCenter(find.byKey(const Key('key-ac')));
    final five = tester.getCenter(find.text('5'));
    final seven = tester.getCenter(find.text('7'));
    final percent = tester.getCenter(find.text('%'));
    final divide = tester.getCenter(find.text('÷'));
    expect(c.dy, lessThan(five.dy));
    expect(c.dx, closeTo(seven.dx, 8));
    expect(percent.dy, closeTo(c.dy, 8));
    expect(divide.dy, closeTo(c.dy, 8));
    expect(tester.getCenter(find.byKey(const Key('key-left'))).dy, lessThan(c.dy));
    expect(tester.getCenter(find.byKey(const Key('key-backspace'))).dy, lessThan(c.dy));
    expect(tester.getCenter(find.byKey(const Key('key-speak'))).dy, lessThan(c.dy));
  });

  testWidgets('large text does not overflow the keypad', (tester) async {
    final settings = await pumpApp(tester);
    await settings.setTextScale(1.5);
    await tester.pumpAndSettle();
    await chooseMode(tester, 'calculator');
    expect(tester.takeException(), isNull);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('AC'), findsNothing);
  });

  testWidgets('C key uses the red clear role', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');
    final button = tester.widget<CalculatorButton>(find.widgetWithText(CalculatorButton, 'C'));
    expect(button.role, ButtonRole.clear);
    expect(button.semanticLabel, 'Clear');
  });

  testWidgets('C clears the display', (WidgetTester tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    await tester.tap(find.text('7'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('calculator-display'))).data, '7');

    await tester.tap(find.text('C'));
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

  testWidgets('calculator opens in basic mode with large number keys', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    expect(find.byKey(const Key('key-sci')), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('±'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('sin'), findsNothing);
    expect(find.text('cos'), findsNothing);
    expect(find.text('log'), findsNothing);

    final fiveRect = tester.getRect(find.text('5'));
    expect(fiveRect.top, greaterThan(0));
    expect(fiveRect.bottom, lessThan(915));
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('calculator-display'))).data, '5');
  });

  testWidgets('SCI reveals scientific keys and marks the toggle selected', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    final sci = tester.widget<CalculatorButton>(find.byKey(const Key('key-sci')));
    expect(sci.selected, isFalse);
    expect(sci.semanticLabel, contains('Scientific keypad'));
    expect(sci.semanticLabel!.toLowerCase(), contains('off'));

    final fiveBefore = tester.getSize(find.widgetWithText(CalculatorButton, '5'));
    final cBefore = tester.getRect(find.byKey(const Key('key-ac')));

    await tester.tap(find.byKey(const Key('key-sci')));
    await tester.pumpAndSettle();

    expect(find.text('sin'), findsOneWidget);
    expect(find.text('cos'), findsOneWidget);
    expect(find.text('log'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    final fiveAfter = tester.getSize(find.widgetWithText(CalculatorButton, '5'));
    expect(fiveAfter.width, closeTo(fiveBefore.width, 1));
    expect(fiveAfter.height, closeTo(fiveBefore.height, 1));
    expect(fiveAfter.width, closeTo(fiveAfter.height, 1));
    expect(tester.getRect(find.byKey(const Key('key-ac'))).top, closeTo(cBefore.top, 1));
    expect(tester.getRect(find.byKey(const Key('key-ac'))).left, closeTo(cBefore.left, 1));

    final selected = tester.widget<CalculatorButton>(find.byKey(const Key('key-sci')));
    expect(selected.selected, isTrue);
    expect(selected.semanticLabel!.toLowerCase(), contains('on'));
  });

  testWidgets('basic pad pins ± 0 . = to the bottom-right squares', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');
    _expectBasicPadFlushBottomRight(tester);
  });

  testWidgets('SCI collapse still lands the basic pad on the bottom-right', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'calculator');

    await tester.tap(find.byKey(const Key('key-sci')));
    await tester.pumpAndSettle();
    expect(find.text('sin'), findsOneWidget);

    final sciEquals = tester.getRect(find.widgetWithText(CalculatorButton, '='));
    final keypad = tester.getRect(find.byType(Keypad));
    expect(sciEquals.right, closeTo(keypad.right - AppMetrics.keypadInset, 1));
    expect(sciEquals.bottom, closeTo(keypad.bottom - AppMetrics.keypadInset, 1));

    await tester.tap(find.byKey(const Key('key-sci')));
    await tester.pumpAndSettle();
    expect(find.text('sin'), findsNothing);
    _expectBasicPadFlushBottomRight(tester);
  });

  testWidgets('SCI mode persists through settings', (tester) async {
    final settings = await pumpApp(tester);
    await chooseMode(tester, 'calculator');
    expect(settings.scientificKeypad, isFalse);

    await tester.tap(find.byKey(const Key('key-sci')));
    await tester.pumpAndSettle();
    expect(settings.scientificKeypad, isTrue);
    expect(find.text('sin'), findsOneWidget);
  });

  testWidgets('wide window puts functions on the left of the same numpad', (tester) async {
    await pumpApp(tester, physicalSize: const Size(800, 600));
    await chooseMode(tester, 'calculator');

    expect(find.text('sin'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('AC'), findsNothing);

    final c = tester.getRect(find.byKey(const Key('key-ac')));
    final seven = tester.getRect(find.widgetWithText(CalculatorButton, '7'));
    final sin = tester.getRect(find.widgetWithText(CalculatorButton, 'sin'));
    final eq = tester.getRect(find.widgetWithText(CalculatorButton, '='));
    final five = tester.getRect(find.widgetWithText(CalculatorButton, '5'));
    final keypad = tester.getRect(find.byType(Keypad));

    expect(sin.left, lessThan(c.left));
    expect(c.left, closeTo(seven.left, 1));
    expect(c.top, lessThan(seven.top));
    expect(five.width, closeTo(five.height, 1));
    expect(c.width, closeTo(five.width, 1));
    expect(eq.right, closeTo(keypad.right - AppMetrics.keypadInset, 1));
    expect(eq.bottom, closeTo(keypad.bottom - AppMetrics.keypadInset, 1));
    _expectBasicPadFlushBottomRight(tester);
  });
}

void _expectBasicPadFlushBottomRight(WidgetTester tester) {
  final sign = tester.getRect(find.widgetWithText(CalculatorButton, '±'));
  final zero = tester.getRect(find.widgetWithText(CalculatorButton, '0'));
  final dot = tester.getRect(find.widgetWithText(CalculatorButton, '.'));
  final plus = tester.getRect(find.widgetWithText(CalculatorButton, '+'));
  final eq = tester.getRect(find.widgetWithText(CalculatorButton, '='));
  final minus = tester.getRect(find.widgetWithText(CalculatorButton, '−'));
  final divide = tester.getRect(find.widgetWithText(CalculatorButton, '÷'));
  final keypad = tester.getRect(find.byType(Keypad));

  expect(eq.width, closeTo(eq.height, 1));
  expect(zero.width, closeTo(eq.width, 1));
  expect(zero.height, closeTo(eq.height, 1));
  expect(plus.width, closeTo(eq.width, 1));
  expect(dot.width, closeTo(eq.width, 1));
  expect(sign.width, closeTo(eq.width, 1));

  expect(sign.bottom, closeTo(eq.bottom, 0.5));
  expect(zero.bottom, closeTo(eq.bottom, 0.5));
  expect(dot.bottom, closeTo(eq.bottom, 0.5));
  expect(plus.bottom, lessThan(eq.top));
  expect(plus.right, closeTo(eq.right, 0.5));

  expect(eq.right, closeTo(minus.right, 0.5));
  expect(eq.right, closeTo(divide.right, 0.5));
  expect(eq.right, closeTo(keypad.right - AppMetrics.keypadInset, 1));
  expect(eq.bottom, closeTo(keypad.bottom - AppMetrics.keypadInset, 1));

  expect(zero.left - sign.right, closeTo(AppMetrics.keypadGutter, 0.5));
  expect(dot.left - zero.right, closeTo(AppMetrics.keypadGutter, 0.5));
  expect(eq.left - dot.right, closeTo(AppMetrics.keypadGutter, 0.5));
}
