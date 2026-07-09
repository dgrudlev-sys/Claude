/// Thrown for invalid matrix operations (mismatched dimensions, a
/// non-square determinant/inverse, a singular inverse).
class MatrixError implements Exception {
  const MatrixError(this.message);

  final String message;

  @override
  String toString() => message;
}

const _epsilon = 1e-10;

/// A plain, immutable dense matrix with the operations a scientific
/// calculator's matrix mode needs: add, subtract, multiply (by a matrix or
/// a scalar), transpose, determinant, inverse, and row-reduced echelon
/// form. No Flutter dependency — this is pure arithmetic, independent of
/// how it's displayed or edited.
class Matrix {
  Matrix(List<List<double>> data)
      : rows = data.length,
        cols = data.isEmpty ? 0 : data.first.length,
        _data = [for (final row in data) List<double>.from(row)] {
    for (final row in data) {
      if (row.length != cols) {
        throw const MatrixError('All rows must have the same length');
      }
    }
  }

  factory Matrix.zero(int rows, int cols) {
    return Matrix([for (var r = 0; r < rows; r++) List.filled(cols, 0.0)]);
  }

  factory Matrix.identity(int n) {
    return Matrix([
      for (var r = 0; r < n; r++)
        [for (var c = 0; c < n; c++) r == c ? 1.0 : 0.0],
    ]);
  }

  final int rows;
  final int cols;
  final List<List<double>> _data;

  bool get isSquare => rows == cols;

  double at(int r, int c) => _data[r][c];

  List<List<double>> toList() => [for (final row in _data) List<double>.from(row)];

  void _requireSameShape(Matrix other, String op) {
    if (rows != other.rows || cols != other.cols) {
      throw MatrixError('Cannot $op a ${rows}x$cols matrix and a ${other.rows}x${other.cols} matrix');
    }
  }

  Matrix operator +(Matrix other) {
    _requireSameShape(other, 'add');
    return Matrix([
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < cols; c++) at(r, c) + other.at(r, c)],
    ]);
  }

  Matrix operator -(Matrix other) {
    _requireSameShape(other, 'subtract');
    return Matrix([
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < cols; c++) at(r, c) - other.at(r, c)],
    ]);
  }

  Matrix scale(double factor) {
    return Matrix([
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < cols; c++) at(r, c) * factor],
    ]);
  }

  Matrix multiply(Matrix other) {
    if (cols != other.rows) {
      throw MatrixError(
          'Cannot multiply a ${rows}x$cols matrix by a ${other.rows}x${other.cols} matrix');
    }
    return Matrix([
      for (var r = 0; r < rows; r++)
        [
          for (var c = 0; c < other.cols; c++)
            [for (var k = 0; k < cols; k++) at(r, k) * other.at(k, c)]
                .fold(0.0, (a, b) => a + b),
        ],
    ]);
  }

  Matrix get transpose {
    return Matrix([
      for (var c = 0; c < cols; c++)
        [for (var r = 0; r < rows; r++) at(r, c)],
    ]);
  }

  /// Gaussian elimination with partial pivoting, tracking the sign flip
  /// from row swaps and the product of pivots.
  double determinant() {
    if (!isSquare) throw const MatrixError('Determinant requires a square matrix');
    final a = toList();
    final n = rows;
    var det = 1.0;

    for (var col = 0; col < n; col++) {
      var pivotRow = col;
      for (var r = col + 1; r < n; r++) {
        if (a[r][col].abs() > a[pivotRow][col].abs()) pivotRow = r;
      }
      if (a[pivotRow][col].abs() < _epsilon) return 0.0;
      if (pivotRow != col) {
        final tmp = a[col];
        a[col] = a[pivotRow];
        a[pivotRow] = tmp;
        det = -det;
      }
      det *= a[col][col];
      for (var r = col + 1; r < n; r++) {
        final factor = a[r][col] / a[col][col];
        for (var c = col; c < n; c++) {
          a[r][c] -= factor * a[col][c];
        }
      }
    }
    return det;
  }

  /// Gauss-Jordan elimination on `[A | I]`, throwing [MatrixError] if the
  /// matrix is singular.
  Matrix inverse() {
    if (!isSquare) throw const MatrixError('Inverse requires a square matrix');
    final n = rows;
    final left = toList();
    final right = Matrix.identity(n).toList();

    for (var col = 0; col < n; col++) {
      var pivotRow = col;
      for (var r = col + 1; r < n; r++) {
        if (left[r][col].abs() > left[pivotRow][col].abs()) pivotRow = r;
      }
      if (left[pivotRow][col].abs() < _epsilon) {
        throw const MatrixError('Matrix is singular — it has no inverse');
      }
      if (pivotRow != col) {
        final tmpL = left[col];
        left[col] = left[pivotRow];
        left[pivotRow] = tmpL;
        final tmpR = right[col];
        right[col] = right[pivotRow];
        right[pivotRow] = tmpR;
      }
      final pivot = left[col][col];
      for (var c = 0; c < n; c++) {
        left[col][c] /= pivot;
        right[col][c] /= pivot;
      }
      for (var r = 0; r < n; r++) {
        if (r == col) continue;
        final factor = left[r][col];
        for (var c = 0; c < n; c++) {
          left[r][c] -= factor * left[col][c];
          right[r][c] -= factor * right[col][c];
        }
      }
    }
    return Matrix(right);
  }

  /// Row-reduced echelon form via Gauss-Jordan elimination (works for
  /// non-square matrices too).
  Matrix rref() {
    final a = toList();
    var pivotRow = 0;
    for (var col = 0; col < cols && pivotRow < rows; col++) {
      var maxRow = pivotRow;
      for (var r = pivotRow + 1; r < rows; r++) {
        if (a[r][col].abs() > a[maxRow][col].abs()) maxRow = r;
      }
      if (a[maxRow][col].abs() < _epsilon) continue;

      final tmp = a[pivotRow];
      a[pivotRow] = a[maxRow];
      a[maxRow] = tmp;

      final pivot = a[pivotRow][col];
      for (var c = 0; c < cols; c++) {
        a[pivotRow][c] /= pivot;
      }
      for (var r = 0; r < rows; r++) {
        if (r == pivotRow) continue;
        final factor = a[r][col];
        for (var c = 0; c < cols; c++) {
          a[r][c] -= factor * a[pivotRow][c];
        }
      }
      pivotRow++;
    }
    return Matrix(a);
  }
}
