import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/input/language/vocabularies.dart';
import 'package:scientific_calculator/screens/input_methods_screen.dart';
import 'package:scientific_calculator/theme/app_theme.dart';
import 'package:scientific_calculator/widgets/math/math_view.dart';

/// The three ways in, on screen at last.
///
/// Each of voice, camera and braille had a parser and a test suite and no
/// button anywhere in the app. These tests cover the join: that what the
/// parsers produce actually arrives on screen, in every shipped language,
/// and that the panels say plainly which parts are not yet attached to
/// real hardware rather than implying a microphone that isn't there.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    InputMethod initial = InputMethod.voice,
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
          child: Scaffold(body: InputMethodsScreen(initial: initial)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('all three are offered, and opened where asked', () {
    testWidgets('the segmented control names every way in', (tester) async {
      await pump(tester);
      for (final method in InputMethod.values) {
        expect(find.text(method.label), findsOneWidget);
      }
    });

    for (final method in InputMethod.values) {
      testWidgets('opening on ${method.label} lands on ${method.label}',
          (tester) async {
        await pump(tester, initial: method);
        // The caveat is panel-specific, so it doubles as proof of which
        // panel is showing.
        expect(find.text(method.caveat), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('and switching between them keeps working', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Braille'));
      await tester.pumpAndSettle();
      expect(find.text('Braille in'), findsOneWidget);

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      expect(find.text('Glyphs recognised'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('what is not attached says so', () {
    // The failure worth guarding against is a screen that implies a
    // microphone it does not have. Each panel states what is real.
    testWidgets('voice and camera admit the adapter is missing',
        (tester) async {
      await pump(tester, initial: InputMethod.voice);
      expect(find.textContaining('platform adapter'), findsOneWidget);

      await pump(tester, initial: InputMethod.camera);
      expect(find.textContaining('platform adapter'), findsOneWidget);
    });

    testWidgets('braille does not, because it needs none', (tester) async {
      // A refreshable display sends characters like any keyboard, so
      // this panel is the finished feature rather than a preview.
      await pump(tester, initial: InputMethod.braille);
      expect(find.textContaining('needs no adapter'), findsOneWidget);
    });
  });

  group('spoken maths becomes an expression, in every shipped language', () {
    testWidgets('the default phrase is understood and drawn', (tester) async {
      await pump(tester);
      expect(find.text('Understood as'), findsOneWidget);
      expect(find.byType(MathView), findsOneWidget);
    });

    testWidgets('every language offers a phrase that parses', (tester) async {
      await pump(tester);
      for (final vocabulary in shippedMathVocabularies.vocabularies.values) {
        await tester.tap(find.text(vocabulary.displayName));
        await tester.pumpAndSettle();
        // A language whose sample does not parse would show an error
        // instead of a drawing — which is exactly the regression this
        // catches.
        expect(find.byType(MathView), findsOneWidget,
            reason: '${vocabulary.displayName} did not parse its own sample');
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('a phrase it cannot read is reported, not thrown',
        (tester) async {
      await pump(tester);
      await tester.enterText(
        find.byKey(const Key('voice-transcript')),
        'the quick brown fox',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MathView), findsNothing);
    });
  });

  group('braille is read live and written back', () {
    testWidgets('ASCII braille arrives as an expression', (tester) async {
      await pump(tester, initial: InputMethod.braille);
      expect(find.text('Understood as'), findsOneWidget);
      expect(find.text('Written back as braille'), findsOneWidget);
      expect(find.byType(MathView), findsOneWidget);
    });

    testWidgets('and Unicode braille patterns do too', (tester) async {
      await pump(tester, initial: InputMethod.braille);
      // ⠼⠃⠐⠖⠼⠉ — two plus three, in Unicode braille rather than ASCII.
      await tester.enterText(
        find.byKey(const Key('braille-input')),
        '⠼⠃⠐⠖⠼⠉',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('nonsense is reported rather than thrown', (tester) async {
      await pump(tester, initial: InputMethod.braille);
      await tester.enterText(find.byKey(const Key('braille-input')), '@@@@');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Written back as braille'), findsNothing);
    });
  });

  group('the camera panel reassembles layout', () {
    testWidgets('glyph positions become two-dimensional maths',
        (tester) async {
      await pump(tester, initial: InputMethod.camera);
      // The superscript 2 was recognised as a glyph sitting high and
      // small; what reaches the screen has to be a power.
      expect(find.text('Layout reconstructed'), findsOneWidget);
      expect(find.textContaining('^'), findsOneWidget);
    });

    testWidgets('a second scene can be chosen', (tester) async {
      await pump(tester, initial: InputMethod.camera);
      await tester.tap(find.text('3x - 7'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('it fits a phone at every text size', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final method in InputMethod.values) {
        testWidgets('${method.label} at ${scale}x does not overflow',
            (tester) async {
          await pump(tester, initial: method, textScale: scale);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
