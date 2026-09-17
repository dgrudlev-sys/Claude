import '../expression.dart';

/// A parse failure that knows *where* it happened, so the UI can point at
/// the problem and offer a fix rather than just saying "Syntax error" —
/// the blueprint's "explain errors" and "suggest missing parentheses"
/// both need position and intent to survive to the surface.
class ParseError implements Exception {
  const ParseError(this.message, {required this.position, this.suggestion});

  final String message;

  /// Character offset into the source where the problem was detected.
  final int position;

  /// A concrete, applyable fix when one is obvious ("add 2 closing
  /// parentheses"), or null when we can only report the problem.
  final String? suggestion;

  @override
  String toString() => message;
}

enum TokenType {
  number,
  identifier,
  plus,
  minus,
  times,
  divide,
  caret,
  lparen,
  rparen,
  comma,
  bang,
  percent,
  bar,
  end,
}

class Token {
  const Token(this.type, this.lexeme, this.start);

  final TokenType type;
  final String lexeme;
  final int start;

  @override
  String toString() => '${type.name}("$lexeme"@$start)';
}

/// Function names the parser recognises as calls rather than variables.
/// Anything else followed by a paren is treated as implied multiplication,
/// so `x(2)` means x times 2 while `sin(2)` is a call.
const knownFunctions = {
  'sin', 'cos', 'tan',
  'asin', 'acos', 'atan', 'arcsin', 'arccos', 'arctan',
  'sinh', 'cosh', 'tanh',
  'asinh', 'acosh', 'atanh',
  'ln', 'log', 'exp',
  'sqrt', 'cbrt', 'root',
  'abs', 'sign', 'floor', 'ceil', 'round',
  'min', 'max', 'gcd', 'lcm',
  'nCr', 'nPr',
};

const _constantNames = {
  'pi': MathConstant.pi,
  'π': MathConstant.pi,
  'e': MathConstant.e,
  'i': MathConstant.imaginaryUnit,
  'phi': MathConstant.goldenRatio,
  'φ': MathConstant.goldenRatio,
};

class Tokenizer {
  const Tokenizer();

  List<Token> tokenize(String source) {
    final tokens = <Token>[];
    var i = 0;

    while (i < source.length) {
      final char = source[i];

      if (char.trim().isEmpty) {
        i++;
        continue;
      }

      if (_isDigit(char) || (char == '.' && i + 1 < source.length && _isDigit(source[i + 1]))) {
        final start = i;
        while (i < source.length && (_isDigit(source[i]) || source[i] == '.')) {
          i++;
        }
        // Scientific notation: 1.5e3, 2e-2 — but only when the 'e' is
        // actually followed by digits, so `2e` stays 2 times e.
        if (i < source.length && (source[i] == 'e' || source[i] == 'E')) {
          final lookahead = i + 1 < source.length && (source[i + 1] == '+' || source[i + 1] == '-')
              ? i + 2
              : i + 1;
          if (lookahead < source.length && _isDigit(source[lookahead])) {
            i = lookahead;
            while (i < source.length && _isDigit(source[i])) {
              i++;
            }
          }
        }
        tokens.add(Token(TokenType.number, source.substring(start, i), start));
        continue;
      }

      if (_isIdentifierStart(char)) {
        final start = i;
        while (i < source.length && _isIdentifierPart(source[i])) {
          i++;
        }
        tokens.add(Token(TokenType.identifier, source.substring(start, i), start));
        continue;
      }

      final type = switch (char) {
        '+' => TokenType.plus,
        '-' || '−' => TokenType.minus,
        '*' || '×' || '·' => TokenType.times,
        '/' || '÷' => TokenType.divide,
        '^' => TokenType.caret,
        '(' => TokenType.lparen,
        ')' => TokenType.rparen,
        ',' => TokenType.comma,
        '!' => TokenType.bang,
        '%' => TokenType.percent,
        '|' => TokenType.bar,
        '√' => TokenType.identifier, // handled as the sqrt function below
        _ => null,
      };

      if (type == null) {
        throw ParseError('Unexpected character "$char"', position: i);
      }
      tokens.add(Token(
        type,
        char == '√' ? 'sqrt' : char,
        i,
      ));
      i++;
    }

    tokens.add(Token(TokenType.end, '', source.length));
    return tokens;
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  /// Symbols that live above the ASCII range but are operators, not
  /// letters. Without this, the identifier scanner would swallow `√9` as
  /// a single variable named "√9", since it accepts any code point above
  /// 127 to allow π and φ.
  static const _nonIdentifierSymbols = {'√', '×', '÷', '−', '·'};

  bool _isIdentifierStart(String c) {
    if (_nonIdentifierSymbols.contains(c)) return false;
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || code > 127;
  }

  bool _isIdentifierPart(String c) => _isIdentifierStart(c) || _isDigit(c);
}

/// Turns source text into an [ExpressionNode] tree.
///
/// Precedence, loosest first: `+ −`, then `× ÷`, then prefix `−`, then
/// `^` (right-associative), then postfix `!` and `%`. That ordering makes
/// `-2^2` evaluate as `-(2²) = -4`, matching standard convention rather
/// than the `(-2)² = 4` a naive parser would produce.
class ExpressionParser {
  const ExpressionParser();

  ExpressionNode parse(String source) {
    final tokens = const Tokenizer().tokenize(source);
    final state = _ParserState(tokens, source);
    if (state.peek().type == TokenType.end) {
      throw const ParseError('Nothing to calculate', position: 0);
    }
    final node = _parseBinary(state, 1);
    if (state.peek().type != TokenType.end) {
      final token = state.peek();
      if (token.type == TokenType.rparen) {
        throw ParseError(
          'Unmatched closing parenthesis',
          position: token.start,
          suggestion: 'Remove the extra ")" or add a matching "("',
        );
      }
      throw ParseError('Unexpected "${token.lexeme}"', position: token.start);
    }
    return node;
  }

