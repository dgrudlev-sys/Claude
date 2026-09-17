import '../expression.dart';

/// Renders an expression tree back to linear text.
///
/// Used for the history list, clipboard copy, saved formulas, and
/// round-tripping through the parser. Parentheses are emitted only where
/// precedence actually requires them, so `(1+2)*3` keeps its grouping
/// while `1+(2*3)` doesn't gain any it didn't need.
class TextRenderer {
  const TextRenderer({this.useUnicodeOperators = true});

  /// When true, uses × ÷ − for display. When false, uses * / - so the
  /// output can be fed straight back into the parser or another tool.
  final bool useUnicodeOperators;

  String render(ExpressionNode node) => _render(node, 0);

  String _multiplySymbol() => useUnicodeOperators ? '×' : '*';
  String _divideSymbol() => useUnicodeOperators ? '÷' : '/';
  String _minusSymbol() => useUnicodeOperators ? '−' : '-';

  String _operatorText(BinaryOperator op) => switch (op) {
        BinaryOperator.add => '+',
        BinaryOperator.subtract => _minusSymbol(),
        BinaryOperator.multiply => _multiplySymbol(),
        BinaryOperator.divide => _divideSymbol(),
        BinaryOperator.modulo => ' mod ',
      };

  String _render(ExpressionNode node, int parentPrecedence) {
    switch (node) {
      case NumberNode(:final literal):
        return literal;

      case ConstantNode(:final constant):
        return constant.symbol;

      case VariableNode(:final name):
        return name;

      case PlaceholderNode():
        return '▢';

      case GroupNode(:final inner):
        return '(${_render(inner, 0)})';

      case BinaryNode(:final operator, :final left, :final right, :final isImplicit):
        final precedence = operator.precedence;
        final text = isImplicit && operator == BinaryOperator.multiply
            ? '${_render(left, precedence)}${_render(right, precedence + 1)}'
            : '${_render(left, precedence)}'
                '${operator == BinaryOperator.modulo ? '' : ' '}'
                '${_operatorText(operator)}'
                '${operator == BinaryOperator.modulo ? '' : ' '}'
                '${_render(right, precedence + 1)}';
        return precedence < parentPrecedence ? '($text)' : text;

      case UnaryNode(:final operator, :final operand):
        return switch (operator) {
          UnaryOperator.negate => '${_minusSymbol()}${_render(operand, 3)}',
          UnaryOperator.factorial => '${_render(operand, 4)}!',
          UnaryOperator.percent => '${_render(operand, 4)}%',
        };

      case FunctionNode(:final name, :final arguments):
        final args = arguments.map((a) => _render(a, 0)).join(', ');
        return '$name($args)';

      case FractionNode(:final numerator, :final denominator):
        return '(${_render(numerator, 0)})/(${_render(denominator, 0)})';

      case PowerNode(:final base, :final exponent):
        return '${_render(base, 5)}^(${_render(exponent, 0)})';

      case RootNode(:final radicand, :final index):
        return index == null
            ? '√(${_render(radicand, 0)})'
            : 'root(${_render(index, 0)}, ${_render(radicand, 0)})';

      case AbsoluteNode(:final operand):
        return '|${_render(operand, 0)}|';

      case MatrixNode(:final rows):
        final body = rows
            .map((row) => row.map((cell) => _render(cell, 0)).join(', '))
            .join('; ');
        return '[$body]';
    }
  }
}
