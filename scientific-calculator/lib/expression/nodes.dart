part of 'expression.dart';

/// A literal number. Keeps the text the user actually typed so "0.50"
/// round-trips as "0.50" rather than collapsing to 1/2 the moment it's
/// parsed — the exact value is derived on demand, not stored in place of
/// the input.
final class NumberNode extends ExpressionNode {
  const NumberNode(this.literal);

  final String literal;

  @override
  List<ExpressionNode> get children => const [];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) => this;

  @override
  bool operator ==(Object other) => other is NumberNode && other.literal == literal;

  @override
  int get hashCode => literal.hashCode;

  @override
  String toString() => 'Number($literal)';
}

/// Named mathematical constants, kept symbolic so speech can say "pi"
/// and evaluation can use full precision rather than whatever the user
/// would have typed.
enum MathConstant {
  pi('π', 'pi'),
  e('e', 'e'),
  imaginaryUnit('i', 'i'),
  goldenRatio('φ', 'phi');

  const MathConstant(this.symbol, this.spokenName);

  final String symbol;
  final String spokenName;
}

final class ConstantNode extends ExpressionNode {
  const ConstantNode(this.constant);

  final MathConstant constant;

  @override
  List<ExpressionNode> get children => const [];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) => this;

  @override
  bool operator ==(Object other) => other is ConstantNode && other.constant == constant;

  @override
  int get hashCode => constant.hashCode;

  @override
  String toString() => 'Constant(${constant.symbol})';
}

/// A free variable — x in a graphed function, n in a sequence, or a
/// user-defined symbol in a saved formula.
final class VariableNode extends ExpressionNode {
  const VariableNode(this.name);

  final String name;

  @override
  List<ExpressionNode> get children => const [];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) => this;

  @override
  bool operator ==(Object other) => other is VariableNode && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Variable($name)';
}

enum BinaryOperator {
  add('+', 'plus', 1),
  subtract('−', 'minus', 1),
  multiply('×', 'times', 2),
  divide('÷', 'divided by', 2),
  modulo('mod', 'mod', 2),

  /// "plus or minus", as in the quadratic formula. Binds like addition
  /// because that is what it stands in for — two additions at once.
  ///
  /// This one does not evaluate to a number, because it is not one
  /// number: it names both branches. Asking for its value is a question
  /// with two answers, and the evaluator says so rather than quietly
  /// picking the positive one.
  plusMinus('±', 'plus or minus', 1);

  const BinaryOperator(this.symbol, this.spokenName, this.precedence);

  final String symbol;
  final String spokenName;
  final int precedence;
}

final class BinaryNode extends ExpressionNode {
  const BinaryNode(this.operator, this.left, this.right, {this.isImplicit = false});

  final BinaryOperator operator;
  final ExpressionNode left;
  final ExpressionNode right;

  /// True for implied multiplication like `2x` or `3(4)`, which renders
  /// without a visible × but still evaluates as one.
  final bool isImplicit;

  @override
  List<ExpressionNode> get children => [left, right];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) =>
      BinaryNode(operator, newChildren[0], newChildren[1], isImplicit: isImplicit);

  @override
  bool operator ==(Object other) =>
      other is BinaryNode &&
      other.operator == operator &&
      other.left == left &&
      other.right == right;

  @override
  int get hashCode => Object.hash(operator, left, right);

  @override
  String toString() => 'Binary(${operator.symbol}, $left, $right)';
}

/// How two sides of a statement are being compared.
///
/// A relation is not an expression: `V = I × R` does not have a value,
/// it makes a claim. Keeping it a separate node is what lets the formula
/// library store Ohm's law as the thing it is, lets the solver see which
/// side is which, and lets the evaluator refuse an equation with an
/// explanation rather than returning a number nobody asked for.
enum RelationOperator {
  equals('=', 'equals'),
  notEquals('≠', 'is not equal to'),
  lessThan('<', 'is less than'),
  lessOrEqual('≤', 'is less than or equal to'),
  greaterThan('>', 'is greater than'),
  greaterOrEqual('≥', 'is greater than or equal to'),
  approximately('≈', 'is approximately');

  const RelationOperator(this.symbol, this.spokenName);

  final String symbol;
  final String spokenName;
}

/// A statement about two expressions: an equation, or an inequality.
final class RelationNode extends ExpressionNode {
  const RelationNode(this.operator, this.left, this.right);

  final RelationOperator operator;
  final ExpressionNode left;
  final ExpressionNode right;

  @override
  List<ExpressionNode> get children => [left, right];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) =>
      RelationNode(operator, newChildren[0], newChildren[1]);

  @override
  bool operator ==(Object other) =>
      other is RelationNode &&
      other.operator == operator &&
      other.left == left &&
      other.right == right;

  @override
  int get hashCode => Object.hash(operator, left, right);

  @override
  String toString() => 'Relation(${operator.symbol}, $left, $right)';
}

enum UnaryOperator {
  negate('−', 'negative'),
  factorial('!', 'factorial'),
  percent('%', 'percent');

  const UnaryOperator(this.symbol, this.spokenName);

  final String symbol;
  final String spokenName;
}

final class UnaryNode extends ExpressionNode {
  const UnaryNode(this.operator, this.operand);

  final UnaryOperator operator;
  final ExpressionNode operand;

  /// Factorial and percent follow their operand; negation precedes it.
  bool get isPostfix =>
      operator == UnaryOperator.factorial || operator == UnaryOperator.percent;

