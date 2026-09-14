/// Everyday percent questions, in plain numbers.
class PercentMath {
  PercentMath._();

  /// What is [percent] % of [ofValue]?
  static double percentOf({required double percent, required double ofValue}) =>
      _clean(ofValue * percent / 100);

  /// [part] is what percent of [whole]?
  static double whatPercent({required double part, required double whole}) {
    if (whole == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return _clean(100 * part / whole);
  }

  /// [amount] after a percent change (negative percent = decrease).
  static double changeBy({required double amount, required double percent}) =>
      _clean(amount * (1 + percent / 100));

  /// Snap IEEE dust so 50 + 10% is exactly 55, not 55.00000000000001.
  static double _clean(double v) {
    if (v.isNaN || v.isInfinite) return v;
    final rounded = v.roundToDouble();
    if ((v - rounded).abs() < 1e-10 * (1 + v.abs())) return rounded;
    return v;
  }
}
