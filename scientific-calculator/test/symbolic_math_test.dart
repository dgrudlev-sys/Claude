import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/angle_mode.dart';
import 'package:scientific_calculator/core/calculator_engine.dart';
import 'package:scientific_calculator/core/symbolic_math.dart';

void main() {
  final engine = CalculatorEngine();

  // Derivative correctness is checked behaviorally — re-evaluate the
  // returned expression string at sample points and compare against the
  // known closed-form derivative — rather than asserting exact string
  // formatting, which is an implementation detail of math_expressions'
  // Expression.toString() this app doesn't control.
  double evalAt(String expr, double x) =>
      engine.evaluate(expr.replaceAll('x', '($x)'), AngleMode.radians);

  group('derivative', () {
    test('d/dx(x^2) = 2x', () {
      final derived = SymbolicMath.derivative('x^2', 'x');
      for (final x in [1.0, 2.0, 5.0, -3.0]) {
        expect(evalAt(derived, x), closeTo(2 * x, 1e-6));
      }
    });

    test('d/dx(x^3) = 3x^2', () {
      final derived = SymbolicMath.derivative('x^3', 'x');
      for (final x in [1.0, 2.0, -2.0]) {
        expect(evalAt(derived, x), closeTo(3 * x * x, 1e-6));
      }
    });

    test('d/dx(sin(x)) = cos(x)', () {
      final derived = SymbolicMath.derivative('sin(x)', 'x');
      for (final x in [0.0, 0.5, 1.0, 2.0]) {
        final expected = engine.evaluate('cos($x)', AngleMode.radians);
        expect(evalAt(derived, x), closeTo(expected, 1e-6));
      }
    });

    test('invalid expression throws', () {
      expect(() => SymbolicMath.derivative('2+*/', 'x'), throwsA(isA<SymbolicError>()));
    });
  });

  group('simplify', () {
    test('preserves the value of the expression', () {
      final simplified = SymbolicMath.simplify('x*1 - (-5)');
      for (final x in [0.0, 3.0, -7.0]) {
        final original = evalAt('x*1 - (-5)', x);
        expect(evalAt(simplified, x), closeTo(original, 1e-9));
      }
    });
  });
}
