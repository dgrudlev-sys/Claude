import '../../expression/expression.dart';
import 'braille_cell.dart';
import 'nemeth_code.dart';

class BrailleParseError implements Exception {
  const BrailleParseError(this.message, {required this.position});

  final String message;

  /// Which cell the problem was found at, so the UI can put the caret
  /// there rather than only saying that something is wrong.
  final int position;

  @override
  String toString() => message;
}

/// Reads Nemeth braille into the Expression Model.
///
/// This is the fourth way into the same tree, alongside the keyboard, the
/// microphone and the camera. A braille display is a keyboard as much as
/// it is a screen, and a user typing on one should not be handed a
/// second-class path that produces something almost-but-not-quite like
/// what typing produces — so this produces exactly the same nodes, and
/// evaluation, editing and speech all come free.
class BrailleMathParser {
  const BrailleMathParser();

  /// Accepts Unicode braille patterns or ASCII braille, in either case.
  ExpressionNode parse(String input) =>
      parseCells(BrailleText.decode(input).cells);

  ExpressionNode parseCells(List<BrailleCell> cells) {
    final parser = _Scanner(cells);
    final expression = parser.readExpression();
    parser.skipBlanks();
    if (!parser.atEnd) {
      throw BrailleParseError(
        'Unexpected cell ${parser.peek()} after the expression',
        position: parser.position,
      );
    }
    return expression;
  }
}

class _Scanner {
  _Scanner(this.cells);

  final List<BrailleCell> cells;
  int position = 0;

  bool get atEnd => position >= cells.length;

  BrailleCell? peek([int ahead = 0]) =>
      position + ahead < cells.length ? cells[position + ahead] : null;

  BrailleCell take() => cells[position++];

  /// Blank cells separate words in braille the way spaces do in print.
  /// They carry no mathematical meaning but they do end a run of
  /// letters, which is what tells `sin x` from a variable called `sinx`.
  void skipBlanks() {
    while (!atEnd && cells[position].isBlank) {
      position++;
    }
  }

  bool nextIs(BrailleCell cell, [int ahead = 0]) => peek(ahead) == cell;

  ExpressionNode readExpression() {
    var left = readTerm();
    while (true) {
      skipBlanks();
      if (nextIs(NemethCode.plus)) {
        take();
        left = BinaryNode(BinaryOperator.add, left, readTerm());
      } else if (nextIs(NemethCode.minus)) {
        take();
        left = BinaryNode(BinaryOperator.subtract, left, readTerm());
      } else {
        return left;
      }
    }
  }

  ExpressionNode readTerm() {
    var left = readFactor();
    while (true) {
      skipBlanks();

      // The cross form of multiplication is two cells; the raised dot is
      // one, and shares its cell with the second half of the cross.
      if (nextIs(NemethCode.timesCrossPrefix) &&
          nextIs(NemethCode.timesCross, 1)) {
        position += 2;
        left = BinaryNode(BinaryOperator.multiply, left, readFactor());
        continue;
      }
      if (nextIs(NemethCode.timesDot)) {
        take();
        left = BinaryNode(BinaryOperator.multiply, left, readFactor());
        continue;
      }
      if (nextIs(NemethCode.prefix46) &&
          nextIs(NemethCode.divideSecondCell, 1)) {
        position += 2;
        left = BinaryNode(BinaryOperator.divide, left, readFactor());
        continue;
      }
      // Two values side by side multiply, which is what 2x means.
      if (startsPrimary()) {
        left = BinaryNode(
          BinaryOperator.multiply,
          left,
          readFactor(),
          isImplicit: true,
        );
        continue;
      }
      return left;
    }
  }

  ExpressionNode readFactor() {
    skipBlanks();
    if (nextIs(NemethCode.minus)) {
      take();
      return UnaryNode(UnaryOperator.negate, readFactor());
    }

    var node = readPrimary();

    while (!atEnd) {
      if (nextIs(NemethCode.factorial)) {
        take();
        node = UnaryNode(UnaryOperator.factorial, node);
        continue;
      }
      if (nextIs(NemethCode.superscript)) {
        take();
        final exponent = readPrimary();
        // The baseline indicator says the exponent has ended. It is
        // optional at the end of an expression, where there is nothing
        // left that could be mistaken for part of it.
        if (nextIs(NemethCode.baseline)) take();
        node = PowerNode(node, exponent);
        continue;
      }
      break;
    }
    return node;
  }

  /// Whether the next cell could begin a value, which is how implicit
  /// multiplication is spotted.
  bool startsPrimary() {
    final cell = peek();
    if (cell == null) return false;
    if (NemethCode.digitByCell.containsKey(cell)) return true;
    if (NemethCode.letterByCell.containsKey(cell)) return true;
    if (cell == NemethCode.letterIndicator) return true;
    if (cell == NemethCode.fractionOpen) return true;
    if (cell == NemethCode.radical) return true;
    if (cell == NemethCode.radicalIndex) return true;
    if (cell == NemethCode.openParen) return true;
    // Dots 4-6 begins a value only when it introduces a Greek letter.
    if (cell == NemethCode.prefix46) {
      final after = peek(1);
      return after != null && NemethCode.letterByCell.containsKey(after);
    }
    return false;
  }

