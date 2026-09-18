part of 'expression.dart';

/// An empty, waiting slot — what a freshly inserted fraction's numerator
/// is before the user types into it.
///
/// This is what makes structural editing possible at all. Pressing the
/// fraction key inserts `FractionNode(Placeholder, Placeholder)` and puts
/// the cursor in the first one; the UI draws a dotted box, the screen
/// reader announces "empty numerator", and evaluation refuses to run
/// until the slots are filled rather than guessing at a value.
final class PlaceholderNode extends ExpressionNode {
  const PlaceholderNode({this.role});

  /// What this slot is for, so a screen reader can say "empty exponent"
  /// instead of just "empty".
  final String? role;

  @override
  List<ExpressionNode> get children => const [];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) => this;

  @override
  bool operator ==(Object other) => other is PlaceholderNode && other.role == role;

  @override
  int get hashCode => role.hashCode;

  @override
  String toString() => 'Placeholder(${role ?? 'empty'})';
}
