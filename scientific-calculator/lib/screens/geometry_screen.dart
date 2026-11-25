import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Offset;
import 'package:flutter/semantics.dart';

import '../core/numeric_input.dart';
import '../geometry/geometry_controller.dart';
import '../geometry/geometry_models.dart';
import '../geometry/geometry_painter.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/chooser_tile.dart';
import '../widgets/numeric_field.dart';

class GeometryScreen extends StatefulWidget {
  const GeometryScreen({super.key, GeometryController? controller})
      : _injectedController = controller;

  final GeometryController? _injectedController;

  @override
  State<GeometryScreen> createState() => _GeometryScreenState();
}

class _GeometryScreenState extends State<GeometryScreen> {
  late final _controller = widget._injectedController ?? GeometryController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  Offset _viewCenter = Offset.zero;
  double _viewScale = 40;

  int? _activePointer;
  Offset _downLocal = Offset.zero;
  Offset _lastLocal = Offset.zero;
  bool _tapCommitted = false;
  String? _draggingId;
  String? _lastAnnounced;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_announce);
  }

  void _announce() {
    final text = _controller.lastSpoken;
    if (text == null || text == _lastAnnounced) return;
    _lastAnnounced = text;
    SemanticsService.announce(text, TextDirection.ltr); // ignore: deprecated_member_use
  }

  @override
  void dispose() {
    _controller.removeListener(_announce);
    _xController.dispose();
    _yController.dispose();
    if (widget._injectedController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Offset _toMath(Offset screenPos, Size size) {
    return Offset(
      (screenPos.dx - size.width / 2) / _viewScale + _viewCenter.dx,
      -(screenPos.dy - size.height / 2) / _viewScale + _viewCenter.dy,
    );
  }

  void _onPointerDown(PointerDownEvent event, Size size) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _downLocal = event.localPosition;
    _lastLocal = event.localPosition;
    _tapCommitted = false;
    _draggingId = null;
    if (_controller.tool == GeometryTool.select) {
      _draggingId = _controller.pointNear(_toMath(event.localPosition, size));
    }
  }

  void _onPointerMove(PointerMoveEvent event, Size size) {
    if (event.pointer != _activePointer) return;
    final delta = event.localPosition - _lastLocal;
    _lastLocal = event.localPosition;

    // Construction tools never pan. A mouse click on Flutter web often
    // includes a few move events; treating those as a pan was swallowing
    // the tap.
    if (_controller.tool != GeometryTool.select) return;

    if (_draggingId != null) {
      _controller.dragPoint(_draggingId!, _toMath(event.localPosition, size));
    } else {
      setState(() {
        _viewCenter -= Offset(
          delta.dx / _viewScale,
          -delta.dy / _viewScale,
        );
      });
    }
  }

  void _commitTap(Size size) {
    if (_tapCommitted) return;
    if (_controller.tool == GeometryTool.select) return;
    _tapCommitted = true;
    _controller.tapAt(_toMath(_downLocal, size));
  }

  void _onPointerUp(PointerUpEvent event, Size size) {
    if (event.pointer != _activePointer) return;
    _commitTap(size);
    _activePointer = null;
    _draggingId = null;
  }

  void _onPointerCancel(Size size) {
    // Flutter web sometimes delivers cancel instead of up for a mouse click.
    if (_activePointer == null) return;
    _commitTap(size);
    _activePointer = null;
    _draggingId = null;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    setState(() {
      final zoom = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      _viewScale = (_viewScale * zoom).clamp(8, 300);
    });
  }

  void _addTypedPoint() {
    final x = double.tryParse(NumericInput.sanitizeScalar(_xController.text).replaceAll(',', '.'));
    final y = double.tryParse(NumericInput.sanitizeScalar(_yController.text).replaceAll(',', '.'));
    if (x == null || y == null) {
      _controller.reportError('Type both numbers first.');
      return;
    }
    _controller.placePoint(Offset(x, y));
    _xController.clear();
    _yController.clear();
  }

  String _statusLine() {
    final strings = L10n.stringsOf(context);
    final how = strings.geometryHint(_controller.tool.name);
    final n = _controller.points.length;
    final count = n == 0
        ? 'No points yet.'
        : (n == 1 ? '1 point on the picture.' : '$n points on the picture.');
    final spoken = _controller.lastSpoken;
    if (spoken == null || spoken.isEmpty) return '$how $count';
    return '$how $count $spoken';
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<CalculatorPalette>()!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            _ToolGrid(controller: _controller),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _statusLine(),
                  key: const Key('geometry-status'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: NumericField(
                      key: const Key('geometry-x'),
                      controller: _xController,
                      labelText: 'X (left-right)',
                      showHelper: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumericField(
                      key: const Key('geometry-y'),
                      controller: _yController,
                      labelText: 'Y (up-down)',
                      showHelper: false,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('geometry-add-point'),
                      onPressed: _addTypedPoint,
                      child: Text('Add Point ${_controller.nextPointLabel}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _controller.undo, child: const Text('Undo')),
                  TextButton(onPressed: _controller.clearAll, child: const Text('Clear')),
                ],
              ),
            ),
            if (_controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  _controller.error!,
                  style: TextStyle(color: palette.errorForeground, fontWeight: FontWeight.w600),
                ),
              ),
            if (_controller.lastMeasurement != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _controller.lastMeasurement!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.onButton, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        return MouseRegion(
                          opaque: true,
                          cursor: SystemMouseCursors.precise,
                          child: Listener(
                            key: const Key('geometry-canvas'),
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (e) => _onPointerDown(e, size),
                            onPointerMove: (e) => _onPointerMove(e, size),
                            onPointerUp: (e) => _onPointerUp(e, size),
                            onPointerCancel: (_) => _onPointerCancel(size),
                            onPointerSignal: _onPointerSignal,
                            child: Semantics(
                              container: true,
                              label:
                                  'Drawing area. ${_statusLine()} ${_controller.lastSpoken ?? ''}',
                              child: ColoredBox(
                                color: palette.displayBackground,
                                child: CustomPaint(
                                  painter: GeometryPainter(
                                    controller: _controller,
                                    viewCenter: _viewCenter,
                                    viewScale: _viewScale,
                                    pointColor: palette.operatorButton,
                                    shapeColor: palette.onButton,
                                    pendingColor: palette.equalsButton,
                                    labelColor: palette.onButton,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.controller});

  final GeometryController controller;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.stringsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: ChooserTile.separated([
        for (final tool in GeometryTool.values)
          ChooserTile(
            key: Key('geometry-tool-${tool.name}'),
            title: strings.geometryTool(tool.name),
            selected: controller.tool == tool,
            onTap: () => controller.setTool(tool),
          ),
      ]),
    );
  }
}
