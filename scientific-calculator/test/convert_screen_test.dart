import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('temperature converter shows live C to F', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-temperature')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('convert-amount')), '0');
    await tester.pump();

    expect(find.byKey(const Key('convert-result')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('convert-result'))).data, contains('32 Fahrenheit'));
  });

  testWidgets('cooking flour 1 cup is about 120 grams and also pounds', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-cooking')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flour'));
    await tester.pumpAndSettle();

    expect(find.textContaining('120'), findsWidgets);
    expect(find.textContaining('grams'), findsWidgets);
    expect(find.textContaining('pounds'), findsWidgets);
  });

  testWidgets('convert categories show icons', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    expect(find.byIcon(Icons.thermostat), findsOneWidget);
  });

  testWidgets('cooking converter 3 teaspoons to tablespoon', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-cooking')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teaspoon (tsp)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tablespoon (tbsp)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Millilitre (mL)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teaspoon (tsp)').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('convert-amount')), '3');
    await tester.pump();

    expect(find.textContaining('1'), findsWidgets);
    expect(find.textContaining('Tablespoon'), findsWidgets);
  });

  testWidgets('length converter 1 meter to centimeter', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-length')));
    await tester.pumpAndSettle();

    // Default from Meter, to Kilometer. Switch to centimeter via dropdown.
    await tester.tap(find.text('Kilometer (km)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Centimeter (cm)').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('convert-amount')), '1');
    await tester.pump();

    expect(find.textContaining('100'), findsWidgets);
    expect(find.textContaining('Centimeter'), findsWidgets);
  });

  testWidgets('tip converter splits a bill', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.scrollUntilVisible(
      find.byKey(const Key('convert-tip')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('convert-tip')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('convert-bill')), '100');
    await tester.enterText(find.byKey(const Key('convert-tip-percent')), '15');
    await tester.enterText(find.byKey(const Key('convert-people')), '2');
    await tester.pump();

    expect(find.textContaining('Tip is 15'), findsOneWidget);
    expect(find.textContaining('Total is 115'), findsOneWidget);
    expect(find.textContaining('Each person pays 57.5'), findsOneWidget);
  });

  testWidgets('converter amount rejects letters', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'convert');
    await tester.tap(find.byKey(const Key('convert-length')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('convert-amount')), 'abc');
    await tester.pump();
    expect(find.widgetWithText(TextFormField, '1'), findsWidgets);
  });
}