  @override
  List<ExpressionNode> get children => [operand];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) =>
      UnaryNode(operator, newChildren[0]);

  @override
  bool operator ==(Object other) =>
      other is UnaryNode && other.operator == operator && other.operand == operand;

  @override
  int get hashCode => Object.hash(operator, operand);

  @override
  String toString() => 'Unary(${operator.symbol}, $operand)';
}

/// A named function call: sin(x), log(10, 100), gcd(a, b).
final class FunctionNode extends ExpressionNode {
  const FunctionNode(this.name, this.arguments);

  final String name;
  final List<ExpressionNode> arguments;

  @override
  List<ExpressionNode> get children => arguments;

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) =>
      FunctionNode(name, newChildren);

  @override
  bool operator ==(Object other) =>
      other is FunctionNode &&
      other.name == name &&
      other.arguments.length == arguments.length &&
      List.generate(arguments.length, (i) => arguments[i] == other.arguments[i])
          .every((equal) => equal);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(arguments));

  @override
  String toString() => 'Function($name, $arguments)';
}

/// A stacked fraction. Deliberately distinct from division: the editor
/// navigates into numerator and denominator as separate slots, the
/// renderer draws a bar, and the screen reader announces "fraction …
/// over … end fraction". Division by `÷` stays a [BinaryNode].
final class FractionNode extends ExpressionNode {
  const FractionNode(this.numerator, this.denominator);

  final ExpressionNode numerator;
  final ExpressionNode denominator;

  @override
  List<ExpressionNode> get children => [numerator, denominator];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) =>
      FractionNode(newChildren[0], newChildren[1]);

  @override
  bool operator ==(Object other) =>
      other is FractionNode &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => 'Fraction($numerator, $denominator)';
}

/// Base raised to an exponent, with the exponent as its own editable
/// slot so typing into a superscript works structurally.
final class PowerNode extends ExpressionNode {
  const PowerNode(this.base, this.exponent);

  final ExpressionNode base;
  final ExpressionNode exponent;

  @override
  List<ExpressionNode> get children => [base, exponent];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) =>
      PowerNode(newChildren[0], newChildren[1]);

  @override
  bool operator ==(Object other) =>
      other is PowerNode && other.base == base && other.exponent == exponent;

  @override
  int get hashCode => Object.hash(base, exponent);

  @override
  String toString() => 'Power($base, $exponent)';
}

/// A radical. A null [index] means square root; otherwise it's an nth
/// root with its own editable index slot.
final class RootNode extends ExpressionNode {
  const RootNode(this.radicand, {this.index});

  final ExpressionNode radicand;
  final ExpressionNode? index;

  bool get isSquareRoot => index == null;

  /// Index first, because that is where it is written and where it is
  /// read: ⁿ√x is spoken "nth root of x". Children are in reading order
  /// by contract, and cursor navigation follows them, so listing the
  /// radicand first would have the caret visit the two slots in the
  /// opposite order to the one they appear in.
  @override
  List<ExpressionNode> get children => index == null ? [radicand] : [index!, radicand];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) => index == null
      ? RootNode(newChildren[0])
      : RootNode(newChildren[1], index: newChildren[0]);

  @override
  bool operator ==(Object other) =>
      other is RootNode && other.radicand == radicand && other.index == index;

  @override
  int get hashCode => Object.hash(radicand, index);

  @override
  String toString() => 'Root($radicand, index: $index)';
}

/// |x| — its own node because it renders as bars and reads as "absolute
/// value of x", which a generic function call wouldn't convey.
final class AbsoluteNode extends ExpressionNode {
  const AbsoluteNode(this.operand);

  final ExpressionNode operand;

  @override
  List<ExpressionNode> get children => [operand];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) =>
      AbsoluteNode(newChildren[0]);

  @override
  bool operator ==(Object other) => other is AbsoluteNode && other.operand == operand;

  @override
  int get hashCode => operand.hashCode;

  @override
  String toString() => 'Absolute($operand)';
}

/// Parentheses the user actually typed. Kept in the tree rather than
/// dissolved into precedence, so their expression renders back the way
/// they wrote it and the cursor can sit inside them.
final class GroupNode extends ExpressionNode {
  const GroupNode(this.inner);

  final ExpressionNode inner;

  @override
  List<ExpressionNode> get children => [inner];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) =>
      GroupNode(newChildren[0]);

  @override
  bool operator ==(Object other) => other is GroupNode && other.inner == inner;

  @override
  int get hashCode => inner.hashCode;

  @override
  String toString() => 'Group($inner)';
}

/// A matrix of expressions, stored row-major. Children are flattened in
/// reading order so cursor navigation and screen-reader traversal work
/// without matrices needing special-case handling everywhere.
final class MatrixNode extends ExpressionNode {
  const MatrixNode(this.rows);

  final List<List<ExpressionNode>> rows;

  int get rowCount => rows.length;
  int get columnCount => rows.isEmpty ? 0 : rows.first.length;

  @override
  List<ExpressionNode> get children => [for (final row in rows) ...row];

  @override
  ExpressionNode withChildren(List<ExpressionNode> newChildren) {
    final rebuilt = <List<ExpressionNode>>[];
    var offset = 0;
    for (final row in rows) {
      rebuilt.add(newChildren.sublist(offset, offset + row.length));
      offset += row.length;
    }
    return MatrixNode(rebuilt);
  }

  @override
  String toString() => 'Matrix(${rowCount}x$columnCount)';
}
