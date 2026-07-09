import 'dart:ui';

import 'package:flutter/material.dart' hide Offset;

import 'geometry_controller.dart';
import 'geometry_math.dart';
import 'geometry_models.dart';

/// Renders the construction (points, segments, lines, circles) for a
/// simple fixed-center, scale-and-pan viewport — no math-space viewport
/// object like the 2D/3D graphers use, since geometry constructions are
/// usually built outward from wherever the user starts tapping rather
/// than fit to a pre-existing function domain.
class GeometryPainter extends CustomPainter {
  GeometryPainter({
    required this.controller,
    required this.viewCenter,
    required this.viewScale,
    required this.pointColor,
    required this.shapeColor,
    required this.pendingColor,
    required this.labelColor,
  });

  final GeometryController controller;
  final Offset viewCenter;
  final double viewScale;
  final Color pointColor;
  final Color shapeColor;
  final Color pendingColor;
  final Color labelColor;

  Offset _toScreen(Offset math, Size size) {
    return Offset(
      (math.dx - viewCenter.dx) * viewScale + size.width / 2,
      size.height / 2 - (math.dy - viewCenter.dy) * viewScale,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shapePaint = Paint()
      ..color = shapeColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (final shape in controller.shapes) {
      final a = controller.pointById(shape.pointAId);
      final b = controller.pointById(shape.pointBId);
      if (a == null || b == null) continue;
      final sa = _toScreen(a.position, size);
      final sb = _toScreen(b.position, size);
      switch (shape.kind) {
        case GeometryShapeKind.segment:
          canvas.drawLine(sa, sb, shapePaint);
        case GeometryShapeKind.line:
          _drawInfiniteLine(canvas, size, sa, sb, shapePaint);
        case GeometryShapeKind.circle:
          final radius = GeometryMath.distance(a.position, b.position) * viewScale;
          canvas.drawCircle(sa, radius, shapePaint);
      }
    }

    for (final point in controller.points) {
      final isPending = controller.pending.contains(point.id);
      final screenPos = _toScreen(point.position, size);
      canvas.drawCircle(
        screenPos,
        isPending ? 6 : 4.5,
        Paint()..color = isPending ? pendingColor : pointColor,
      );
      _drawLabel(canvas, point.label, screenPos + const Offset(8, -14));
    }
  }

  void _drawInfiniteLine(Canvas canvas, Size size, Offset a, Offset b, Paint paint) {
    final direction = (b - a);
    if (direction.distance < 1e-6) return;
    final unit = direction / direction.distance;
    final farLength = size.longestSide * 2;
    canvas.drawLine(a - unit * farLength, a + unit * farLength, paint);
  }

  void _drawLabel(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant GeometryPainter oldDelegate) => true;
}
