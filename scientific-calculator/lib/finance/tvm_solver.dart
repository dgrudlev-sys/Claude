import 'dart:math' as math;

class TvmError implements Exception {
  const TvmError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The standard five time-value-of-money variables. Cash convention is the
/// usual financial-calculator sign rule: money paid out is negative, money
/// received is positive (so a loan's PV is positive, its PMT is negative).
///
/// Rate is per-period (matching how N counts periods) rather than modeling
/// separate payments-per-year / compounding-per-year settings — the
/// simpler, spreadsheet-`PV`/`FV`/`RATE`-style convention, not the
/// P/Y-and-C/Y model a full financial calculator exposes.
enum TvmVariable { n, ratePercent, pv, pmt, fv }

/// 0 = "ordinary annuity" (payments at the end of each period), 1 =
/// "annuity due" (payments at the start).
class TvmSolver {
  static double _balance({
    required double i,
    required double n,
    required double pv,
    required double pmt,
    required double fv,
    required int type,
  }) {
    if (i.abs() < 1e-12) {
      return pv + pmt * n + fv;
    }
    final growth = math.pow(1 + i, n).toDouble();
    return pv + pmt * (1 + i * type) * ((1 - 1 / growth) / i) + fv / growth;
  }

  static double solveFv({
    required double n,
    required double ratePercent,
    required double pv,
    required double pmt,
    int type = 0,
  }) {
    final i = ratePercent / 100;
    if (i.abs() < 1e-12) return -(pv + pmt * n);
    final growth = math.pow(1 + i, n).toDouble();
    return -(pv * growth + pmt * (1 + i * type) * ((growth - 1) / i));
  }

  static double solvePv({
    required double n,
    required double ratePercent,
    required double pmt,
    required double fv,
    int type = 0,
  }) {
    final i = ratePercent / 100;
    if (i.abs() < 1e-12) return -(fv + pmt * n);
    final growth = math.pow(1 + i, n).toDouble();
    return -(fv + pmt * (1 + i * type) * ((growth - 1) / i)) / growth;
  }

  static double solvePmt({
    required double n,
    required double ratePercent,
    required double pv,
    required double fv,
    int type = 0,
  }) {
    final i = ratePercent / 100;
    if (n == 0) throw const TvmError('N must be non-zero');
    if (i.abs() < 1e-12) return -(pv + fv) / n;
    final growth = math.pow(1 + i, n).toDouble();
    final annuityFactor = (1 + i * type) * ((growth - 1) / i);
    if (annuityFactor.abs() < 1e-15) {
      throw const TvmError('No solution for PMT with these values');
    }
    return -(pv * growth + fv) / annuityFactor;
  }

  static double solveN({
    required double ratePercent,
    required double pv,
    required double pmt,
    required double fv,
    int type = 0,
  }) {
    final i = ratePercent / 100;
    if (i.abs() < 1e-12) {
      if (pmt == 0) throw const TvmError('Cannot solve N with rate 0 and PMT 0');
      final n = -(pv + fv) / pmt;
      if (n <= 0) throw const TvmError('These values imply a negative or zero number of periods');
      return n;
    }
    final annuityTerm = pmt * (1 + i * type) / i;
    final numerator = pv + annuityTerm;
    final denominator = annuityTerm - fv;
    if (denominator == 0) throw const TvmError('No solution for N with these values');
    final x = numerator / denominator;
    if (x <= 0) throw const TvmError('These values have no real solution for N');
    return -math.log(x) / math.log(1 + i);
  }

  /// Solves for the periodic rate (as a percent) via bisection on the TVM
  /// balance equation — unlike the other four variables, the rate appears
  /// transcendentally, so there's no closed form.
  static double solveRatePercent({
    required double n,
    required double pv,
    required double pmt,
    required double fv,
    int type = 0,
  }) {
    double lo = -0.999999;
    double hi = 10.0;
    var fLo = _balance(i: lo, n: n, pv: pv, pmt: pmt, fv: fv, type: type);
    var fHi = _balance(i: hi, n: n, pv: pv, pmt: pmt, fv: fv, type: type);

    var expansions = 0;
    while (fLo.sign == fHi.sign && expansions < 12) {
      hi *= 2;
      fHi = _balance(i: hi, n: n, pv: pv, pmt: pmt, fv: fv, type: type);
      expansions++;
    }
    if (fLo.sign == fHi.sign) {
      throw const TvmError('No solution found for the interest rate with these values');
    }

    var mid = 0.0;
    for (var iter = 0; iter < 200; iter++) {
      mid = (lo + hi) / 2;
      final fMid = _balance(i: mid, n: n, pv: pv, pmt: pmt, fv: fv, type: type);
      if (fMid.abs() < 1e-12 || (hi - lo).abs() < 1e-14) return mid * 100;
      if (fMid.sign == fLo.sign) {
        lo = mid;
        fLo = fMid;
      } else {
        hi = mid;
      }
    }
    return mid * 100;
  }
}
