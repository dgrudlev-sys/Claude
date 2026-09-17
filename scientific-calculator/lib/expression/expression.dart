/// The Expression Model: the one structure every input method produces
/// and every output method renders from.
///
///   touch / keyboard / voice / camera  ──→  ExpressionNode tree
///   ExpressionNode tree  ──→  visual layout, speech, braille, cursor
///                             navigation, evaluation, step-by-step
///
/// Two properties make that work:
///
/// **Nodes are immutable.** Editing returns a new tree rather than
/// mutating in place, so undo/redo is just keeping old roots, and no two
/// parts of the UI can disagree about what the expression currently is.
///
/// **Structure is preserved, not flattened to text.** A stacked fraction
/// is a [FractionNode], not a division operator that happens to be drawn
/// differently — because the editor, the screen reader, and the visual
/// renderer each need to know it's a fraction. This is the difference
/// between an expression the user can navigate and a string they can
/// only retype.
library;

part 'nodes.dart';
part 'placeholder.dart';

/// Where a cursor or selection sits in the tree: the child indices to
/// follow from the root. A path rather than a node id, so it stays
/// meaningful as the tree is rebuilt on every edit.
typedef ExpressionPath = List<int>;

sealed class ExpressionNode {
  const ExpressionNode();

  /// Child nodes in reading order — the order a screen reader visits
  /// them and the order cursor navigation steps through them.
  List<ExpressionNode> get children;

  /// Rebuilds this node with a new set of children, same order as
  /// [children]. The editor uses this to replace a subtree without
  /// every node type needing bespoke edit logic.
  ExpressionNode withChildren(List<ExpressionNode> newChildren);

  /// True when this node, or anything inside it, is still an unfilled
  /// slot — an expression with placeholders isn't ready to evaluate.
  bool get hasPlaceholder =>
      this is PlaceholderNode || children.any((c) => c.hasPlaceholder);

  /// Depth-first walk in reading order, including this node.
  Iterable<ExpressionNode> walk() sync* {
    yield this;
    for (final child in children) {
      yield* child.walk();
    }
  }

  /// The node at [path], or null when the path doesn't lead anywhere.
  ExpressionNode? nodeAt(ExpressionPath path) {
    ExpressionNode current = this;
    for (final index in path) {
      final kids = current.children;
      if (index < 0 || index >= kids.length) return null;
      current = kids[index];
    }
    return current;
  }

  /// Returns a copy of this tree with the node at [path] replaced by
  /// [replacement]. The immutable equivalent of an in-place edit.
  ExpressionNode replaceAt(ExpressionPath path, ExpressionNode replacement) {
    if (path.isEmpty) return replacement;
    final index = path.first;
    final kids = List<ExpressionNode>.from(children);
    if (index < 0 || index >= kids.length) return this;
    kids[index] = kids[index].replaceAt(path.sublist(1), replacement);
    return withChildren(kids);
  }
}
