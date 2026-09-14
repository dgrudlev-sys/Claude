import 'package:flutter/foundation.dart';

import 'matrix.dart';

enum MatrixOp { add, subtract, multiply, transposeA, determinantA, inverseA, rrefA }

/// UI state for the matrix screen: two editable matrices (A, B) and
/// whatever the last-run operation produced.
class MatrixController extends ChangeNotifier {
  List<List<double>> _a = [
    [1, 0],
    [0, 1],
  ];
  List<List<double>> _b = [
    [1, 0],
    [0, 1],
  ];

  List<List<double>> get a => _a;
  List<List<double>> get b => _b;

  Matrix? _resultMatrix;
  double? _resultScalar;
  String? _error;

  Matrix? get resultMatrix => _resultMatrix;
  double? get resultScalar => _resultScalar;
  String? get error => _error;

  void resizeA(int rows, int cols) {
    _a = _resized(_a, rows, cols);
    notifyListeners();
  }

  void resizeB(int rows, int cols) {
    _b = _resized(_b, rows, cols);
    notifyListeners();
  }

  List<List<double>> _resized(List<List<double>> m, int rows, int cols) {
    return [
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < cols; c++) r < m.length && c < m[r].length ? m[r][c] : 0.0],
    ];
  }

  void setA(int r, int c, double value) {
    _a[r][c] = value;
    notifyListeners();
  }

  void setB(int r, int c, double value) {
    _b[r][c] = value;
    notifyListeners();
  }

  void run(MatrixOp op) {
    _error = null;
    _resultMatrix = null;
    _resultScalar = null;
    try {
      final matA = Matrix(_a);
      final matB = Matrix(_b);
      switch (op) {
        case MatrixOp.add:
          _resultMatrix = matA + matB;
        case MatrixOp.subtract:
          _resultMatrix = matA - matB;
        case MatrixOp.multiply:
          _resultMatrix = matA.multiply(matB);
        case MatrixOp.transposeA:
          _resultMatrix = matA.transpose;
        case MatrixOp.determinantA:
          _resultScalar = matA.determinant();
        case MatrixOp.inverseA:
          _resultMatrix = matA.inverse();
        case MatrixOp.rrefA:
          _resultMatrix = matA.rref();
      }
    } on MatrixError catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }
}
