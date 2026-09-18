import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/graphing3d/vector3.dart';

void main() {
  test('rotation preserves length (it is an orthogonal transform)', () {
    const points = [
      Vector3(1, 2, 3),
      Vector3(-4, 0.5, 7),
      Vector3(0, 0, 5),
    ];
    for (final p in points) {
      final rotated = p.rotated(azimuth: 0.7, elevation: 1.1);
      expect(rotated.length, closeTo(p.length, 1e-9));
    }
  });

  test('zero rotation is the identity', () {
    const p = Vector3(3, -2, 5);
    final rotated = p.rotated(azimuth: 0, elevation: 0);
    expect(rotated.x, closeTo(p.x, 1e-9));
    expect(rotated.y, closeTo(p.y, 1e-9));
    expect(rotated.z, closeTo(p.z, 1e-9));
  });

  test('90-degree azimuth maps +x onto the z axis', () {
    const p = Vector3(1, 0, 0);
    final rotated = p.rotated(azimuth: math.pi / 2, elevation: 0);
    expect(rotated.x, closeTo(0, 1e-9));
    expect(rotated.y, closeTo(0, 1e-9));
    expect(rotated.z.abs(), closeTo(1, 1e-9));
  });

  test('360-degree azimuth returns to the original point', () {
    const p = Vector3(2, 3, -1);
    final rotated = p.rotated(azimuth: 2 * math.pi, elevation: 0);
    expect(rotated.x, closeTo(p.x, 1e-6));
    expect(rotated.y, closeTo(p.y, 1e-6));
    expect(rotated.z, closeTo(p.z, 1e-6));
  });
}