  ExpressionNode _parseBinary(_ParserState state, int minPrecedence) {
    var left = _parseUnary(state);

    while (true) {
      final token = state.peek();
      final op = switch (token.type) {
        TokenType.plus => BinaryOperator.add,
        TokenType.minus => BinaryOperator.subtract,
        TokenType.times => BinaryOperator.multiply,
        TokenType.divide => BinaryOperator.divide,
        _ => null,
      };

      if (op != null && op.precedence >= minPrecedence) {
        state.advance();
        final right = _parseBinary(state, op.precedence + 1);
        left = BinaryNode(op, left, right);
        continue;
      }

      // Implied multiplication: 2x, 2(3), (1+2)(3+4), 2sin(x).
      if (_startsImplicitProduct(state) && BinaryOperator.multiply.precedence >= minPrecedence) {
        final right = _parseBinary(state, BinaryOperator.multiply.precedence + 1);
        left = BinaryNode(BinaryOperator.multiply, left, right, isImplicit: true);
        continue;
      }

      return left;
    }
  }

  bool _startsImplicitProduct(_ParserState state) {
    final token = state.peek();
    return token.type == TokenType.number ||
        token.type == TokenType.identifier ||
        token.type == TokenType.lparen;
  }

  ExpressionNode _parseUnary(_ParserState state) {
    final token = state.peek();
    if (token.type == TokenType.minus) {
      state.advance();
      return UnaryNode(UnaryOperator.negate, _parseUnary(state));
    }
    if (token.type == TokenType.plus) {
      state.advance();
      return _parseUnary(state);
    }
    return _parsePower(state);
  }

  ExpressionNode _parsePower(_ParserState state) {
    final base = _parsePostfix(state);
    if (state.peek().type == TokenType.caret) {
      state.advance();
      // Right-associative, and the exponent may itself be negated:
      // 2^-1 and 2^3^2 both parse the way they're written.
      final exponent = _parseUnary(state);
      return PowerNode(base, exponent);
    }
    return base;
  }

  ExpressionNode _parsePostfix(_ParserState state) {
    var node = _parseAtom(state);
    while (true) {
      switch (state.peek().type) {
        case TokenType.bang:
          state.advance();
          node = UnaryNode(UnaryOperator.factorial, node);
        case TokenType.percent:
          state.advance();
          node = UnaryNode(UnaryOperator.percent, node);
        default:
          return node;
      }
    }
  }

  ExpressionNode _parseAtom(_ParserState state) {
    final token = state.peek();

    switch (token.type) {
      case TokenType.number:
        state.advance();
        return NumberNode(token.lexeme);

      case TokenType.lparen:
        state.advance();
        final inner = _parseBinary(state, 1);
        _expectClosingParen(state, token);
        return GroupNode(inner);

      case TokenType.bar:
        state.advance();
        final inner = _parseBinary(state, 1);
        if (state.peek().type != TokenType.bar) {
          throw ParseError(
            'Unclosed absolute value',
            position: token.start,
            suggestion: 'Add a closing "|"',
          );
        }
        state.advance();
        return AbsoluteNode(inner);

      case TokenType.identifier:
        return _parseIdentifier(state, token);

      case TokenType.end:
        throw ParseError(
          'The expression ends before it is finished',
          position: token.start,
          suggestion: 'Add a value after the last operator',
        );

      default:
        throw ParseError('Unexpected "${token.lexeme}"', position: token.start);
    }
  }

  ExpressionNode _parseIdentifier(_ParserState state, Token token) {
    final name = token.lexeme;
    state.advance();

    if (knownFunctions.contains(name)) {
      final arguments = <ExpressionNode>[];
      if (state.peek().type == TokenType.lparen) {
        final open = state.peek();
        state.advance();
        if (state.peek().type != TokenType.rparen) {
          arguments.add(_parseBinary(state, 1));
          while (state.peek().type == TokenType.comma) {
            state.advance();
            arguments.add(_parseBinary(state, 1));
          }
        }
        _expectClosingParen(state, open);
      } else {
        // sqrt 9 and sin x without parens — accept, since calculators do.
        arguments.add(_parseUnary(state));
      }

      // sqrt and cbrt are radicals in the model, not generic calls, so the
      // editor and screen reader treat them structurally.
      if (name == 'sqrt' && arguments.length == 1) {
        return RootNode(arguments.single);
      }
      if (name == 'cbrt' && arguments.length == 1) {
        return RootNode(arguments.single, index: const NumberNode('3'));
      }
      if (name == 'root' && arguments.length == 2) {
        return RootNode(arguments[1], index: arguments[0]);
      }
      if (name == 'abs' && arguments.length == 1) {
        return AbsoluteNode(arguments.single);
      }
      return FunctionNode(name, arguments);
    }

    final constant = _constantNames[name];
    if (constant != null) return ConstantNode(constant);

    return VariableNode(name);
  }

  void _expectClosingParen(_ParserState state, Token openToken) {
    if (state.peek().type != TokenType.rparen) {
      throw ParseError(
        'Missing closing parenthesis',
        position: state.peek().start,
        suggestion: 'Add ")" to close the "(" at position ${openToken.start + 1}',
      );
    }
    state.advance();
  }
}

class _ParserState {
  _ParserState(this.tokens, this.source);

  final List<Token> tokens;
  final String source;
  int index = 0;

  Token peek() => tokens[index];

  void advance() {
    if (index < tokens.length - 1) index++;
  }
}
