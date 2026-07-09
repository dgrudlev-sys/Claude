import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/angle_mode.dart';
import 'package:scientific_calculator/core/calculator_engine.dart';

void main() {
  final engine = CalculatorEngine();

  group('basic arithmetic', () {
    test('adds', () => expect(engine.evaluate('2+3', AngleMode.radians), 5));
    test('order of operations',
        () => expect(engine.evaluate('2+3*4', AngleMode.radians), 14));
    test('parentheses',
        () => expect(engine.evaluate('(2+3)*4', AngleMode.radians), 20));
    test('auto-closes missing parens',
        () => expect(engine.evaluate('(2+3', AngleMode.radians), 5));
  });

  group('trig — radians', () {
    test('sin(pi/2) is 1', () {
      expect(engine.evaluate('sin(pi/2)', AngleMode.radians), closeTo(1, 1e-9));
    });
  });

  group('trig — degrees', () {
    test('sin(90) is 1', () {
      expect(engine.evaluate('sin(90)', AngleMode.degrees), closeTo(1, 1e-9));
    });
    test('cos(60) is 0.5', () {
      expect(engine.evaluate('cos(60)', AngleMode.degrees), closeTo(0.5, 1e-9));
    });
    test('arcsin(1) is 90 degrees', () {
      expect(engine.evaluate('arcsin(1)', AngleMode.degrees), closeTo(90, 1e-9));
    });
    test('arcsin inside a larger expression only converts its own term', () {
      // arcsin(1) -> 90 degrees, so arcsin(1)+10 should be 100, not
      // (arcsin(1)+10) scaled as a whole.
      expect(engine.evaluate('arcsin(1)+10', AngleMode.degrees), closeTo(100, 1e-9));
    });
    test('does not mistake arcsin for sin', () {
      // If the (?<!arc) guard were missing, this would double-convert.
      expect(engine.evaluate('arcsin(0.5)', AngleMode.degrees), closeTo(30, 1e-6));
    });
  });

  group('functions', () {
    test('sqrt', () => expect(engine.evaluate('sqrt(16)', AngleMode.radians), 4));
    test('ln(e) is 1',
        () => expect(engine.evaluate('ln(e)', AngleMode.radians), closeTo(1, 1e-9)));
    test('log base 10 of 100 is 2',
        () => expect(engine.evaluate('log(10,100)', AngleMode.radians), closeTo(2, 1e-9)));
    test('power', () => expect(engine.evaluate('2^10', AngleMode.radians), 1024));
  });

  group('errors', () {
    test('empty expression throws', () {
      expect(() => engine.evaluate('', AngleMode.radians),
          throwsA(isA<CalculatorError>()));
    });
    test('garbage input throws', () {
      expect(() => engine.evaluate('2++*/', AngleMode.radians),
          throwsA(isA<CalculatorError>()));
    });
    test('division by zero throws', () {
      expect(() => engine.evaluate('1/0', AngleMode.radians),
          throwsA(isA<CalculatorError>()));
    });
  });
}
