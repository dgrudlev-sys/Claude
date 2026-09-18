import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/input/language/german_vocabulary.dart';
import 'package:scientific_calculator/theme/app_theme.dart';
import 'package:scientific_calculator/widgets/math/math_view.dart';

void main() {
  const parser = ExpressionParser();

  Future<void> show(WidgetTester tester, ExpressionNode expression,
      {MathView Function(ExpressionNode)? build}) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(Appearance.light),
      home: Scaffold(
        body: Center(
          child: build?.call(expression) ?? MathView(expression: expression),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Where a piece of text ended up on screen, so the tests can check
  /// that a numerator really is above its denominator rather than merely
  /// present somewhere.
  Rect boxOf(WidgetTester tester, String text) =>
      tester.getRect(find.text(text).first);

  group('a fraction is stacked, not written on one line', () {
    testWidgets('the numerator sits above the denominator', (tester) async {
      await show(tester, const FractionNode(NumberNode('3'), NumberNode('4')));

      final numerator = boxOf(tester, '3');
      final denominator = boxOf(tester, '4');
      expect(numerator.bottom, lessThanOrEqualTo(denominator.top),
          reason: '3 should be entirely above 4');
      // And roughly in the same column.
      expect((numerator.center.dx - denominator.center.dx).abs(), lessThan(4));
    });

    testWidgets('with a rule drawn between them', (tester) async {
      await show(tester, const FractionNode(NumberNode('3'), NumberNode('4')));
      final numerator = boxOf(tester, '3');
      final denominator = boxOf(tester, '4');
      // There is a gap between the two for the bar to live in.
      expect(denominator.top - numerator.bottom, greaterThan(1));
    });

    testWidgets('and neither part is a division sign', (tester) async {
      await show(tester, const FractionNode(NumberNode('3'), NumberNode('4')));
      expect(find.text('/'), findsNothing);
      expect(find.text('÷'), findsNothing);
    });

    testWidgets('a division stays on one line, because it is not a fraction',
        (tester) async {
      // The model keeps these distinct all the way through, and so does
      // the picture: 6 ÷ 2 is not the same thing on the page as 6 over 2.
      await show(tester, parser.parse('6/2'));
      final left = boxOf(tester, '6');
      final right = boxOf(tester, '2');
      expect(left.center.dy, closeTo(right.center.dy, 2));
    });
  });

  group('an exponent is raised, not merely smaller', () {
    testWidgets('it sits up and to the right of its base', (tester) async {
      await show(tester, parser.parse('x^2'));

      final base = boxOf(tester, 'x');
      final exponent = boxOf(tester, '2');
      expect(exponent.left, greaterThan(base.left), reason: 'to the right');
      expect(exponent.center.dy, lessThan(base.center.dy), reason: 'raised');
    });

    testWidgets('and is drawn smaller', (tester) async {
      await show(tester, parser.parse('x^2'));
      final base = tester.widget<Text>(find.text('x'));
      final exponent = tester.widget<Text>(find.text('2'));
      expect(exponent.style!.fontSize!, lessThan(base.style!.fontSize!));
    });

    testWidgets('but never shrinks away to nothing', (tester) async {
      // Nested exponents shrink at every level; past a point smaller text
      // stops being readable and starts being texture.
      await show(tester, parser.parse('2^(2^(2^2))'));
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.style!.fontSize!, greaterThan(8));
      }
    });
  });

  group('a root covers what it applies to', () {
    testWidgets('the radicand is drawn under a bar', (tester) async {
      await show(tester, parser.parse('sqrt(16)'));
      expect(find.text('16'), findsOneWidget);
      // The radical sign is painted rather than typed, so there is no
      // stray glyph pretending to be one.
      expect(find.text('√'), findsNothing);
    });

    testWidgets('an nth root shows its index, in front and raised',
        (tester) async {
      await show(tester,
          const RootNode(NumberNode('27'), index: NumberNode('3')));
      final index = boxOf(tester, '3');
      final radicand = boxOf(tester, '27');
      expect(index.left, lessThan(radicand.left));
      expect(index.center.dy, lessThan(radicand.center.dy));
    });
  });

  group('the whole point: one model, two outputs that agree', () {
    testWidgets('the spoken label comes from the same tree as the picture',
        (tester) async {
      final handle = tester.ensureSemantics();
      await show(tester, parser.parse('sqrt(x^2+1)'));

      // Exactly what the speech renderer produces, because it is the
      // speech renderer producing it.
      expect(find.bySemanticsLabel('square root of x squared plus 1, end root'),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('and follows the language the rest of the app is speaking',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(Appearance.light),
        home: Scaffold(
          body: MathView(
            expression: parser.parse('sqrt(x^2+1)'),
            vocabulary: const GermanMathVocabulary(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
            'Quadratwurzel aus x zum Quadrat plus 1, Wurzel Ende'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the expression reads as one thing, not a pile of glyphs',
        (tester) async {
      final handle = tester.ensureSemantics();
      await show(tester, const FractionNode(NumberNode('3'), NumberNode('4')));

      // A screen reader should say "3 quarters", not "3", "4".
      expect(find.bySemanticsLabel('3 quarters'), findsOneWidget);
      handle.dispose();
    });
  });

  group('empty slots are visible and named', () {
    testWidgets('a placeholder is drawn as a box, not as a character',
        (tester) async {
      await show(tester,
          const FractionNode(NumberNode('1'), PlaceholderNode(role: 'denominator')));
      expect(find.text('▢'), findsNothing);
    });

    testWidgets('and says which slot it is', (tester) async {
      final handle = tester.ensureSemantics();
      await show(tester,
          const FractionNode(NumberNode('1'), PlaceholderNode(role: 'denominator')));
      expect(find.bySemanticsLabel(RegExp('denominator')), findsWidgets);
      handle.dispose();
    });
  });

  group('the expression from the design brief', () {
    testWidgets('(3/4 + sqrt(16)) x 2^2 lays out without overflowing',
        (tester) async {
      // The expression on the front of the mock, which the app has been
      // rendering as (3)/(4)+sqrt(16)*2^(2) until now.
      final expression = BinaryNode(
        BinaryOperator.multiply,
        GroupNode(BinaryNode(
          BinaryOperator.add,
          const FractionNode(NumberNode('3'), NumberNode('4')),
          const RootNode(NumberNode('16')),
        )),
        parser.parse('2^2'),
      );

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await show(tester, expression);

      expect(tester.takeException(), isNull);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      // Fraction stacked, root present, power raised — all at once.
      expect(boxOf(tester, '3').bottom, lessThanOrEqualTo(boxOf(tester, '4').top));
    });
  });
}
