import 'angle_mode.dart';
import 'calculator_engine.dart';

class EquationSolverError implements Exception {
  const EquationSolverError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Numeric root-finding (Newton-Raphson with a finite-difference
/// derivative) for "solve for x" — deliberately numeric rather than
/// symbolic, both because it's the same technique a physical calculator's
/// Equation Solver uses (it also asks for a starting guess) and because it
/// works on anything [CalculatorEngine] can evaluate, not just expressions
/// a symbolic differentiator understands.
class EquationSolver {
  /// Solves [equation] for [variable]. If [equation] contains an `=`, the
  /// two sides are solved as `left(x) - right(x) = 0`; otherwise the whole
  /// expression is treated as already being set to zero.
  static double solve(
    String equation,
    String variable, {
    required double initialGuess,
    required AngleMode angleMode,
    int maxIterations = 100,
  }) {
    final engine = CalculatorEngine();
    final parts = equation.split('=');
    if (parts.length > 2) {
      throw const EquationSolverError('Only one "=" is allowed');
    }

    final leftExpr = engine.prepareExpression(parts[0], angleMode);
    final rightExpr = parts.length == 2 ? engine.prepareExpression(parts[1], angleMode) : null;

    double f(double x) {
      final left = engine.evaluateExpression(leftExpr, variables: {variable: x});
      final right = rightExpr == null
          ? 0.0
          : engine.evaluateExpression(rightExpr, variables: {variable: x});
      return left - right;
    }

    var x = initialGuess;
    const h = 1e-6;
    for (var i = 0; i < maxIterations; i++) {
      final fx = f(x);
      if (fx.abs() < 1e-9) return x;

      final derivative = (f(x + h) - f(x - h)) / (2 * h);
      if (derivative.abs() < 1e-12) {
        throw const EquationSolverError(
            'Got stuck at a flat point — try a different starting guess');
      }
      final newX = x - fx / derivative;
      if ((newX - x).abs() < 1e-12) return newX;
      x = newX;
    }
    throw const EquationSolverError('Did not converge — try a different starting guess');
  }
}
