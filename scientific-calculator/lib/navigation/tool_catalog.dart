/// What the Formulas & Tools browser contains, as data.
///
/// The app had eight tools sitting flat on one screen, each with a
/// sentence under it. Eight is already too many to scan and the list was
/// going to keep growing — a converter, a formula library, a programmer's
/// mode. Flat lists do not survive that; trees do.
///
/// So this is a tree. A [ToolGroup] is a heading you can open, a
/// [ToolEntry] is a leaf that opens a screen, and the browser renders
/// both with the same row. Nothing here knows what a widget is, which is
/// what lets the whole structure be tested as data and lets one screen
/// render every level of it.
library;

import 'package:flutter/material.dart';

import 'calculator_mode.dart';

/// One item in the browser: either a group of more items, or a tool.
sealed class ToolNode {
  const ToolNode({
    required this.title,
    required this.summary,
    required this.icon,
  });

  /// What the row says.
  final String title;

  /// One line under it. Also the row's screen-reader hint, so the choice
  /// is as clear by ear as by eye.
  final String summary;

  final IconData icon;

  /// Every word that should match this node in a search — its own title
  /// and summary, plus those of everything beneath it, so searching for
  /// "gallon" finds the Unit Converter that contains it.
  String get searchText;
}

/// A heading that opens onto more rows.
final class ToolGroup extends ToolNode {
  const ToolGroup({
    required super.title,
    required super.summary,
    required super.icon,
    required this.children,
  });

  final List<ToolNode> children;

  @override
  String get searchText => [
        title,
        summary,
        for (final child in children) child.searchText,
      ].join(' ').toLowerCase();
}

/// A leaf that opens one of the app's screens.
final class ToolEntry extends ToolNode {
  const ToolEntry({
    required super.title,
    required super.summary,
    required super.icon,
    required this.mode,
    this.keywords = const [],
  });

  /// The screen this row opens.
  final CalculatorMode mode;

  /// Words people would search for that the title does not contain —
  /// "derivative" for Graph, "gallon" for the converter.
  final List<String> keywords;

  @override
  String get searchText =>
      [title, summary, ...keywords].join(' ').toLowerCase();
}

/// The browser's contents, top level first.
///
/// Grouped by the kind of question being asked rather than by which
/// engine answers it, because that is how someone looking for help
/// thinks: "I have an equation" comes before "I need the solver".
const toolCatalog = <ToolNode>[
  ToolGroup(
    title: 'Mathematics',
    summary: 'Algebra, calculus, trigonometry…',
    icon: Icons.functions,
    children: [
      ToolEntry(
        title: 'Solve an equation',
        summary: 'Roots of an equation or a polynomial.',
        icon: Icons.balance_outlined,
        mode: CalculatorMode.solve,
        keywords: ['root', 'quadratic', 'polynomial', 'zero', 'x'],
      ),
      ToolEntry(
        title: 'Graphs',
        summary: 'Plot a function and read off its intercepts.',
        icon: Icons.show_chart,
        mode: CalculatorMode.graph,
        keywords: ['plot', 'curve', 'intercept', 'derivative', 'asymptote'],
      ),
      ToolEntry(
        title: 'Surfaces in 3D',
        summary: 'Plot a surface and turn it around.',
        icon: Icons.view_in_ar_outlined,
        mode: CalculatorMode.surface3d,
        keywords: ['three dimensions', 'z', 'contour', 'mesh'],
      ),
      ToolEntry(
        title: 'Matrices',
        summary: 'Multiply, invert and reduce.',
        icon: Icons.grid_on,
        mode: CalculatorMode.matrix,
        keywords: ['determinant', 'inverse', 'rref', 'linear system'],
      ),
      ToolEntry(
        title: 'Geometry',
        summary: 'Construct points, lines and shapes, and measure them.',
        icon: Icons.change_history,
        mode: CalculatorMode.geometry,
        keywords: ['angle', 'triangle', 'circle', 'area', 'perimeter'],
      ),
    ],
  ),
  ToolGroup(
    title: 'Data & statistics',
    summary: 'Summarise a set, fit a line.',
    icon: Icons.bar_chart,
    children: [
      ToolEntry(
        title: 'Statistics',
        summary: 'Mean, median, spread and regression.',
        icon: Icons.insights_outlined,
        mode: CalculatorMode.statistics,
        keywords: [
          'mean',
          'median',
          'standard deviation',
          'variance',
          'regression',
        ],
      ),
    ],
  ),
  ToolEntry(
    title: 'Unit converter',
    summary: 'Length, mass, temperature, data, currency…',
    icon: Icons.swap_horiz_rounded,
    mode: CalculatorMode.convert,
    keywords: [
      'metre',
      'foot',
      'inch',
      'mile',
      'kilogram',
      'pound',
      'litre',
      'gallon',
      'celsius',
      'fahrenheit',
      'cooking',
      'cup',
      'gigabyte',
      'currency',
      'exchange rate',
    ],
  ),
  ToolEntry(
    title: 'Finance',
    summary: 'Interest, payments and the time value of money.',
    icon: Icons.savings_outlined,
    mode: CalculatorMode.finance,
    keywords: ['interest', 'loan', 'mortgage', 'annuity', 'compound', 'apr'],
  ),
  ToolEntry(
    title: 'Speak or scan',
    summary: 'Say it, or photograph it off the page.',
    icon: Icons.mic_none_rounded,
    mode: CalculatorMode.input,
    keywords: ['voice', 'dictate', 'camera', 'ocr', 'braille', 'nemeth'],
  ),
];

/// Every leaf in the tree, flattened — what a search runs over.
List<ToolEntry> get allToolEntries {
  final found = <ToolEntry>[];
  void walk(List<ToolNode> nodes) {
    for (final node in nodes) {
      switch (node) {
        case ToolEntry():
          found.add(node);
        case ToolGroup(:final children):
          walk(children);
      }
    }
  }

  walk(toolCatalog);
  return found;
}

/// The leaves whose text contains [query], for the search field.
///
/// Searching the flattened leaves rather than the tree is deliberate: a
/// result you have to go on to expand is not a result. Typing "gallon"
/// puts you one tap from the converter, not one tap from a heading.
List<ToolEntry> searchTools(String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  return [
    for (final entry in allToolEntries)
      if (entry.searchText.contains(needle)) entry,
  ];
}
