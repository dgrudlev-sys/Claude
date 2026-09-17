import '../expression.dart';

/// Renders an expression tree as speech for VoiceOver and TalkBack.
///
/// Follows the conventions screen-reader users already expect from
/// MathSpeak and ClearSpeak: nested structures are explicitly opened and
/// closed ("fraction … over … end fraction") so a listener can tell
/// where a fraction stops without seeing it, and common forms get their
/// natural names ("x squared", not "x to the power of 2").
///
/// The "end" markers are what make long expressions followable by ear.
/// They're suppressed for short, unambiguous contents, because
/// "fraction 1 over 2 end fraction" is tiring when "1 half" will do.
class SpeechRenderer {
  const SpeechRenderer({this.verbosity = SpeechVerbosity.natural});

  final SpeechVerbosity verbosity;

  String render(ExpressionNode node) =>
      _render(node).replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Whether a node is simple enough to skip its closing marker — a lone
  /// number or symbol can't be confused with anything that follows.
  bool _isAtomic(ExpressionNode node) =>
      node is NumberNode || node is ConstantNode || node is VariableNode;

  String _render(ExpressionNode node) {
    switch (node) {
      case NumberNode(:final literal):
        return _spokenNumber(literal);

      case ConstantNode(:final constant):
        return constant.spokenName;

      case VariableNode(:final name):
        return name;

      case PlaceholderNode(:final role):
        return role == null ? 'empty slot' : 'empty $role';

      case GroupNode(:final inner):
        return 'open paren ${_render(inner)} close paren';

      case BinaryNode(:final operator, :final left, :final right, :final isImplicit):
        // Implied multiplication is spoken as juxtaposition, the way it's
        // read aloud: "2 x", not "2 times x".
        if (isImplicit && operator == BinaryOperator.multiply) {
          return '${_render(left)} ${_render(right)}';
        }
        return '${_render(left)} ${operator.spokenName} ${_render(right)}';

      case UnaryNode(:final operator, :final operand):
        return switch (operator) {
          UnaryOperator.negate => 'negative ${_render(operand)}',
          UnaryOperator.factorial => '${_render(operand)} factorial',
          UnaryOperator.percent => '${_render(operand)} percent',
        };

      case FunctionNode(:final name, :final arguments):
        final spokenName = _spokenFunctionName(name);
        if (arguments.length == 1) {
          final argument = arguments.single;
          return _isAtomic(argument)
              ? '$spokenName of ${_render(argument)}'
              : '$spokenName of ${_render(argument)}, end $spokenName';
        }
        final args = arguments.map(_render).join(', ');
        return '$spokenName of $args';

      case FractionNode(:final numerator, :final denominator):
        final simple = _simpleFractionName(numerator, denominator);
        if (simple != null) return simple;
        final needsEnd = !_isAtomic(numerator) || !_isAtomic(denominator);
        final body = 'fraction ${_render(numerator)} over ${_render(denominator)}';
        return needsEnd ? '$body, end fraction' : body;

      case PowerNode(:final base, :final exponent):
        if (exponent case NumberNode(literal: '2')) {
          return '${_render(base)} squared';
        }
        if (exponent case NumberNode(literal: '3')) {
          return '${_render(base)} cubed';
        }
        final needsEnd = !_isAtomic(exponent);
        final body = '${_render(base)} to the power of ${_render(exponent)}';
        return needsEnd ? '$body, end power' : body;

      case RootNode(:final radicand, :final index):
        if (index == null) {
          return _isAtomic(radicand)
              ? 'square root of ${_render(radicand)}'
              : 'square root of ${_render(radicand)}, end root';
        }
        if (index case NumberNode(literal: '3')) {
          return 'cube root of ${_render(radicand)}, end root';
        }
        return '${_render(index)}th root of ${_render(radicand)}, end root';

      case AbsoluteNode(:final operand):
        return 'absolute value of ${_render(operand)}, end absolute value';

      case MatrixNode(:final rows):
        final buffer = StringBuffer(
          '${rows.length} by ${rows.isEmpty ? 0 : rows.first.length} matrix, ',
        );
        for (var r = 0; r < rows.length; r++) {
          buffer.write('row ${r + 1}: ');
          buffer.write(rows[r].map(_render).join(', '));
          buffer.write(r == rows.length - 1 ? ', end matrix' : '; ');
        }
        return buffer.toString();
    }
  }

  /// Reads a decimal digit by digit after the point — "3 point 1 4",
  /// not "three point fourteen", which is how the digits are actually
  /// meant to be heard.
  String _spokenNumber(String literal) {
    if (verbosity == SpeechVerbosity.terse) return literal;
    final dot = literal.indexOf('.');
    if (dot == -1) return literal;
    final whole = literal.substring(0, dot);
    final decimals = literal.substring(dot + 1).split('').join(' ');
    return '${whole.isEmpty ? '0' : whole} point $decimals';
  }

  /// Common fractions have names people actually use out loud.
  String? _simpleFractionName(ExpressionNode numerator, ExpressionNode denominator) {
    if (verbosity == SpeechVerbosity.terse) return null;
    if (numerator is! NumberNode || denominator is! NumberNode) return null;
    const names = {'2': 'half', '3': 'third', '4': 'quarter'};
    final name = names[denominator.literal];
    if (name == null) return null;
    if (numerator.literal == '1') return 'one $name';
    return '${numerator.literal} ${name}s';
  }

  String _spokenFunctionName(String name) => switch (name) {
        'sin' => 'sine',
        'cos' => 'cosine',
        'tan' => 'tangent',
        'asin' || 'arcsin' => 'inverse sine',
        'acos' || 'arccos' => 'inverse cosine',
        'atan' || 'arctan' => 'inverse tangent',
        'sinh' => 'hyperbolic sine',
        'cosh' => 'hyperbolic cosine',
        'tanh' => 'hyperbolic tangent',
        'ln' => 'natural log',
        'log' => 'log',
        'exp' => 'e to the power of',
        'abs' => 'absolute value',
        _ => name,
      };
}

enum SpeechVerbosity {
  /// Reads structure aloud with explicit end markers and natural names.
  natural,

  /// Minimal narration, for users who find the full form slow once
  /// they're familiar with it.
  terse,
}
