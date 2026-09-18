import 'package:flutter/material.dart';

import '../graphing3d/surface_controller.dart';
import '../graphing3d/surface_painter.dart';
import '../theme/app_theme.dart';

class Surface3dScreen extends StatefulWidget {
  const Surface3dScreen({super.key, SurfaceController? controller}) : _injectedController = controller;

  /// Exposed for tests that need to verify a simulated drag actually
  /// reached the controller — see the matching note on [GraphScreen].
  final SurfaceController? _injectedController;

  @override
  State<Surface3dScreen> createState() => _Surface3dScreenState();
}

class _Surface3dScreenState extends State<Surface3dScreen> {
  late final _controller = widget._injectedController ?? SurfaceController();
  late final _exprField = TextEditingController(text: _controller.expression);

  @override
  void initState() {
    super.initState();
    _controller.compute();
  }

  @override
  void dispose() {
    _exprField.dispose();
    if (widget._injectedController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  const Text('z =', style: TextStyle(fontFamily: 'monospace')),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      controller: _exprField,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                      onFieldSubmitted: (v) {
                        _controller.setExpression(v);
                        _controller.compute();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () {
                      _controller.setExpression(_exprField.text);
                      _controller.compute();
                    },
                    child: const Text('Plot'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    tooltip: 'Zoom in',
                    onPressed: () => _controller.setZoom(_controller.zoom * 1.2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    tooltip: 'Zoom out',
                    onPressed: () => _controller.setZoom(_controller.zoom / 1.2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt),
                    tooltip: 'Reset view',
                    onPressed: _controller.resetView,
                  ),
                  const Spacer(),
                  Text(
                    'Drag to rotate',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (_controller.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(padding: const EdgeInsets.all(12), child: Text(_controller.error!)),
                ),
              ),
            Expanded(
              child: GestureDetector(
                key: const Key('surface3d-canvas'),
                // See the matching comment in graph_screen.dart: without
                // this, a bare CustomPaint child never claims the hit test
                // and drag-to-rotate silently does nothing.
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  _controller.rotate(details.delta.dx * 0.01, -details.delta.dy * 0.01);
                },
                child: Semantics(
                  label:
                      'Rotatable 3D surface plot of z equals ${_controller.expression}. '
                      'Use the zoom and reset controls above for precise navigation.',
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: SurfacePainter(
                      surface: _controller.surface,
                      azimuth: _controller.azimuth,
                      elevation: _controller.elevation,
                      zoom: _controller.zoom,
                      lineColor: palette.accent,
                      axisColor: palette.secondaryLabel,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
