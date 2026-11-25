import 'package:flutter/material.dart';

/// Tools on the chooser. Finance stays on the enum for math and tests,
/// but is not listed on this app's home.
enum CalculatorMode {
  calculator(
    label: 'Calculator',
    description: 'Arithmetic, powers, trig. History keeps recent results.',
    icon: Icons.calculate_outlined,
  ),
  convert(
    label: 'Convert',
    description: 'Units, currency, cooking, tip.',
    icon: Icons.swap_horiz,
  ),
  percentage(
    label: 'Percentage',
    description: 'Part of, reverse percent, percent change.',
    icon: Icons.percent,
  ),
  fractions(
    label: 'Fractions',
    description: 'Add, subtract, multiply, divide; simplified.',
    icon: Icons.pie_chart_outline,
  ),
  graph(
    label: 'Graph',
    description: 'Plot a formula. Table of values.',
    icon: Icons.show_chart,
  ),
  surface3d(
    label: '3D',
    description: 'Plot z = f(x, y).',
    icon: Icons.view_in_ar_outlined,
  ),
  geometry(
    label: 'Geometry',
    description: 'Points, lines, circles, measure.',
    icon: Icons.change_history,
  ),
  matrix(
    label: 'Matrix',
    description: 'Add, multiply, det, inverse.',
    icon: Icons.grid_on,
  ),
  statistics(
    label: 'Statistics',
    description: 'Mean, spread, fit, distributions.',
    icon: Icons.bar_chart,
  ),
  finance(
    label: 'Finance',
    description: 'Interest, loans, savings, and monthly payments.',
    icon: Icons.attach_money,
  ),
  solve(
    label: 'Solve',
    description: 'Find x, polynomial roots, derivative.',
    icon: Icons.functions,
  );

  const CalculatorMode({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;

  /// Finance is kept on the enum for math/tests, but not on this app's home.
  bool get inChooser => this != finance;

  /// Always-visible chooser rows (Calc through Solve).
  bool get isPrimary => switch (this) {
        calculator || convert || percentage || fractions || graph || solve => true,
        _ => false,
      };

  /// Collapsed under More: Statistics, Matrix, Geometry, 3D.
  bool get isMore => switch (this) {
        statistics || matrix || geometry || surface3d => true,
        _ => false,
      };

  static const primaryChooserOrder = [
    calculator,
    convert,
    percentage,
    fractions,
    graph,
    solve,
  ];

  static const moreChooserOrder = [
    statistics,
    matrix,
    geometry,
    surface3d,
  ];
}
