import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/expression/render/text_renderer.dart';

void main() {
  const parser = ExpressionParser();
  const evaluator = Evaluator();

  NumberValue eval(String source, [EvaluationContext? ctx]) =>
      evaluator.evaluate(parser.parse(source), ctx ?? const EvaluationContext());

  RationalValue rat(int n, [int d = 1]) =>
      RationalValue(BigInt.from(n), BigInt.from(d));

  group('parsing structure', () {
    test('precedence: multiplication binds tighter than addition', () {
      expect(eval('1 + 2 * 3'), rat(7));
    });

    test('parentheses override precedence', () {
      expect(eval('(1 + 2) * 3'), rat(9));
    });

    test('unary minus binds looser than power, so -2^2 is -4', () {
      expect(eval('-2^2'), rat(-4));
      expect(eval('(-2)^2'), rat(4));
    });

    test('power is right-associative: 2^3^2 is 2^9', () {
      expect(eval('2^3^2'), rat(512));
    });

    test('implicit multiplication', () {
      expect(eval('2(3)'), rat(6));
      expect(eval('(1+2)(3+4)'), rat(21));
      expect(
        eval('2x', const EvaluationContext(variables: {'x': RealValue(5)})).toDouble(),
        closeTo(10, 1e-12),
      );
    });

    test('an implicit product is marked as implicit in the tree', () {
      final tree = parser.parse('2x') as BinaryNode;
      expect(tree.isImplicit, isTrue);
      expect(const TextRenderer().render(tree), '2x');
    });

    test('sqrt parses as a radical node, not a generic function call', () {
      expect(parser.parse('sqrt(9)'), isA<RootNode>());
      expect(parser.parse('√9'), isA<RootNode>());
    });

    test('postfix factorial and percent', () {
      expect(eval('5!'), rat(120));
      expect(eval('50%'), rat(1, 2));
    });
  });

  group('exactness survives the whole pipeline', () {
    test('1/3 + 1/3 + 1/3 is exactly 1', () {
      final result = eval('1/3 + 1/3 + 1/3');
      expect(result, rat(1));
      expect(result.isExact, isTrue);
    });

    test('0.1 + 0.2 is exactly 0.3', () {
      final result = eval('0.1 + 0.2');
      expect(result, rat(3, 10));
      expect(result.isExact, isTrue);
    });

    test('sqrt(16) stays exact but sqrt(2) does not', () {
      expect(eval('sqrt(16)'), rat(4));
      expect(eval('sqrt(16)').isExact, isTrue);
      expect(eval('sqrt(2)').isExact, isFalse);
    });

    test('20 factorial is exact, beyond double precision', () {
      final result = eval('20!') as RationalValue;
      expect(result.numerator.toString(), '2432902008176640000');
    });

    test('the approximate toggle converts an exact result to a decimal', () {
      final approx = eval('1/3', const EvaluationContext(preferExact: false));
      expect(approx.isExact, isFalse);
      expect(approx.toDouble(), closeTo(0.3333333333333333, 1e-15));
    });

    test('floor and round stay exact for rationals', () {
      expect(eval('floor(7/2)'), rat(3));
      expect(eval('ceil(7/2)'), rat(4));
      expect(eval('floor(-7/2)'), rat(-4));
    });
  });

  group('angle modes', () {
    test('sin(90) in degrees is 1', () {
      final result = eval('sin(90)', const EvaluationContext(angleUnit: AngleUnit.degrees));
      expect(result.toDouble(), closeTo(1, 1e-12));
    });

    test('sin(pi/2) in radians is 1', () {
      expect(eval('sin(pi/2)').toDouble(), closeTo(1, 1e-12));
    });

    test('inverse trig returns the context unit', () {
      final degrees =
          eval('asin(1)', const EvaluationContext(angleUnit: AngleUnit.degrees));
      expect(degrees.toDouble(), closeTo(90, 1e-9));
    });

    test('gradians work too', () {
      final result = eval('sin(100)', const EvaluationContext(angleUnit: AngleUnit.gradians));
      expect(result.toDouble(), closeTo(1, 1e-12));
    });
  });

  group('complex results', () {
    test('sqrt of a negative gives an exact imaginary result', () {
      final result = eval('sqrt(-4)') as ComplexValue;
      expect(result.imaginary, rat(2));
      expect(result.isExact, isTrue);
    });

    test('the imaginary unit is available as a constant', () {
      expect(eval('i*i'), rat(-1));
    });
  });

  group('combinatorics', () {
    test('nCr and nPr', () {
      expect(eval('nCr(5, 2)'), rat(10));
      expect(eval('nPr(5, 2)'), rat(20));
    });

    test('nCr with r greater than n is zero', () {
      expect(eval('nCr(2, 5)'), rat(0));
    });

    test('large combinations stay exact', () {
      expect(eval('nCr(50, 25)') as RationalValue,
          RationalValue(BigInt.parse('126410606437752'), BigInt.one));
    });
  });

  group('errors explain themselves', () {
    test('missing closing paren reports a position and a fix', () {
      try {
        parser.parse('2 * (3 + 4');
        fail('should have thrown');
      } on ParseError catch (e) {
        expect(e.message, contains('Missing closing parenthesis'));
        expect(e.suggestion, contains('Add ")"'));
      }
    });

    test('an extra closing paren is reported distinctly', () {
      try {
        parser.parse('2 + 3)');
        fail('should have thrown');
      } on ParseError catch (e) {
        expect(e.message, contains('Unmatched closing parenthesis'));
      }
    });

    test('a trailing operator says what is missing', () {
      try {
        parser.parse('2 +');
        fail('should have thrown');
      } on ParseError catch (e) {
        expect(e.suggestion, contains('Add a value'));
      }
    });

    test('domain errors name the actual constraint', () {
      try {
        eval('asin(5)');
        fail('should have thrown');
      } on MathError catch (e) {
        expect(e.kind, MathErrorKind.domainError);
        expect(e.message, contains('between'));
      }
    });

    test('division by zero is typed, not a crash', () {
      expect(
        () => eval('1/0'),
        throwsA(isA<MathError>()
            .having((e) => e.kind, 'kind', MathErrorKind.divisionByZero)),
      );
    });

    test('an unfilled placeholder refuses to evaluate rather than guessing', () {
      const tree = FractionNode(NumberNode('1'), PlaceholderNode(role: 'denominator'));
      expect(
        () => evaluator.evaluate(tree),
        throwsA(isA<MathError>().having((e) => e.message, 'message', contains('empty slots'))),
      );
    });
  });

  group('the full loop: text in, structure out, many renderings', () {
    test('one source string becomes a tree that evaluates, prints, and speaks', () {
      final tree = parser.parse('sqrt(x^2 + 1)');

      expect(
        const TextRenderer().render(tree),
        '√(x^(2) + 1)',
      );
      expect(
        const SpeechRenderer().render(tree),
        'square root of x squared plus 1, end root',
      );
      expect(
        evaluator
            .evaluate(tree, const EvaluationContext(variables: {'x': RealValue(0)}))
            .toDouble(),
        closeTo(1, 1e-12),
      );
    });

    test('round trip: parse, render to ascii, reparse, same value', () {
      const source = '2 * (3 + 4) / 7';
      final first = parser.parse(source);
      final rendered = const TextRenderer(useUnicodeOperators: false).render(first);
      final second = parser.parse(rendered);
      expect(evaluator.evaluate(second), evaluator.evaluate(first));
    });
  });
}
