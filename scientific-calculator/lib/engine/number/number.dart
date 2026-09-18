/// The calculator's numeric tower.
///
/// Every value the engine produces is one of three kinds, ordered by how
/// much structure they preserve:
///
///   Rational  — exact, BigInt-backed p/q. Integers, fractions, and any
///               decimal the user actually typed.
///   Real      — approximate double. What you get once a result leaves the
///               rational world (sin, ln, sqrt of a non-square).
///   Complex   — a pair of the above, for roots of negatives and complex
///               polynomial roots.
///
/// Operations promote upward and never silently demote: adding a Rational
/// to a Real gives a Real, and anything touching a Complex gives a
/// Complex. Exactness is preserved whenever it legitimately can be —
/// `sqrt(4)` stays the exact integer 2, `sqrt(2)` becomes a Real — which
/// is what lets the UI offer a meaningful "exact vs approximate" toggle
/// rather than always showing a rounded double.
library;

import 'dart:math' as math;

part 'big_int_math.dart';
part 'complex.dart';
part 'rational.dart';
part 'real.dart';

/// What kind of thing went wrong, so the UI can explain it rather than
/// just showing "Error" — the blueprint's "explain errors" requirement
/// needs the reason to survive all the way to the surface.
enum MathErrorKind {
  divisionByZero,
  domainError,
  undefined,
  overflow,
  unsupported,
}

class MathError implements Exception {
  const MathError(this.kind, this.message);

  const MathError.divisionByZero()
      : kind = MathErrorKind.divisionByZero,
        message = 'Division by zero';

  final MathErrorKind kind;
  final String message;

  @override
  String toString() => message;
}

sealed class NumberValue {
  const NumberValue();

  /// Whether this value is mathematically exact. A [RationalValue] always
  /// is; a [RealValue] never is; a [ComplexValue] is exact only when both
  /// of its components are.
  bool get isExact;

  /// Best-effort double, for plotting, comparisons, and anywhere an
  /// approximation is genuinely what's wanted.
  double toDouble();

  bool get isZero;

  NumberValue add(NumberValue other);
  NumberValue subtract(NumberValue other);
  NumberValue multiply(NumberValue other);
  NumberValue divide(NumberValue other);
  NumberValue power(NumberValue exponent);
  NumberValue negate();

  /// Exact where possible (`sqrt(9/4)` → `3/2`), otherwise approximate,
  /// and complex for negatives.
  NumberValue sqrt();

  /// The approximate form of this value — used by the "approximate"
  /// display toggle and by anything that needs a plain decimal.
  NumberValue toApproximate();

  static NumberValue fromInt(int value) => RationalValue.fromInt(value);

  static NumberValue fromDouble(double value) => RealValue(value);

  /// Parses a literal exactly: "0.25" becomes 1/4, not 0.25000000000001.
  /// This is how exactness enters the system from user input.
  static NumberValue parse(String literal) {
    final text = literal.trim();
    if (text.isEmpty) {
      throw const MathError(MathErrorKind.undefined, 'Empty number');
    }
    // Scientific notation stays exact when the mantissa is exact.
    final eIndex = text.indexOf(RegExp('[eE]'));
    if (eIndex != -1) {
      final mantissa = NumberValue.parse(text.substring(0, eIndex));
      final exponent = int.tryParse(text.substring(eIndex + 1));
      if (exponent == null) {
        throw MathError(MathErrorKind.undefined, 'Bad exponent in "$literal"');
      }
      final scale = RationalValue(BigInt.from(10).pow(exponent.abs()), BigInt.one);
      return exponent >= 0 ? mantissa.multiply(scale) : mantissa.divide(scale);
    }

    final dot = text.indexOf('.');
    if (dot == -1) {
      final parsed = BigInt.tryParse(text);
      if (parsed == null) {
        throw MathError(MathErrorKind.undefined, 'Not a number: "$literal"');
      }
      return RationalValue(parsed, BigInt.one);
    }

    final whole = text.substring(0, dot);
    final fraction = text.substring(dot + 1);
    final digits = BigInt.tryParse('${whole.isEmpty ? '0' : whole}$fraction');
    if (digits == null || fraction.contains(RegExp(r'\D'))) {
      throw MathError(MathErrorKind.undefined, 'Not a number: "$literal"');
    }
    return RationalValue(digits, BigInt.from(10).pow(fraction.length));
  }
}

/// Raises both operands to the widest type of the two, so each concrete
/// implementation only has to handle its own kind.
({NumberValue left, NumberValue right}) _promote(NumberValue a, NumberValue b) {
  if (a is ComplexValue || b is ComplexValue) {
    return (left: ComplexValue.from(a), right: ComplexValue.from(b));
  }
  if (a is RealValue || b is RealValue) {
    return (left: RealValue(a.toDouble()), right: RealValue(b.toDouble()));
  }
  return (left: a, right: b);
}
