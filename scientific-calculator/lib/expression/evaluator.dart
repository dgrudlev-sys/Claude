import 'dart:math' as math;

import '../engine/number/number.dart';
import 'expression.dart';

enum AngleUnit { radians, degrees, gradians }

/// Everything evaluation needs that isn't in the tree: angle mode,
/// variable bindings, and whether to keep results exact where possible.
class EvaluationContext {
  const EvaluationContext({
    this.angleUnit = AngleUnit.radians,
    this.variables = const {},
    this.preferExact = true,
  });

  final AngleUnit angleUnit;
  final Map<String, NumberValue> variables;

  /// When false, results are converted to decimals immediately — the
  /// "approximate" side of the exact/approximate toggle.
  final bool preferExact;

  EvaluationContext withVariable(String name, NumberValue value) =>
      EvaluationContext(
        angleUnit: angleUnit,
        variables: {...variables, name: value},
        preferExact: preferExact,
      );
}

/// Evaluates an [ExpressionNode] tree over the numeric tower.
///
/// Exactness is the interesting part: this never converts to double
/// unless the maths actually requires it, so `1/3 + 1/3 + 1/3` comes back
/// as exactly `1` and `sqrt(16)` as exactly `4`, while `sin(1)` and
/// `sqrt(2)` become approximate because they genuinely are.
class Evaluator {
  const Evaluator();

  NumberValue evaluate(ExpressionNode node, [EvaluationContext context = const EvaluationContext()]) {
    if (node.hasPlaceholder) {
      throw const MathError(
        MathErrorKind.undefined,
        'The expression still has empty slots to fill in',
      );
    }
    final result = _eval(node, context);
    return context.preferExact ? result : result.toApproximate();
  }

  NumberValue _eval(ExpressionNode node, EvaluationContext ctx) {
    switch (node) {
      case NumberNode(:final literal):
        return NumberValue.parse(literal);

      case ConstantNode(:final constant):
        return switch (constant) {
          MathConstant.pi => const RealValue(math.pi),
          MathConstant.e => const RealValue(math.e),
          MathConstant.imaginaryUnit =>
            ComplexValue(RationalValue.zero, RationalValue.one),
          MathConstant.goldenRatio => const RealValue(1.618033988749895),
        };

      case VariableNode(:final name):
        final value = ctx.variables[name];
        if (value == null) {
          throw MathError(MathErrorKind.undefined, 'No value assigned to "$name"');
        }
        return value;

      case PlaceholderNode():
        throw const MathError(MathErrorKind.undefined, 'Empty slot');

      case GroupNode(:final inner):
        return _eval(inner, ctx);

      case BinaryNode(:final operator, :final left, :final right):
        final a = _eval(left, ctx);
        final b = _eval(right, ctx);
        return switch (operator) {
          BinaryOperator.add => a.add(b),
          BinaryOperator.subtract => a.subtract(b),
          BinaryOperator.multiply => a.multiply(b),
          BinaryOperator.divide => a.divide(b),
          BinaryOperator.plusMinus => throw const MathError(
            MathErrorKind.unsupported,
            'Plus-or-minus has two values, not one. Ask for both branches '
            'rather than a single result.',
          ),
        BinaryOperator.modulo => _modulo(a, b),
        };

      case UnaryNode(:final operator, :final operand):
        final value = _eval(operand, ctx);
        return switch (operator) {
          UnaryOperator.negate => value.negate(),
          UnaryOperator.factorial => _factorial(value),
          UnaryOperator.percent =>
            value.divide(RationalValue(BigInt.from(100), BigInt.one)),
        };

      case FractionNode(:final numerator, :final denominator):
        return _eval(numerator, ctx).divide(_eval(denominator, ctx));

      case PowerNode(:final base, :final exponent):
        return _eval(base, ctx).power(_eval(exponent, ctx));

      case RootNode(:final radicand, :final index):
        final value = _eval(radicand, ctx);
        if (index == null) return value.sqrt();
        final degree = _eval(index, ctx);
        if (degree.isZero) {
          throw const MathError(MathErrorKind.domainError, 'A root cannot have index 0');
        }
        return value.power(RationalValue.one.divide(degree));

      case AbsoluteNode(:final operand):
        return _absolute(_eval(operand, ctx));

      case FunctionNode(:final name, :final arguments):
        return _callFunction(name, [for (final a in arguments) _eval(a, ctx)], ctx);

      case RelationNode():
        // An equation is a claim, not a quantity. Returning a number here
        // would answer a question nobody asked — solving and evaluating
        // are different operations, and this is the latter.
        throw const MathError(
          MathErrorKind.unsupported,
          'This is an equation, not an expression. Use Solve to find the '
          'value that makes it true.',
        );

      case MatrixNode():
        throw const MathError(
          MathErrorKind.unsupported,
          'Matrices are evaluated by the matrix tools, not as a single value',
        );
    }
  }

