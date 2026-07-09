import 'dart:math' as math;

/// The visible math-space window (`[xMin, xMax] x [yMin, yMax]`) a graph is
/// drawn through. Kept as a plain, testable value type — the painter and
/// gesture handling both derive screen<->math transforms from it, but don't
/// own the state themselves.
class GraphViewport {
  const GraphViewport({
    this.xMin = -10,
    this.xMax = 10,
    this.yMin = -10,
    this.yMax = 10,
  });

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  double get width => xMax - xMin;
  double get height => yMax - yMin;

  GraphViewport copyWith({double? xMin, double? xMax, double? yMin, double? yMax}) {
    return GraphViewport(
      xMin: xMin ?? this.xMin,
      xMax: xMax ?? this.xMax,
      yMin: yMin ?? this.yMin,
      yMax: yMax ?? this.yMax,
    );
  }

  /// Translates the window by ([dx], [dy]) math units.
  GraphViewport pan(double dx, double dy) {
    return copyWith(xMin: xMin + dx, xMax: xMax + dx, yMin: yMin + dy, yMax: yMax + dy);
  }

  /// Scales the window around its own center by [factor] (>1 zooms out,
  /// <1 zooms in) — matches a physical calculator's centered zoom rather
  /// than a pinch-to-point, which keeps the interaction predictable
  /// whether it's driven by a gesture or a plain zoom in/out button.
  GraphViewport zoom(double factor) {
    final cx = (xMin + xMax) / 2;
    final cy = (yMin + yMax) / 2;
    final halfW = width / 2 * factor;
    final halfH = height / 2 * factor;
    return GraphViewport(xMin: cx - halfW, xMax: cx + halfW, yMin: cy - halfH, yMax: cy + halfH);
  }

  /// A "nice" gridline spacing (1/2/5 × a power of ten) for a given axis
  /// range, so grid/tick labels land on human-friendly numbers instead of
  /// whatever the raw range happens to divide into.
  static double niceStep(double range, {int targetLines = 8}) {
    if (range <= 0) return 1;
    final rough = range / targetLines;
    final exponent = (math.log(rough) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final normalized = rough / magnitude;

    double niceNormalized;
    if (normalized < 1.5) {
      niceNormalized = 1;
    } else if (normalized < 3) {
      niceNormalized = 2;
    } else if (normalized < 7) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }
    return niceNormalized * magnitude;
  }
}
