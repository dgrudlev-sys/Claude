import '../core/angle_mode.dart';
import '../core/calculator_engine.dart';
import 'vector3.dart';

/// A regular grid of sampled `(x, y, f(x,y))` points, plus the axis
/// extents actually reached (which can be smaller than the requested
/// domain if the function errors out at some points) — the painter uses
/// the extents to scale the model so the surface fills the view.
class SampledSurface {
  const SampledSurface(this.grid, this.resolution);

  /// Row-major grid of points, `null` where the function couldn't be
  /// evaluated (kept as a hole rather than skewing the surface).
  final List<List<Vector3?>> grid;
  final int resolution;

  double get maxExtent {
    var maxAbs = 1e-9;
    for (final row in grid) {
      for (final p in row) {
        if (p == null) continue;
        for (final v in [p.x, p.y, p.z]) {
          if (v.abs() > maxAbs) maxAbs = v.abs();
        }
      }
    }
    return maxAbs;
  }
}

/// Evaluates `z = f(x, y)` over a grid — the 3D equivalent of
/// [FunctionSampler], binding both `x` and `y` per sample rather than
/// just `x`.
class SurfaceSampler {
  const SurfaceSampler(this._engine);

  final CalculatorEngine _engine;

  SampledSurface sample(
    String expression,
    AngleMode angleMode, {
    required double xMin,
    required double xMax,
    required double yMin,
    required double yMax,
    int resolution = 24,
  }) {
    final prepared = _engine.prepareExpression(expression, angleMode);
    final grid = <List<Vector3?>>[];
    for (var i = 0; i <= resolution; i++) {
      final x = xMin + (xMax - xMin) * i / resolution;
      final row = <Vector3?>[];
      for (var j = 0; j <= resolution; j++) {
        final y = yMin + (yMax - yMin) * j / resolution;
        try {
          final z = _engine.evaluateExpression(prepared, variables: {'x': x, 'y': y});
          row.add(Vector3(x, y, z));
        } catch (_) {
          row.add(null);
        }
      }
      grid.add(row);
    }
    return SampledSurface(grid, resolution);
  }
}
