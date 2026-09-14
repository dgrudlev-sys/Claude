import 'dart:ui';

import 'package:flutter/material.dart' hide Offset;

import 'surface_sampler.dart';
import 'vector3.dart';

class _ProjectedLine {
  const _ProjectedLine(this.a, this.b, this.depth);

  final Offset a;
  final Offset b;
  final double depth;
}

/// Renders a sampled surface as a rotated wireframe: every grid point is
/// rotated in model space, projected orthographically, then every
/// row/column segment is drawn back-to-front (sorted by average depth) with
/// depth-based opacity as a cheap stand-in for real shading — a full
/// hidden-surface/z-buffer renderer is a lot more machinery than a
/// wireframe grapher needs to be readable.
class SurfacePainter extends CustomPainter {
  SurfacePainter({
    required this.surface,
    required this.azimuth,
    required this.elevation,
    required this.zoom,
    required this.lineColor,
    required this.axisColor,
  });

  final SampledSurface? surface;
  final double azimuth;
  final double elevation;
  final double zoom;
  final Color lineColor;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = surface;
    if (s == null) return;

    final extent = s.maxExtent;
    final scale = (size.shortestSide / 2.4) / extent * zoom;
    final center = Offset(size.width / 2, size.height / 2);

    Offset? project(Vector3? p) {
      if (p == null) return null;
      final r = p.rotated(azimuth: azimuth, elevation: elevation);
      return Offset(center.dx + r.x * scale, center.dy - r.y * scale);
    }

    double? depthOf(Vector3? p) {
      if (p == null) return null;
      return p.rotated(azimuth: azimuth, elevation: elevation).z;
    }

    _drawAxes(canvas, center, scale, extent);

    final lines = <_ProjectedLine>[];
    final grid = s.grid;
    for (var i = 0; i < grid.length; i++) {
      for (var j = 0; j < grid[i].length; j++) {
        final p = grid[i][j];
        if (p == null) continue;
        if (j + 1 < grid[i].length && grid[i][j + 1] != null) {
          final a = project(p)!;
          final b = project(grid[i][j + 1])!;
          final depth = ((depthOf(p) ?? 0) + (depthOf(grid[i][j + 1]) ?? 0)) / 2;
          lines.add(_ProjectedLine(a, b, depth));
        }
        if (i + 1 < grid.length && grid[i + 1][j] != null) {
          final a = project(p)!;
          final b = project(grid[i + 1][j])!;
          final depth = ((depthOf(p) ?? 0) + (depthOf(grid[i + 1][j]) ?? 0)) / 2;
          lines.add(_ProjectedLine(a, b, depth));
        }
      }
    }

    lines.sort((a, b) => a.depth.compareTo(b.depth));
    if (lines.isEmpty) return;
    final minDepth = lines.first.depth;
    final maxDepth = lines.last.depth;
    final depthRange = (maxDepth - minDepth).abs() < 1e-9 ? 1 : maxDepth - minDepth;

    for (final line in lines) {
      final t = (line.depth - minDepth) / depthRange; // 0 = farthest, 1 = nearest
      final paint = Paint()
        ..color = lineColor.withValues(alpha: 0.25 + 0.65 * t)
        ..strokeWidth = 1.2;
      canvas.drawLine(line.a, line.b, paint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double scale, double extent) {
    final paint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.4;
    final axisEndpoints = <List<Vector3>>[
      [Vector3(-extent, 0, 0), Vector3(extent, 0, 0)],
      [Vector3(0, -extent, 0), Vector3(0, extent, 0)],
      [Vector3(0, 0, -extent), Vector3(0, 0, extent)],
    ];
    for (final axis in axisEndpoints) {
      final a = axis[0].rotated(azimuth: azimuth, elevation: elevation);
      final b = axis[1].rotated(azimuth: azimuth, elevation: elevation);
      canvas.drawLine(
        Offset(center.dx + a.x * scale, center.dy - a.y * scale),
        Offset(center.dx + b.x * scale, center.dy - b.y * scale),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SurfacePainter oldDelegate) {
    return oldDelegate.surface != surface ||
        oldDelegate.azimuth != azimuth ||
        oldDelegate.elevation != elevation ||
        oldDelegate.zoom != zoom;
  }
}
