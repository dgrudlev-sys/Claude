import '../../input/language/english_vocabulary.dart';
import '../../input/language/math_vocabulary.dart';
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
  const SpeechRenderer({
    this.verbosity = SpeechVerbosity.natural,
    this.vocabulary = const EnglishMathVocabulary(),
  });

  final SpeechVerbosity verbosity;

  /// The language this renderer speaks. Every word it emits comes from
  /// here, so a new language is a new vocabulary rather than a change to
  /// any of the logic below.
  final MathVocabulary vocabulary;

  SpeechTerms get _t => vocabulary.speech;

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
        return role == null ? _t.emptySlot : _t.emptyNamedSlot(role);

      case GroupNode(:final inner):
        return '${_t.openParen} ${_render(inner)} ${_t.closeParen}';

      case BinaryNode(:final operator, :final left, :final right, :final isImplicit):
        // Implied multiplication is spoken as juxtaposition, the way it's
        // read aloud: "2 x", not "2 times x".
        if (isImplicit && operator == BinaryOperator.multiply) {
          return '${_render(left)} ${_render(right)}';
        }
        return '${_render(left)} ${_operatorWord(operator)} ${_render(right)}';

      case UnaryNode(:final operator, :final operand):
        return switch (operator) {
          UnaryOperator.negate => '${_t.negative} ${_render(operand)}',
          UnaryOperator.factorial => '${_render(operand)} ${_t.factorial}',
          UnaryOperator.percent => '${_render(operand)} ${_t.percent}',
        };

      case FunctionNode(:final name, :final arguments):
        final spokenName = _spokenFunctionName(name);
        if (arguments.length == 1) {
          final argument = arguments.single;
          final body = '$spokenName ${_t.functionOf} ${_render(argument)}';
          return _isAtomic(argument)
              ? body
              : '$body, ${_t.functionEnd(spokenName)}';
        }
        final args = arguments.map(_render).join(', ');
        return '$spokenName ${_t.functionOf} $args';

      case FractionNode(:final numerator, :final denominator):
        final simple = _simpleFractionName(numerator, denominator);
        if (simple != null) return simple;
        final needsEnd = !_isAtomic(numerator) || !_isAtomic(denominator);
        final body = '${_t.fractionOpen} ${_render(numerator)} '
            '${_t.fractionOver} ${_render(denominator)}';
        return needsEnd ? '$body, ${_t.fractionEnd}' : body;

      case PowerNode(:final base, :final exponent):
        if (exponent case NumberNode(literal: '2')) {
          return '${_render(base)} ${_t.squared}';
        }
        if (exponent case NumberNode(literal: '3')) {
          return '${_render(base)} ${_t.cubed}';
        }
        final needsEnd = !_isAtomic(exponent);
        final body = '${_render(base)} ${_t.toThePowerOf} ${_render(exponent)}';
        return needsEnd ? '$body, ${_t.powerEnd}' : body;

      case RootNode(:final radicand, :final index):
        if (index == null) {
          return _isAtomic(radicand)
              ? '${_t.squareRootOf} ${_render(radicand)}'
              : '${_t.squareRootOf} ${_render(radicand)}, ${_t.rootEnd}';
        }
        if (index case NumberNode(literal: '3')) {
          return '${_t.cubeRootOf} ${_render(radicand)}, ${_t.rootEnd}';
        }
        return '${_t.nthRootOf(_render(index))} ${_render(radicand)}, ${_t.rootEnd}';

      case AbsoluteNode(:final operand):
        return '${_t.absoluteValueOf} ${_render(operand)}, ${_t.absoluteEnd}';

      case RelationNode(:final operator, :final left, :final right):
        return '${_render(left)} ${_t.relation(operator.name)} ${_render(right)}';

      case MatrixNode(:final rows):
        final buffer = StringBuffer(
          '${_t.matrixSize('${rows.length}', '${rows.isEmpty ? 0 : rows.first.length}')}, ',
        );
        for (var r = 0; r < rows.length; r++) {
          buffer.write(_t.matrixRow('${r + 1}'));
          buffer.write(rows[r].map(_render).join(', '));
          buffer.write(r == rows.length - 1 ? ', ${_t.matrixEnd}' : '; ');
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
    return '${whole.isEmpty ? '0' : whole} ${_t.decimalPoint} $decimals';
  }

  /// Common fractions have names people actually use out loud.
  String? _simpleFractionName(ExpressionNode numerator, ExpressionNode denominator) {
    if (verbosity == SpeechVerbosity.terse) return null;
    if (numerator is! NumberNode || denominator is! NumberNode) return null;
    return _t.simpleFraction(numerator.literal, denominator.literal);
  }

  String _operatorWord(BinaryOperator operator) => switch (operator) {
        BinaryOperator.add => _t.plus,
        BinaryOperator.subtract => _t.minus,
        BinaryOperator.multiply => _t.times,
        BinaryOperator.divide => _t.dividedBy,
        BinaryOperator.plusMinus => _t.plusOrMinus,
        BinaryOperator.modulo => _t.modulo,
      };

  String _spokenFunctionName(String name) => _t.functionNames[name] ?? name;
}

enum SpeechVerbosity {
  /// Reads structure aloud with explicit end markers and natural names.
  natural,

  /// Minimal narration, for users who find the full form slow once
  /// they're familiar with it.
  terse,
}
