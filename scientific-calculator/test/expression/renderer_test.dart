import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/expression/render/text_renderer.dart';

void main() {
  const text = TextRenderer();
  const plainText = TextRenderer(useUnicodeOperators: false);
  const speech = SpeechRenderer();

  group('text rendering', () {
    test('renders a simple sum', () {
      expect(
        text.render(const BinaryNode(
          BinaryOperator.add,
          NumberNode('1'),
          NumberNode('2'),
        )),
        '1 + 2',
      );
    });

    test('adds parentheses only where precedence needs them', () {
      // (1 + 2) × 3 — the sum must be parenthesised
      const needsParens = BinaryNode(
        BinaryOperator.multiply,
        BinaryNode(BinaryOperator.add, NumberNode('1'), NumberNode('2')),
        NumberNode('3'),
      );
      expect(text.render(needsParens), '(1 + 2) × 3');

      // 1 + 2 × 3 — the product binds tighter, no parens needed
      const noParens = BinaryNode(
        BinaryOperator.add,
        NumberNode('1'),
        BinaryNode(BinaryOperator.multiply, NumberNode('2'), NumberNode('3')),
      );
      expect(text.render(noParens), '1 + 2 × 3');
    });

    test('implicit multiplication renders without a symbol', () {
      expect(
        text.render(const BinaryNode(
          BinaryOperator.multiply,
          NumberNode('2'),
          VariableNode('x'),
          isImplicit: true,
        )),
        '2x',
      );
    });

    test('ascii mode emits parser-friendly operators', () {
      const tree = BinaryNode(
        BinaryOperator.multiply,
        NumberNode('2'),
        NumberNode('3'),
      );
      expect(text.render(tree), '2 × 3');
      expect(plainText.render(tree), '2 * 3');
    });

    test('renders placeholders visibly rather than as nothing', () {
      expect(
        text.render(const FractionNode(
          PlaceholderNode(role: 'numerator'),
          NumberNode('2'),
        )),
        '(▢)/(2)',
      );
    });

    test('renders a matrix', () {
      expect(
        text.render(const MatrixNode([
          [NumberNode('1'), NumberNode('2')],
          [NumberNode('3'), NumberNode('4')],
        ])),
        '[1, 2; 3, 4]',
      );
    });
  });

  group('speech rendering — the accessibility surface', () {
    test('common fractions get their spoken names', () {
      expect(
        speech.render(const FractionNode(NumberNode('1'), NumberNode('2'))),
        'one half',
      );
      expect(
        speech.render(const FractionNode(NumberNode('3'), NumberNode('4'))),
        '3 quarters',
      );
    });

    test('a complex fraction is opened and closed explicitly', () {
      // fraction (x+1) over 2 — a listener needs to know where it ends
      const tree = FractionNode(
        BinaryNode(BinaryOperator.add, VariableNode('x'), NumberNode('1')),
        NumberNode('2'),
      );
      expect(speech.render(tree), 'fraction x plus 1 over 2, end fraction');
    });

    test('squares and cubes use their natural names', () {
      expect(
        speech.render(const PowerNode(VariableNode('x'), NumberNode('2'))),
        'x squared',
      );
      expect(
        speech.render(const PowerNode(VariableNode('x'), NumberNode('3'))),
        'x cubed',
      );
    });

    test('other exponents are spoken in full', () {
      expect(
        speech.render(const PowerNode(VariableNode('x'), NumberNode('5'))),
        'x to the power of 5',
      );
    });

    test('roots announce their type and close', () {
      expect(
        speech.render(const RootNode(NumberNode('9'))),
        'square root of 9',
      );
      expect(
        speech.render(const RootNode(NumberNode('8'), index: NumberNode('3'))),
        'cube root of 8, end root',
      );
    });

    test('function names are spoken, not spelled', () {
      expect(
        speech.render(const FunctionNode('sin', [VariableNode('x')])),
        'sine of x',
      );
      expect(
        speech.render(const FunctionNode('ln', [VariableNode('x')])),
        'natural log of x',
      );
    });

    test('decimals are read digit by digit after the point', () {
      expect(speech.render(const NumberNode('3.14')), '3 point 1 4');
    });

    test('negation is spoken as "negative", not "minus"', () {
      expect(
        speech.render(const UnaryNode(UnaryOperator.negate, NumberNode('5'))),
        'negative 5',
      );
    });

    test('a matrix is announced with its shape and rows', () {
      expect(
        speech.render(const MatrixNode([
          [NumberNode('1'), NumberNode('2')],
          [NumberNode('3'), NumberNode('4')],
        ])),
        '2 by 2 matrix, row 1: 1, 2; row 2: 3, 4, end matrix',
      );
    });

    test('an empty slot says what it is waiting for', () {
      expect(
        speech.render(const PlaceholderNode(role: 'exponent')),
        'empty exponent',
      );
    });

    test('implied multiplication is read as juxtaposition', () {
      expect(
        speech.render(const BinaryNode(
          BinaryOperator.multiply,
          NumberNode('2'),
          VariableNode('x'),
          isImplicit: true,
        )),
        '2 x',
      );
    });
  });

  group('one model, many outputs', () {
    test('the same tree renders correctly for sight and for hearing', () {
      // √(x² + 1)
      const tree = RootNode(
        BinaryNode(
          BinaryOperator.add,
          PowerNode(VariableNode('x'), NumberNode('2')),
          NumberNode('1'),
        ),
      );
      expect(text.render(tree), '√(x^(2) + 1)');
      expect(speech.render(tree), 'square root of x squared plus 1, end root');
    });
  });
}
