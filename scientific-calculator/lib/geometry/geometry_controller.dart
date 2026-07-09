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

  final List<String> _pending = [];
  List<String> get pending => List.unmodifiable(_pending);

  static const double hitRadius = 0.4;

  int _idCounter = 0;
  String _newId() => 'pt${_idCounter++}';
  String _nextLabel() {
    // A, B, ... Z, A1, B1, ...
    final n = points.length;
    final letter = String.fromCharCode('A'.codeUnitAt(0) + n % 26);
    final suffix = n ~/ 26;
    return suffix == 0 ? letter : '$letter$suffix';
  }

  void setTool(GeometryTool newTool) {
    tool = newTool;
    _pending.clear();
    error = null;
    lastMeasurement = null;
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

  void tapAt(Offset position) {
    error = null;
    if (tool == GeometryTool.select) return;

    if (tool == GeometryTool.point) {
      points.add(GeometryPoint(id: _newId(), position: position, label: _nextLabel()));
      notifyListeners();
      return;
    }

    final existing = _findNear(position);
    final point = existing ?? GeometryPoint(id: _newId(), position: position, label: _nextLabel());
    if (existing == null) points.add(point);

    // Multi-tap tools shouldn't accept the same point twice in a row.
    if (_pending.isNotEmpty && _pending.last == point.id) {
      notifyListeners();
      return;
    }
    _pending.add(point.id);

    if (_pending.length < tool.pointsNeeded) {
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
        case GeometryTool.line:
          shapes.add(GeometryShape.line(pointAId: _pending[0], pointBId: _pending[1]));
        case GeometryTool.circle:
          shapes.add(GeometryShape.circle(centerId: _pending[0], radiusPointId: _pending[1]));
        case GeometryTool.midpoint:
          final a = pointById(_pending[0])!;
          final b = pointById(_pending[1])!;
          points.add(GeometryPoint(
            id: _newId(),
            position: GeometryMath.midpoint(a.position, b.position),
            label: _nextLabel(),
          ));
        case GeometryTool.measureDistance:
          final a = pointById(_pending[0])!;
          final b = pointById(_pending[1])!;
          final d = GeometryMath.distance(a.position, b.position);
          lastMeasurement = '${a.label}${b.label} = ${d.toStringAsFixed(4)}';
        case GeometryTool.measureAngle:
          final vertex = pointById(_pending[0])!;
          final a = pointById(_pending[1])!;
          final b = pointById(_pending[2])!;
          final angle = GeometryMath.angleDegrees(vertex.position, a.position, b.position);
          lastMeasurement = '∠${a.label}${vertex.label}${b.label} = ${angle.toStringAsFixed(2)}°';
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
    _idCounter = 0;
    notifyListeners();
  }

  void undo() {
    if (shapes.isNotEmpty) {
      shapes.removeLast();
    } else if (points.isNotEmpty) {
      points.removeLast();
    }
    notifyListeners();
  }
}
