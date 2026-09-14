import 'dart:math' as math;

import '../matrix/matrix.dart';

class StatsError implements Exception {
  const StatsError(this.message);

  final String message;

  @override
  String toString() => message;
}

class OneVarStats {
  const OneVarStats({
    required this.n,
    required this.mean,
    required this.sum,
    required this.sampleStdDev,
    required this.populationStdDev,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
  });

  final int n;
  final double mean;
  final double sum;
  final double sampleStdDev;
  final double populationStdDev;
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
}

enum RegressionKind { linear, quadratic, cubic, quartic, power, exponential, logarithmic }

class RegressionResult {
  const RegressionResult({required this.coefficients, required this.rSquared, required this.equation});

  /// Ascending-degree coefficients for polynomial fits (`[c0, c1, c2, ...]`
  /// meaning `y = c0 + c1*x + c2*x^2 + ...`). For power/exponential/log
  /// fits this holds `[a, b]` for that model's own `y = ...` form — see
  /// [equation] for which.
  final List<double> coefficients;
  final double rSquared;
  final String equation;
}

/// Pure-Dart statistics: one-variable summary stats, a regression suite
/// built on ordinary least squares (polynomial fits solve the normal
/// equations via [Matrix]; power/exponential/log fits linearize first),
/// and the normal/binomial distribution functions a stats-mode calculator
/// needs.
class StatsEngine {
  static OneVarStats oneVar(List<double> data) {
    if (data.isEmpty) throw const StatsError('Need at least one data point');
    final n = data.length;
    final sum = data.fold(0.0, (a, b) => a + b);
    final mean = sum / n;
    final sorted = [...data]..sort();

    double variance(int denominator) {
      if (denominator <= 0) return 0;
      final ss = data.fold(0.0, (acc, x) => acc + (x - mean) * (x - mean));
      return ss / denominator;
    }

    return OneVarStats(
      n: n,
      mean: mean,
      sum: sum,
      sampleStdDev: n > 1 ? math.sqrt(variance(n - 1)) : 0,
      populationStdDev: math.sqrt(variance(n)),
      min: sorted.first,
      q1: _percentile(sorted, 0.25),
      median: _percentile(sorted, 0.5),
      q3: _percentile(sorted, 0.75),
      max: sorted.last,
    );
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.length == 1) return sorted.first;
    final pos = p * (sorted.length - 1);
    final lower = pos.floor();
    final upper = pos.ceil();
    if (lower == upper) return sorted[lower];
    final frac = pos - lower;
    return sorted[lower] + (sorted[upper] - sorted[lower]) * frac;
  }

  static void _validatePairs(List<double> x, List<double> y, int minPoints) {
    if (x.length != y.length) throw const StatsError('x and y lists must be the same length');
    if (x.length < minPoints) throw StatsError('Need at least $minPoints data points');
  }

  /// Ordinary least squares polynomial fit of the given [degree], solved
  /// via the normal equations `(XᵀX)β = Xᵀy`.
  static RegressionResult polynomial(List<double> x, List<double> y, int degree) {
    _validatePairs(x, y, degree + 1);
    final n = x.length;
    final design = Matrix([
      for (var i = 0; i < n; i++)
        [for (var j = 0; j <= degree; j++) math.pow(x[i], j).toDouble()],
    ]);
    final yCol = Matrix([for (final v in y) [v]]);
    final xt = design.transpose;
    final beta = (xt.multiply(design)).inverse().multiply(xt.multiply(yCol));
    final coeffs = [for (var j = 0; j <= degree; j++) beta.at(j, 0)];

    final predicted = [for (final xi in x) _evalPolynomial(coeffs, xi)];
    return RegressionResult(
      coefficients: coeffs,
      rSquared: _rSquared(y, predicted),
      equation: _formatPolynomial(coeffs),
    );
  }

  static double _evalPolynomial(List<double> coeffs, double x) {
    var result = 0.0;
    for (var j = 0; j < coeffs.length; j++) {
      result += coeffs[j] * math.pow(x, j);
    }
    return result;
  }

  static String _formatPolynomial(List<double> coeffs) {
    final terms = <String>[];
    for (var j = coeffs.length - 1; j >= 0; j--) {
      final c = coeffs[j];
      final power = j == 0 ? '' : (j == 1 ? 'x' : 'x^$j');
      terms.add('${c.toStringAsFixed(4)}${power.isEmpty ? '' : '*$power'}');
    }
    return 'y = ${terms.join(' + ')}';
  }

  static RegressionResult power(List<double> x, List<double> y) {
    _validatePairs(x, y, 2);
    if (x.any((v) => v <= 0) || y.any((v) => v <= 0)) {
      throw const StatsError('Power regression needs all x and y values > 0');
    }
    final lnX = x.map(math.log).toList();
    final lnY = y.map(math.log).toList();
    final fit = polynomial(lnX, lnY, 1);
    final a = math.exp(fit.coefficients[0]);
    final b = fit.coefficients[1];
    final predicted = [for (final xi in x) a * math.pow(xi, b)];
    return RegressionResult(
      coefficients: [a, b],
      rSquared: _rSquared(y, predicted),
      equation: 'y = ${a.toStringAsFixed(4)}*x^${b.toStringAsFixed(4)}',
    );
  }

  static RegressionResult exponential(List<double> x, List<double> y) {
    _validatePairs(x, y, 2);
    if (y.any((v) => v <= 0)) {
      throw const StatsError('Exponential regression needs all y values > 0');
    }
    final lnY = y.map(math.log).toList();
    final fit = polynomial(x, lnY, 1);
    final a = math.exp(fit.coefficients[0]);
    final b = math.exp(fit.coefficients[1]);
    final predicted = [for (final xi in x) a * math.pow(b, xi)];
    return RegressionResult(
      coefficients: [a, b],
      rSquared: _rSquared(y, predicted),
      equation: 'y = ${a.toStringAsFixed(4)}*${b.toStringAsFixed(4)}^x',
    );
  }

  static RegressionResult logarithmic(List<double> x, List<double> y) {
    _validatePairs(x, y, 2);
    if (x.any((v) => v <= 0)) {
      throw const StatsError('Logarithmic regression needs all x values > 0');
    }
    final lnX = x.map(math.log).toList();
    final fit = polynomial(lnX, y, 1);
    final a = fit.coefficients[0];
    final b = fit.coefficients[1];
    final predicted = [for (final xi in x) a + b * math.log(xi)];
    return RegressionResult(
      coefficients: [a, b],
      rSquared: _rSquared(y, predicted),
      equation: 'y = ${a.toStringAsFixed(4)} + ${b.toStringAsFixed(4)}*ln(x)',
    );
  }

  static double _rSquared(List<double> actual, List<double> predicted) {
    final mean = actual.fold(0.0, (a, b) => a + b) / actual.length;
    var ssRes = 0.0;
    var ssTot = 0.0;
    for (var i = 0; i < actual.length; i++) {
      ssRes += (actual[i] - predicted[i]) * (actual[i] - predicted[i]);
      ssTot += (actual[i] - mean) * (actual[i] - mean);
    }
    if (ssTot == 0) return 1.0;
    return 1 - ssRes / ssTot;
  }

  // ---- Distributions ----

  /// P(lower < X < upper) for a normal distribution with the given [mean]
  /// and standard deviation [sd].
  static double normalCdf(double lower, double upper, {double mean = 0, double sd = 1}) {
    if (sd <= 0) throw const StatsError('Standard deviation must be positive');
    return _standardNormalCdf((upper - mean) / sd) - _standardNormalCdf((lower - mean) / sd);
  }

  /// The inverse normal: the z (or x, if [mean]/[sd] given) below which
  /// [area] of the distribution lies.
  static double invNorm(double area, {double mean = 0, double sd = 1}) {
    if (area <= 0 || area >= 1) throw const StatsError('area must be strictly between 0 and 1');
    // Newton-Raphson on the standard normal CDF, starting from a
    // Beasley-Springer-Moro-style rough guess so it converges quickly
    // even for tail areas.
    var z = _initialInvNormGuess(area);
    for (var i = 0; i < 100; i++) {
      final cdf = _standardNormalCdf(z);
      final pdf = _standardNormalPdf(z);
      if (pdf < 1e-300) break;
      var step = (cdf - area) / pdf;
      if (step.abs() > 3) step = step.sign * 3; // avoid wild overshoot
      final newZ = z - step;
      if ((newZ - z).abs() < 1e-12) {
        z = newZ;
        break;
      }
      z = newZ;
    }
    return mean + sd * z;
  }

  static double _initialInvNormGuess(double p) {
    // A cheap rational approximation, good enough as a Newton starting
    // point across the whole (0,1) range.
    final t = math.sqrt(-2 * math.log(p < 0.5 ? p : 1 - p));
    final guess = t - (2.515517 + 0.802853 * t + 0.010328 * t * t) /
        (1 + 1.432788 * t + 0.189269 * t * t + 0.001308 * t * t * t);
    return p < 0.5 ? -guess : guess;
  }

  static double _standardNormalPdf(double z) => math.exp(-z * z / 2) / math.sqrt(2 * math.pi);

  static double _standardNormalCdf(double z) => 0.5 * (1 + _erf(z / math.sqrt2));

  /// Abramowitz & Stegun 7.1.26 approximation (max error ~1.5e-7).
  static double _erf(double x) {
    final sign = x < 0 ? -1.0 : 1.0;
    final ax = x.abs();
    const a1 = 0.254829592, a2 = -0.284496736, a3 = 1.421413741;
    const a4 = -1.453152027, a5 = 1.061405429, p = 0.3275911;
    final t = 1 / (1 + p * ax);
    final poly = ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t;
    final y = 1 - poly * math.exp(-ax * ax);
    return sign * y;
  }

  static double nCr(int n, int r) {
    if (r < 0 || r > n) return 0;
    final k = r < n - r ? r : n - r;
    var result = 1.0;
    for (var i = 0; i < k; i++) {
      result = result * (n - i) / (i + 1);
    }
    return result;
  }

  static double binomialPdf(int n, double p, int k) {
    if (p < 0 || p > 1) throw const StatsError('p must be between 0 and 1');
    if (k < 0 || k > n) return 0;
    return nCr(n, k) * math.pow(p, k) * math.pow(1 - p, n - k);
  }

  static double binomialCdf(int n, double p, int k) {
    var total = 0.0;
    for (var i = 0; i <= k; i++) {
      total += binomialPdf(n, p, i);
    }
    return total;
  }
}
