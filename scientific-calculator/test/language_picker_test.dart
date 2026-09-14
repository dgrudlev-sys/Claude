import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scientific_calculator/app.dart';
import 'package:scientific_calculator/core/calculator_mode.dart';
import 'package:scientific_calculator/l10n/app_language.dart';
import 'package:scientific_calculator/l10n/app_strings.dart';
import 'package:scientific_calculator/services/settings_controller.dart';

void main() {
  test('search matches English and native names in one list', () {
    expect(AppLanguage.byCode('bg').matches('Bulgarian'), isTrue);
    expect(AppLanguage.byCode('bg').matches('български'), isTrue);
    expect(AppLanguage.byCode('ru').matches('Russian'), isTrue);
    expect(AppLanguage.byCode('ru').matches('руски'), isTrue);
    expect(AppLanguage.byCode('ru').matches('русский'), isTrue);
    expect(AppLanguage.byCode('fr').matches('xyzzy'), isFalse);
  });

  test('list labels are title case with native names', () {
    expect(AppLanguage.byCode('bg').listLabel, 'Bulgarian · Български');
    expect(AppLanguage.byCode('ru').listLabel, 'Russian · Русский');
  });

  test('Bulgarian and every other locale translate category titles AND subtitles', () {
    final en = AppStrings.of(AppLanguage.english);
    expect(AppStrings.of(AppLanguage.byCode('bg')).modeLabel('calculator'), 'Калкулатор');
    expect(
      AppStrings.of(AppLanguage.byCode('bg')).modeDescription('calculator'),
      contains('Събиране'),
    );
    expect(
      AppStrings.of(AppLanguage.byCode('bg')).modeDescription('calculator'),
      isNot(en.modeDescription('calculator')),
    );

    for (final lang in AppLanguage.supported) {
      if (lang.code == 'en') continue;
      final s = AppStrings.of(lang);
      for (final mode in CalculatorMode.values) {
        expect(
          s.modeDescription(mode.name),
          isNot(en.modeDescription(mode.name)),
          reason: '${lang.code} ${mode.name} subtitle was still English',
        );
        expect(
          s.modeDescription(mode.name).startsWith('modeDesc_'),
          isFalse,
          reason: '${lang.code} ${mode.name} missing subtitle key',
        );
      }
    }
  });

  test('European locales use a decimal comma and semicolon args', () {
    expect(AppLanguage.byCode('fr').decimalSeparator, ',');
    expect(AppLanguage.byCode('de').argumentSeparator, ';');
    expect(formatForLocale('sin(0.5)+log(10,100)', AppLanguage.byCode('fr')), 'sin(0,5)+log(10;100)');
    expect(formatForLocale('3.14', AppLanguage.english), '3.14');
  });

  testWidgets('first launch shows language picker; search finds Bulgarian and Russian', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.create();
    await tester.pumpWidget(CalculatorApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('language-search')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('language-search')), 'български');
    await tester.pump();
    expect(find.text('Bulgarian · Български'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('language-search')), 'руски');
    await tester.pump();
    expect(find.text('Russian · Русский'), findsOneWidget);
    expect(find.text('Bulgarian · Български'), findsNothing);

    await tester.tap(find.byKey(const Key('lang-ru')));
    await tester.pumpAndSettle();
    expect(settings.language?.code, 'ru');
    expect(find.textContaining('калькулятор'), findsWidgets);
  });

  testWidgets('Bulgarian chooser shows translated titles and subtitles', (tester) async {
    SharedPreferences.setMockInitialValues({'language_code': 'bg'});
    final settings = await SettingsController.create();
    await tester.pumpWidget(CalculatorApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.text('Калкулатор'), findsOneWidget);
    expect(find.textContaining('Събиране, изваждане'), findsOneWidget);
    expect(find.text('Преобразуване'), findsOneWidget);
    expect(find.textContaining('Arithmetic, trigonometry'), findsNothing);
  });

  testWidgets('French overlay labels the decimal key with a comma', (tester) async {
    SharedPreferences.setMockInitialValues({'language_code': 'fr'});
    final settings = await SettingsController.create();
    await tester.pumpWidget(CalculatorApp(settings: settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mode-calculator')));
    await tester.pumpAndSettle();

    expect(find.text('2nde'), findsOneWidget);
    expect(find.text(','), findsWidgets);
  });
}
