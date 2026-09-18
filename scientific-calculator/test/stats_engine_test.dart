import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/statistics/stats_engine.dart';

void main() {
  group('one-variable stats', () {
    test('matches hand-computed values for a small sample', () {
      final s = StatsEngine.oneVar([2, 4, 4, 4, 5, 5, 7, 9]);
      expect(s.n, 8);
      expect(s.mean, 5);
      expect(s.populationStdDev, closeTo(2, 1e-9));
      expect(s.sampleStdDev, closeTo(2.13809, 1e-4));
      expect(s.min, 2);
      expect(s.max, 9);
      expect(s.median, closeTo(4.5, 1e-9));
    });

    test('empty data throws', () {
      expect(() => StatsEngine.oneVar([]), throwsA(isA<StatsError>()));
    });
  });

  group('polynomial regression', () {
    test('recovers exact quadratic coefficients from noise-free data', () {
      // y = 2x^2 + 3x + 1, cross-checked with numpy.polyfit -> [2, 3, 1]
      final x = <double>[0.0, 1, 2, 3, 4];
      final y = [for (final xi in x) 2 * xi * xi + 3 * xi + 1];
      final fit = StatsEngine.polynomial(x, y, 2);
      // coefficients are ascending degree: [c0, c1, c2]
      expect(fit.coefficients[0], closeTo(1, 1e-6));
      expect(fit.coefficients[1], closeTo(3, 1e-6));
      expect(fit.coefficients[2], closeTo(2, 1e-6));
      expect(fit.rSquared, closeTo(1, 1e-9));
    });

    test('linear regression on a straight line is a perfect fit', () {
      final x = <double>[1.0, 2, 3, 4];
      final y = <double>[3.0, 5, 7, 9]; // y = 2x + 1
      final fit = StatsEngine.polynomial(x, y, 1);
      expect(fit.coefficients[0], closeTo(1, 1e-9));
      expect(fit.coefficients[1], closeTo(2, 1e-9));
      expect(fit.rSquared, closeTo(1, 1e-9));
    });

    test('too few points for the degree throws', () {
      expect(() => StatsEngine.polynomial([1, 2], [1, 2], 2), throwsA(isA<StatsError>()));
    });
  });

  group('power regression', () {
    test('recovers y = 2*x^1.5 (cross-checked with numpy)', () {
      final x = <double>[1.0, 2, 3, 4, 5];
      final y = [for (final xi in x) 2 * math.pow(xi, 1.5).toDouble()];
      final fit = StatsEngine.power(x, y);
      expect(fit.coefficients[0], closeTo(2, 1e-6)); // a
      expect(fit.coefficients[1], closeTo(1.5, 1e-6)); // b
    });

    test('non-positive values throw', () {
      expect(() => StatsEngine.power([-1, 2], [1, 2]), throwsA(isA<StatsError>()));
    });
  });

  group('exponential regression', () {
    test('recovers y = 3*2^x', () {
      final x = <double>[0.0, 1, 2, 3];
      final y = [for (final xi in x) 3 * math.pow(2, xi).toDouble()];
      final fit = StatsEngine.exponential(x, y);
      expect(fit.coefficients[0], closeTo(3, 1e-6));
      expect(fit.coefficients[1], closeTo(2, 1e-6));
    });
  });

  group('logarithmic regression', () {
    test('recovers y = 1 + 2*ln(x)', () {
      final x = <double>[1.0, 2, 4, 8, 16];
      final y = [for (final xi in x) 1 + 2 * math.log(xi)];
      final fit = StatsEngine.logarithmic(x, y);
      expect(fit.coefficients[0], closeTo(1, 1e-6));
      expect(fit.coefficients[1], closeTo(2, 1e-6));
    });
  });

  group('normalCdf', () {
    test('matches scipy.stats.norm.cdf(1.96) - cdf(-1.96) area under the curve', () {
      expect(StatsEngine.normalCdf(-1.96, 1.96), closeTo(0.9500021, 1e-5));
    });

    test('P(-1<Z<1) ~ 0.6827 (68-95-99.7 rule)', () {
      expect(StatsEngine.normalCdf(-1, 1), closeTo(0.6826894921, 1e-6));
    });
  });

  group('invNorm', () {
    test('inverts the median to 0', () {
      expect(StatsEngine.invNorm(0.5), closeTo(0, 1e-6));
    });

    test('matches scipy.stats.norm.ppf(0.975)', () {
      expect(StatsEngine.invNorm(0.975), closeTo(1.959963984540054, 1e-4));
    });

    test('matches scipy.stats.norm.ppf(0.01) (lower tail)', () {
      expect(StatsEngine.invNorm(0.01), closeTo(-2.3263478740408408, 1e-4));
    });

    test('matches scipy.stats.norm.ppf(0.0001) (extreme tail)', () {
      expect(StatsEngine.invNorm(0.0001), closeTo(-3.7190164854556804, 1e-3));
    });

    test('round-trips through normalCdf', () {
      final z = StatsEngine.invNorm(0.8);
      expect(StatsEngine.normalCdf(-100, z), closeTo(0.8, 1e-6));
    });

    test('out-of-range area throws', () {
      expect(() => StatsEngine.invNorm(0), throwsA(isA<StatsError>()));
      expect(() => StatsEngine.invNorm(1), throwsA(isA<StatsError>()));
    });
  });

  group('binomial', () {
    test('pmf matches scipy.stats.binom.pmf(5, 10, 0.5)', () {
      expect(StatsEngine.binomialPdf(10, 0.5, 5), closeTo(0.24609375, 1e-9));
    });

    test('cdf matches scipy.stats.binom.cdf(5, 10, 0.5)', () {
      expect(StatsEngine.binomialCdf(10, 0.5, 5), closeTo(0.623046875, 1e-9));
    });

    test('k out of range gives 0 pdf', () {
      expect(StatsEngine.binomialPdf(10, 0.5, -1), 0);
      expect(StatsEngine.binomialPdf(10, 0.5, 11), 0);
    });
  });
}
