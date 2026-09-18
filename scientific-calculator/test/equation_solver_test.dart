import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/angle_mode.dart';
import 'package:scientific_calculator/core/equation_solver.dart';

void main() {
  group('implicit "= 0" form', () {
    test('solves x^2 - 4 = 0 near the positive root', () {
      final x = EquationSolver.solve('x^2-4', 'x',
          initialGuess: 1, angleMode: AngleMode.radians);
      expect(x, closeTo(2, 1e-6));
    });

    test('solves x^2 - 4 = 0 near the negative root', () {
      final x = EquationSolver.solve('x^2-4', 'x',
          initialGuess: -1, angleMode: AngleMode.radians);
      expect(x, closeTo(-2, 1e-6));
    });
  });

  group('explicit "left = right" form', () {
    test('solves x^2 = 4', () {
      final x = EquationSolver.solve('x^2=4', 'x',
          initialGuess: 1, angleMode: AngleMode.radians);
      expect(x, closeTo(2, 1e-6));
    });

    test('solves 2*x+3 = x+10', () {
      // 2x+3 = x+10 -> x = 7
      final x = EquationSolver.solve('2*x+3=x+10', 'x',
          initialGuess: 0, angleMode: AngleMode.radians);
      expect(x, closeTo(7, 1e-6));
    });

    test('too many "=" signs throws', () {
      expect(
        () => EquationSolver.solve('x=1=2', 'x', initialGuess: 0, angleMode: AngleMode.radians),
        throwsA(isA<EquationSolverError>()),
      );
    });
  });

  test('a transcendental equation: cos(x) = x near 0.7 (the Dottie number)', () {
    final x = EquationSolver.solve('cos(x)=x', 'x', initialGuess: 0.5, angleMode: AngleMode.radians);
    expect(x, closeTo(0.7390851332151607, 1e-6));
  });

  test('does not converge from a hopeless guess on a flat function', () {
    expect(
      () => EquationSolver.solve('0*x+5', 'x', initialGuess: 0, angleMode: AngleMode.radians),
      throwsA(isA<EquationSolverError>()),
    );
  });
}
