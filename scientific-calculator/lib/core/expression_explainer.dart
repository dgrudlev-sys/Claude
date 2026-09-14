import 'package:math_expressions/math_expressions.dart';

import 'angle_mode.dart';
import 'calculator_engine.dart';
import 'explanation.dart';

class _Node {
  const _Node({required this.symbols, required this.value, required this.steps});

  final String symbols;
  final double value;
  final List<ExplanationStep> steps;
}

/// Walks an expression tree and writes plain-language beats (words + symbols).
class ExpressionExplainer {
  ExpressionExplainer({CalculatorEngine? engine}) : _engine = engine ?? CalculatorEngine();

  final CalculatorEngine _engine;

  /// Explains [rawExpression] the way the keypad would evaluate it.
  Explanation explain(String rawExpression, AngleMode angleMode) {
    final trimmed = rawExpression.trim();
    if (trimmed.isEmpty) return const Explanation(steps: []);
    try {
      final parsed = GrammarParser().parse(_autoClose(trimmed));
      final walked = _walk(parsed, angleMode);
      return Explanation(steps: walked.steps);
    } catch (_) {
      return const Explanation(steps: []);
    }
  }

  String _autoClose(String expr) {
    final openCount = '('.allMatches(expr).length;
    final closeCount = ')'.allMatches(expr).length;
    if (openCount <= closeCount) return expr;
    return expr + ')' * (openCount - closeCount);
  }

  Expression _unwrap(Expression e) {
    if (e is BoundVariable) {
      final inner = e.value;
      if (inner is Expression) return _unwrap(inner);
    }
    return e;
  }

  _Node _walk(Expression raw, AngleMode mode) {
    final e = _unwrap(raw);
    if (e is Number) {
      final v = (e.value as num).toDouble();
      return _Node(symbols: formatExplainNumber(v), value: v, steps: const []);
    }
    if (e is Variable) {
      return _variable(e, mode);
    }
    if (e is UnaryMinus) {
      return _unary(e.exp, mode, op: '-');
    }
    if (e is Plus) {
      return _binary(e.first, e.second, mode, symbol: '+', wordsOf: (l, r) => 'Adding $l and $r.');
    }
    if (e is Minus) {
      return _binary(e.first, e.second, mode, symbol: '−', wordsOf: (l, r) => 'Subtracting $r from $l.');
    }
    if (e is Times) {
      return _binary(
        e.first,
        e.second,
        mode,
        symbol: '×',
        wordsOf: (l, r) => 'Multiply $l and $r; multiplication takes precedence here.',
      );
    }
    if (e is Divide) {
      return _binary(e.first, e.second, mode, symbol: '÷', wordsOf: (l, r) => 'Dividing $l by $r.');
    }
    if (e is Power) {
      return _binary(
        e.first,
        e.second,
        mode,
        symbol: '^',
        wordsOf: (l, r) => 'Raising $l to the power of $r.',
      );
    }
    if (e is Modulo) {
      return _binary(
        e.first,
        e.second,
        mode,
        symbol: 'mod',
        wordsOf: (l, r) => 'The remainder after dividing $l by $r.',
      );
    }
    if (e is Sin) return _trig(e.arg, mode, 'sine', 'sin');
    if (e is Cos) return _trig(e.arg, mode, 'cosine', 'cos');
    if (e is Tan) return _trig(e.arg, mode, 'tangent', 'tan');
    if (e is Asin) return _trig(e.arg, mode, 'arcsine', 'arcsin', inverse: true);
    if (e is Acos) return _trig(e.arg, mode, 'arccosine', 'arccos', inverse: true);
    if (e is Atan) return _trig(e.arg, mode, 'arctangent', 'arctan', inverse: true);
    if (e is Sqrt) {
      return _fn1(e.arg, mode, wordsOf: (s) => 'Square root of $s.', name: '√', evalName: 'sqrt');
    }
    if (e is Ln) {
      return _fn1(
        e.arg,
        mode,
        wordsOf: (s) => 'Natural logarithm of $s (base e).',
        name: 'ln',
        evalName: 'ln',
      );
    }
    if (e is Log) {
      return _log(e, mode);
    }
    if (e is Abs) {
      return _fn1(e.arg, mode, wordsOf: (s) => 'Absolute value of $s.', name: 'abs', evalName: 'abs');
    }
    if (e is Exponential) {
      return _fn1(
        e.exp,
        mode,
        wordsOf: (s) => 'e raised to the power $s.',
        name: 'e^',
        evalName: 'e^',
      );
    }
    if (e is Root) {
      return _root(e, mode);
    }
    return _fallback(e, mode);
  }

