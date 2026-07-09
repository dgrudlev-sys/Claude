import 'dart:ui';

import 'package:flutter/material.dart' hide Offset;

import '../geometry/geometry_controller.dart';
import '../geometry/geometry_models.dart';
import '../geometry/geometry_painter.dart';
import '../theme/app_theme.dart';

class GeometryScreen extends StatefulWidget {
  const GeometryScreen({super.key});

  @override
  State<GeometryScreen> createState() => _GeometryScreenState();
}

class _GeometryScreenState extends State<GeometryScreen> {
  final _controller = GeometryController();

  Offset _viewCenter = Offset.zero;
  double _viewScale = 40;

  String? _draggingId;
  Offset _tapCandidateMath = Offset.zero;
  double _totalMovement = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _toMath(Offset screenPos, Size size) {
    return Offset(
      (screenPos.dx - size.width / 2) / _viewScale + _viewCenter.dx,
      -(screenPos.dy - size.height / 2) / _viewScale + _viewCenter.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            _Toolbar(controller: _controller),
            if (_controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(_controller.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_controller.lastMeasurement != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  _controller.lastMeasurement!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  return GestureDetector(
                    key: const Key('geometry-canvas'),
                    // See the matching comment in graph_screen.dart: a bare
                    // CustomPaint child never claims the hit test on its
                    // own, so without `opaque` every tap/drag on this
                    // canvas would silently do nothing.
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (details) {
                      _totalMovement = 0;
                      final mathPos = _toMath(details.localFocalPoint, size);
                      _tapCandidateMath = mathPos;
                      _draggingId = _controller.tool == GeometryTool.select
                          ? _controller.pointNear(mathPos)
                          : null;
                    },
                    onScaleUpdate: (details) {
                      _totalMovement += details.focalPointDelta.distance;
                      if (_draggingId != null) {
                        final mathPos = _toMath(details.localFocalPoint, size);
                        _controller.dragPoint(_draggingId!, mathPos);
                      } else {
                        setState(() {
                          _viewCenter -= Offset(
                            details.focalPointDelta.dx / _viewScale,
                            -details.focalPointDelta.dy / _viewScale,
                          );
                          if ((details.scale - 1).abs() > 0.01) {
                            _viewScale = (_viewScale * details.scale).clamp(8, 300);
                          }
                        });
                      }
                    },
                    onScaleEnd: (details) {
                      if (_draggingId == null && _totalMovement < 6) {
                        _controller.tapAt(_tapCandidateMath);
                      }
                      _draggingId = null;
                    },
                    child: Semantics(
                      label: 'Geometry construction canvas. Tap to place points, drag to move them, '
                          'pinch to zoom.',
                      child: CustomPaint(
                        size: size,
                        painter: GeometryPainter(
                          controller: _controller,
                          viewCenter: _viewCenter,
                          viewScale: _viewScale,
                          pointColor: palette.operatorButton,
                          shapeColor: palette.onButton,
                          pendingColor: palette.equalsButton,
                          labelColor: palette.onButton,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller});

  final GeometryController controller;

  static const _toolIcons = {
    GeometryTool.select: Icons.pan_tool_outlined,
    GeometryTool.point: Icons.fiber_manual_record,
    GeometryTool.segment: Icons.show_chart,
    GeometryTool.line: Icons.horizontal_rule,
    GeometryTool.circle: Icons.circle_outlined,
    GeometryTool.midpoint: Icons.linear_scale,
    GeometryTool.measureDistance: Icons.straighten,
    GeometryTool.measureAngle: Icons.architecture,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          for (final tool in GeometryTool.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                avatar: Icon(_toolIcons[tool], size: 18),
                label: Text(tool.label),
                selected: controller.tool == tool,
                onSelected: (_) => controller.setTool(tool),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: controller.undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: controller.clearAll,
          ),
        ],
      ),
    );
  }
}
