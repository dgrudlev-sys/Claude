part of 'number.dart';

/// An approximate double-precision value — what a result becomes once it
/// leaves the exact rational world.
final class RealValue extends NumberValue {
  const RealValue(this.value);

  final double value;

  @override
  bool get isExact => false;

  @override
  bool get isZero => value == 0;

  @override
  double toDouble() => value;

  @override
  NumberValue toApproximate() => this;

  void _guard(double result) {
    if (result.isNaN) {
      throw const MathError(MathErrorKind.undefined, 'Result is not a number');
    }
    if (result.isInfinite) {
      throw const MathError(MathErrorKind.overflow, 'Result is too large to represent');
    }
  }

  RealValue _wrap(double result) {
    _guard(result);
    return RealValue(result);
  }

  @override
  NumberValue add(NumberValue other) {
    if (other is ComplexValue) return ComplexValue.from(this).add(other);
    return _wrap(value + other.toDouble());
  }

  @override
  NumberValue subtract(NumberValue other) {
    if (other is ComplexValue) return ComplexValue.from(this).subtract(other);
    return _wrap(value - other.toDouble());
  }

  @override
  NumberValue multiply(NumberValue other) {
    if (other is ComplexValue) return ComplexValue.from(this).multiply(other);
    return _wrap(value * other.toDouble());
  }

  @override
  NumberValue divide(NumberValue other) {
    if (other is ComplexValue) return ComplexValue.from(this).divide(other);
    if (other.isZero) throw const MathError.divisionByZero();
    return _wrap(value / other.toDouble());
  }

  @override
  NumberValue negate() => RealValue(-value);

  @override
  NumberValue power(NumberValue exponent) {
    if (exponent is ComplexValue) {
      return ComplexValue.from(this).power(exponent);
    }
    final e = exponent.toDouble();
    // A negative base with a fractional exponent is complex, not an error.
    if (value < 0 && e != e.roundToDouble()) {
      return ComplexValue.from(this).power(exponent);
    }
    return _wrap(math.pow(value, e).toDouble());
  }

  @override
  NumberValue sqrt() {
    if (value < 0) {
      return ComplexValue(RationalValue.zero, RealValue(math.sqrt(-value)));
    }
    return _wrap(math.sqrt(value));
  }

  @override
  bool operator ==(Object other) => other is RealValue && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}
