import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/angle_mode.dart';
import 'package:scientific_calculator/core/calculator_engine.dart';
import 'package:scientific_calculator/graphing/function_sampler.dart';
import 'package:scientific_calculator/graphing/graph_mode.dart';
import 'package:scientific_calculator/graphing/plot_definition.dart';

void main() {
  final sampler = FunctionSampler(CalculatorEngine());

  PlotDefinition plot(GraphMode mode, String primary, [String secondary = '']) {
    return PlotDefinition(id: 't', mode: mode, color: plotColors[0], primaryExpression: primary, secondaryExpression: secondary);
  }

  group('function mode', () {
    test('samples a line across the full domain', () {
      final segments = sampler.sample(plot(GraphMode.function, 'x'), AngleMode.radians,
          domainMin: -5, domainMax: 5, samples: 10);
      expect(segments, hasLength(1));
      expect(segments.first.length, 11);
      expect(segments.first.first.dx, -5);
      expect(segments.first.first.dy, -5);
      expect(segments.first.last.dx, 5);
      expect(segments.first.last.dy, 5);
    });

    test('breaks into separate segments across an asymptote', () {
      // 1/x jumps from a large negative value to a large positive value
      // right around x=0 — that should not draw one continuous line.
      final segments = sampler.sample(plot(GraphMode.function, '1/x'), AngleMode.radians,
          domainMin: -2, domainMax: 2, samples: 400);
      expect(segments.length, greaterThanOrEqualTo(2));
    });

    test('sin(x) in radians has period 2*pi', () {
      final segments = sampler.sample(plot(GraphMode.function, 'sin(x)'), AngleMode.radians,
          domainMin: 0, domainMax: 2 * math.pi, samples: 4);
      // samples at 0, pi/2, pi, 3pi/2, 2pi -> sin values 0,1,0,-1,0
      final ys = segments.single.map((p) => p.dy).toList();
      expect(ys[0], closeTo(0, 1e-9));
      expect(ys[1], closeTo(1, 1e-9));
      expect(ys[2], closeTo(0, 1e-9));
    });
  });

  group('parametric mode', () {
    test('unit circle traced by (cos t, sin t)', () {
      final segments = sampler.sample(
        plot(GraphMode.parametric, 'cos(t)', 'sin(t)'),
        AngleMode.radians,
        domainMin: 0,
        domainMax: 2 * math.pi,
        samples: 4,
      );
      final points = segments.single;
      expect(points.first.dx, closeTo(1, 1e-9));
      expect(points.first.dy, closeTo(0, 1e-9));
    });
  });

  group('polar mode', () {
    test('r=1 traces the unit circle', () {
      final segments = sampler.sample(plot(GraphMode.polar, '1'), AngleMode.radians,
          domainMin: 0, domainMax: 2 * math.pi, samples: 4);
      final points = segments.single;
      for (final p in points) {
        expect(p.dx * p.dx + p.dy * p.dy, closeTo(1, 1e-6));
      }
    });
  });

  group('sequence mode', () {
    test('u(n)=n^2 produces one point per integer n as its own segment', () {
      final segments = sampler.sample(plot(GraphMode.sequence, 'n^2'), AngleMode.radians,
          domainMin: 0, domainMax: 3);
      expect(segments, hasLength(4)); // n = 0,1,2,3
      expect(segments[2].single.dy, 4); // n=2 -> 4
    });
  });

  test('empty expression produces no segments', () {
    final segments = sampler.sample(plot(GraphMode.function, ''), AngleMode.radians,
        domainMin: -5, domainMax: 5);
    expect(segments, isEmpty);
  });
}
