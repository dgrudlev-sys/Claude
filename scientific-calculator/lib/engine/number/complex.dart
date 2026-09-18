part of 'number.dart';

/// A complex number whose real and imaginary parts are each a non-complex
/// [NumberValue], so exactness survives where it can: `sqrt(-4)` is
/// exactly `2i`, not `1.9999999999i`.
final class ComplexValue extends NumberValue {
  factory ComplexValue(NumberValue real, NumberValue imaginary) {
    assert(real is! ComplexValue && imaginary is! ComplexValue,
        'Complex components must themselves be real-valued');
    return ComplexValue._(real, imaginary);
  }

  const ComplexValue._(this.real, this.imaginary);

  /// Widens any value into the complex plane.
  factory ComplexValue.from(NumberValue value) {
    if (value is ComplexValue) return value;
    return ComplexValue._(value, RationalValue.zero);
  }

  final NumberValue real;
  final NumberValue imaginary;

  /// Collapses back to a plain value when the imaginary part vanished —
  /// so (2+3i) + (1-3i) reads as 3, not "3 + 0i".
  NumberValue simplified() => imaginary.isZero ? real : this;

  @override
  bool get isExact => real.isExact && imaginary.isExact;

  @override
  bool get isZero => real.isZero && imaginary.isZero;

  @override
  double toDouble() {
    if (!imaginary.isZero) {
      throw const MathError(
        MathErrorKind.domainError,
        'A complex number has no single real value',
      );
    }
    return real.toDouble();
  }

  @override
  NumberValue toApproximate() =>
      ComplexValue._(real.toApproximate(), imaginary.toApproximate());

  @override
  NumberValue add(NumberValue other) {
    final o = ComplexValue.from(other);
    return ComplexValue._(real.add(o.real), imaginary.add(o.imaginary)).simplified();
  }

  @override
  NumberValue subtract(NumberValue other) {
    final o = ComplexValue.from(other);
    return ComplexValue._(real.subtract(o.real), imaginary.subtract(o.imaginary))
        .simplified();
  }

  @override
  NumberValue multiply(NumberValue other) {
    final o = ComplexValue.from(other);
    // (a+bi)(c+di) = (ac - bd) + (ad + bc)i
    final ac = real.multiply(o.real);
    final bd = imaginary.multiply(o.imaginary);
    final ad = real.multiply(o.imaginary);
    final bc = imaginary.multiply(o.real);
    return ComplexValue._(ac.subtract(bd), ad.add(bc)).simplified();
  }

  @override
  NumberValue divide(NumberValue other) {
    final o = ComplexValue.from(other);
    if (o.isZero) throw const MathError.divisionByZero();
    // Multiply through by the conjugate: (a+bi)/(c+di).
    final denom = o.real.multiply(o.real).add(o.imaginary.multiply(o.imaginary));
    final realPart =
        real.multiply(o.real).add(imaginary.multiply(o.imaginary)).divide(denom);
    final imagPart =
        imaginary.multiply(o.real).subtract(real.multiply(o.imaginary)).divide(denom);
    return ComplexValue._(realPart, imagPart).simplified();
  }

  @override
  NumberValue negate() => ComplexValue._(real.negate(), imaginary.negate()).simplified();

  @override
  NumberValue power(NumberValue exponent) {
    // Small integer powers stay exact via repeated multiplication.
    if (exponent is RationalValue && exponent.isInteger) {
      final e = exponent.numerator;
      if (e.abs() <= BigInt.from(64)) {
        if (e == BigInt.zero) return RationalValue.one;
        final times = e.abs().toInt();
        NumberValue result = RationalValue.one;
        for (var i = 0; i < times; i++) {
          result = result.multiply(this);
        }
        return e.isNegative ? RationalValue.one.divide(result) : result;
      }
    }
    // Otherwise go through polar form, which is inherently approximate.
    final r = math.sqrt(
      real.toDouble() * real.toDouble() + imaginary.toDouble() * imaginary.toDouble(),
    );
    if (r == 0) return RationalValue.zero;
    final theta = math.atan2(imaginary.toDouble(), real.toDouble());
    final e = exponent.toDouble();
    final magnitude = math.pow(r, e).toDouble();
    return ComplexValue._(
      RealValue(magnitude * math.cos(theta * e)),
      RealValue(magnitude * math.sin(theta * e)),
    ).simplified();
  }

  @override
  NumberValue sqrt() => power(RationalValue(BigInt.one, BigInt.two));

  @override
  bool operator ==(Object other) =>
      other is ComplexValue && real == other.real && imaginary == other.imaginary;

  @override
  int get hashCode => Object.hash(real, imaginary);

  @override
  String toString() {
    final sign = imaginary is RationalValue && (imaginary as RationalValue).isNegative
        ? '-'
        : '+';
    final magnitude = imaginary is RationalValue && (imaginary as RationalValue).isNegative
        ? imaginary.negate()
        : imaginary;
    return '$real $sign ${magnitude}i';
  }
}
