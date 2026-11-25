import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scientific_calculator/app.dart';
import 'package:scientific_calculator/l10n/app_language.dart';
import 'package:scientific_calculator/services/settings_controller.dart';

Future<SettingsController> pumpApp(
  WidgetTester tester, {
  Size physicalSize = const Size(411, 915),
}) async {
  SharedPreferences.setMockInitialValues({'language_code': 'en'});
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final settings = await SettingsController.create();
  await settings.setLanguage(AppLanguage.english);
  await tester.pumpWidget(CalculatorApp(settings: settings));
  await tester.pumpAndSettle();
  return settings;
}

/// Opens the mode chooser from the current tool (no-op if already there).
Future<void> openChooser(WidgetTester tester) async {
  if (find.byKey(const Key('mode-calculator')).evaluate().isNotEmpty) return;
  await tester.tap(find.byKey(const Key('switch-calculator')));
  await tester.pumpAndSettle();
}

Future<void> expandChooserMore(WidgetTester tester) async {
  final more = find.byKey(const Key('chooser-more'));
  if (more.evaluate().isEmpty) return;
  if (find.byKey(const Key('mode-matrix')).evaluate().isNotEmpty) return;
  await tester.ensureVisible(more);
  await tester.tap(more);
  await tester.pumpAndSettle();
}

Future<void> chooseMode(WidgetTester tester, String modeName) async {
  if (modeName == 'calculator' &&
      find.byKey(const Key('calculator-display')).evaluate().isNotEmpty) {
    return;
  }
  if (find.byKey(Key('mode-$modeName')).evaluate().isEmpty) {
    await openChooser(tester);
  }
  if (find.byKey(Key('mode-$modeName')).evaluate().isEmpty) {
    await expandChooserMore(tester);
  }
  final finder = find.byKey(Key('mode-$modeName'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
import 'package:financial_calculator/models/plan_month.dart';

double budgetCarryInBalance(PlanMonth month) {
  // Placeholder implementation: returns a default balance.
  // In a full implementation, this would compute the carry‑in balance
  // based on previous months' data.
  return 0.0;
}
