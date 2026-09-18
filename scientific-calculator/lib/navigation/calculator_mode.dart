import 'package:flutter/material.dart';

/// The tools this app contains, and how each one introduces itself.
///
/// These used to be eight entries in a scrolling tab bar, which is two
/// problems at once. The Human Interface Guidelines cap a tab bar at five
/// and treat anything beyond that as a sign the information architecture
/// needs rethinking rather than a wider bar — and in practice the eighth
/// label was cut off mid-word on a phone, with nothing to suggest that
/// scrolling sideways would reveal it.
///
/// A named button carrying a sentence of its own is plainer than a row of
/// icons: it says what the tool is for before you open it, it cannot clip,
/// and it grows with the user's text size instead of being squeezed.
enum CalculatorMode {
  calculator(
    title: 'Calculator',
    summary: 'Arithmetic, trigonometry, logarithms and powers.',
    icon: Icons.calculate_outlined,
  ),
  graph(
    title: 'Graph',
    summary: 'Plot functions and read off their intercepts.',
    icon: Icons.show_chart,
  ),
  surface3d(
    title: '3D surfaces',
    summary: 'Plot a surface in three dimensions and turn it around.',
    icon: Icons.view_in_ar_outlined,
  ),
  geometry(
    title: 'Geometry',
    summary: 'Construct points, lines and shapes, and measure them.',
    icon: Icons.change_history,
  ),
  matrix(
    title: 'Matrices',
    summary: 'Multiply, invert and reduce matrices.',
    icon: Icons.grid_on,
  ),
  statistics(
    title: 'Statistics',
    summary: 'Summarise a data set and fit a line to it.',
    icon: Icons.bar_chart,
  ),
  finance(
    title: 'Finance',
    summary: 'Interest, payments and the time value of money.',
    icon: Icons.attach_money,
  ),
  solve(
    title: 'Solve',
    summary: 'Find the roots of an equation or a polynomial.',
    icon: Icons.functions,
  ),
  convert(
    title: 'Convert',
    summary: 'Units, cooking measures, data sizes and currency.',
    icon: Icons.swap_horiz,
  ),
  input(
    title: 'Speak, scan or braille',
    summary: 'Say it, photograph it off the page, or type it in Nemeth.',
    icon: Icons.mic_none_outlined,
  );

  const CalculatorMode({
    required this.title,
    required this.summary,
    required this.icon,
  });

  /// The name on the button, and the title of the screen it opens — which
  /// is also what the back button says on the way out, as HIG requires.
  final String title;

  /// One sentence on what the tool is for. Shown under the title and read
  /// out as the button's accessibility hint, so the choice is as clear by
  /// ear as by eye.
  final String summary;

  final IconData icon;

  /// The most-used tool, given its own place at the top of the list.
  static const CalculatorMode primary = CalculatorMode.calculator;

  /// Everything else, in the order it is offered.
  static List<CalculatorMode> get secondary =>
      values.where((mode) => mode != primary).toList(growable: false);
}
