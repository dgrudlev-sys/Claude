import 'package:math_expressions/math_expressions.dart';

import 'angle_mode.dart';

/// Thrown when an expression can't be parsed or evaluated.
class CalculatorError implements Exception {
  const CalculatorError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pure math layer: turns a calculator-style expression string into a
/// number. Knows nothing about widgets, buttons, or settings.
///
/// Parsing and evaluation are split ([prepareExpression] /
/// [evaluateExpression]) so callers that need to evaluate the same
/// expression many times with different variable bindings — the graphing
/// sampler evaluating `f(x)` at hundreds of x values, for instance — only
/// pay the parsing cost once.
class CalculatorEngine {
  static const _directTrig = ['sin(', 'cos(', 'tan('];
  static const _inverseTrig = ['arcsin(', 'arccos(', 'arctan('];

  /// Parses [rawExpression] into an [Expression], applying the same
  /// degree-mode rewriting [evaluate] does. Throws [CalculatorError] on
  /// invalid syntax.
  Expression prepareExpression(String rawExpression, AngleMode angleMode) {
    final balanced = _autoCloseParens(rawExpression.trim());
    if (balanced.isEmpty) {
      throw const CalculatorError('Empty expression');
    }

    final prepared = angleMode == AngleMode.degrees
        ? _wrapInverseTrigForDegrees(_wrapDirectTrigForDegrees(balanced))
        : balanced;

    try {
      return GrammarParser().parse(prepared);
    } catch (_) {
      throw const CalculatorError('Syntax error');
    }
  }

  /// Evaluates an already-[prepareExpression]d expression, optionally
  /// binding [variables] (e.g. `{'x': 2.0}`) first.
  double evaluateExpression(Expression expression, {Map<String, double> variables = const {}}) {
    final context = ContextModel();
    for (final entry in variables.entries) {
      context.bindVariableName(entry.key, Number(entry.value));
    }
    try {
      final result = RealEvaluator(context).evaluate(expression);
      final value = result.toDouble();
      if (value.isNaN || value.isInfinite) {
        throw const CalculatorError('Math error');
      }
      return value;
    } on CalculatorError {
      rethrow;
    } catch (_) {
      throw const CalculatorError('Math error');
    }
  }

  /// Evaluates [rawExpression] and returns the numeric result.
  ///
  /// In [AngleMode.degrees], sin/cos/tan take degree input and
  /// arcsin/arccos/arctan return degrees, matching how a physical
  /// scientific calculator behaves — the underlying parser only knows
  /// radians, so this rewrites the expression before evaluating it.
  double evaluate(String rawExpression, AngleMode angleMode) {
    return evaluateExpression(prepareExpression(rawExpression, angleMode));
  }

  /// Appends any closing parentheses the user left off, so `sin(30` still
  /// evaluates instead of erroring — a small, expected convenience.
  String _autoCloseParens(String expr) {
    final openCount = '('.allMatches(expr).length;
    final closeCount = ')'.allMatches(expr).length;
    if (openCount <= closeCount) return expr;
    return expr + ')' * (openCount - closeCount);
  }

  /// Rewrites `sin(x)` → `sin(pi/180*x)` etc. (and equivalent for cos/tan),
  /// without touching `arcsin(`/`arccos(`/`arctan(`.
  String _wrapDirectTrigForDegrees(String expr) {
    var result = expr;
    for (final fn in _directTrig) {
      final name = fn.substring(0, fn.length - 1); // strip trailing '('
      final pattern = RegExp('(?<!arc)$name\\(');
      result = result.replaceAll(pattern, '$name(pi/180*');
    }
    return result;
  }

  /// Rewrites `arcsin(x)` → `(180/pi*arcsin(x))` etc., using paren
  /// matching so nested/compound expressions still balance correctly.
  String _wrapInverseTrigForDegrees(String expr) {
    final insertions = <MapEntry<int, String>>[];
    var i = 0;
    while (i < expr.length) {
      String? matched;
      for (final fn in _inverseTrig) {
        if (expr.startsWith(fn, i)) {
          matched = fn;
          break;
        }
      }
      if (matched == null) {
        i++;
        continue;
      }
      final openParenIndex = i + matched.length - 1;
      var depth = 1;
      var j = openParenIndex + 1;
      while (j < expr.length && depth > 0) {
        if (expr[j] == '(') depth++;
        if (expr[j] == ')') depth--;
        j++;
      }
      insertions.add(MapEntry(i, '(180/pi*'));
      insertions.add(MapEntry(j, ')'));
      i = openParenIndex + 1;
    }

    if (insertions.isEmpty) return expr;
    insertions.sort((a, b) => b.key.compareTo(a.key));
    var result = expr;
    for (final insertion in insertions) {
      result = result.substring(0, insertion.key) +
          insertion.value +
          result.substring(insertion.key);
    }
    return result;
  }
}
