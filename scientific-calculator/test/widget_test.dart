import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scientific_calculator/app.dart';
import 'package:scientific_calculator/services/settings_controller.dart';

void main() {
  Finder display() => find.byKey(const Key('calculator-display'));

  testWidgets('5 + 3 = evaluates to 8', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.create();

    await tester.pumpWidget(CalculatorApp(settings: settings));
    await tester.pumpAndSettle();
    // The calculator is now opened from the home screen rather than being
    // the first tab.
    await tester.tap(find.text('Calculator'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    expect(tester.widget<Text>(display()).data, '8');
  });

  testWidgets('AC clears the display', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.create();

    await tester.pumpWidget(CalculatorApp(settings: settings));
    await tester.pumpAndSettle();
    // The calculator is now opened from the home screen rather than being
    // the first tab.
    await tester.tap(find.text('Calculator'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('7'));
    await tester.pump();
    expect(tester.widget<Text>(display()).data, '7');

    await tester.tap(find.text('AC'));
    await tester.pump();
    expect(tester.widget<Text>(display()).data, '0');
  });
}
