import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/input/camera/math_layout_reconstructor.dart';

void main() {
  const reconstructor = MathLayoutReconstructor();
  const parser = ExpressionParser();
  const evaluator = Evaluator();

  /// Builds a glyph on a normal baseline: 20 tall, sitting at y=100.
  RecognizedGlyph base(String text, double left, {double width = 12}) =>
      RecognizedGlyph(text: text, left: left, top: 100, width: width, height: 20);

  /// Builds a raised, smaller glyph — what a printed superscript looks
  /// like to a text recogniser.
  RecognizedGlyph sup(String text, double left, {double width = 7}) =>
      RecognizedGlyph(text: text, left: left, top: 92, width: width, height: 11);

  group('superscripts become powers', () {
    test('x squared', () {
      final result = reconstructor.reconstruct([base('x', 0), sup('2', 13)]);
      expect(result.normalizedSource, 'x^(2)');
      expect(
        evaluator
            .evaluate(parser.parse(result.normalizedSource),
                const EvaluationContext(variables: {'x': RealValue(4)}))
            .toDouble(),
        closeTo(16, 1e-12),
      );
    });

    test('a multi-digit exponent stays one exponent', () {
      // x^10 must not read as x^1 followed by a stray 0.
      final result = reconstructor.reconstruct([
        base('x', 0),
        sup('1', 13),
        sup('0', 20),
      ]);
      expect(result.normalizedSource, 'x^(10)');
    });

    test('same-size digits on the baseline are not superscripts', () {
      final result = reconstructor.reconstruct([base('1', 0), base('2', 13)]);
      expect(result.normalizedSource, '12');
    });

    test('a full expression with a power', () {
      // x² + 1
      final result = reconstructor.reconstruct([
        base('x', 0),
        sup('2', 13),
        base('+', 25),
        base('1', 40),
      ]);
      expect(result.normalizedSource, 'x^(2)+1');
    });
  });

  group('fraction bars become fractions', () {
    test('a wide bar with content above and below', () {
      // 1 over 2, drawn as a stacked fraction
      final result = reconstructor.reconstruct([
        const RecognizedGlyph(text: '1', left: 4, top: 70, width: 12, height: 20),
        const RecognizedGlyph(text: '-', left: 0, top: 96, width: 20, height: 3),
        const RecognizedGlyph(text: '2', left: 4, top: 110, width: 12, height: 20),
      ]);
      expect(result.normalizedSource, '(1)/(2)');
      expect(evaluator.evaluate(parser.parse(result.normalizedSource)),
          RationalValue(BigInt.one, BigInt.two));
    });

    test('a narrow dash on the baseline stays a minus sign', () {
      final result = reconstructor.reconstruct([
        base('5', 0),
        const RecognizedGlyph(text: '-', left: 14, top: 108, width: 8, height: 3),
        base('3', 26),
      ]);
      expect(result.normalizedSource, '5-3');
      expect(evaluator.evaluate(parser.parse(result.normalizedSource)),
          RationalValue.fromInt(2));
    });

    test('a compound numerator is grouped', () {
      // (x+1) over 2
      final result = reconstructor.reconstruct([
        const RecognizedGlyph(text: 'x', left: 2, top: 70, width: 12, height: 20),
        const RecognizedGlyph(text: '+', left: 16, top: 70, width: 12, height: 20),
        const RecognizedGlyph(text: '1', left: 30, top: 70, width: 12, height: 20),
        const RecognizedGlyph(text: '—', left: 0, top: 96, width: 46, height: 3),
        const RecognizedGlyph(text: '2', left: 18, top: 110, width: 12, height: 20),
      ]);
      expect(result.normalizedSource, '(x+1)/(2)');
    });

    test('content after the fraction is kept', () {
      // 1/2 + 3
      final result = reconstructor.reconstruct([
        const RecognizedGlyph(text: '1', left: 4, top: 70, width: 12, height: 20),
        const RecognizedGlyph(text: '-', left: 0, top: 96, width: 20, height: 3),
        const RecognizedGlyph(text: '2', left: 4, top: 110, width: 12, height: 20),
        const RecognizedGlyph(text: '+', left: 30, top: 96, width: 12, height: 20),
        const RecognizedGlyph(text: '3', left: 46, top: 96, width: 12, height: 20),
      ]);
      expect(result.normalizedSource, '(1)/(2)+3');
      expect(evaluator.evaluate(parser.parse(result.normalizedSource)),
          RationalValue(BigInt.from(7), BigInt.two));
    });
  });

  group('radicals', () {
    test('a wide radical covers what sits under it', () {
      final result = reconstructor.reconstruct([
        const RecognizedGlyph(text: '√', left: 0, top: 96, width: 40, height: 22),
        base('1', 10),
        base('6', 22),
      ]);
      expect(result.normalizedSource, 'sqrt(16)');
      expect(evaluator.evaluate(parser.parse(result.normalizedSource)),
          RationalValue.fromInt(4));
    });

    test('a narrow radical takes the next glyph and warns about it', () {
      final result = reconstructor.reconstruct([
        const RecognizedGlyph(text: '√', left: 0, top: 96, width: 10, height: 20),
        base('9', 12),
      ]);
      expect(result.normalizedSource, 'sqrt(9)');
      expect(result.warnings.single, contains('check if it should cover more'));
    });
  });

  group('transparency about what was read', () {
    test('low confidence is surfaced as a warning to check', () {
      final result = reconstructor.reconstruct([
        const RecognizedGlyph(
            text: '5', left: 0, top: 100, width: 12, height: 20, confidence: 0.4),
        base('+', 14),
        base('3', 28),
      ]);
      expect(result.confidence, closeTo(0.4, 1e-9));
      expect(result.warnings.any((w) => w.contains('hard to read')), isTrue);
    });

    test('an empty frame reports that nothing was found', () {
      final result = reconstructor.reconstruct([]);
      expect(result.normalizedSource, isEmpty);
      expect(result.warnings.single, contains('Nothing was recognised'));
    });

    test('OCR mangling of operators is corrected', () {
      final result = reconstructor.reconstruct([
        base('6', 0),
        base('÷', 14),
        base('2', 28),
      ]);
      expect(result.normalizedSource, '6/2');
    });
  });

  group('the point of all this: OCR output reaches the same model', () {
    test('a photographed expression evaluates like a typed one', () {
      // Photograph of: x² + 1  (with x = 3)  →  10
      final photographed = reconstructor.reconstruct([
        base('x', 0),
        sup('2', 13),
        base('+', 25),
        base('1', 40),
      ]);
      final fromCamera = parser.parse(photographed.normalizedSource);
      final typed = parser.parse('x^2 + 1');

      const ctx = EvaluationContext(variables: {'x': RealValue(3)});
      expect(
        evaluator.evaluate(fromCamera, ctx).toDouble(),
        evaluator.evaluate(typed, ctx).toDouble(),
      );
    });
  });
}
