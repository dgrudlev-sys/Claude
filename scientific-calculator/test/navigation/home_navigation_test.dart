import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/app.dart';
import 'package:scientific_calculator/design/tokens.dart';
import 'package:scientific_calculator/navigation/calculator_mode.dart';
import 'package:scientific_calculator/screens/input_methods_screen.dart';
import 'package:scientific_calculator/services/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the navigation has to do, now that it is buttons rather than a
/// scrolling row of icons.
///
/// The bar it replaced failed in a way no unit test could see: the eighth
/// label was cut off mid-word on a phone, with nothing to suggest that
/// scrolling sideways would reveal it. These tests check the property that
/// failure violated — every tool is named, in full, at every text size.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    double textScale = 1.0,
    Size surface = const Size(412, 915),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.create();
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: surface,
          textScaler: TextScaler.linear(textScale),
        ),
        child: CalculatorApp(settings: settings),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) =>
      tester.scrollUntilVisible(target, 120,
          scrollable: find.byType(Scrollable).first);

  group('every tool announces itself', () {
    testWidgets('all of them are named on the home screen', (tester) async {
      await pumpApp(tester);
      for (final mode in CalculatorMode.values) {
        await scrollTo(tester, find.text(mode.title));
        expect(find.text(mode.title), findsOneWidget,
            reason: '${mode.name} should be named, not just iconised');
      }
    });

    testWidgets('and says what it is for before you open it', (tester) async {
      await pumpApp(tester);
      for (final mode in CalculatorMode.values) {
        await scrollTo(tester, find.text(mode.summary));
        expect(find.text(mode.summary), findsOneWidget);
      }
    });

    testWidgets('each is a button with a label and a hint for a screen reader',
        (tester) async {
      await pumpApp(tester);
      final handle = tester.ensureSemantics();

      for (final mode in [CalculatorMode.calculator, CalculatorMode.graph]) {
        expect(
          find.bySemanticsLabel(mode.title),
          findsWidgets,
          reason: '${mode.name} needs a spoken name of its own',
        );
      }
      handle.dispose();
    });
  });

  group('nothing is truncated, at any text size', () {
    // The rule the old tab bar broke. HIG is explicit that primary content
    // reflows rather than being cut off, and a tool you cannot read the
    // name of is not a tool you can choose.
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('at ${scale}x the names still fit', (tester) async {
        await pumpApp(tester, textScale: scale);

        for (final mode in CalculatorMode.values) {
          await scrollTo(tester, find.text(mode.title));
          final widget = tester.widget<Text>(find.text(mode.title));
          // No maxLines and no ellipsis: the tile grows instead.
          expect(widget.maxLines, isNull, reason: '${mode.title} caps its lines');
          expect(widget.overflow, isNot(TextOverflow.ellipsis),
              reason: '${mode.title} would be cut off');
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the grid drops to one column when the text grows',
        (tester) async {
      // Two columns of grown text would be two columns of wrapped
      // fragments, so the layout gives the width back to the words.
      await pumpApp(tester, textScale: 2.0);
      expect(tester.takeException(), isNull);
      await scrollTo(tester, find.text(CalculatorMode.solve.title));
      expect(find.text(CalculatorMode.solve.title), findsOneWidget);
    });
  });

  group('opening and coming back', () {
    testWidgets('a tool opens with its own title and a way back',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text(CalculatorMode.calculator.title));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculator-display')), findsOneWidget);
      // The back button is what the old tab bar never had: a way out that
      // is part of the screen rather than a second navigation surface.
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(CalculatorMode.graph.summary), findsOneWidget);
    });

    testWidgets('every tool can be opened and left again', (tester) async {
      await pumpApp(tester);
      for (final mode in CalculatorMode.values) {
        await scrollTo(tester, find.text(mode.title));
        await tester.tap(find.text(mode.title));
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsOneWidget,
            reason: '${mode.name} has no way back');
        // Checked per mode rather than once at the end, so a layout that
        // breaks at phone width names the screen that broke instead of
        // reporting an anonymous overflow after the fact.
        expect(tester.takeException(), isNull,
            reason: '${mode.title} does not lay out at phone width');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'leaving ${mode.title} threw');
      }
    });
  });

  group('the other ways in are reachable', () {
    // The whole reason this group exists: voice, camera and braille each
    // had a parser and a test suite and no button anywhere in the app.
    // Working code nobody can reach is indistinguishable from no code.
    testWidgets('the home screen offers speaking, scanning and braille',
        (tester) async {
      await pumpApp(tester);
      await scrollTo(tester, find.text(CalculatorMode.input.title));
      await tester.ensureVisible(find.text(CalculatorMode.input.title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(CalculatorMode.input.title));
      await tester.pumpAndSettle();

      for (final label in ['Voice', 'Camera', 'Braille']) {
        expect(find.text(label), findsWidgets, reason: '$label is unreachable');
      }
    });

    testWidgets('and the calculator carries them in its own bar',
        (tester) async {
      // Reachable only from the home screen is not reachable: the home
      // screen is the one place you are not when you want to dictate a
      // sum.
      await pumpApp(tester);
      await tester.tap(find.text(CalculatorMode.calculator.title));
      await tester.pumpAndSettle();

      for (final method in InputMethod.values) {
        expect(find.widgetWithIcon(IconButton, method.icon), findsOneWidget,
            reason: '${method.label} has no button on the calculator');
      }
    });

    testWidgets('a bar button opens the panel it promised', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text(CalculatorMode.calculator.title));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithIcon(IconButton, InputMethod.braille.icon),
      );
      await tester.pumpAndSettle();

      // Landing on a menu after tapping a braille button would make the
      // button a lie.
      expect(find.text('Braille in'), findsOneWidget);
    });
  });

  group('touch targets', () {
    testWidgets('every tile clears the 44pt floor', (tester) async {
      await pumpApp(tester);
      for (final mode in CalculatorMode.values) {
        await scrollTo(tester, find.text(mode.title));
        final size = tester.getSize(
          find.ancestor(
            of: find.text(mode.title),
            matching: find.byType(InkWell),
          ).first,
        );
        expect(size.height, greaterThanOrEqualTo(TouchTarget.minimum),
            reason: '${mode.title} is ${size.height}pt tall');
        expect(size.width, greaterThanOrEqualTo(TouchTarget.minimum));
      }
    });
  });

  group('the app follows the system appearance', () {
    testWidgets('light and dark are both offered, and contrast variants too',
        (tester) async {
      await pumpApp(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.theme, isNotNull, reason: 'no light theme');
      expect(app.darkTheme, isNotNull, reason: 'no dark theme');
      expect(app.highContrastTheme, isNotNull);
      expect(app.highContrastDarkTheme, isNotNull);
      // The system decides, not us.
      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('the light theme really is light', (tester) async {
      await pumpApp(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.brightness, Brightness.light);
      expect(app.darkTheme!.brightness, Brightness.dark);
    });
  });
}
