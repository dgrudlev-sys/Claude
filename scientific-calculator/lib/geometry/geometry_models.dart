import 'dart:ui';

class GeometryPoint {
  const GeometryPoint({required this.id, required this.position, required this.label});

  final String id;
  final Offset position;
  final String label;

  GeometryPoint moveTo(Offset newPosition) =>
      GeometryPoint(id: id, position: newPosition, label: label);
}

enum GeometryShapeKind { segment, line, circle }

/// A shape defined in terms of point *ids*, not fixed coordinates — so
/// dragging a point it references moves the shape with it, without a full
/// constraint-solving engine. (A computed point like a midpoint is a
/// snapshot at creation time, not a live constraint — dragging its
/// parents afterward won't move it. That's a deliberate v1 scope line,
/// not an oversight.)
class GeometryShape {
  const GeometryShape.segment({required this.pointAId, required this.pointBId})
      : kind = GeometryShapeKind.segment;

  const GeometryShape.line({required this.pointAId, required this.pointBId})
      : kind = GeometryShapeKind.line;

  const GeometryShape.circle({required String centerId, required String radiusPointId})
      : kind = GeometryShapeKind.circle,
        pointAId = centerId,
        pointBId = radiusPointId;

  final GeometryShapeKind kind;
  final String pointAId;
  final String pointBId; // radius-defining point, for circles
}

enum GeometryTool {
  select('Move', 0),
  point('Point', 0),
  segment('Segment', 2),
  line('Line', 2),
  circle('Circle', 2),
  midpoint('Midpoint', 2),
  measureDistance('Measure distance', 2),
  measureAngle('Measure angle', 3);

  const GeometryTool(this.label, this.pointsNeeded);

  final String label;

  /// How many point taps this tool needs before it commits (0 = acts
  /// immediately on a single tap, e.g. placing a point).
  final int pointsNeeded;
}
