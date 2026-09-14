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

Future<void> chooseMode(WidgetTester tester, String modeName) async {
  final finder = find.byKey(Key('mode-$modeName'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
