import 'package:flutter/material.dart';

/// The top-level calculator a user picks on the chooser screen.
///
/// Set is based on what actually ships in the best tools people already
/// use, then written in plain language:
/// - Samsung/Google: everyday arithmetic + Convert (units and tip)
/// - Casio ClassWiz: Calculate, Statistics, Matrix, Equation
/// - TI-84: Graph, Finance, Matrix, Stat, Solver
/// - GeoGebra: Geometry constructions and 3D surfaces
enum CalculatorMode {
  calculator(
    label: 'Calculator',
    description: 'Add, subtract, multiply, and divide. Also sin, logs, and powers. History keeps your last sums.',
    icon: Icons.calculate_outlined,
  ),
  convert(
    label: 'Convert',
    description: 'Change units: money, length, cooking, temperature, volume, mass, data, speed, time, and tip.',
    icon: Icons.swap_horiz,
  ),
  percentage(
    label: 'Percentage',
    description: 'What is 15% of 80? Or: 20 is what percent of 50?',
    icon: Icons.percent,
  ),
  fractions(
    label: 'Fractions',
    description: 'Add, subtract, multiply, or divide two fractions. The answer is simplified.',
    icon: Icons.pie_chart_outline,
  ),
  graph(
    label: 'Graph',
    description: 'Draw a picture of a formula, like y = x².',
    icon: Icons.show_chart,
  ),
  surface3d(
    label: '3D',
    description: 'Spin a 3D picture of z = f(x, y).',
    icon: Icons.view_in_ar_outlined,
  ),
  geometry(
    label: 'Geometry',
    description: 'Add points by tapping or typing x and y. Then draw lines, circles, and measure.',
    icon: Icons.change_history,
  ),
  matrix(
    label: 'Matrix',
    description: 'Work with grids of numbers: add, multiply, determinant, inverse.',
    icon: Icons.grid_on,
  ),
  statistics(
    label: 'Statistics',
    description: 'Average, spread, best-fit line, and chance (normal, binomial).',
    icon: Icons.bar_chart,
  ),
  finance(
    label: 'Finance',
    description: 'Interest, loans, savings, and monthly payments — in plain words.',
    icon: Icons.attach_money,
  ),
  solve(
    label: 'Solve',
    description: 'Find x in an equation. Also polynomial roots and derivatives.',
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

  /// Everyday tools stay ungrouped at the top of the chooser.
  bool get isEveryday => switch (this) {
        calculator || convert || percentage || fractions => true,
        _ => false,
      };

  /// Section under which this mode is listed. Null = everyday, on top.
  String? get chooserGroup => switch (this) {
        graph || surface3d || geometry => 'graphs',
        matrix || statistics || solve => 'school',
        finance => 'money',
        _ => null,
      };

  static const chooserGroupOrder = ['graphs', 'school', 'money'];
}
