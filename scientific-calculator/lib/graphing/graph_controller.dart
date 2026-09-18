import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:math_expressions/math_expressions.dart' show Expression;

import '../core/angle_mode.dart';
import '../core/calculator_engine.dart';
import 'function_sampler.dart';
import 'graph_mode.dart';
import 'graph_viewport.dart';
import 'plot_definition.dart';

class TableRow {
  const TableRow(this.input, this.output);

  final double input;
  final double? output;
}

/// Owns everything a graph screen needs: the plot list, the current mode,
/// the viewport, and (re-)sampling — plots are re-sampled lazily and
/// cached until something that would change their shape (an expression,
/// the viewport, angle mode, or the parameter domain) actually changes.
class GraphController extends ChangeNotifier {
  GraphController({FunctionSampler? sampler})
      : _sampler = sampler ?? FunctionSampler(CalculatorEngine()) {
    _ensureAtLeastOnePlot();
  }

  final FunctionSampler _sampler;

  GraphMode _mode = GraphMode.function;
  GraphViewport _viewport = const GraphViewport();
  AngleMode _angleMode = AngleMode.radians;

  // Parameter domains for modes where the sampling axis isn't the
  // viewport's x-axis (t for parametric, theta for polar, n for sequence).
  double _paramMin = 0;
  double _paramMax = 2 * 3.141592653589793;
  double _sequenceMin = 0;
  double _sequenceMax = 20;

  List<PlotDefinition> _plots = [];
  final _sampleCache = <String, List<List<Offset>>>{};

  GraphMode get mode => _mode;
  GraphViewport get viewport => _viewport;
  AngleMode get angleMode => _angleMode;
  double get paramMin => _paramMin;
  double get paramMax => _paramMax;
  double get sequenceMin => _sequenceMin;
  double get sequenceMax => _sequenceMax;
  List<PlotDefinition> get plots => List.unmodifiable(_plots);

  void _ensureAtLeastOnePlot() {
    if (_plots.isEmpty) {
      _plots = [
        PlotDefinition(id: _newId(), mode: _mode, color: plotColors[0]),
      ];
    }
  }

  int _idCounter = 0;
  String _newId() => 'plot-${_idCounter++}';

  void setMode(GraphMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    // Switching modes starts a fresh plot list — a y=f(x) expression
    // isn't meaningful once you're plotting r(theta).
    _plots = [PlotDefinition(id: _newId(), mode: mode, color: plotColors[0])];
    _sampleCache.clear();
    notifyListeners();
  }

  void addPlot() {
    if (_plots.length >= plotColors.length) return;
    _plots = [
      ..._plots,
      PlotDefinition(id: _newId(), mode: _mode, color: plotColors[_plots.length]),
    ];
    notifyListeners();
  }

  void removePlot(String id) {
    if (_plots.length <= 1) return;
    _plots = _plots.where((p) => p.id != id).toList();
    _sampleCache.remove(id);
    notifyListeners();
  }

  void updatePrimaryExpression(String id, String expression) {
    _updatePlot(id, (p) => p.copyWith(primaryExpression: expression, error: null));
  }

  void updateSecondaryExpression(String id, String expression) {
    _updatePlot(id, (p) => p.copyWith(secondaryExpression: expression, error: null));
  }

  void toggleVisible(String id) {
    _updatePlot(id, (p) => p.copyWith(visible: !p.visible));
  }

  void _updatePlot(String id, PlotDefinition Function(PlotDefinition) transform) {
    _plots = [
      for (final p in _plots)
        if (p.id == id) transform(p) else p,
    ];
    _sampleCache.remove(id);
    notifyListeners();
  }

  void setAngleMode(AngleMode mode) {
    if (mode == _angleMode) return;
    _angleMode = mode;
    _sampleCache.clear();
    notifyListeners();
  }

  void setParamDomain(double min, double max) {
    _paramMin = min;
    _paramMax = max;
    _sampleCache.clear();
    notifyListeners();
  }

  void setSequenceDomain(double min, double max) {
    _sequenceMin = min;
    _sequenceMax = max;
    _sampleCache.clear();
    notifyListeners();
  }

  void pan(double dx, double dy) {
    _viewport = _viewport.pan(dx, dy);
    notifyListeners();
  }

  void zoom(double factor) {
    _viewport = _viewport.zoom(factor);
    notifyListeners();
  }

  void resetViewport() {
    _viewport = const GraphViewport();
    notifyListeners();
  }

  /// Sampled polylines for [plot], in math space. Cached per-plot until
  /// something that affects its shape changes.
  List<List<Offset>> segmentsFor(PlotDefinition plot) {
    if (plot.isEmpty || !plot.visible) return const [];
    final cacheKey = plot.id;
    final cached = _sampleCache[cacheKey];
    if (cached != null) return cached;

    try {
      final domainMin = _mode == GraphMode.parametric
          ? _paramMin
          : _mode == GraphMode.polar
              ? _paramMin
              : _mode == GraphMode.sequence
                  ? _sequenceMin
                  : _viewport.xMin;
      final domainMax = _mode == GraphMode.parametric
          ? _paramMax
          : _mode == GraphMode.polar
              ? _paramMax
              : _mode == GraphMode.sequence
                  ? _sequenceMax
                  : _viewport.xMax;

      final segments = _sampler.sample(
        plot,
        _angleMode,
        domainMin: domainMin,
        domainMax: domainMax,
      );
      _sampleCache[cacheKey] = segments;
      if (plot.error != null) {
        _updatePlot(plot.id, (p) => p.copyWith(error: null));
      }
      return segments;
    } on CalculatorError catch (e) {
      _sampleCache[cacheKey] = const [];
      Future.microtask(() => _updatePlot(plot.id, (p) => p.copyWith(error: e.message)));
      return const [];
    }
  }

  /// A table of (x, f(x)) values for function-mode plots.
  List<TableRow> tableFor(PlotDefinition plot,
      {required double start, required double step, int count = 20}) {
    if (plot.mode != GraphMode.function || plot.primaryExpression.trim().isEmpty) return const [];
    final engine = CalculatorEngine();
    final prepared = engine.prepareExpression(plot.primaryExpression, _angleMode);
    return [
      for (var i = 0; i < count; i++)
        _tableRowAt(engine, prepared, start + step * i),
    ];
  }

  TableRow _tableRowAt(CalculatorEngine engine, Expression prepared, double x) {
    try {
      final y = engine.evaluateExpression(prepared, variables: {'x': x});
      return TableRow(x, y);
    } catch (_) {
      return TableRow(x, null);
    }
  }
}