  ExpressionNode readPrimary() {
    skipBlanks();
    final cell = peek();
    if (cell == null) {
      throw BrailleParseError('The expression ends early', position: position);
    }

    if (NemethCode.digitByCell.containsKey(cell)) return readNumber();

    if (cell == NemethCode.openParen) {
      take();
      final inner = readExpression();
      skipBlanks();
      if (!nextIs(NemethCode.closeParen)) {
        throw BrailleParseError(
          'This opening parenthesis is never closed',
          position: position,
        );
      }
      take();
      return GroupNode(inner);
    }

    if (cell == NemethCode.fractionOpen) return readFraction();
    if (cell == NemethCode.radical) return readRadical(index: null);
    if (cell == NemethCode.radicalIndex) {
      take();
      final index = readPrimary();
      skipBlanks();
      if (!nextIs(NemethCode.radical)) {
        throw BrailleParseError(
          'A root index must be followed by the radical sign',
          position: position,
        );
      }
      return readRadical(index: index);
    }

    if (cell == NemethCode.prefix46 &&
        NemethCode.letterByCell.containsKey(peek(1))) {
      take();
      final letter = NemethCode.letterByCell[take()]!;
      final name = NemethCode.greekLetters[letter];
      if (name == null) {
        throw BrailleParseError(
          'Unsupported Greek letter "$letter"',
          position: position - 1,
        );
      }
      return ConstantNode(
        name == 'pi' ? MathConstant.pi : MathConstant.goldenRatio,
      );
    }

    if (cell == NemethCode.letterIndicator ||
        NemethCode.letterByCell.containsKey(cell)) {
      return readLetters();
    }

    throw BrailleParseError('Unexpected cell $cell', position: position);
  }

  ExpressionNode readNumber() {
    final digits = StringBuffer();
    while (!atEnd && NemethCode.digitByCell.containsKey(peek())) {
      digits.write(NemethCode.digitByCell[take()]);
    }
    // Dots 4-6 is a decimal point when a digit follows it, and something
    // else entirely when anything else does.
    if (nextIs(NemethCode.decimalPoint) &&
        NemethCode.digitByCell.containsKey(peek(1))) {
      take();
      digits.write('.');
      while (!atEnd && NemethCode.digitByCell.containsKey(peek())) {
        digits.write(NemethCode.digitByCell[take()]);
      }
    }
    return NumberNode(digits.toString());
  }

  ExpressionNode readFraction() {
    take(); // opening indicator
    final numerator = readExpression();
    skipBlanks();
    if (!nextIs(NemethCode.fractionLine)) {
      throw BrailleParseError(
        'This fraction has no fraction line',
        position: position,
      );
    }
    take();
    final denominator = readExpression();
    skipBlanks();
    if (!nextIs(NemethCode.fractionClose)) {
      throw BrailleParseError(
        'This fraction is never closed',
        position: position,
      );
    }
    take();
    return FractionNode(numerator, denominator);
  }

  ExpressionNode readRadical({required ExpressionNode? index}) {
    take(); // radical sign
    final radicand = readExpression();
    skipBlanks();
    if (!nextIs(NemethCode.radicalEnd)) {
      throw BrailleParseError(
        'This root is never closed',
        position: position,
      );
    }
    take();
    return RootNode(radicand, index: index);
  }

  /// Reads a run of letters, which is either a function name or a string
  /// of variables multiplied together.
  ExpressionNode readLetters() {
    if (nextIs(NemethCode.letterIndicator)) take();

    final run = StringBuffer();
    final startedAt = position;
    while (!atEnd) {
      if (nextIs(NemethCode.letterIndicator)) {
        take();
        continue;
      }
      final letter = NemethCode.letterByCell[peek()];
      if (letter == null) break;
      run.write(letter);
      take();
    }

    final letters = run.toString();
    if (letters.isEmpty) {
      throw BrailleParseError('Expected a letter', position: startedAt);
    }

    // The longest leading run that names a function wins, so "sin" is a
    // sine and "xy" is two variables.
    for (var length = letters.length; length >= 2; length--) {
      final candidate = letters.substring(0, length);
      if (!NemethCode.functionNames.contains(candidate)) continue;
      final trailing = letters.substring(length);
      // Put back whatever followed the function name, so it can be read
      // as the start of the argument.
      position -= trailing.length;
      skipBlanks();
      final argument = readPrimary();
      return FunctionNode(candidate, [argument]);
    }

    // A run of letters is one variable name, which is the rule the
    // typed and spoken paths already use: "xy" is a variable called xy,
    // and x times y is written with a multiplication sign. Reading it as
    // a product here instead would mean braille produced a different
    // tree from the same maths typed in, and the whole point is that it
    // does not.
    return VariableNode(letters);
  }
}
