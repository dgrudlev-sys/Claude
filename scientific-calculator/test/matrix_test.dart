import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/matrix/matrix.dart';

void main() {
  group('add/subtract/scale', () {
    test('adds element-wise', () {
      final a = Matrix([
        [1, 2],
        [3, 4],
      ]);
      final b = Matrix([
        [5, 6],
        [7, 8],
      ]);
      expect((a + b).toList(), [
        [6, 8],
        [10, 12],
      ]);
    });

    test('subtracts element-wise', () {
      final a = Matrix([
        [5, 6],
      ]);
      final b = Matrix([
        [1, 2],
      ]);
      expect((a - b).toList(), [
        [4, 4],
      ]);
    });

    test('mismatched shapes throw', () {
      final a = Matrix([
        [1, 2],
      ]);
      final b = Matrix([
        [1],
        [2],
      ]);
      expect(() => a + b, throwsA(isA<MatrixError>()));
    });

    test('scales every element', () {
      final a = Matrix([
        [1, -2],
        [3, 4],
      ]);
      expect(a.scale(2).toList(), [
        [2, -4],
        [6, 8],
      ]);
    });
  });

  group('multiply', () {
    test('2x3 times 3x2 gives 2x2', () {
      final a = Matrix([
        [1, 2, 3],
        [4, 5, 6],
      ]);
      final b = Matrix([
        [7, 8],
        [9, 10],
        [11, 12],
      ]);
      final result = a.multiply(b);
      expect(result.rows, 2);
      expect(result.cols, 2);
      expect(result.toList(), [
        [58, 64],
        [139, 154],
      ]);
    });

    test('incompatible shapes throw', () {
      final a = Matrix([
        [1, 2],
      ]);
      final b = Matrix([
        [1, 2],
      ]);
      expect(() => a.multiply(b), throwsA(isA<MatrixError>()));
    });
  });

  test('transpose flips rows and columns', () {
    final a = Matrix([
      [1, 2, 3],
      [4, 5, 6],
    ]);
    expect(a.transpose.toList(), [
      [1, 4],
      [2, 5],
      [3, 6],
    ]);
  });

  group('determinant', () {
    test('2x2', () {
      final a = Matrix([
        [3, 8],
        [4, 6],
      ]);
      expect(a.determinant(), closeTo(-14, 1e-9));
    });

    test('3x3', () {
      final a = Matrix([
        [6, 1, 1],
        [4, -2, 5],
        [2, 8, 7],
      ]);
      expect(a.determinant(), closeTo(-306, 1e-6));
    });

    test('singular matrix has determinant 0', () {
      final a = Matrix([
        [1, 2],
        [2, 4],
      ]);
      expect(a.determinant(), closeTo(0, 1e-9));
    });

    test('identity has determinant 1', () {
      expect(Matrix.identity(4).determinant(), closeTo(1, 1e-9));
    });

    test('non-square throws', () {
      final a = Matrix([
        [1, 2, 3],
      ]);
      expect(() => a.determinant(), throwsA(isA<MatrixError>()));
    });
  });

  group('inverse', () {
    test('2x2 inverse multiplied by original gives identity', () {
      final a = Matrix([
        [4, 7],
        [2, 6],
      ]);
      final inv = a.inverse();
      final product = a.multiply(inv);
      for (var r = 0; r < 2; r++) {
        for (var c = 0; c < 2; c++) {
          expect(product.at(r, c), closeTo(r == c ? 1 : 0, 1e-9));
        }
      }
    });

    test('singular matrix throws', () {
      final a = Matrix([
        [1, 2],
        [2, 4],
      ]);
      expect(() => a.inverse(), throwsA(isA<MatrixError>()));
    });
  });

  group('rref', () {
    test('reduces a solvable linear system to identity + solution column', () {
      // x + 2y = 5, 3x + 4y = 6  ->  x=-4, y=4.5 (cross-checked with numpy)
      final a = Matrix([
        [1, 2, 5],
        [3, 4, 6],
      ]);
      final r = a.rref();
      expect(r.at(0, 0), closeTo(1, 1e-9));
      expect(r.at(0, 1), closeTo(0, 1e-9));
      expect(r.at(0, 2), closeTo(-4, 1e-9));
      expect(r.at(1, 0), closeTo(0, 1e-9));
      expect(r.at(1, 1), closeTo(1, 1e-9));
      expect(r.at(1, 2), closeTo(4.5, 1e-9));
    });

    test('rref of the identity is itself', () {
      final r = Matrix.identity(3).rref();
      expect(r.toList(), Matrix.identity(3).toList());
    });
  });
}
