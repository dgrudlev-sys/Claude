part of 'number.dart';

/// The decimal expansion of a rational, split so the UI can render the
/// repeating part with an overbar: 1/3 → "0." + "" + "3̅", 1/6 → "0.1" +
/// "6̅", 1/4 → "0.25" with nothing repeating.
class DecimalExpansion {
  const DecimalExpansion({
    required this.isNegative,
    required this.integerPart,
    required this.nonRepeating,
    required this.repeating,
    required this.truncated,
  });

  final bool isNegative;
  final String integerPart;
  final String nonRepeating;
  final String repeating;

  /// True when the expansion was cut off at the digit budget rather than
  /// actually terminating or repeating — the value is longer than shown.
  final bool truncated;

  bool get terminates => repeating.isEmpty && !truncated;
}

/// An exact rational number, always stored in lowest terms with a
/// positive denominator.
final class RationalValue extends NumberValue {
  factory RationalValue(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw const MathError.divisionByZero();
    }
    var n = numerator;
    var d = denominator;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final divisor = n.gcd(d);
    if (divisor > BigInt.one) {
      n = n ~/ divisor;
      d = d ~/ divisor;
    }
    return RationalValue._(n, d);
  }

  const RationalValue._(this.numerator, this.denominator);

  factory RationalValue.fromInt(int value) =>
      RationalValue._(BigInt.from(value), BigInt.one);

  factory RationalValue.fromBigInt(BigInt value) =>
      RationalValue._(value, BigInt.one);

  static final zero = RationalValue._(BigInt.zero, BigInt.one);
  static final one = RationalValue._(BigInt.one, BigInt.one);

  final BigInt numerator;
  final BigInt denominator;

  bool get isInteger => denominator == BigInt.one;

  @override
  bool get isExact => true;

  @override
  bool get isZero => numerator == BigInt.zero;

  bool get isNegative => numerator.isNegative;

  @override
  double toDouble() => numerator / denominator;

  @override
  NumberValue toApproximate() => RealValue(toDouble());

  @override
  NumberValue add(NumberValue other) {
    if (other is! RationalValue) {
      final p = _promote(this, other);
      return p.left.add(p.right);
    }
    return RationalValue(
      numerator * other.denominator + other.numerator * denominator,
      denominator * other.denominator,
    );
  }

  @override
  NumberValue subtract(NumberValue other) {
    if (other is! RationalValue) {
      final p = _promote(this, other);
      return p.left.subtract(p.right);
    }
    return RationalValue(
      numerator * other.denominator - other.numerator * denominator,
      denominator * other.denominator,
    );
  }

  @override
  NumberValue multiply(NumberValue other) {
    if (other is! RationalValue) {
      final p = _promote(this, other);
      return p.left.multiply(p.right);
    }
    return RationalValue(numerator * other.numerator, denominator * other.denominator);
  }

  @override
  NumberValue divide(NumberValue other) {
    if (other is! RationalValue) {
      final p = _promote(this, other);
      return p.left.divide(p.right);
    }
    if (other.isZero) throw const MathError.divisionByZero();
    return RationalValue(numerator * other.denominator, denominator * other.numerator);
  }

  @override
  NumberValue negate() => RationalValue._(-numerator, denominator);

  @override
  NumberValue power(NumberValue exponent) {
    if (exponent is RationalValue && exponent.isInteger) {
      final e = exponent.numerator;
      if (e == BigInt.zero) {
        if (isZero) {
          throw const MathError(MathErrorKind.undefined, '0 to the power of 0 is undefined');
        }
        return RationalValue.one;
      }
      // Guard against absurd exponents that would hang on BigInt.pow.
      if (e.abs() > BigInt.from(100000)) {
        return RealValue(math.pow(toDouble(), e.toDouble()).toDouble());
      }
      if (e.isNegative) {
        if (isZero) throw const MathError.divisionByZero();
        return RationalValue(
          denominator.pow(-e.toInt()),
          numerator.pow(-e.toInt()),
        );
      }
      return RationalValue(numerator.pow(e.toInt()), denominator.pow(e.toInt()));
    }

    // A rational exponent may still land exactly — 8^(1/3) is 2.
    if (exponent is RationalValue) {
      final degree = exponent.denominator;
      if (degree <= BigInt.from(64)) {
        final rootNum = _exactIntegerRoot(numerator, degree.toInt());
        final rootDen = _exactIntegerRoot(denominator, degree.toInt());
        if (rootNum != null && rootDen != null) {
          return RationalValue(rootNum, rootDen).power(
            RationalValue._(exponent.numerator, BigInt.one),
          );
        }
      }
    }

    if (exponent is ComplexValue) {
      return ComplexValue.from(this).power(exponent);
    }
    // No exact form exists, so drop to double arithmetic explicitly.
    // Going through _promote here would hand back two rationals again and
    // recurse forever.
    return RealValue(toDouble()).power(RealValue(exponent.toDouble()));
  }

  @override
  NumberValue sqrt() {
    if (isNegative) {
      return ComplexValue(RationalValue.zero, negate().sqrt());
    }
    final rootNum = _exactIntegerRoot(numerator, 2);
    final rootDen = _exactIntegerRoot(denominator, 2);
    if (rootNum != null && rootDen != null) {
      return RationalValue(rootNum, rootDen);
    }
    return RealValue(math.sqrt(toDouble()));
  }

  /// The decimal expansion, detecting the repeating cycle by long
  /// division and watching for a remainder we've already seen.
  DecimalExpansion toDecimalExpansion({int maxDigits = 64}) {
    final negative = isNegative;
    var remainder = numerator.abs();
    final whole = remainder ~/ denominator;
    remainder = remainder % denominator;

    if (remainder == BigInt.zero) {
      return DecimalExpansion(
        isNegative: negative,
        integerPart: whole.toString(),
        nonRepeating: '',
        repeating: '',
        truncated: false,
      );
    }

    final seen = <BigInt, int>{};
    final digits = <String>[];
    final ten = BigInt.from(10);

    while (remainder != BigInt.zero &&
        !seen.containsKey(remainder) &&
        digits.length < maxDigits) {
      seen[remainder] = digits.length;
      remainder *= ten;
      digits.add((remainder ~/ denominator).toString());
      remainder = remainder % denominator;
    }

    if (remainder == BigInt.zero) {
      return DecimalExpansion(
        isNegative: negative,
        integerPart: whole.toString(),
        nonRepeating: digits.join(),
        repeating: '',
        truncated: false,
      );
    }

    final cycleStart = seen[remainder];
    if (cycleStart == null) {
      return DecimalExpansion(
        isNegative: negative,
        integerPart: whole.toString(),
        nonRepeating: digits.join(),
        repeating: '',
        truncated: true,
      );
    }

    return DecimalExpansion(
      isNegative: negative,
      integerPart: whole.toString(),
      nonRepeating: digits.sublist(0, cycleStart).join(),
      repeating: digits.sublist(cycleStart).join(),
      truncated: false,
    );
  }

  /// Splits an improper fraction into whole and fractional parts, for
  /// mixed-number display (7/2 → 3 and 1/2). Null when already proper.
  ({BigInt whole, RationalValue fraction})? toMixedNumber() {
    if (isInteger) return null;
    if (numerator.abs() < denominator) return null;
    final whole = numerator ~/ denominator;
    final remainder = numerator - whole * denominator;
    return (whole: whole, fraction: RationalValue(remainder.abs(), denominator));
  }

  @override
  bool operator ==(Object other) =>
      other is RationalValue &&
      numerator == other.numerator &&
      denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';
}
