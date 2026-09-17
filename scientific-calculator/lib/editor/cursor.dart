import '../expression/expression.dart';

/// Where the caret sits: a path to a leaf, and how far into it.
///
/// A position rather than a node, because a caret lives *between* things.
/// In the number 25 there are three places to stand — before the 2,
/// between the digits, after the 5 — and typing produces a different
/// result at each.
///
/// The path addresses a leaf only. Structural nodes are never the
/// cursor's home; the cursor is always inside one of their slots, which
/// is what makes "in the numerator" a thing the editor can say out loud.
class EditorCursor {
  const EditorCursor(this.path, this.offset);

  const EditorCursor.atRoot() : path = const [], offset = 0;

  final ExpressionPath path;

  /// Characters into the leaf's text, or 0/1 for a leaf with no text of
  /// its own — before it or after it.
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is EditorCursor &&
      other.offset == offset &&
      other.path.length == path.length &&
      _samePath(other.path, path);

  static bool _samePath(ExpressionPath a, ExpressionPath b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(path), offset);

  @override
  String toString() => '${path.join('.')}@$offset';
}

/// One place the caret can stand, in reading order.
class CursorStop {
  const CursorStop({required this.path, required this.offset, required this.node});

  final ExpressionPath path;
  final int offset;
  final ExpressionNode node;

  EditorCursor get cursor => EditorCursor(path, offset);
}

/// Turns the tree into the ordered list of places a caret can be.
///
/// Left and right arrows step through this list, which is why they move
/// into a fraction's numerator and back out again without any of the
/// navigation code knowing what a fraction is. The order is the tree's
/// reading order, so it matches what a screen reader says and what the
/// visual renderer draws.
class CursorStops {
  const CursorStops._(this.stops);

  factory CursorStops.of(ExpressionNode root) {
    final stops = <CursorStop>[];
    _collect(root, const [], stops);
    return CursorStops._(stops);
  }

  final List<CursorStop> stops;

  int get length => stops.length;

  CursorStop operator [](int index) => stops[index];

  /// How many places the caret can stand inside one leaf.
  ///
  /// A number has one more than it has characters — a caret can sit at
  /// either end as well as between digits. A placeholder has exactly
  /// one: it is a single slot with no inside to be partway through.
  static int stopsIn(ExpressionNode leaf) => switch (leaf) {
        NumberNode(:final literal) => literal.length + 1,
        VariableNode(:final name) => name.length + 1,
        PlaceholderNode() => 1,
        // A symbol is atomic: you stand before it or after it, never in
        // the middle of π.
        _ => 2,
      };

  static bool isLeaf(ExpressionNode node) =>
      node is NumberNode ||
      node is VariableNode ||
      node is ConstantNode ||
      node is PlaceholderNode;

  /// A node drawn as a shape of its own — a fraction, a root, a function
  /// call — as opposed to the operators that merely join things.
  ///
  /// The distinction matters for navigation: a structure has an outside
  /// as well as an inside, so the caret needs somewhere to stand just
  /// before and just after it. Without those two stops there would be no
  /// way to type anything *after* a fraction, because every position
  /// would be inside one of its slots.
  static bool isStructural(ExpressionNode node) =>
      !isLeaf(node) && node is! BinaryNode && node is! UnaryNode;

  static void _collect(
    ExpressionNode node,
    ExpressionPath path,
    List<CursorStop> out,
  ) {
    if (isLeaf(node)) {
      for (var offset = 0; offset < stopsIn(node); offset++) {
        out.add(CursorStop(path: path, offset: offset, node: node));
      }
      return;
    }

    final structural = isStructural(node);
    if (structural) {
      out.add(CursorStop(path: path, offset: 0, node: node));
    }
    final children = node.children;
    for (var i = 0; i < children.length; i++) {
      _collect(children[i], [...path, i], out);
    }
    if (structural) {
      out.add(CursorStop(path: path, offset: 1, node: node));
    }
  }

  /// The index of [cursor] in the stop list, or the nearest stop before
  /// it when the cursor does not land exactly on one — which happens
  /// after an edit reshapes the tree under it.
  int indexOf(EditorCursor cursor) {
    for (var i = 0; i < stops.length; i++) {
      if (stops[i].cursor == cursor) return i;
    }
    // Fall back to the first stop at or after the cursor's path, so a
    // cursor left dangling by an edit still lands somewhere sensible
    // rather than jumping to the start of the expression.
    for (var i = 0; i < stops.length; i++) {
      if (_pathAtOrAfter(stops[i].path, cursor.path)) return i;
    }
    return stops.isEmpty ? 0 : stops.length - 1;
  }

  static bool _pathAtOrAfter(ExpressionPath candidate, ExpressionPath target) {
    for (var i = 0; i < candidate.length && i < target.length; i++) {
      if (candidate[i] > target[i]) return true;
      if (candidate[i] < target[i]) return false;
    }
    return candidate.length >= target.length;
  }
}
