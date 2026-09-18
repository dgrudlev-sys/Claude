import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/braille_renderer.dart';
import 'package:scientific_calculator/expression/render/text_renderer.dart';
import 'package:scientific_calculator/input/braille/braille_cell.dart';
import 'package:scientific_calculator/input/braille/braille_math_parser.dart';
import 'package:scientific_calculator/input/braille/nemeth_code.dart';

/// Braille is the one output nobody on this team can proofread by eye, so
/// these tests are built to check themselves rather than to check against
/// what someone remembered.
///
/// Three independent things have to agree:
///
///   1. the dot numbers, which can be read off a published Nemeth chart
///   2. the ASCII braille table, which was designed to line up with
///      Nemeth and comes from a completely separate source
///   3. round trips through the parser and renderer, which catch a table
///      that is self-inconsistent even when every entry looks plausible
///
/// A wrong cell would have to be wrong in all three ways at once to get
/// through, and the three do not share a failure mode.
void main() {
  const parser = BrailleMathParser();
  const renderer = BrailleRenderer();
  const text = TextRenderer(useUnicodeOperators: false);
  const evaluator = Evaluator();

  /// The expressions used for the round-trip properties. Chosen to cover
  /// every node type the braille layer claims to support.
  const corpus = [
    '5',
    '42',
    '0.5',
    '3.14159',
    '2+3',
    '10-4',
    '6*7',
    '10/4',
    '2+3*4',
    '(2+3)*4',
    '2-3-4',
    '2^10',
    'x^2',
    '2^(3+1)',
    'x',
    '2x',
    'xy',
    '-5',
    '-x+1',
    '5!',
    'sqrt(9)',
    'sqrt(2+7)',
    'root(3, 27)',
    'sin(x)',
    'ln(2)',
    'pi',
    '2*pi',
  ];

  group('a cell is its dots, and the dots are checkable', () {
    test('dot numbers pack into the Unicode braille block', () {
      // U+2800 is the blank cell; each dot is one bit, dot 1 lowest.
      expect(BrailleCell({}).character, '⠀');
      expect(BrailleCell({1}).character, '⠁');
      expect(BrailleCell({1, 2}).character, '⠃');
      expect(BrailleCell({8}).character, '⢀');
    });

    test('a cell round trips through Unicode', () {
      for (var bits = 0; bits < 256; bits++) {
        final cell = BrailleCell.fromBits(bits);
        expect(BrailleCell.fromCharacter(cell.character), cell);
        expect(BrailleCell(cell.dots), cell);
      }
    });

    test('a six-dot cell round trips through ASCII braille', () {
      for (var bits = 0; bits < 64; bits++) {
        final cell = BrailleCell.fromBits(bits);
        expect(BrailleCell.fromAscii(cell.ascii), cell);
      }
    });

    test('the ASCII braille table has 64 distinct characters', () {
      final seen = {
        for (var bits = 0; bits < 64; bits++) BrailleCell.fromBits(bits).ascii,
      };
      expect(seen, hasLength(64));
    });

    test('eight-dot cells have no ASCII form, and say so', () {
      expect(() => BrailleCell({7}).ascii, throwsStateError);
      expect(BrailleCell({1, 2, 3}).isSixDot, isTrue);
      expect(BrailleCell({1, 7}).isSixDot, isFalse);
    });

    test('a dot outside 1 to 8 is refused', () {
      expect(() => BrailleCell({0}), throwsArgumentError);
      expect(() => BrailleCell({9}), throwsArgumentError);
    });
  });

  group('the Nemeth table agrees with ASCII braille', () {
    // The ASCII braille ordering was laid out so that Nemeth's symbols
    // land on the matching ASCII punctuation. Every one of these is the
    // dot numbers and the ASCII table agreeing from separate sources.
    test('operators', () {
      expect(NemethCode.plus.ascii, '+');
      expect(NemethCode.minus.ascii, '-');
      expect(NemethCode.timesDot.ascii, '*');
    });

    test('fraction indicators', () {
      expect(NemethCode.fractionOpen.ascii, '?');
      expect(NemethCode.fractionLine.ascii, '/');
      expect(NemethCode.fractionClose.ascii, '#');
    });

    test('powers and roots', () {
      expect(NemethCode.superscript.ascii, '^');
      expect(NemethCode.baseline.ascii, '"');
      expect(NemethCode.radical.ascii, '>');
      expect(NemethCode.radicalEnd.ascii, ']');
      expect(NemethCode.radicalIndex.ascii, '<');
    });

    test('grouping and the rest', () {
      expect(NemethCode.openParen.ascii, '(');
      expect(NemethCode.closeParen.ascii, ')');
      expect(NemethCode.factorial.ascii, '&');
      expect(NemethCode.letterIndicator.ascii, ';');
      expect(NemethCode.prefix46.ascii, '.');
    });

    test('the numerals are the letters a to j dropped one row', () {
      // This is the defining property of Nemeth numerals, and it is why
      // they need no numeric indicator: shifting a letter down by one
      // row moves dot 1 to 2, 2 to 3, 4 to 5 and 5 to 6.
      const lettersInOrder = 'abcdefghij';
      const digitsInOrder = '1234567890';
      for (var i = 0; i < 10; i++) {
        final letter = NemethCode.letters[lettersInOrder[i]]!;
        final digit = NemethCode.digits[digitsInOrder[i]]!;
        final dropped = {
          for (final dot in letter.dots) const {1: 2, 2: 3, 4: 5, 5: 6}[dot]!,
        };
        expect(digit.dots, dropped,
            reason: '${digitsInOrder[i]} should be ${lettersInOrder[i]} dropped');
      }
    });

    test('the numerals also land on the ASCII digits', () {
      // A second, independent confirmation of the same ten cells.
      for (final entry in NemethCode.digits.entries) {
        expect(entry.value.ascii, entry.key);
      }
    });

    test('no two symbols in the table share a cell', () {
      // A duplicate would make one of them unreadable, and the parser
      // would silently pick whichever it checked first.
      final singleCells = <String, BrailleCell>{
        'plus': NemethCode.plus,
        'minus': NemethCode.minus,
        'timesDot': NemethCode.timesDot,
        'fractionOpen': NemethCode.fractionOpen,
        'fractionLine': NemethCode.fractionLine,
        'fractionClose': NemethCode.fractionClose,
        'superscript': NemethCode.superscript,
        'baseline': NemethCode.baseline,
        'radical': NemethCode.radical,
        'radicalEnd': NemethCode.radicalEnd,
        'radicalIndex': NemethCode.radicalIndex,
        'openParen': NemethCode.openParen,
        'closeParen': NemethCode.closeParen,
        'factorial': NemethCode.factorial,
        'letterIndicator': NemethCode.letterIndicator,
        'prefix46': NemethCode.prefix46,
        ...NemethCode.digits.map((k, v) => MapEntry('digit $k', v)),
        ...NemethCode.letters.map((k, v) => MapEntry('letter $k', v)),
      };
      final byCell = <BrailleCell, List<String>>{};
      for (final entry in singleCells.entries) {
        byCell.putIfAbsent(entry.value, () => []).add(entry.key);
      }
      for (final entry in byCell.entries) {
        expect(entry.value, hasLength(1),
            reason: '${entry.value} all use ${entry.key}');
      }
    });
  });

  group('reading braille into the Expression Model', () {
    ExpressionNode read(String braille) => parser.parse(braille);
    NumberValue valueOf(String braille) => evaluator.evaluate(read(braille));

    test('a numeral needs no numeric indicator', () {
      expect(read(NemethCode.digits['5']!.character), const NumberNode('5'));
    });

    test('ASCII braille is accepted as readily as Unicode patterns', () {
      // A braille display in computer mode and a screen reader send the
      // same expression two different ways.
      expect(valueOf('2+3'), RationalValue.fromInt(5));
      expect(
        valueOf(renderer.renderUnicode(const ExpressionParser().parse('2+3'))),
        RationalValue.fromInt(5),
      );
    });

    test('the four operations', () {
      expect(valueOf('2+3'), RationalValue.fromInt(5));
      expect(valueOf('9-4'), RationalValue.fromInt(5));
      expect(valueOf('6*7'), RationalValue.fromInt(42));
      expect(valueOf('1./4'), RationalValue(BigInt.one, BigInt.from(4)));
    });

    test('precedence is the same as everywhere else in the app', () {
      expect(valueOf('2+3*4'), RationalValue.fromInt(14));
      expect(valueOf('(2+3)*4'), RationalValue.fromInt(20));
    });

    test('a fraction is a fraction, not a division', () {
      // ?1/2#  — opening indicator, 1, fraction line, 2, closing.
      final node = read('?1/2#');
      expect(node, isA<FractionNode>());
      expect(evaluator.evaluate(node), RationalValue(BigInt.one, BigInt.two));
    });

    test('a decimal point is told from division by what follows it', () {
      // Dots 4-6 does both jobs. A digit after it makes it a decimal
      // point; the fraction-line cell makes it division.
      expect(valueOf('3.5'), NumberValue.parse('3.5'));
      expect(valueOf('3./5'), RationalValue(BigInt.from(3), BigInt.from(5)));
    });

    test('powers close with the baseline indicator', () {
      expect(valueOf('2^10"'), RationalValue.fromInt(1024));
      // And the indicator may be left off at the very end.
      expect(valueOf('2^10'), RationalValue.fromInt(1024));
    });

    test('what follows a baseline indicator is back on the main line', () {
      // 2^2 + 1 is 5. Without the baseline the +1 would belong upstairs.
      expect(valueOf('2^2"+1'), RationalValue.fromInt(5));
    });

    test('roots, with and without an index', () {
      expect(valueOf('>9]'), RationalValue.fromInt(3));
      expect(valueOf('<3>27]'), RationalValue.fromInt(3));
    });

    test('variables and implied multiplication', () {
      final node = read('2x');
      expect(
        evaluator.evaluate(node,
            const EvaluationContext(variables: {'x': RealValue(5)})).toDouble(),
        closeTo(10, 1e-12),
      );
    });

    test('a run of letters that names a function is one', () {
      expect(read('sin x'), isA<FunctionNode>());
      expect((read('sin x') as FunctionNode).name, 'sin');
    });

    test('any other run of letters is one variable, as everywhere else', () {
      // The typed path reads "xy" as a variable called xy, not as x
      // times y. Braille has to agree, or the same maths would produce
      // two different trees depending on how it was entered.
      expect(read('xy'), const VariableNode('xy'));
      expect(const ExpressionParser().parse('xy'), const VariableNode('xy'));
    });

    test('the letter indicator is accepted and carries no value', () {
      expect(read(';x'), const VariableNode('x'));
    });

    test('pi is the Greek indicator and the letter p', () {
      expect(read('.p'), const ConstantNode(MathConstant.pi));
      expect(valueOf('2*.p').toDouble(), closeTo(6.283185307, 1e-9));
    });

    test('factorial', () {
      expect(valueOf('5&'), RationalValue.fromInt(120));
    });

    test('a negative sign at the front is a negation', () {
      expect(valueOf('-5'), RationalValue.fromInt(-5));
    });
  });

  group('errors say what is wrong and where', () {
    test('an unclosed fraction is reported', () {
      expect(
        () => parser.parse('?1/2'),
        throwsA(isA<BrailleParseError>()
            .having((e) => e.message, 'message', contains('never closed'))),
      );
    });

    test('an unclosed root is reported', () {
      expect(
        () => parser.parse('>9'),
        throwsA(isA<BrailleParseError>()
            .having((e) => e.message, 'message', contains('never closed'))),
      );
    });

    test('an unclosed parenthesis is reported', () {
      expect(
        () => parser.parse('(2+3'),
        throwsA(isA<BrailleParseError>()
            .having((e) => e.message, 'message', contains('never closed'))),
      );
    });

    test('the position points at the offending cell', () {
      try {
        parser.parse('2++3');
        fail('should have thrown');
      } on BrailleParseError catch (error) {
        expect(error.position, greaterThan(0));
      }
    });

    test('text that is not braille at all is refused clearly', () {
      expect(
        () => parser.parse('hello ∑ world'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('writing braille out', () {
    test('a fraction gets real fraction indicators', () {
      const half = FractionNode(NumberNode('1'), NumberNode('2'));
      expect(renderer.renderAscii(half), '?1/2#');
    });

    test('a power is closed so what follows reads on the main line', () {
      final tree = const ExpressionParser().parse('x^2+1');
      // ASCII braille is written in capitals by convention; a BRF file
      // has no lower case at all.
      expect(renderer.renderAscii(tree), 'X^2"+1');
    });

    test('a root is opened and closed', () {
      expect(
        renderer.renderAscii(const RootNode(NumberNode('9'))),
        '>9]',
      );
      expect(
        renderer.renderAscii(
            const RootNode(NumberNode('27'), index: NumberNode('3'))),
        '<3>27]',
      );
    });

    test('parentheses appear only where precedence needs them', () {
      final parsed = const ExpressionParser();
      expect(renderer.renderAscii(parsed.parse('2+3*4')), '2+3@*4');
      // Built directly, so there is no GroupNode carrying the grouping.
      expect(
        renderer.renderAscii(const BinaryNode(
          BinaryOperator.multiply,
          BinaryNode(BinaryOperator.add, NumberNode('2'), NumberNode('3')),
          NumberNode('4'),
        )),
        '(2+3)@*4',
      );
    });

    test('an expression with empty slots refuses rather than guessing', () {
      expect(
        () => renderer.render(const PlaceholderNode()),
        throwsA(isA<BrailleRenderError>()
            .having((e) => e.message, 'message', contains('empty slots'))),
      );
    });

    test('what is not implemented says so instead of writing nonsense', () {
      expect(
        () => renderer.render(const AbsoluteNode(NumberNode('5'))),
        throwsA(isA<BrailleRenderError>()
            .having((e) => e.message, 'message', contains('not implemented'))),
      );
      expect(
        () => renderer.render(const MatrixNode([
          [NumberNode('1')]
        ])),
        throwsA(isA<BrailleRenderError>()),
      );
    });
  });

  group('the round trip, which is what actually proves the table', () {
    test('every expression in the corpus survives braille and back', () {
      const source = ExpressionParser();
      for (final expression in corpus) {
        final original = source.parse(expression);
        final braille = renderer.renderUnicode(original);
        final returned = parser.parse(braille);
        expect(text.render(returned), text.render(original),
            reason: 'round trip of "$expression" via $braille');
      }
    });

    test('and evaluates to the same number afterwards', () {
      const source = ExpressionParser();
      // "xy" is one variable, not x times y — see the letter-run test.
      const context = EvaluationContext(
        variables: {'x': RealValue(3), 'xy': RealValue(12)},
      );
      for (final expression in corpus) {
        final original = source.parse(expression);
        final returned = parser.parse(renderer.renderUnicode(original));
        expect(
          evaluator.evaluate(returned, context).toDouble(),
          closeTo(evaluator.evaluate(original, context).toDouble(), 1e-12),
          reason: 'value of "$expression" after a round trip',
        );
      }
    });

    test('Unicode and ASCII forms carry the same cells', () {
      const source = ExpressionParser();
      for (final expression in corpus) {
        final braille = renderer.render(source.parse(expression));
        expect(BrailleText.decode(braille.ascii).cells, braille.cells,
            reason: expression);
        expect(BrailleText.decode(braille.unicode).cells, braille.cells,
            reason: expression);
      }
    });

    test('a fraction is still a fraction on the way back', () {
      const source = ExpressionParser();
      final tree = FractionNode(
        source.parse('1+2'),
        const NumberNode('3'),
      );
      final returned = parser.parse(renderer.renderUnicode(tree));
      expect(returned, isA<FractionNode>());
      expect(evaluator.evaluate(returned), RationalValue.fromInt(1));
    });
  });
}