  _Node _variable(Variable e, AngleMode mode) {
    if (e.name == 'pi') {
      final v = _eval('pi', mode);
      return _Node(symbols: 'π', value: v, steps: const []);
    }
    if (e.name == 'e') {
      final v = _eval('e', mode);
      return _Node(symbols: 'e', value: v, steps: const []);
    }
    final v = _eval(e.name, mode);
    return _Node(symbols: e.name, value: v, steps: const []);
  }

  _Node _binary(
    Expression leftRaw,
    Expression rightRaw,
    AngleMode mode, {
    required String Function(String left, String right) wordsOf,
    required String symbol,
  }) {
    final left = _walk(leftRaw, mode);
    final right = _walk(rightRaw, mode);
    final value = _eval('(${_evalString(leftRaw)})${_evalOp(symbol)}(${_evalString(rightRaw)})', mode);
    return _Node(
      symbols: formatExplainNumber(value),
      value: value,
      steps: [
        ...left.steps,
        ...right.steps,
        ExplanationStep(
          words: wordsOf(left.symbols, right.symbols),
          symbols: '${left.symbols} $symbol ${right.symbols} = ${formatExplainNumber(value)}',
        ),
      ],
    );
  }

  String _evalOp(String symbol) {
    return switch (symbol) {
      '×' => '*',
      '÷' => '/',
      '−' => '-',
      'mod' => '%',
      _ => symbol,
    };
  }

  _Node _unary(Expression innerRaw, AngleMode mode, {required String op}) {
    final inner = _walk(innerRaw, mode);
    final value = _eval('(-(${_evalString(innerRaw)}))', mode);
    return _Node(
      symbols: formatExplainNumber(value),
      value: value,
      steps: [
        ...inner.steps,
        ExplanationStep(
          words: 'Negating ${inner.symbols}.',
          symbols: '$op(${inner.symbols}) = ${formatExplainNumber(value)}',
        ),
      ],
    );
  }

  _Node _trig(Expression argRaw, AngleMode mode, String word, String name, {bool inverse = false}) {
    final inner = _walk(argRaw, mode);
    final unit = mode == AngleMode.degrees ? 'degrees' : 'radians';
    final value = _eval('$name(${_evalString(argRaw)})', mode);
    final unitHint = inverse
        ? 'The result is an angle in $unit.'
        : 'The input is in $unit.';
    return _Node(
      symbols: formatExplainNumber(value),
      value: value,
      steps: [
        ...inner.steps,
        ExplanationStep(
          words: '${word[0].toUpperCase()}${word.substring(1)} of ${inner.symbols}. $unitHint',
          symbols: '$name(${inner.symbols}) = ${formatExplainNumber(value)}',
        ),
      ],
    );
  }

  _Node _fn1(
    Expression argRaw,
    AngleMode mode, {
    required String Function(String input) wordsOf,
    required String name,
    required String evalName,
  }) {
    final inner = _walk(argRaw, mode);
    final call = evalName == 'e^' ? 'e^(${_evalString(argRaw)})' : '$evalName(${_evalString(argRaw)})';
    final value = _eval(call, mode);
    final shown = name == '√'
        ? '√(${inner.symbols})'
        : name == 'e^'
            ? 'e^(${inner.symbols})'
            : '$name(${inner.symbols})';
    return _Node(
      symbols: formatExplainNumber(value),
      value: value,
      steps: [
        ...inner.steps,
        ExplanationStep(
          words: wordsOf(inner.symbols),
          symbols: '$shown = ${formatExplainNumber(value)}',
        ),
      ],
    );
  }

