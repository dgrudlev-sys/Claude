import 'dart:ui';

import 'package:flutter/material.dart' hide Offset;

import 'graph_mode.dart';
import 'graph_viewport.dart';
import 'plot_definition.dart';

/// Renders the grid, axes, and every visible plot's sampled curves for the
/// current [GraphViewport]. All math-space -> screen-space conversion
/// lives here so the controller and sampler never need to know about
/// pixels.
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.viewport,
    required this.plots,
    required this.segmentsOf,
    required this.axisColor,
    required this.gridColor,
    required this.labelColor,
  });

  final GraphViewport viewport;
  final List<PlotDefinition> plots;
  final List<List<Offset>> Function(PlotDefinition) segmentsOf;
  final Color axisColor;
  final Color gridColor;
  final Color labelColor;

  Offset _toScreen(Offset math, Size size) {
    final sx = (math.dx - viewport.xMin) / viewport.width * size.width;
    final sy = size.height - (math.dy - viewport.yMin) / viewport.height * size.height;
    return Offset(sx, sy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    _paintAxes(canvas, size);
    for (final plot in plots) {
      _paintPlot(canvas, size, plot);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final stepX = GraphViewport.niceStep(viewport.width);
    final stepY = GraphViewport.niceStep(viewport.height);

    var x = (viewport.xMin / stepX).ceil() * stepX;
    for (; x <= viewport.xMax; x += stepX) {
      final p = _toScreen(Offset(x, 0), size);
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), paint);
    }
    var y = (viewport.yMin / stepY).ceil() * stepY;
    for (; y <= viewport.yMax; y += stepY) {
      final p = _toScreen(Offset(0, y), size);
      canvas.drawLine(Offset(0, p.dy), Offset(size.width, p.dy), paint);
    }
  }

  void _paintAxes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.6;
    if (viewport.yMin <= 0 && viewport.yMax >= 0) {
      final p = _toScreen(const Offset(0, 0), size);
      canvas.drawLine(Offset(0, p.dy), Offset(size.width, p.dy), paint);
    }
    if (viewport.xMin <= 0 && viewport.xMax >= 0) {
      final p = _toScreen(const Offset(0, 0), size);
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), paint);
    }
    _paintAxisLabels(canvas, size);
  }

  void _paintAxisLabels(Canvas canvas, Size size) {
    final stepX = GraphViewport.niceStep(viewport.width);
    final stepY = GraphViewport.niceStep(viewport.height);
    final origin = _toScreen(const Offset(0, 0), size);
    final labelY = origin.dy.clamp(0, size.height - 14);

    var x = (viewport.xMin / stepX).ceil() * stepX;
    for (; x <= viewport.xMax; x += stepX) {
      if (x.abs() < stepX / 100) continue; // skip the origin label, axes cross there
      final p = _toScreen(Offset(x, 0), size);
      _drawLabel(canvas, _formatTick(x), Offset(p.dx + 2, labelY.toDouble()));
    }
    var y = (viewport.yMin / stepY).ceil() * stepY;
    final labelX = origin.dx.clamp(0, size.width - 24);
    for (; y <= viewport.yMax; y += stepY) {
      if (y.abs() < stepY / 100) continue;
      final p = _toScreen(Offset(0, y), size);
      _drawLabel(canvas, _formatTick(y), Offset(labelX.toDouble() + 2, p.dy));
    }
  }

  String _formatTick(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  void _drawLabel(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: labelColor, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  void _paintPlot(Canvas canvas, Size size, PlotDefinition plot) {
    final segments = segmentsOf(plot);
    if (segments.isEmpty) return;

    if (plot.mode == GraphMode.sequence) {
      final dotPaint = Paint()..color = plot.color;
      for (final segment in segments) {
        final p = _toScreen(segment.first, size);
        canvas.drawCircle(p, 3.5, dotPaint);
      }
      return;
    }

    final linePaint = Paint()
      ..color = plot.color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (final segment in segments) {
      if (segment.length < 2) continue;
      final path = Path()..moveTo(_toScreen(segment.first, size).dx, _toScreen(segment.first, size).dy);
      for (final point in segment.skip(1)) {
        final p = _toScreen(point, size);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.viewport != viewport || !identical(oldDelegate.plots, plots);
  }
}
