import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/convert/unit.dart';
import 'package:scientific_calculator/screens/convert_screen.dart';
import 'package:scientific_calculator/theme/app_theme.dart';

/// The converter screen, which until now did not exist.
///
/// The conversion engine has been finished and tested for a while; what
/// was missing was any way to reach it. These tests check the part a unit
/// test of the engine cannot see — that the numbers arrive on screen, in
/// a readable form, with the exactness claim attached to them.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    Size surface = const Size(412, 915),
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Appearance.light),
        home: MediaQuery(
          data: MediaQueryData(
            size: surface,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(body: ConvertScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isNotEmpty) return;
    await tester.scrollUntilVisible(target, 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Future<void> enterAmount(WidgetTester tester, String amount) async {
    await reveal(tester, find.byKey(const Key('convert-amount')));
    await tester.enterText(find.byKey(const Key('convert-amount')), amount);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String field, String unit) async {
    await reveal(tester, find.byKey(Key('convert-$field')));
    await tester.tap(find.byKey(Key('convert-$field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(unit).last);
    await tester.pumpAndSettle();
  }

  group('a conversion reaches the screen', () {
    testWidgets('it opens on something usable rather than empty',
        (tester) async {
      await pump(tester);
      expect(find.byKey(const Key('convert-amount')), findsOneWidget);
      expect(find.text('Length'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a mile really is 1609.344 metres, in full', (tester) async {
      await pump(tester);
      await choose(tester, 'From', 'Mile (mi)');
      await choose(tester, 'To', 'Metre (m)');
      await enterAmount(tester, '1');

      // Not 1609.34: the definition is exact and the display says so.
      expect(find.text('1609.344'), findsOneWidget);
      expect(find.text('Exactly'), findsOneWidget);
    });

    testWidgets('and an approximation is labelled as one', (tester) async {
      await pump(tester);
      await choose(tester, 'From', 'Mile (mi)');
      await choose(tester, 'To', 'Metre (m)');
      await enterAmount(tester, '1.7');

      // 1.7 miles is 2735.8848 m exactly — still exact. What is not is
      // a category whose factor involves π, checked below.
      expect(find.text('Exactly'), findsOneWidget);
    });

    testWidgets('a factor through π is never claimed to be exact',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Angle'));
      await tester.pumpAndSettle();
      await choose(tester, 'From', 'Degree (°)');
      await choose(tester, 'To', 'Radian (rad)');
      await enterAmount(tester, '180');

      expect(find.text('Approximately'), findsOneWidget);
      expect(find.text('Exactly'), findsNothing);
    });
  });

  group('the whole picture, not one pairing', () {
    testWidgets('the rest of the category is listed underneath',
        (tester) async {
      await pump(tester);
      await enterAmount(tester, '1');
      // Whichever two units are selected, the others are still shown —
      // the useful question is usually "and what is that in everything
      // else".
      await tester.scrollUntilVisible(
        find.text('The same amount, everywhere else'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('The same amount, everywhere else'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Mile'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Mile'), findsOneWidget);
    });

    testWidgets('every category opens on a pair worth seeing', (tester) async {
      // A mistyped default id would fall back silently to the first two
      // units in the catalog — metres into kilometres, whose answer is
      // 0.001. This walks every category so that stays a caught bug
      // rather than a quiet disappointment.
      await pump(tester, surface: const Size(412, 1400));
      for (final category in UnitCategory.values) {
        final chip = find.text(category.displayName);
        if (chip.evaluate().isEmpty) continue;
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: category.name);
        // 1 of the source unit converted to itself would mean the
        // fallback pair collapsed to one unit.
        expect(find.text('Swap'), findsOneWidget, reason: category.name);
      }
    });

    testWidgets('length opens on metres and feet, not metres and kilometres',
        (tester) async {
      await pump(tester);
      expect(find.text('Metre (m)'), findsOneWidget);
      expect(find.text('Foot (ft)'), findsOneWidget);
    });

    testWidgets('switching category switches both units with it',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Temperature'));
      await tester.pumpAndSettle();

      // Leaving "metre" selected under Temperature would be an offer to
      // convert kilograms into metres — the exact mistake the engine's
      // category rule exists to prevent.
      expect(find.text('Metre (m)'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('it holds together when things go wrong', () {
    testWidgets('nonsense in the amount field is reported, not thrown',
        (tester) async {
      await pump(tester);
      await enterAmount(tester, 'banana');
      expect(find.text('That is not a number.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('below absolute zero is a warning, not an error',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Temperature'));
      await tester.pumpAndSettle();
      await enterAmount(tester, '-500');

      // The arithmetic is fine; the physics is not, and the screen says
      // which.
      expect(
        find.textContaining('below absolute zero'),
        findsOneWidget,
      );
    });

    testWidgets('an empty field does not crash mid-typing', (tester) async {
      await pump(tester);
      await enterAmount(tester, '');
      expect(tester.takeException(), isNull);
    });
  });

  group('it survives a phone and grown text', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('at ${scale}x nothing overflows', (tester) async {
        await pump(tester, textScale: scale);
        await enterAmount(tester, '12345');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('grown text does not bury the amount field under chips',
        (tester) async {
      // Fifteen wrapped chips at double size fill the screen on their
      // own. Opening a converter and seeing no way to type a number in
      // is a broken screen, however well it wraps.
      await pump(tester, textScale: 2.0);
      expect(find.byKey(const Key('convert-amount')), findsOneWidget);
      expect(find.byKey(const Key('convert-category')), findsOneWidget);
    });

    testWidgets('a very long result shrinks rather than overflowing',
        (tester) async {
      await pump(tester, surface: const Size(320, 640));
      await choose(tester, 'From', 'Kilometre (km)');
      await choose(tester, 'To', 'Millimetre (mm)');
      await enterAmount(tester, '987654321');
      expect(tester.takeException(), isNull);
    });
  });
}
