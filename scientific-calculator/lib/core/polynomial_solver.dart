import 'package:equations/equations.dart' as eq;

class PolynomialError implements Exception {
  const PolynomialError(this.message);

  final String message;

  @override
  String toString() => message;
}

class PolynomialRoot {
  const PolynomialRoot(this.real, this.imaginary);

  final double real;
  final double imaginary;

  bool get isReal => imaginary.abs() < 1e-9;

  @override
  String toString() {
    if (isReal) return real.toStringAsFixed(6);
    final sign = imaginary >= 0 ? '+' : '-';
    return '${real.toStringAsFixed(6)} $sign ${imaginary.abs().toStringAsFixed(6)}i';
  }
}

/// Exact polynomial root-finding (real and complex) built on the
/// `equations` package: closed-form solutions for degree 1-4 (via the
/// linear/quadratic/cubic/quartic formulas), and the Aberth method's
/// numeric approximation for degree 5+, where no closed form exists.
///
/// This is real symbolic-adjacent capability — not a general CAS (it
/// can't solve transcendental equations or do symbolic algebra), but for
/// the specific case of "find every root of this polynomial, including
/// complex ones," it's exact where [EquationSolver]'s numeric
/// Newton's-method approach can only ever find one real root per guess.
class PolynomialSolver {
  /// [coefficients] are highest-degree first, e.g. `[1, -6, 5]` for
  /// `x^2 - 6x + 5`.
  static List<PolynomialRoot> solve(List<double> coefficients) {
    final trimmed = _trimLeadingZeros(coefficients);
    final degree = trimmed.length - 1;
    if (degree < 1) {
      throw const PolynomialError('Need at least a degree-1 (linear) polynomial');
    }
    if (trimmed.length > 20) {
      throw const PolynomialError('Degree is too high to solve reliably');
    }

    late final eq.Algebraic algebraic;
    switch (degree) {
      case 1:
        algebraic = eq.Linear.realEquation(a: trimmed[0], b: trimmed[1]);
      case 2:
        algebraic = eq.Quadratic.realEquation(a: trimmed[0], b: trimmed[1], c: trimmed[2]);
      case 3:
        algebraic =
            eq.Cubic.realEquation(a: trimmed[0], b: trimmed[1], c: trimmed[2], d: trimmed[3]);
      case 4:
        algebraic = eq.Quartic.realEquation(
            a: trimmed[0], b: trimmed[1], c: trimmed[2], d: trimmed[3], e: trimmed[4]);
      default:
        algebraic = eq.GenericAlgebraic(
          coefficients: [for (final c in trimmed) eq.Complex.fromReal(c)],
        );
    }

    try {
      final roots = algebraic.solutions();
      return [for (final r in roots) PolynomialRoot(r.real, r.imaginary)];
    } catch (_) {
      throw const PolynomialError('Could not find roots for these coefficients');
    }
  }

  static List<double> _trimLeadingZeros(List<double> coefficients) {
    var start = 0;
    while (start < coefficients.length - 1 && coefficients[start] == 0) {
      start++;
    }
    return coefficients.sublist(start);
  }
}
