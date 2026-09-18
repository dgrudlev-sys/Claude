import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/geometry/geometry_controller.dart';
import 'package:scientific_calculator/geometry/geometry_models.dart';

void main() {
  group('point tool', () {
    test('a single tap places one labeled point', () {
      final c = GeometryController();
      c.tapAt(const Offset(1, 1));
      expect(c.points, hasLength(1));
      expect(c.points.single.label, 'A');
    });

    test('points are labeled A, B, C, ...', () {
      final c = GeometryController();
      c.tapAt(const Offset(0, 0));
      c.tapAt(const Offset(1, 1));
      c.tapAt(const Offset(2, 2));
      expect(c.points.map((p) => p.label), ['A', 'B', 'C']);
    });
  });

  group('segment tool', () {
    test('needs two taps before it commits', () {
      final c = GeometryController()..setTool(GeometryTool.segment);
      c.tapAt(const Offset(0, 0));
      expect(c.shapes, isEmpty); // first tap only creates the point
      c.tapAt(const Offset(1, 1));
      expect(c.shapes, hasLength(1));
      expect(c.shapes.single.kind, GeometryShapeKind.segment);
    });

    test('tapping near an existing point reuses it instead of creating a new one', () {
      final c = GeometryController()..setTool(GeometryTool.point);
      c.tapAt(const Offset(0, 0));
      final existingId = c.points.single.id;

      c.setTool(GeometryTool.segment);
      c.tapAt(const Offset(0.05, 0.05)); // within hitRadius of the existing point
      c.tapAt(const Offset(5, 5));

      expect(c.points, hasLength(2)); // did not create a 3rd point
      expect(c.shapes.single.pointAId, existingId);
    });
  });

  group('midpoint tool', () {
    test('creates a new point at the midpoint of two taps', () {
      final c = GeometryController()..setTool(GeometryTool.midpoint);
      c.tapAt(const Offset(0, 0));
      c.tapAt(const Offset(4, 6));
      expect(c.points, hasLength(3)); // 2 taps + 1 computed midpoint
      final mid = c.points.last;
      expect(mid.position.dx, closeTo(2, 1e-9));
      expect(mid.position.dy, closeTo(3, 1e-9));
    });
  });

  group('measurement tools', () {
    test('measureDistance reports a formatted result and creates no shape', () {
      final c = GeometryController()..setTool(GeometryTool.measureDistance);
      c.tapAt(const Offset(0, 0));
      c.tapAt(const Offset(3, 4));
      expect(c.shapes, isEmpty);
      expect(c.lastMeasurement, contains('5.0000'));
    });

    test('measureAngle needs three taps and reports degrees', () {
      final c = GeometryController()..setTool(GeometryTool.measureAngle);
      c.tapAt(const Offset(0, 0)); // vertex
      expect(c.lastMeasurement, isNull);
      c.tapAt(const Offset(1, 0));
      c.tapAt(const Offset(0, 1));
      expect(c.lastMeasurement, contains('90.00'));
    });
  });

  group('dragging', () {
    test('moves the point and any shape referencing it follows (by id, not snapshot)', () {
      final c = GeometryController()..setTool(GeometryTool.segment);
      c.tapAt(const Offset(0, 0));
      c.tapAt(const Offset(1, 0));
      final aId = c.points.first.id;

      c.dragPoint(aId, const Offset(10, 10));
      expect(c.pointById(aId)!.position, const Offset(10, 10));
      // the segment still references the same point id, so it "follows"
      expect(c.shapes.single.pointAId, aId);
    });

    test('pointNear finds a point within the hit radius and null otherwise', () {
      final c = GeometryController()..setTool(GeometryTool.point);
      c.tapAt(const Offset(2, 2));
      final id = c.points.single.id;
      expect(c.pointNear(const Offset(2.1, 2.1)), id);
      expect(c.pointNear(const Offset(50, 50)), isNull);
    });
  });

  group('clearAll and undo', () {
    test('clearAll empties points and shapes', () {
      final c = GeometryController()..setTool(GeometryTool.segment);
      c.tapAt(const Offset(0, 0));
      c.tapAt(const Offset(1, 1));
      c.clearAll();
      expect(c.points, isEmpty);
      expect(c.shapes, isEmpty);
    });

    test('undo removes the most recent shape before touching points', () {
      final c = GeometryController()..setTool(GeometryTool.segment);
      c.tapAt(const Offset(0, 0));
      c.tapAt(const Offset(1, 1));
      expect(c.shapes, hasLength(1));
      c.undo();
      expect(c.shapes, isEmpty);
      expect(c.points, hasLength(2)); // points stay until a second undo
    });
  });

  test('switching tools clears any in-progress tap sequence', () {
    final c = GeometryController()..setTool(GeometryTool.segment);
    c.tapAt(const Offset(0, 0));
    expect(c.pending, hasLength(1));
    c.setTool(GeometryTool.circle);
    expect(c.pending, isEmpty);
  });
}
