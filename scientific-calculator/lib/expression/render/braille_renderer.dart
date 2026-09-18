import '../../input/braille/braille_cell.dart';
import '../../input/braille/nemeth_code.dart';
import '../expression.dart';

class BrailleRenderError implements Exception {
  const BrailleRenderError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Renders an expression tree as Nemeth braille.
///
/// The fourth output from the one model, alongside the visual layout,
/// speech and text. A refreshable display shows this directly; a
/// [BrailleText.ascii] of it is what goes into a BRF file for embossing.
///
/// Structure survives because the model kept it: a [FractionNode] gets
/// real fraction indicators, which is what lets a reader feel where the
/// numerator ends. A renderer working from flattened text could only
/// ever produce a division sign.
class BrailleRenderer {
  const BrailleRenderer();

  BrailleText render(ExpressionNode node) {
    final cells = <BrailleCell>[];
    _render(node, cells, 0);
    return BrailleText(cells);
  }

  /// Convenience for a display or a BRF file.
  String renderUnicode(ExpressionNode node) => render(node).unicode;
  String renderAscii(ExpressionNode node) => render(node).ascii;

  void _render(ExpressionNode node, List<BrailleCell> out, int parentPrecedence) {
    switch (node) {
      case NumberNode(:final literal):
        for (final character in literal.split('')) {
          if (character == '.') {
            out.add(NemethCode.decimalPoint);
            continue;
          }
          final digit = NemethCode.digits[character];
          if (digit == null) {
            throw BrailleRenderError('Cannot write "$character" in braille');
          }
          out.add(digit);
        }

      case VariableNode(:final name):
        _writeLetters(name, out);

      case ConstantNode(:final constant):
        final letter = NemethCode.greekLetters.entries
            .where((entry) => entry.value == constant.spokenName)
            .map((entry) => entry.key)
            .firstOrNull;
        if (letter == null) {
          throw BrailleRenderError(
            'The constant ${constant.spokenName} has no Nemeth form here',
          );
        }
        out.add(NemethCode.greekIndicator);
        out.add(NemethCode.letters[letter]!);

      case BinaryNode(:final operator, :final left, :final right, :final isImplicit):
        final precedence = operator.precedence;
        final needsParens = precedence < parentPrecedence;
        if (needsParens) out.add(NemethCode.openParen);
        _render(left, out, precedence);
        if (!(isImplicit && operator == BinaryOperator.multiply)) {
          switch (operator) {
            case BinaryOperator.add:
              out.add(NemethCode.plus);
            case BinaryOperator.subtract:
              out.add(NemethCode.minus);
            case BinaryOperator.multiply:
              out.add(NemethCode.timesCrossPrefix);
              out.add(NemethCode.timesCross);
            case BinaryOperator.divide:
              out.add(NemethCode.prefix46);
              out.add(NemethCode.divideSecondCell);
            case BinaryOperator.modulo:
              throw const BrailleRenderError(
                'Modulo has no Nemeth form in this implementation',
              );
          }
        }
        _render(right, out, precedence + 1);
        if (needsParens) out.add(NemethCode.closeParen);

      case UnaryNode(:final operator, :final operand):
        switch (operator) {
          case UnaryOperator.negate:
            out.add(NemethCode.minus);
            _render(operand, out, 3);
          case UnaryOperator.factorial:
            _render(operand, out, 4);
            out.add(NemethCode.factorial);
          case UnaryOperator.percent:
            throw const BrailleRenderError(
              'Percent has no Nemeth form in this implementation',
            );
        }

      case FractionNode(:final numerator, :final denominator):
        out.add(NemethCode.fractionOpen);
        _render(numerator, out, 0);
        out.add(NemethCode.fractionLine);
        _render(denominator, out, 0);
        out.add(NemethCode.fractionClose);

      case PowerNode(:final base, :final exponent):
        _render(base, out, 5);
        out.add(NemethCode.superscript);
        _render(exponent, out, 0);
        // Always closed, so that anything following is read on the main
        // line rather than as more of the exponent.
        out.add(NemethCode.baseline);

      case RootNode(:final radicand, :final index):
        if (index != null) {
          out.add(NemethCode.radicalIndex);
          _render(index, out, 0);
        }
        out.add(NemethCode.radical);
        _render(radicand, out, 0);
        out.add(NemethCode.radicalEnd);

      case GroupNode(:final inner):
        out.add(NemethCode.openParen);
        _render(inner, out, 0);
        out.add(NemethCode.closeParen);

      case FunctionNode(:final name, :final arguments):
        if (!NemethCode.functionNames.contains(name)) {
          throw BrailleRenderError('No Nemeth form for the function "$name"');
        }
        if (arguments.length != 1) {
          throw BrailleRenderError(
            '"$name" takes ${arguments.length} arguments, which this '
            'implementation cannot write in braille',
          );
        }
        _writeLetters(name, out);
        // A blank cell ends the function name, so a following variable
        // is not read as more of it.
        out.add(const BrailleCell.fromBits(0));
        _render(arguments.single, out, 0);

      case PlaceholderNode():
        throw const BrailleRenderError(
          'An expression with empty slots cannot be written in braille',
        );

      case AbsoluteNode():
        throw const BrailleRenderError(
          'Absolute value is not implemented in braille yet',
        );

      case MatrixNode():
        throw const BrailleRenderError(
          'Matrices are not implemented in braille yet',
        );
    }
  }

  void _writeLetters(String text, List<BrailleCell> out) {
    for (final character in text.toLowerCase().split('')) {
      final cell = NemethCode.letters[character];
      if (cell == null) {
        throw BrailleRenderError('Cannot write the letter "$character"');
      }
      out.add(cell);
    }
  }
}