  NumberValue _absolute(NumberValue value) {
    if (value is ComplexValue) {
      final re = value.real.toDouble();
      final im = value.imaginary.toDouble();
      return RealValue(math.sqrt(re * re + im * im));
    }
    if (value is RationalValue) {
      return value.isNegative ? value.negate() : value;
    }
    return RealValue(value.toDouble().abs());
  }

  NumberValue _modulo(NumberValue a, NumberValue b) {
    if (b.isZero) throw const MathError.divisionByZero();
    if (a is RationalValue && b is RationalValue && a.isInteger && b.isInteger) {
      return RationalValue(a.numerator % b.numerator, BigInt.one);
    }
    return RealValue(a.toDouble() % b.toDouble());
  }

  /// Exact for non-negative integers, because a factorial of an integer
  /// genuinely is one — 20! stays precise instead of drifting the way a
  /// double would.
  NumberValue _factorial(NumberValue value) {
    if (value is! RationalValue || !value.isInteger || value.isNegative) {
      throw const MathError(
        MathErrorKind.domainError,
        'Factorial needs a whole number that is zero or greater',
      );
    }
    final n = value.numerator;
    if (n > BigInt.from(10000)) {
      throw const MathError(MathErrorKind.overflow, 'That factorial is too large');
    }
    var result = BigInt.one;
    for (var i = BigInt.two; i <= n; i += BigInt.one) {
      result *= i;
    }
    return RationalValue(result, BigInt.one);
  }

  /// Converts an angle from the context's unit into radians, which is
  /// what dart:math works in.
  double _toRadians(NumberValue value, EvaluationContext ctx) => switch (ctx.angleUnit) {
        AngleUnit.radians => value.toDouble(),
        AngleUnit.degrees => value.toDouble() * math.pi / 180,
        AngleUnit.gradians => value.toDouble() * math.pi / 200,
      };

  /// Converts a radian result back into the context's unit.
  NumberValue _fromRadians(double radians, EvaluationContext ctx) => switch (ctx.angleUnit) {
        AngleUnit.radians => RealValue(radians),
        AngleUnit.degrees => RealValue(radians * 180 / math.pi),
        AngleUnit.gradians => RealValue(radians * 200 / math.pi),
      };

