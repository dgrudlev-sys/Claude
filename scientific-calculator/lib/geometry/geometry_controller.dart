import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'geometry_math.dart';
import 'geometry_models.dart';

/// Owns the construction: points, shapes, the active tool, and whatever
/// multi-tap sequence is in progress (e.g. a Segment needs two taps
/// before it commits). A tap either extends the in-progress sequence or,
/// for [GeometryTool.point], commits immediately.
class GeometryController extends ChangeNotifier {
  final List<GeometryPoint> points = [];
  final List<GeometryShape> shapes = [];
  GeometryTool tool = GeometryTool.point;
  String? draggingPointId;
  String? lastMeasurement;
  String? error;
  String? lastSpoken;

  final List<String> _pending = [];
  List<String> get pending => List.unmodifiable(_pending);

  static const double hitRadius = 0.4;

  int _idCounter = 0;
  String _newId() => 'pt${_idCounter++}';

  /// Next label: A, B, ... Z, A1, B1, ...
  String get nextPointLabel {
    final n = points.length;
    final letter = String.fromCharCode('A'.codeUnitAt(0) + n % 26);
    final suffix = n ~/ 26;
    return suffix == 0 ? letter : '$letter$suffix';
  }

  String formatPointLocation(GeometryPoint p) =>
      'Point ${p.label} at ${_fmt(p.position.dx)}, ${_fmt(p.position.dy)}';

  static String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return v.toString();
    if ((v - v.roundToDouble()).abs() < 1e-9) return v.round().toString();
    var text = v.toStringAsFixed(4);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }

  void setTool(GeometryTool newTool) {
    tool = newTool;
    _pending.clear();
    error = null;
    lastMeasurement = null;
    lastSpoken = '${newTool.label} tool selected. ${newTool.hint}';
    notifyListeners();
  }

  GeometryPoint? pointById(String id) {
    for (final p in points) {
      if (p.id == id) return p;
    }
    return null;
  }

  GeometryPoint? _findNear(Offset position) {
    GeometryPoint? closest;
    var bestDist = hitRadius;
    for (final p in points) {
      final d = GeometryMath.distance(p.position, position);
      if (d < bestDist) {
        bestDist = d;
        closest = p;
      }
    }
    return closest;
  }

  /// The point id to start (or continue) dragging, if [position] is close
  /// enough to an existing point — called from the UI's pan-start.
  String? pointNear(Offset position) => _findNear(position)?.id;

  void dragPoint(String id, Offset newPosition) {
    final index = points.indexWhere((p) => p.id == id);
    if (index == -1) return;
    points[index] = points[index].moveTo(newPosition);
    notifyListeners();
  }

  GeometryPoint _addPoint(Offset position) {
    final point = GeometryPoint(id: _newId(), position: position, label: nextPointLabel);
    points.add(point);
    return point;
  }

  /// Always places a new point at exact coordinates (typed x, y), even if
  /// another tool is selected. Used by the number fields, not by canvas taps.
  void reportError(String message) {
    error = message;
    lastSpoken = message;
    notifyListeners();
  }

  void placePoint(Offset position) {
    error = null;
    final point = _addPoint(position);
    lastSpoken =
        '${formatPointLocation(point)}. ${points.length == 1 ? '1 point' : '${points.length} points'} on the canvas.';
    notifyListeners();
  }

  void tapAt(Offset position) {
    error = null;
    if (tool == GeometryTool.select) return;

    if (tool == GeometryTool.point) {
      placePoint(position);
      return;
    }

    final existing = _findNear(position);
    late final GeometryPoint point;
    if (existing == null) {
      point = _addPoint(position);
      lastSpoken = '${formatPointLocation(point)}. ${tool.hint}';
    } else {
      point = existing;
      lastSpoken = 'Used existing point ${point.label}.';
    }

    // Multi-tap tools shouldn't accept the same point twice in a row.
    if (_pending.isNotEmpty && _pending.last == point.id) {
      notifyListeners();
      return;
    }
    _pending.add(point.id);

    if (_pending.length < tool.pointsNeeded) {
      lastSpoken =
          '${lastSpoken ?? ''} ${tool.pointsNeeded - _pending.length} more tap${tool.pointsNeeded - _pending.length == 1 ? '' : 's'} needed.';
      notifyListeners();
      return;
    }

    _commit();
  }

  void _commit() {
    try {
      switch (tool) {
        case GeometryTool.segment:
          shapes.add(GeometryShape.segment(pointAId: _pending[0], pointBId: _pending[1]));
          lastSpoken = 'Segment created.';
        case GeometryTool.line:
          shapes.add(GeometryShape.line(pointAId: _pending[0], pointBId: _pending[1]));
          lastSpoken = 'Line created.';
        case GeometryTool.circle:
          shapes.add(GeometryShape.circle(centerId: _pending[0], radiusPointId: _pending[1]));
          lastSpoken = 'Circle created.';
        case GeometryTool.midpoint:
          final a = pointById(_pending[0])!;
          final b = pointById(_pending[1])!;
          final mid = _addPoint(GeometryMath.midpoint(a.position, b.position));
          lastSpoken = '${formatPointLocation(mid)} is the midpoint.';
        case GeometryTool.measureDistance:
          final a = pointById(_pending[0])!;
          final b = pointById(_pending[1])!;
          final d = GeometryMath.distance(a.position, b.position);
          lastMeasurement = '${a.label}${b.label} = ${d.toStringAsFixed(4)}';
          lastSpoken = 'Distance $lastMeasurement';
        case GeometryTool.measureAngle:
          final vertex = pointById(_pending[0])!;
          final a = pointById(_pending[1])!;
          final b = pointById(_pending[2])!;
          final angle = GeometryMath.angleDegrees(vertex.position, a.position, b.position);
          lastMeasurement = '∠${a.label}${vertex.label}${b.label} = ${angle.toStringAsFixed(2)}°';
          lastSpoken = 'Angle $lastMeasurement';
        case GeometryTool.select:
        case GeometryTool.point:
          break;
      }
    } on GeometryError catch (e) {
      error = e.message;
    }
    _pending.clear();
    notifyListeners();
  }

  void clearAll() {
    points.clear();
    shapes.clear();
    _pending.clear();
    lastMeasurement = null;
    error = null;
    lastSpoken = 'All points and shapes cleared.';
    _idCounter = 0;
    notifyListeners();
  }

  void undo() {
    if (shapes.isNotEmpty) {
      shapes.removeLast();
      lastSpoken = 'Undid last shape.';
    } else if (points.isNotEmpty) {
      points.removeLast();
      lastSpoken = 'Undid last point.';
    }
    notifyListeners();
  }
}
