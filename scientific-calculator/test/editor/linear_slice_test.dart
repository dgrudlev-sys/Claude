import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/editor/linear_slice.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/text_renderer.dart';

/// The trick that lets the editor reuse the parser without losing
/// structure, tested on its own because everything else depends on it.
void main() {
  const parser = ExpressionParser();
  const renderer = TextRenderer(useUnicodeOperators: false);

  group('flattening', () {
    test('a plain expression comes out as parser-ready text', () {
      final slice = LinearSlice.of(parser.parse('3+4*2'));
      expect(slice.text, '3+4*2');
      expect(slice.sentinels, isEmpty);
    });

    test('parentheses are emitted where precedence would otherwise be lost', () {
      // Built directly rather than parsed, so there is no GroupNode to
      // carry the grouping — the flattener has to supply it.
      const tree = BinaryNode(
        BinaryOperator.multiply,
        BinaryNode(BinaryOperator.add, NumberNode('3'), NumberNode('4')),
        NumberNode('2'),
      );
      expect(LinearSlice.of(tree).text, '(3+4)*2');
    });

    test('parentheses the user typed are kept as a structure, not as text', () {
      // "(3+4)*2" parses to a GroupNode, which is something the user put
      // there deliberately. Flattening it back to bare text would let a
      // later edit dissolve it, so it stays opaque like any structure.
      final slice = LinearSlice.of(parser.parse('(3+4)*2'));
      expect(slice.sentinels, hasLength(1));
      expect(slice.sentinels.values.single, isA<GroupNode>());
      expect(slice.text.endsWith('*2'), isTrue);
    });

    test('a structure becomes a single opaque character', () {
      const tree = BinaryNode(
        BinaryOperator.add,
        FractionNode(NumberNode('1'), NumberNode('2')),
        NumberNode('5'),
      );
      final slice = LinearSlice.of(tree);

      expect(slice.sentinels, hasLength(1));
      // One character standing in for the whole fraction.
      expect(slice.text.length, 3);
      expect(slice.text.endsWith('+5'), isTrue);
      expect(slice.sentinels[slice.text[0]], isA<FractionNode>());
    });

    test('an empty slot is opaque too, having no text of its own', () {
      final slice = LinearSlice.of(const PlaceholderNode());
      expect(slice.sentinels, hasLength(1));
      expect(slice.text.length, 1);
    });
  });

  group('round tripping', () {
    test('flatten then restore is the identity', () {
      for (final source in ['3+4*2', '(3+4)*2', '-2^3', '5!', 'sin(x)+1', '2x']) {
        final tree = parser.parse(source);
        final slice = LinearSlice.of(tree);
        expect(renderer.render(slice.restore(slice.text)), renderer.render(tree),
            reason: source);
      }
    });

    test('a fraction survives the round trip as a fraction', () {
      const tree = FractionNode(NumberNode('1'), NumberNode('2'));
      final slice = LinearSlice.of(tree);
      // Rendering to text and reparsing would give a division here. It
      // does not, because the parser never sees inside the sentinel.
      expect(slice.restore(slice.text), isA<FractionNode>());
    });

    test('the parser regroups around a structure without opening it', () {
      const tree = FractionNode(NumberNode('1'), NumberNode('2'));
      final slice = LinearSlice.of(tree);
      // Type "+3" after the fraction.
      final restored = slice.restore('${slice.text}+3');

      expect(restored, isA<BinaryNode>());
      expect((restored as BinaryNode).left, isA<FractionNode>());
      expect(restored.right, const NumberNode('3'));
    });

    test('precedence applies to sentinels like any other operand', () {
      const tree = BinaryNode(
        BinaryOperator.add,
        NumberNode('1'),
        FractionNode(NumberNode('1'), NumberNode('2')),
      );
      final slice = LinearSlice.of(tree);
      // Multiplying on the end must bind to the fraction, not the sum.
      final restored = slice.restore('${slice.text}*4') as BinaryNode;

      expect(restored.operator, BinaryOperator.add);
      final product = restored.right as BinaryNode;
      expect(product.operator, BinaryOperator.multiply);
      expect(product.left, isA<FractionNode>());
    });
  });

  group('mapping between the tree and the text', () {
    test('a leaf position maps to a character offset and back', () {
      final slice = LinearSlice.of(parser.parse('12+345'));
      // The caret after "345" is at the end of the text.
      expect(slice.offsetOf([1], 3), 6);
      final located = slice.locate(6)!;
      expect(located.path, [1]);
      expect(located.offset, 3);
    });

    test('at a boundary the earlier leaf wins', () {
      // In "2x" the two leaves touch at offset 1. A caret there is
      // "after the 2", which is where the user left it.
      final slice = LinearSlice.of(parser.parse('2x'));
      final located = slice.locate(1)!;
      expect(located.path, [0]);
      expect(located.offset, 1);
    });

    test('a structure has an offset either side of its token', () {
      const tree = FractionNode(NumberNode('1'), NumberNode('2'));
      final slice = LinearSlice.of(tree);
      expect(slice.offsetOf(const [], 0), 0);
      expect(slice.offsetOf(const [], 1), 1);
    });

    test('a registered structure can be spliced in and comes back whole', () {
      final slice = LinearSlice.of(parser.parse('2'));
      const inserted = FractionNode(NumberNode('1'), NumberNode('2'));
      final sentinel = slice.registerSentinel(inserted);

      final restored = slice.restore('${slice.text}+$sentinel') as BinaryNode;
      expect(restored.right, same(inserted));
    });
  });
}