  NumberValue _callFunction(String name, List<NumberValue> args, EvaluationContext ctx) {
    void expect(int count) {
      if (args.length != count) {
        throw MathError(
          MathErrorKind.undefined,
          '$name takes $count argument${count == 1 ? '' : 's'}, got ${args.length}',
        );
      }
    }

    double arg0() => args.first.toDouble();

    switch (name) {
      case 'sin':
        expect(1);
        return RealValue(math.sin(_toRadians(args.first, ctx)));
      case 'cos':
        expect(1);
        return RealValue(math.cos(_toRadians(args.first, ctx)));
      case 'tan':
        expect(1);
        return RealValue(math.tan(_toRadians(args.first, ctx)));

      case 'asin' || 'arcsin':
        expect(1);
        if (arg0().abs() > 1) {
          throw const MathError(
            MathErrorKind.domainError,
            'Inverse sine needs a value between −1 and 1',
          );
        }
        return _fromRadians(math.asin(arg0()), ctx);
      case 'acos' || 'arccos':
        expect(1);
        if (arg0().abs() > 1) {
          throw const MathError(
            MathErrorKind.domainError,
            'Inverse cosine needs a value between −1 and 1',
          );
        }
        return _fromRadians(math.acos(arg0()), ctx);
      case 'atan' || 'arctan':
        expect(1);
        return _fromRadians(math.atan(arg0()), ctx);

      case 'sinh':
        expect(1);
        final x = arg0();
        return RealValue((math.exp(x) - math.exp(-x)) / 2);
      case 'cosh':
        expect(1);
        final x = arg0();
        return RealValue((math.exp(x) + math.exp(-x)) / 2);
      case 'tanh':
        expect(1);
        final x = arg0();
        return RealValue((math.exp(2 * x) - 1) / (math.exp(2 * x) + 1));

      case 'ln':
        expect(1);
        if (arg0() <= 0) {
          throw const MathError(
            MathErrorKind.domainError,
            'Natural log needs a value greater than 0',
          );
        }
        return RealValue(math.log(arg0()));
      case 'log':
        if (args.length == 1) {
          if (arg0() <= 0) {
            throw const MathError(
              MathErrorKind.domainError,
              'Log needs a value greater than 0',
            );
          }
          return RealValue(math.log(arg0()) / math.ln10);
        }
        expect(2);
        return RealValue(math.log(args[1].toDouble()) / math.log(args[0].toDouble()));
      case 'exp':
        expect(1);
        return RealValue(math.exp(arg0()));

      case 'sign':
        expect(1);
        final v = arg0();
        return RationalValue.fromInt(v > 0 ? 1 : (v < 0 ? -1 : 0));
      case 'floor':
        expect(1);
        return _roundTo(args.first, (d) => d.floorToDouble(), (r) => _floorRational(r));
      case 'ceil':
        expect(1);
        return _roundTo(args.first, (d) => d.ceilToDouble(), (r) => _ceilRational(r));
      case 'round':
        expect(1);
        return _roundTo(args.first, (d) => d.roundToDouble(), (r) => _roundRational(r));

      case 'min':
        if (args.isEmpty) throw const MathError(MathErrorKind.undefined, 'min needs values');
        return args.reduce((a, b) => a.toDouble() <= b.toDouble() ? a : b);
      case 'max':
        if (args.isEmpty) throw const MathError(MathErrorKind.undefined, 'max needs values');
        return args.reduce((a, b) => a.toDouble() >= b.toDouble() ? a : b);

      case 'gcd':
        expect(2);
        return RationalValue(
          _asBigInt(args[0], 'gcd').gcd(_asBigInt(args[1], 'gcd')),
          BigInt.one,
        );
      case 'lcm':
        expect(2);
        final a = _asBigInt(args[0], 'lcm').abs();
        final b = _asBigInt(args[1], 'lcm').abs();
        if (a == BigInt.zero || b == BigInt.zero) return RationalValue.zero;
        return RationalValue(a ~/ a.gcd(b) * b, BigInt.one);

      case 'nCr':
        expect(2);
        return _combinations(args[0], args[1], ordered: false);
      case 'nPr':
        expect(2);
        return _combinations(args[0], args[1], ordered: true);

      default:
        throw MathError(MathErrorKind.unsupported, 'Unknown function "$name"');
    }
  }

  BigInt _asBigInt(NumberValue value, String context) {
    if (value is RationalValue && value.isInteger) return value.numerator;
    throw MathError(MathErrorKind.domainError, '$context needs whole numbers');
  }

  /// Rounding stays exact for rationals — floor(7/2) is exactly 3, not
  /// 3.0 with the exactness quietly thrown away.
  NumberValue _roundTo(
    NumberValue value,
    double Function(double) approximate,
    BigInt Function(RationalValue) exact,
  ) {
    if (value is RationalValue) return RationalValue(exact(value), BigInt.one);
    return RealValue(approximate(value.toDouble()));
  }

  BigInt _floorRational(RationalValue r) {
    final q = r.numerator ~/ r.denominator;
    return r.isNegative && q * r.denominator != r.numerator ? q - BigInt.one : q;
  }

  BigInt _ceilRational(RationalValue r) {
    final q = r.numerator ~/ r.denominator;
    return !r.isNegative && q * r.denominator != r.numerator ? q + BigInt.one : q;
  }

  BigInt _roundRational(RationalValue r) {
    final doubled = RationalValue(r.numerator * BigInt.two, r.denominator);
    final floorOfHalf = _floorRational(
      RationalValue(doubled.numerator + doubled.denominator, doubled.denominator * BigInt.two),
    );
    return floorOfHalf;
  }

  NumberValue _combinations(NumberValue nValue, NumberValue rValue, {required bool ordered}) {
    final n = _asBigInt(nValue, ordered ? 'nPr' : 'nCr');
    final r = _asBigInt(rValue, ordered ? 'nPr' : 'nCr');
    if (n.isNegative || r.isNegative) {
      throw const MathError(
        MathErrorKind.domainError,
        'Combinations need values of zero or greater',
      );
    }
    if (r > n) return RationalValue.zero;

    // Build the product directly instead of dividing two factorials, so
    // big inputs stay tractable.
    var result = BigInt.one;
    final times = r.toInt();
    for (var i = 0; i < times; i++) {
      result = result * (n - BigInt.from(i));
    }
    if (!ordered) {
      var divisor = BigInt.one;
      for (var i = 1; i <= times; i++) {
        divisor *= BigInt.from(i);
      }
      result = result ~/ divisor;
    }
    return RationalValue(result, BigInt.one);
  }
}
