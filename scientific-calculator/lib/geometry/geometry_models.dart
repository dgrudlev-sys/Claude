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
  select('Move', 0, 'Drag a point to move it, or drag empty space to pan.'),
  point('Point', 0, 'Add a point: tap the picture, or type numbers.'),
  segment('Segment', 2, 'Tap two points to draw a segment.'),
  line('Line', 2, 'Tap two points to draw an infinite line.'),
  circle('Circle', 2, 'Tap the center, then a point on the circle.'),
  midpoint('Midpoint', 2, 'Tap two points to place their midpoint.'),
  measureDistance('Measure distance', 2, 'Tap two points to measure the distance.'),
  measureAngle('Measure angle', 3, 'Tap the vertex, then two more points to measure the angle.');

  const GeometryTool(this.label, this.pointsNeeded, this.hint);

  final String label;
  final String hint;

  /// How many point taps this tool needs before it commits (0 = acts
  /// immediately on a single tap, e.g. placing a point).
  final int pointsNeeded;
}
