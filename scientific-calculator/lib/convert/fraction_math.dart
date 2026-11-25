/// Integer fractions, always stored in lowest terms with a positive denominator.
class Fraction {
  Fraction(int numerator, int denominator) {
    if (denominator == 0) {
      throw ArgumentError('Denominator cannot be 0');
    }
    var n = numerator;
    var d = denominator;
    if (d < 0) {
      n = -n;
      d = -d;
    }
    final g = _gcd(n.abs(), d);
    this.numerator = n ~/ g;
    this.denominator = d ~/ g;
  }

  late final int numerator;
  late final int denominator;

  factory Fraction.mixed({
    int whole = 0,
    required int numerator,
    required int denominator,
  }) {
    final extra = numerator.abs();
    final signedExtra = numerator < 0 ? -extra : extra;
    final body =
        whole * denominator + (whole < 0 ? -signedExtra.abs() : signedExtra);
    return Fraction(body, denominator);
  }

  int compareTo(Fraction other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  bool get isWhole => denominator == 1;

  Fraction operator +(Fraction other) => Fraction(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  Fraction operator -(Fraction other) => Fraction(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  Fraction operator *(Fraction other) =>
      Fraction(numerator * other.numerator, denominator * other.denominator);

  Fraction operator /(Fraction other) {
    if (other.numerator == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return Fraction(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  double get toDecimal => numerator / denominator;

  /// "1 1/2" or "3/4" or "2".
  String get mixedLabel {
    if (isWhole) return '$numerator';
    final sign = numerator < 0 ? '-' : '';
    final absN = numerator.abs();
    final whole = absN ~/ denominator;
    final rem = absN % denominator;
    if (whole == 0) return '$sign$rem/$denominator';
    return '$sign$whole $rem/$denominator';
  }

  String get improperLabel => '$numerator/$denominator';

  static int _gcd(int a, int b) {
    var x = a;
    var y = b;
    while (y != 0) {
      final t = y;
      y = x % y;
      x = t;
    }
    return x == 0 ? 1 : x;
  }
}

enum FractionOp { add, subtract, multiply, divide }

Fraction evalFractions(Fraction a, FractionOp op, Fraction b) =>
    evalFractionTerms([a, b], op);

/// One operation across every term: add all, subtract in order, multiply all,
/// or divide left to right.
Fraction evalFractionTerms(List<Fraction> terms, FractionOp op) {
  if (terms.length < 2) {
    throw ArgumentError('Need at least two fractions');
  }
  switch (op) {
    case FractionOp.add:
      return terms.reduce((a, b) => a + b);
    case FractionOp.subtract:
      var acc = terms.first;
      for (final next in terms.skip(1)) {
        acc = acc - next;
      }
      return acc;
    case FractionOp.multiply:
      return terms.reduce((a, b) => a * b);
    case FractionOp.divide:
      var acc = terms.first;
      for (final next in terms.skip(1)) {
        acc = acc / next;
      }
      return acc;
  }
}

/// Least common multiple of every denominator, used to rewrite a sum or difference.
int commonDenominator(List<Fraction> terms) {
  if (terms.isEmpty) {
    throw ArgumentError('Need at least one fraction');
  }
  var acc = terms.first.denominator;
  for (final term in terms.skip(1)) {
    acc = _lcm(acc, term.denominator);
  }
  return acc;
}

int _lcm(int a, int b) {
  if (a == 0 || b == 0) return 0;
  return (a ~/ Fraction._gcd(a.abs(), b.abs())) * b;
}
