import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/expression/expression.dart';

void main() {
  // 1/2 + x
  ExpressionNode sample() => const BinaryNode(
        BinaryOperator.add,
        FractionNode(NumberNode('1'), NumberNode('2')),
        VariableNode('x'),
      );

  group('tree navigation', () {
    test('walk visits every node in reading order', () {
      final kinds = sample().walk().map((n) => n.runtimeType.toString()).toList();
      expect(kinds, [
        'BinaryNode',
        'FractionNode',
        'NumberNode',
        'NumberNode',
        'VariableNode',
      ]);
    });

    test('nodeAt follows a path of child indices', () {
      final tree = sample();
      expect(tree.nodeAt([]), tree);
      expect(tree.nodeAt([0]), isA<FractionNode>());
      expect(tree.nodeAt([0, 1]), const NumberNode('2'));
      expect(tree.nodeAt([1]), const VariableNode('x'));
    });

    test('an out-of-range path resolves to null rather than throwing', () {
      expect(sample().nodeAt([5]), isNull);
      expect(sample().nodeAt([0, 9]), isNull);
    });
  });

  group('immutable editing', () {
    test('replaceAt swaps a subtree and leaves the original untouched', () {
      final original = sample();
      final edited = original.replaceAt([0, 1], const NumberNode('3'));

      expect(edited.nodeAt([0, 1]), const NumberNode('3'));
      // The original tree is unchanged — this is what makes undo trivial.
      expect(original.nodeAt([0, 1]), const NumberNode('2'));
    });

    test('replacing the root returns the replacement', () {
      final edited = sample().replaceAt([], const NumberNode('7'));
      expect(edited, const NumberNode('7'));
    });

    test('replaceAt preserves sibling structure', () {
      final edited = sample().replaceAt([1], const VariableNode('y')) as BinaryNode;
      expect(edited.left, isA<FractionNode>());
      expect(edited.right, const VariableNode('y'));
      expect(edited.operator, BinaryOperator.add);
    });

    test('an implicit multiplication survives a rebuild', () {
      const implicit = BinaryNode(
        BinaryOperator.multiply,
        NumberNode('2'),
        VariableNode('x'),
        isImplicit: true,
      );
      final edited = implicit.replaceAt([1], const VariableNode('y')) as BinaryNode;
      expect(edited.isImplicit, isTrue);
    });
  });

  group('placeholders', () {
    test('a fresh fraction is not ready to evaluate', () {
      const fresh = FractionNode(
        PlaceholderNode(role: 'numerator'),
        PlaceholderNode(role: 'denominator'),
      );
      expect(fresh.hasPlaceholder, isTrue);
    });

    test('filling every slot clears the placeholder state', () {
      const fresh = FractionNode(
        PlaceholderNode(role: 'numerator'),
        PlaceholderNode(role: 'denominator'),
      );
      final filled = fresh
          .replaceAt([0], const NumberNode('1'))
          .replaceAt([1], const NumberNode('2'));
      expect(filled.hasPlaceholder, isFalse);
    });

    test('a placeholder nested deep still marks the whole tree unready', () {
      const tree = BinaryNode(
        BinaryOperator.add,
        NumberNode('1'),
        PowerNode(NumberNode('2'), PlaceholderNode(role: 'exponent')),
      );
      expect(tree.hasPlaceholder, isTrue);
    });

    test('a complete tree has no placeholders', () {
      expect(sample().hasPlaceholder, isFalse);
    });
  });

  group('matrices', () {
    test('children flatten row-major for traversal', () {
      const matrix = MatrixNode([
        [NumberNode('1'), NumberNode('2')],
        [NumberNode('3'), NumberNode('4')],
      ]);
      expect(
        matrix.children.map((n) => (n as NumberNode).literal).toList(),
        ['1', '2', '3', '4'],
      );
      expect(matrix.rowCount, 2);
      expect(matrix.columnCount, 2);
    });

    test('rebuilding from flat children restores the row shape', () {
      const matrix = MatrixNode([
        [NumberNode('1'), NumberNode('2')],
        [NumberNode('3'), NumberNode('4')],
      ]);
      final edited = matrix.replaceAt([2], const NumberNode('9')) as MatrixNode;
      expect(edited.rowCount, 2);
      expect(edited.columnCount, 2);
      expect((edited.rows[1][0] as NumberNode).literal, '9');
      expect((edited.rows[0][0] as NumberNode).literal, '1');
    });
  });

  group('roots', () {
    test('a square root has one child, an nth root has two', () {
      expect(const RootNode(NumberNode('9')).children.length, 1);
      expect(const RootNode(NumberNode('9')).isSquareRoot, isTrue);

      const cube = RootNode(NumberNode('8'), index: NumberNode('3'));
      expect(cube.children.length, 2);
      expect(cube.isSquareRoot, isFalse);
    });
  });
}