  _Node _log(Log e, AngleMode mode) {
    if (e is Ln) {
      return _fn1(e.arg, mode, wordsOf: (s) => 'Natural logarithm of $s (base e).', name: 'ln', evalName: 'ln');
    }
    final base = _walk(e.base, mode);
    final arg = _walk(e.arg, mode);
    final value = _eval('log(${_evalString(e.base)},${_evalString(e.arg)})', mode);
    return _Node(
      symbols: formatExplainNumber(value),
      value: value,
      steps: [
        ...base.steps,
        ...arg.steps,
        ExplanationStep(
          words: 'Logarithm of ${arg.symbols} in base ${base.symbols}: the exponent that raises the base to this value.',
          symbols: 'log_${base.symbols}(${arg.symbols}) = ${formatExplainNumber(value)}',
        ),
      ],
    );
  }

  _Node _root(Root e, AngleMode mode) {
    final n = _walk(e.n, mode);
    final arg = _walk(e.arg, mode);
    final value = _eval('nrt(${_evalString(e.n)},${_evalString(e.arg)})', mode);
    return _Node(
      symbols: formatExplainNumber(value),
      value: value,
      steps: [
        ...n.steps,
        ...arg.steps,
        ExplanationStep(
          words: 'The ${n.symbols}-th root of ${arg.symbols}.',
          symbols: 'ⁿ√(${arg.symbols}) = ${formatExplainNumber(value)}'.replaceFirst('ⁿ', n.symbols),
        ),
      ],
    );
  }

  _Node _fallback(Expression e, AngleMode mode) {
    try {
      final value = _eval(_evalString(e), mode);
      return _Node(
        symbols: formatExplainNumber(value),
        value: value,
        steps: [
          ExplanationStep(
            words: 'This part evaluates to a single value.',
            symbols: '${e.toString()} = ${formatExplainNumber(value)}',
          ),
        ],
      );
    } catch (_) {
      return _Node(symbols: e.toString(), value: double.nan, steps: const []);
    }
  }

  String _evalString(Expression raw) {
    final e = _unwrap(raw);
    if (e is Number) return (e.value as num).toString();
    if (e is Variable) return e.name;
    if (e is UnaryMinus) return '(-(${_evalString(e.exp)}))';
    if (e is Plus) return '(${_evalString(e.first)}+${_evalString(e.second)})';
    if (e is Minus) return '(${_evalString(e.first)}-${_evalString(e.second)})';
    if (e is Times) return '(${_evalString(e.first)}*${_evalString(e.second)})';
    if (e is Divide) return '(${_evalString(e.first)}/${_evalString(e.second)})';
    if (e is Power) return '(${_evalString(e.first)}^${_evalString(e.second)})';
    if (e is Modulo) return '(${_evalString(e.first)}%${_evalString(e.second)})';
    if (e is Sin) return 'sin(${_evalString(e.arg)})';
    if (e is Cos) return 'cos(${_evalString(e.arg)})';
    if (e is Tan) return 'tan(${_evalString(e.arg)})';
    if (e is Asin) return 'arcsin(${_evalString(e.arg)})';
    if (e is Acos) return 'arccos(${_evalString(e.arg)})';
    if (e is Atan) return 'arctan(${_evalString(e.arg)})';
    if (e is Sqrt) return 'sqrt(${_evalString(e.arg)})';
    if (e is Ln) return 'ln(${_evalString(e.arg)})';
    if (e is Log) return 'log(${_evalString(e.base)},${_evalString(e.arg)})';
    if (e is Abs) return 'abs(${_evalString(e.arg)})';
    if (e is Exponential) return 'e^(${_evalString(e.exp)})';
    if (e is Root) return 'nrt(${_evalString(e.n)},${_evalString(e.arg)})';
    return e.toString();
  }

  double _eval(String expr, AngleMode mode) => _engine.evaluate(expr, mode);
}
