import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/finance/tvm_solver.dart';

void main() {
  group('solveFv', () {
    test('lump sum growth with no payments (cross-checked in Python)', () {
      final fv = TvmSolver.solveFv(n: 10, ratePercent: 5, pv: 1000, pmt: 0);
      expect(fv, closeTo(-1628.894626777442, 1e-6));
    });

    test('zero rate is simple sum', () {
      final fv = TvmSolver.solveFv(n: 12, ratePercent: 0, pv: 1000, pmt: -50);
      expect(fv, closeTo(-(1000 - 50 * 12), 1e-9));
    });
  });

  group('solvePmt', () {
    test('amortizing loan payment (cross-checked in Python)', () {
      final pmt = TvmSolver.solvePmt(n: 12, ratePercent: 1, pv: 1000, fv: 0);
      expect(pmt, closeTo(-88.84878867834168, 1e-6));
    });
  });

  group('round trips', () {
    const n = 24.0;
    const rate = 0.75;
    const pv = 5000.0;
    const pmt = -230.0;

    test('solveFv then solvePv recovers the original PV', () {
      final fv = TvmSolver.solveFv(n: n, ratePercent: rate, pv: pv, pmt: pmt);
      final recoveredPv = TvmSolver.solvePv(n: n, ratePercent: rate, pmt: pmt, fv: fv);
      expect(recoveredPv, closeTo(pv, 1e-6));
    });

    test('solveFv then solvePmt recovers the original PMT', () {
      final fv = TvmSolver.solveFv(n: n, ratePercent: rate, pv: pv, pmt: pmt);
      final recoveredPmt = TvmSolver.solvePmt(n: n, ratePercent: rate, pv: pv, fv: fv);
      expect(recoveredPmt, closeTo(pmt, 1e-6));
    });

    test('solveFv then solveN recovers the original N', () {
      final fv = TvmSolver.solveFv(n: n, ratePercent: rate, pv: pv, pmt: pmt);
      final recoveredN = TvmSolver.solveN(ratePercent: rate, pv: pv, pmt: pmt, fv: fv);
      expect(recoveredN, closeTo(n, 1e-6));
    });

    test('solveFv then solveRatePercent recovers the original rate', () {
      final fv = TvmSolver.solveFv(n: n, ratePercent: rate, pv: pv, pmt: pmt);
      final recoveredRate = TvmSolver.solveRatePercent(n: n, pv: pv, pmt: pmt, fv: fv);
      expect(recoveredRate, closeTo(rate, 1e-4));
    });

    test('zero-rate round trip: solveN recovers N', () {
      final fv = TvmSolver.solveFv(n: 20, ratePercent: 0, pv: 2000, pmt: -100);
      final recoveredN = TvmSolver.solveN(ratePercent: 0, pv: 2000, pmt: -100, fv: fv);
      expect(recoveredN, closeTo(20, 1e-9));
    });
  });

  group('annuity due (type=1)', () {
    test('payments at the start of the period change the result', () {
      final ordinary = TvmSolver.solveFv(n: 12, ratePercent: 1, pv: 0, pmt: -100, type: 0);
      final due = TvmSolver.solveFv(n: 12, ratePercent: 1, pv: 0, pmt: -100, type: 1);
      // an annuity due always grows to a larger FV than an ordinary annuity
      expect(due.abs(), greaterThan(ordinary.abs()));
    });
  });

  group('errors', () {
    test('solvePmt with N=0 throws', () {
      expect(() => TvmSolver.solvePmt(n: 0, ratePercent: 5, pv: 1000, fv: 0),
          throwsA(isA<TvmError>()));
    });
  });
}
