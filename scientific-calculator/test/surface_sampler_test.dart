import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/angle_mode.dart';
import 'package:scientific_calculator/core/calculator_engine.dart';
import 'package:scientific_calculator/graphing3d/surface_sampler.dart';

void main() {
  final sampler = SurfaceSampler(CalculatorEngine());

  test('samples a flat plane z=x+y correctly at the grid corners', () {
    final surface = sampler.sample('x+y', AngleMode.radians,
        xMin: -1, xMax: 1, yMin: -1, yMax: 1, resolution: 2);
    // resolution 2 -> 3x3 grid; corners are at (-1,-1), (-1,1), (1,-1), (1,1)
    expect(surface.grid[0][0]!.z, closeTo(-2, 1e-9)); // x=-1,y=-1
    expect(surface.grid[0][2]!.z, closeTo(0, 1e-9)); // x=-1,y=1
    expect(surface.grid[2][0]!.z, closeTo(0, 1e-9)); // x=1,y=-1
    expect(surface.grid[2][2]!.z, closeTo(2, 1e-9)); // x=1,y=1
    expect(surface.grid[1][1]!.z, closeTo(0, 1e-9)); // center x=0,y=0
  });

  test('maxExtent reflects the largest coordinate magnitude reached', () {
    final surface = sampler.sample('x*y', AngleMode.radians,
        xMin: -3, xMax: 3, yMin: -3, yMax: 3, resolution: 6);
    expect(surface.maxExtent, greaterThanOrEqualTo(3));
  });

  test('undefined points become null holes rather than crashing', () {
    final surface = sampler.sample('sqrt(x+y)', AngleMode.radians,
        xMin: -2, xMax: 2, yMin: -2, yMax: 2, resolution: 4);
    // some (x+y) combinations are negative -> sqrt undefined -> should be null
    final hasHole = surface.grid.expand((row) => row).any((p) => p == null);
    expect(hasHole, isTrue);
  });
}
