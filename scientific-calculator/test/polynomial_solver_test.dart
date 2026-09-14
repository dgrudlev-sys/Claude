import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/polynomial_solver.dart';

void main() {
  // All expected roots below are cross-checked with numpy.roots(...).

  test('linear: 2x - 4 = 0 -> x = 2', () {
    final roots = PolynomialSolver.solve([2, -4]);
    expect(roots, hasLength(1));
    expect(roots.single.real, closeTo(2, 1e-9));
    expect(roots.single.isReal, isTrue);
  });

  test('quadratic with real roots: x^2 - 6x + 5 -> {1, 5}', () {
    final roots = PolynomialSolver.solve([1, -6, 5]);
    final values = roots.map((r) => r.real).toList()..sort();
    expect(values, [closeTo(1, 1e-9), closeTo(5, 1e-9)]);
    expect(roots.every((r) => r.isReal), isTrue);
  });

  test('quadratic with complex roots: x^2 + 1 -> {i, -i}', () {
    final roots = PolynomialSolver.solve([1, 0, 1]);
    expect(roots, hasLength(2));
    expect(roots.every((r) => !r.isReal), isTrue);
    final imagParts = roots.map((r) => r.imaginary).toList()..sort();
    expect(imagParts[0], closeTo(-1, 1e-9));
    expect(imagParts[1], closeTo(1, 1e-9));
  });

  test('cubic: x^3 - 6x^2 + 11x - 6 -> {1, 2, 3}', () {
    final roots = PolynomialSolver.solve([1, -6, 11, -6]);
    final values = roots.map((r) => r.real).toList()..sort();
    expect(values, [closeTo(1, 1e-6), closeTo(2, 1e-6), closeTo(3, 1e-6)]);
  });

  test('quartic: x^4 - 1 -> {1, -1, i, -i}', () {
    final roots = PolynomialSolver.solve([1, 0, 0, 0, -1]);
    expect(roots, hasLength(4));
    final realRoots = roots.where((r) => r.isReal).map((r) => r.real).toList()..sort();
    expect(realRoots, [closeTo(-1, 1e-6), closeTo(1, 1e-6)]);
    expect(roots.where((r) => !r.isReal), hasLength(2));
  });

  test('quintic (degree 5, no closed form): x^5 - 1 has a real root at 1', () {
    final roots = PolynomialSolver.solve([1, 0, 0, 0, 0, -1]);
    expect(roots, hasLength(5));
    final realRoots = roots.where((r) => r.isReal).toList();
    expect(realRoots, hasLength(1));
    expect(realRoots.single.real, closeTo(1, 1e-4));
  });

  test('leading zero coefficients are trimmed (degree detected correctly)', () {
    final roots = PolynomialSolver.solve([0, 0, 1, -6, 5]); // same as x^2-6x+5
    expect(roots, hasLength(2));
  });

  test('degree-0 (all but one coefficient zero) throws', () {
    expect(() => PolynomialSolver.solve([0, 5]), throwsA(isA<PolynomialError>()));
  });
}
