import 'package:math_expressions/math_expressions.dart';

class SymbolicError implements Exception {
  const SymbolicError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Symbolic differentiation and simplification, built directly on
/// `math_expressions`' own `Expression.derive`/`Expression.simplify` —
/// this is not a from-scratch computer algebra system, just exposing the
/// symbolic primitives the parsing library already provides. Full
/// symbolic equation solving (isolating x algebraically) is out of scope;
/// see [EquationSolver] for the numeric alternative used instead.
class SymbolicMath {
  static String derivative(String expression, String variable) {
    try {
      final parsed = GrammarParser().parse(expression);
      final derived = parsed.derive(variable).simplify();
      return derived.toString();
    } catch (_) {
      throw const SymbolicError('Could not differentiate this expression');
    }
  }

  static String simplify(String expression) {
    try {
      final parsed = GrammarParser().parse(expression);
      return parsed.simplify().toString();
    } catch (_) {
      throw const SymbolicError('Could not simplify this expression');
    }
  }
}
