import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/geometry/geometry_math.dart';

void main() {
  group('distance', () {
    test('3-4-5 right triangle', () {
      expect(GeometryMath.distance(const Offset(0, 0), const Offset(3, 4)), closeTo(5, 1e-9));
    });

    test('distance to self is 0', () {
      const p = Offset(2, 7);
      expect(GeometryMath.distance(p, p), 0);
    });
  });

  group('midpoint', () {
    test('is equidistant from both endpoints', () {
      const a = Offset(0, 0);
      const b = Offset(6, 8);
      final m = GeometryMath.midpoint(a, b);
      expect(GeometryMath.distance(m, a), closeTo(GeometryMath.distance(m, b), 1e-9));
      expect(m.dx, closeTo(3, 1e-9));
      expect(m.dy, closeTo(4, 1e-9));
    });
  });

  group('angleDegrees', () {
    test('perpendicular rays measure 90 degrees', () {
      final angle = GeometryMath.angleDegrees(
          const Offset(0, 0), const Offset(1, 0), const Offset(0, 1));
      expect(angle, closeTo(90, 1e-6));
    });

    test('opposite rays measure 180 degrees', () {
      final angle = GeometryMath.angleDegrees(
          const Offset(0, 0), const Offset(1, 0), const Offset(-1, 0));
      expect(angle, closeTo(180, 1e-6));
    });

    test('coincident rays measure 0 degrees', () {
      final angle = GeometryMath.angleDegrees(
          const Offset(0, 0), const Offset(1, 0), const Offset(2, 0));
      expect(angle, closeTo(0, 1e-6));
    });

    test('a 3-4-5 triangle has a 90 degree angle at the right-angle vertex', () {
      // vertex at (0,0), legs to (3,0) and (0,4) -> right angle
      final angle = GeometryMath.angleDegrees(
          const Offset(0, 0), const Offset(3, 0), const Offset(0, 4));
      expect(angle, closeTo(90, 1e-6));
    });

    test('coincident points throw', () {
      expect(
        () => GeometryMath.angleDegrees(const Offset(0, 0), const Offset(0, 0), const Offset(1, 1)),
        throwsA(isA<GeometryError>()),
      );
    });
  });

  group('circle formulas', () {
    test('circumference of unit circle is 2*pi', () {
      expect(GeometryMath.circleCircumference(1), closeTo(6.283185307179586, 1e-9));
    });

    test('area of radius-2 circle is 4*pi', () {
      expect(GeometryMath.circleArea(2), closeTo(12.566370614359172, 1e-9));
    });
  });
}
