import 'dart:math' as math;

/// A plain 3D point/vector. No Flutter dependency — this is the model-space
/// math that [SurfacePainter] later projects into screen pixels.
class Vector3 {
  const Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  double get length => math.sqrt(x * x + y * y + z * z);

  /// Rotates this point [azimuth] radians around the Y axis, then
  /// [elevation] radians around the (new) X axis — the standard two-angle
  /// "orbit camera" composition, applied in model space before projection.
  Vector3 rotated({required double azimuth, required double elevation}) {
    final cosA = math.cos(azimuth);
    final sinA = math.sin(azimuth);
    final x1 = x * cosA + z * sinA;
    final z1 = -x * sinA + z * cosA;
    final y1 = y;

    final cosE = math.cos(elevation);
    final sinE = math.sin(elevation);
    final y2 = y1 * cosE - z1 * sinE;
    final z2 = y1 * sinE + z1 * cosE;

    return Vector3(x1, y2, z2);
  }
}
