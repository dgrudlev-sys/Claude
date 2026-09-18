import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/expression/render/text_renderer.dart';
import 'package:scientific_calculator/input/language/german_vocabulary.dart';
import 'package:scientific_calculator/input/language/vocabularies.dart';

/// Equations and plus-or-minus.
///
/// The formula library cannot exist without these two. Ohm's law is
/// `V = I × R` — a claim about two expressions, not an expression — and
/// the quadratic formula needs a ± that stands for both branches at once.
/// Neither had anywhere to live in the model.
void main() {
  const parser = ExpressionParser();
  const text = TextRenderer(useUnicodeOperators: false);
  const evaluator = Evaluator();

  group('an equation is a statement, not a quantity', () {
    test('it parses into a relation rather than an expression', () {
      final node = parser.parse('V=I*R');
      expect(node, isA<RelationNode>());
      final relation = node as RelationNode;
      expect(relation.operator, RelationOperator.equals);
      expect(relation.left, const VariableNode('V'));
    });

    test('the relation binds looser than anything inside it', () {
      // 2x + 1 = 5 groups as (2x + 1) = (5), not 2x + (1 = 5).
      final relation = parser.parse('2x+1=5') as RelationNode;
      expect(relation.left, isA<BinaryNode>());
      expect(relation.right, const NumberNode('5'));
    });

    test('inequalities parse too', () {
      for (final entry in {
        'x<5': RelationOperator.lessThan,
        'x>5': RelationOperator.greaterThan,
        'x≤5': RelationOperator.lessOrEqual,
        'x≥5': RelationOperator.greaterOrEqual,
        'x≠5': RelationOperator.notEquals,
        'x≈5': RelationOperator.approximately,
      }.entries) {
        expect((parser.parse(entry.key) as RelationNode).operator, entry.value,
            reason: entry.key);
      }
    });

    test('evaluating one refuses, and says why', () {
      // Returning a number here would answer a question nobody asked.
      // Solving and evaluating are different operations.
      expect(
        () => evaluator.evaluate(parser.parse('x=5')),
        throwsA(isA<MathError>().having((e) => e.message, 'message',
            allOf(contains('equation'), contains('Solve')))),
      );
    });

    test('an equation with nothing on the right is reported', () {
      expect(
        () => parser.parse('x='),
        throwsA(isA<ParseError>().having((e) => e.message, 'message',
            contains('Nothing on the right'))),
      );
    });

    test('it round trips through text', () {
      for (final source in ['V=I*R', '2x+1=5', 'x<5']) {
        expect(text.render(parser.parse(source)),
            text.render(parser.parse(text.render(parser.parse(source)))),
            reason: source);
      }
    });

    test('and reads aloud in every shipped language', () {
      final equation = parser.parse('V=I*R');
      for (final entry in shippedMathVocabularies.vocabularies.entries) {
        final spoken = SpeechRenderer(vocabulary: entry.value).render(equation);
        expect(spoken, isNotEmpty, reason: entry.key);
        // The relation word is the language's own, not a symbol.
        expect(spoken, isNot(contains('=')), reason: entry.key);
      }
      expect(
        const SpeechRenderer(vocabulary: GermanMathVocabulary()).render(equation),
        'V gleich I mal R',
      );
    });
  });

  group('plus or minus stands for both branches', () {
    test('it parses and binds like addition', () {
      final node = parser.parse('1±2') as BinaryNode;
      expect(node.operator, BinaryOperator.plusMinus);
      expect(BinaryOperator.plusMinus.precedence, BinaryOperator.add.precedence);
    });

    test('evaluating it refuses rather than picking the positive branch', () {
      // Quietly choosing one of two answers is the failure mode worth
      // guarding against: it would be wrong exactly half the time and
      // never say so.
      expect(
        () => evaluator.evaluate(parser.parse('1±2')),
        throwsA(isA<MathError>().having((e) => e.message, 'message',
            contains('two values'))),
      );
    });

    test('it renders and reads back', () {
      expect(text.render(parser.parse('1±2')), '1 ± 2');
      expect(const SpeechRenderer().render(parser.parse('1±2')),
          '1 plus or minus 2');
    });
  });

  group('the quadratic formula, which needed both', () {
    ExpressionNode quadratic() => RelationNode(
          RelationOperator.equals,
          const VariableNode('x'),
          FractionNode(
            BinaryNode(
              BinaryOperator.plusMinus,
              UnaryNode(UnaryOperator.negate, const VariableNode('b')),
              RootNode(parser.parse('b^2-4*a*c')),
            ),
            parser.parse('2*a'),
          ),
        );

    test('it can finally be written down', () {
      final formula = quadratic();
      expect(formula, isA<RelationNode>());
      expect(text.render(formula), contains('±'));
      expect(text.render(formula), startsWith('x = '));
    });

    test('and spoken', () {
      final spoken = const SpeechRenderer().render(quadratic());
      expect(spoken, startsWith('x equals'));
      expect(spoken, contains('plus or minus'));
      expect(spoken, contains('square root of'));
    });

    test('which is what the formula library will store', () {
      // Ohm's law, for the same reason: a formula is a relation between
      // named quantities, and storing it as a bare expression would throw
      // away which side is which.
      final ohm = parser.parse('V=I*R') as RelationNode;
      expect(ohm.left, const VariableNode('V'));
      expect(const SpeechRenderer().render(ohm), 'V equals I times R');
    });
  });
}
