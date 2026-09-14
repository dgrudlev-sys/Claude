import 'dart:math' as math;
import 'dart:ui';

import '../core/angle_mode.dart';
import '../core/calculator_engine.dart';
import 'graph_mode.dart';
import 'plot_definition.dart';

/// Turns a [PlotDefinition] into one or more polylines in *math space*
/// (not screen pixels — the painter applies the viewport transform).
/// Each returned polyline is a continuous run; sampling breaks into a new
/// polyline wherever the function errors out or jumps by an amount large
/// enough to be an asymptote rather than a steep-but-real slope, so
/// `tan(x)` doesn't draw a vertical line connecting its branches.
class FunctionSampler {
  const FunctionSampler(this._engine);

  final CalculatorEngine _engine;

  List<List<Offset>> sample(
    PlotDefinition def,
    AngleMode angleMode, {
    required double domainMin,
    required double domainMax,
    int samples = 500,
  }) {
    if (def.isEmpty) return const [];
    switch (def.mode) {
      case GraphMode.function:
        return _sampleFunction(def.primaryExpression, angleMode, domainMin, domainMax, samples);
      case GraphMode.parametric:
        return _sampleParametric(def.primaryExpression, def.secondaryExpression, angleMode,
            domainMin, domainMax, samples);
      case GraphMode.polar:
        return _samplePolar(def.primaryExpression, angleMode, domainMin, domainMax, samples);
      case GraphMode.sequence:
        return _sampleSequence(def.primaryExpression, angleMode, domainMin, domainMax);
    }
  }

  List<List<Offset>> _sampleFunction(
      String expr, AngleMode angleMode, double xMin, double xMax, int samples) {
    final prepared = _engine.prepareExpression(expr, angleMode);
    final segments = <List<Offset>>[];
    var current = <Offset>[];
    double? prevY;
    final jumpThreshold = (xMax - xMin).abs() * 25 + 1;

    for (var i = 0; i <= samples; i++) {
      final x = xMin + (xMax - xMin) * i / samples;
      double? y;
      try {
        y = _engine.evaluateExpression(prepared, variables: {'x': x});
      } catch (_) {
        y = null;
      }
      if (y == null) {
        if (current.length > 1) segments.add(current);
        current = [];
        prevY = null;
        continue;
      }
      if (prevY != null && (y - prevY).abs() > jumpThreshold) {
        if (current.length > 1) segments.add(current);
        current = [];
      }
      current.add(Offset(x, y));
      prevY = y;
    }
    if (current.length > 1) segments.add(current);
    return segments;
  }

  List<List<Offset>> _sampleParametric(String xExpr, String yExpr, AngleMode angleMode,
      double tMin, double tMax, int samples) {
    final preparedX = _engine.prepareExpression(xExpr, angleMode);
    final preparedY = _engine.prepareExpression(yExpr, angleMode);
    final points = <Offset>[];
    for (var i = 0; i <= samples; i++) {
      final t = tMin + (tMax - tMin) * i / samples;
      try {
        final x = _engine.evaluateExpression(preparedX, variables: {'t': t});
        final y = _engine.evaluateExpression(preparedY, variables: {'t': t});
        points.add(Offset(x, y));
      } catch (_) {
        if (points.length > 1) {
          return [points];
        }
        points.clear();
      }
    }
    return points.length > 1 ? [points] : const [];
  }

  List<List<Offset>> _samplePolar(
      String rExpr, AngleMode angleMode, double thetaMin, double thetaMax, int samples) {
    final prepared = _engine.prepareExpression(rExpr, angleMode);
    final points = <Offset>[];
    for (var i = 0; i <= samples; i++) {
      final theta = thetaMin + (thetaMax - thetaMin) * i / samples;
      try {
        final r = _engine.evaluateExpression(prepared, variables: {'theta': theta});
        final thetaRad = angleMode == AngleMode.degrees ? theta * math.pi / 180 : theta;
        points.add(Offset(r * math.cos(thetaRad), r * math.sin(thetaRad)));
      } catch (_) {
        // skip this sample, keep the polyline going
      }
    }
    return points.length > 1 ? [points] : const [];
  }

  List<List<Offset>> _sampleSequence(
      String expr, AngleMode angleMode, double nMin, double nMax) {
    final prepared = _engine.prepareExpression(expr, angleMode);
    final points = <Offset>[];
    final start = nMin.round();
    final end = nMax.round();
    for (var n = start; n <= end; n++) {
      try {
        final value = _engine.evaluateExpression(prepared, variables: {'n': n.toDouble()});
        points.add(Offset(n.toDouble(), value));
      } catch (_) {
        // skip undefined terms
      }
    }
    // Sequence points are discrete — each is its own "segment" so the
    // painter draws markers rather than connecting them with a line.
    return [for (final p in points) [p]];
  }
}
