import 'package:flutter/material.dart';

import 'graph_mode.dart';

/// A palette distinct from the keypad's amber/charcoal identity — plots
/// need several mutually distinguishable colors, not one accent.
const plotColors = <Color>[
  Color(0xFFE0526B),
  Color(0xFF4FA6E0),
  Color(0xFF5FBF6E),
  Color(0xFFD9A441),
  Color(0xFFA07AE0),
  Color(0xFF3FBFB0),
];

/// One entry in the graph's function list. What [primaryExpression] (and
/// [secondaryExpression]) mean depends on [mode]:
/// - function:    primary = f(x)
/// - parametric:  primary = x(t), secondary = y(t)
/// - polar:       primary = r(theta)
/// - sequence:    primary = u(n)
class PlotDefinition {
  PlotDefinition({
    required this.id,
    required this.mode,
    required this.color,
    this.primaryExpression = '',
    this.secondaryExpression = '',
    this.visible = true,
    this.error,
  });

  final String id;
  final GraphMode mode;
  final Color color;
  final String primaryExpression;
  final String secondaryExpression;
  final bool visible;
  final String? error;

  bool get isEmpty => primaryExpression.trim().isEmpty &&
      (mode != GraphMode.parametric || secondaryExpression.trim().isEmpty);

  PlotDefinition copyWith({
    String? primaryExpression,
    String? secondaryExpression,
    bool? visible,
    Object? error = _unset,
  }) {
    return PlotDefinition(
      id: id,
      mode: mode,
      color: color,
      primaryExpression: primaryExpression ?? this.primaryExpression,
      secondaryExpression: secondaryExpression ?? this.secondaryExpression,
      visible: visible ?? this.visible,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

const _unset = Object();
