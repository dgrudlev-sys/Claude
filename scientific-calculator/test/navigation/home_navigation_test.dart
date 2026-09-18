import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/app.dart';
import 'package:scientific_calculator/design/tokens.dart';
import 'package:scientific_calculator/navigation/calculator_mode.dart';
import 'package:scientific_calculator/navigation/tool_catalog.dart';
import 'package:scientific_calculator/screens/input_methods_screen.dart';
import 'package:scientific_calculator/services/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the navigation has to do, now that the app has four destinations
/// and a browsable catalog behind one of them.
///
/// Two earlier shapes failed here and both failures are still worth
/// guarding against. A scrolling bar of eight icon tabs clipped its own
/// last label mid-word with nothing to say that scrolling would reveal
/// it. A wall of tiles fixed the clipping and lost the calculator — you
/// had to open it, and come back out of it, like any other tool.
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

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    if (target.evaluate().isNotEmpty) return;
    await tester.scrollUntilVisible(target, 120,
        scrollable: find.byType(Scrollable).first);
  }

  group('the app opens on the calculator', () {
    testWidgets('and the calculator is a place, not a thing you open',
        (tester) async {
      // The wall of tiles made the calculator one tool among eight. It
      // is the app; everything else is in support of it.
      await pumpApp(tester);
      expect(find.byKey(const Key('calculator-display')), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('all four destinations are named, not just iconised',
        (tester) async {
      await pumpApp(tester);
      for (final label in ['Calculator', 'Formulas', 'History', 'Settings']) {
        expect(find.text(label), findsWidgets, reason: '$label is unnamed');
      }
    });

    testWidgets('and there are four of them, which is inside the cap',
        (tester) async {
      // The guideline caps a tab bar at five and treats more as a sign
      // the information architecture needs rethinking rather than a
      // wider bar. Eight was the old mistake.
      await pumpApp(tester);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.length, lessThanOrEqualTo(5));
    });
  });

  group('every tool announces itself in the browser', () {
    testWidgets('the top level names each group and says what it holds',
        (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Formulas');

      for (final node in toolCatalog) {
        await scrollTo(tester, find.text(node.title));
        expect(find.text(node.title), findsOneWidget, reason: node.title);
        expect(find.text(node.summary), findsOneWidget,
            reason: '${node.title} does not say what it is for');
      }
    });

    testWidgets('each row is a button with a label and a hint',
        (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Formulas');
      final handle = tester.ensureSemantics();

      expect(find.bySemanticsLabel('Mathematics'), findsWidgets);
      expect(find.bySemanticsLabel('Unit converter'), findsWidgets);
      handle.dispose();
    });

    testWidgets('a group opens onto its children with a way back',
        (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Formulas');
      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(find.text('Graphs'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Unit converter'), findsOneWidget);
    });

    testWidgets('and search reaches a tool without knowing where it lives',
        (tester) async {
      // "gallon" is nowhere in the converter's title — it is in the
      // catalog's keywords, which is the point of having them.
      await pumpApp(tester);
      await openTab(tester, 'Formulas');
      await tester.enterText(find.byType(TextField).first, 'gallon');
      await tester.pumpAndSettle();

      expect(find.text('Unit converter'), findsOneWidget);
      expect(find.text('Mathematics'), findsNothing);
    });

    testWidgets('a search with no answer says so rather than emptying out',
        (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Formulas');
      await tester.enterText(find.byType(TextField).first, 'xylophone');
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing matches'), findsOneWidget);
    });
  });

  group('nothing is truncated, at any text size', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('at ${scale}x the names still fit', (tester) async {
        await pumpApp(tester, textScale: scale);
        await openTab(tester, 'Formulas');

        for (final node in toolCatalog) {
          await scrollTo(tester, find.text(node.title));
          final widget = tester.widget<Text>(find.text(node.title));
          // No maxLines and no ellipsis: the row grows instead.
          expect(widget.maxLines, isNull, reason: '${node.title} caps lines');
          expect(widget.overflow, isNot(TextOverflow.ellipsis),
              reason: '${node.title} would be cut off');
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('and the calculator itself survives doubled text',
        (tester) async {
      await pumpApp(tester, textScale: 2.0);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('calculator-display')), findsOneWidget);
    });
  });

  group('the other ways in are reachable', () {
    // Voice, camera and braille each had a parser and a test suite and no
    // button anywhere in the app. Working code nobody can reach is
    // indistinguishable from no code.
    testWidgets('the calculator offers them directly under the display',
        (tester) async {
      // Under the readout rather than in the navigation bar, which is
      // where you look for settings, not for a microphone.
      await pumpApp(tester);
      for (final method in InputMethod.values) {
        expect(find.text(method.label), findsOneWidget,
            reason: '${method.label} is not offered on the calculator');
      }
    });

    testWidgets('and tapping one opens the panel it promised',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text(InputMethod.braille.label));
      await tester.pumpAndSettle();
      expect(find.text('Braille in'), findsOneWidget);
    });

    testWidgets('the browser offers them too', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Formulas');
      await scrollTo(tester, find.text('Speak or scan'));
      await tester.tap(find.text('Speak or scan'));
      await tester.pumpAndSettle();
      expect(find.text('Voice'), findsWidgets);
    });
  });

  group('history is shared with the calculator', () {
    testWidgets('a result worked out on one tab appears on the other',
        (tester) async {
      // Two controllers would give a history tab that is always empty —
      // the kind of bug that survives to release because each half
      // works on its own.
      await pumpApp(tester);
      for (final key in ['7', '+', '8', '=']) {
        await tester.tap(find.widgetWithText(InkWell, key).first);
        await tester.pumpAndSettle();
      }

      await openTab(tester, 'History');
      expect(find.text('15'), findsWidgets);
      expect(find.text('Nothing yet'), findsNothing);
    });

    testWidgets('and an empty history explains itself', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'History');
      expect(find.text('Nothing yet'), findsOneWidget);
      // Honest about the limit rather than letting someone find out by
      // losing something.
      expect(find.textContaining('not saved to your device'), findsOneWidget);
    });
  });

  group('touch targets', () {
    testWidgets('every browser row clears the 44pt floor', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Formulas');

      for (final node in toolCatalog) {
        await scrollTo(tester, find.text(node.title));
        final size = tester.getSize(
          find
              .ancestor(
                of: find.text(node.title),
                matching: find.byType(InkWell),
              )
              .first,
        );
        expect(size.height, greaterThanOrEqualTo(TouchTarget.minimum),
            reason: '${node.title} is ${size.height}pt tall');
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

    testWidgets('and the bundled typeface is actually applied',
        (tester) async {
      // A font declared in the manifest and never named in the theme is
      // two megabytes of nothing.
      await pumpApp(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.textTheme.bodyLarge!.fontFamily, 'Inter');
    });
  });

  group('every tool still opens and closes', () {
    testWidgets('each leaf in the catalog lays out at phone width',
        (tester) async {
      await pumpApp(tester);

      for (final entry in allToolEntries) {
        await openTab(tester, 'Formulas');
        await tester.enterText(find.byType(TextField).first, entry.title);
        await tester.pumpAndSettle();

        final row = find.text(entry.title).last;
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.tap(row);
        await tester.pumpAndSettle();

        expect(find.byType(BackButton), findsOneWidget,
            reason: '${entry.title} has no way back');
        // Checked per tool rather than once at the end, so a layout that
        // breaks names the screen that broke.
        expect(tester.takeException(), isNull,
            reason: '${entry.title} does not lay out at phone width');

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'leaving ${entry.title} threw');
      }
    });

    testWidgets('and every mode the catalog can reach is accounted for',
        (tester) async {
      // A mode with no row anywhere is a screen nobody can open.
      final reachable = {for (final entry in allToolEntries) entry.mode};
      final missing = CalculatorMode.values.toSet().difference(reachable)
        ..remove(CalculatorMode.calculator); // its own tab
      expect(missing, isEmpty,
          reason: 'unreachable modes: ${missing.map((m) => m.name).join(', ')}');
    });
  });
}
