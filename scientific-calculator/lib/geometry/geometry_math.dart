import 'dart:math' as math;
import 'dart:ui';

class GeometryError implements Exception {
  const GeometryError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Plain 2D geometry formulas — distance, midpoint, angle — kept free of
/// any controller/widget state so they're directly testable.
class GeometryMath {
  static double distance(Offset a, Offset b) => (a - b).distance;

  static Offset midpoint(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  /// The angle at [vertex] between rays toward [a] and [b], in degrees,
  /// in `[0, 180]`.
  static double angleDegrees(Offset vertex, Offset a, Offset b) {
    final v1 = a - vertex;
    final v2 = b - vertex;
    final mag = v1.distance * v2.distance;
    if (mag < 1e-12) {
      throw const GeometryError('Angle is undefined for coincident points');
    }
    final cosTheta = ((v1.dx * v2.dx + v1.dy * v2.dy) / mag).clamp(-1.0, 1.0);
    return math.acos(cosTheta) * 180 / math.pi;
  }

  static double circleCircumference(double radius) => 2 * math.pi * radius;

  static double circleArea(double radius) => math.pi * radius * radius;
}
