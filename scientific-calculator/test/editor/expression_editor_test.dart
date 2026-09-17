import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/editor/cursor.dart';
import 'package:scientific_calculator/editor/expression_editor.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/render/text_renderer.dart';

void main() {
  const renderer = TextRenderer(useUnicodeOperators: false);
  const evaluator = Evaluator();

  String text(ExpressionEditor editor) => renderer.render(editor.expression);

  NumberValue value(ExpressionEditor editor) =>
      evaluator.evaluate(editor.expression);

  /// Types a run of digits, the way a keypad sends them one at a time.
  void type(ExpressionEditor editor, String digits) {
    for (final digit in digits.split('')) {
      editor.insertDigit(digit);
    }
  }

  group('typing numbers', () {
    test('a new editor is one empty slot', () {
      final editor = ExpressionEditor.empty();
      expect(editor.isEmpty, isTrue);
      expect(editor.hasPlaceholders, isTrue);
      expect(text(editor), '▢');
    });

    test('the first digit fills the slot rather than sitting beside it', () {
      final editor = ExpressionEditor.empty();
      editor.insertDigit('5');
      expect(editor.expression, const NumberNode('5'));
      expect(editor.hasPlaceholders, isFalse);
    });

    test('digits accumulate into one number', () {
      final editor = ExpressionEditor.empty();
      type(editor, '123');
      expect(editor.expression, const NumberNode('123'));
    });

    test('a digit typed mid-number goes where the caret is', () {
      final editor = ExpressionEditor.empty();
      type(editor, '34');
      editor.moveLeft();
      editor.insertDigit('9');
      expect(editor.expression, const NumberNode('394'));
    });

    test('a bare decimal point gets the zero a person would write', () {
      final editor = ExpressionEditor.empty();
      editor.insertDigit('.');
      editor.insertDigit('5');
      expect(text(editor), '0.5');
      expect(value(editor), RationalValue(BigInt.one, BigInt.two));
    });
  });

  group('operators are grouped by the parser, not by the editor', () {
    test('an operator opens a slot to fill', () {
      final editor = ExpressionEditor.empty();
      type(editor, '3');
      editor.insertOperator(BinaryOperator.add);
      expect(text(editor), '3 + ▢');
      // And the caret is waiting in it.
      expect(editor.nodeAtCursor, isA<PlaceholderNode>());
    });

    test('precedence comes out right without the editor knowing any', () {
      final editor = ExpressionEditor.empty();
      type(editor, '3');
      editor.insertOperator(BinaryOperator.add);
      type(editor, '4');
      editor.insertOperator(BinaryOperator.multiply);
      type(editor, '2');

      expect(text(editor), '3 + 4 * 2');
      expect(value(editor), RationalValue.fromInt(11));
      // The multiplication really is nested under the addition.
      expect(editor.expression, isA<BinaryNode>());
      expect((editor.expression as BinaryNode).operator, BinaryOperator.add);
    });

    test('a later operator regroups what came before it', () {
      final editor = ExpressionEditor.empty();
      type(editor, '3');
      editor.insertOperator(BinaryOperator.multiply);
      type(editor, '4');
      editor.insertOperator(BinaryOperator.add);
      type(editor, '2');

      expect(text(editor), '3 * 4 + 2');
      expect(value(editor), RationalValue.fromInt(14));
      // This time the addition is on top.
      expect((editor.expression as BinaryNode).operator, BinaryOperator.add);
    });

    test('an operator typed at the very start opens a slot before it', () {
      final editor = ExpressionEditor.empty();
      type(editor, '5');
      editor.moveToStart();
      editor.insertOperator(BinaryOperator.multiply);
      expect(text(editor), '▢ * 5');
    });

    test('a variable beside a number becomes implied multiplication', () {
      final editor = ExpressionEditor.empty();
      type(editor, '2');
      editor.insertVariable('x');
      expect(text(editor), '2x');
      expect(
        evaluator.evaluate(editor.expression,
            const EvaluationContext(variables: {'x': RealValue(5)})).toDouble(),
        closeTo(10, 1e-12),
      );
    });

    test('constants can be typed', () {
      final editor = ExpressionEditor.empty();
      type(editor, '2');
      editor.insertOperator(BinaryOperator.multiply);
      editor.insertConstant(MathConstant.pi);
      expect(value(editor).toDouble(), closeTo(6.283185307, 1e-9));
    });
  });

  group('structures', () {
    test('a fraction captures what precedes it, like pressing divide', () {
      final editor = ExpressionEditor.empty();
      type(editor, '3');
      editor.insertFraction();
      expect(text(editor), '(3)/(▢)');
      expect(editor.expression, isA<FractionNode>());
      // The caret waits in the denominator.
      expect(editor.nodeAtCursor, isA<PlaceholderNode>());
      type(editor, '4');
      expect(text(editor), '(3)/(4)');
      expect(value(editor), RationalValue(BigInt.from(3), BigInt.from(4)));
    });

    test('a fraction captures only the last operand, not the whole sum', () {
      final editor = ExpressionEditor.empty();
      type(editor, '3');
      editor.insertOperator(BinaryOperator.add);
      type(editor, '4');
      editor.insertFraction();
      type(editor, '5');
      // 3 + (4/5), not (3+4)/5.
      expect(value(editor), RationalValue(BigInt.from(19), BigInt.from(5)));
    });

    test('a fraction on an empty slot gets two empty slots', () {
      final editor = ExpressionEditor.empty();
      editor.insertFraction();
      expect(text(editor), '(▢)/(▢)');
      // The caret is in the numerator, the first thing to fill.
      type(editor, '7');
      expect(text(editor), '(7)/(▢)');
    });

    test('a power captures its base', () {
      final editor = ExpressionEditor.empty();
      type(editor, '2');
      editor.insertPower();
      type(editor, '10');
      expect(value(editor), RationalValue.fromInt(1024));
    });

    test('a square root does not capture, because it is written first', () {
      final editor = ExpressionEditor.empty();
      editor.insertSquareRoot();
      expect(text(editor), '√(▢)');
      type(editor, '16');
      expect(value(editor), RationalValue.fromInt(4));
    });

    test('a function opens with its argument slot ready', () {
      final editor = ExpressionEditor.empty();
      editor.insertFunction('sin');
      expect(text(editor), 'sin(▢)');
      type(editor, '0');
      expect(value(editor), const RealValue(0.0));
    });

    test('an nth root puts the caret in the index first', () {
      final editor = ExpressionEditor.empty();
      editor.insertNthRoot();
      type(editor, '3');
      editor.moveToNextPlaceholder();
      type(editor, '27');
      expect(value(editor), RationalValue.fromInt(3));
    });

    test('a structure typed after a value multiplies against it', () {
      final editor = ExpressionEditor.empty();
      type(editor, '2');
      editor.insertSquareRoot();
      type(editor, '9');
      // 2√9 = 6, by implied multiplication.
      expect(value(editor), RationalValue.fromInt(6));
    });
  });

  group('a fraction survives being edited around', () {
    test('there is somewhere to stand after a fraction', () {
      final editor = ExpressionEditor.empty();
      type(editor, '1');
      editor.insertFraction();
      type(editor, '2');
      editor.moveToEnd();

      // Without a stop outside the structure, this would land inside the
      // denominator and there would be no way to type after a fraction
      // at all.
      editor.insertOperator(BinaryOperator.add);
      type(editor, '1');

      expect(editor.expression, isA<BinaryNode>());
      expect(value(editor), RationalValue(BigInt.from(3), BigInt.two));
    });

    test('the fraction is still a fraction afterwards', () {
      final editor = ExpressionEditor.empty();
      type(editor, '1');
      editor.insertFraction();
      type(editor, '2');
      editor.moveToEnd();
      editor.insertOperator(BinaryOperator.add);
      type(editor, '1');

      final sum = editor.expression as BinaryNode;
      // Rendering to text and back would have turned this into a plain
      // division. It did not, because the parser never saw inside it.
      expect(sum.left, isA<FractionNode>());
    });

    test('editing inside a numerator stays inside it', () {
      final editor = ExpressionEditor.empty();
      type(editor, '1');
      editor.insertFraction();
      type(editor, '2');

      // Back into the numerator, to just after the 1, and add to it.
      editor.moveToStart();
      editor.moveRight();
      editor.moveRight();
      editor.insertOperator(BinaryOperator.add);
      type(editor, '5');

      // (1+5)/2, not 1 + (5/2) — the edit did not reach out of the slot.
      expect(value(editor), RationalValue.fromInt(3));
      expect(editor.expression, isA<FractionNode>());
    });

    test('a fraction nested inside a fraction survives too', () {
      final editor = ExpressionEditor.empty();
      type(editor, '1');
      editor.insertFraction();
      type(editor, '2');
      editor.moveToEnd();
      editor.insertFraction();
      type(editor, '3');

      // (1/2)/3
      expect(value(editor), RationalValue(BigInt.one, BigInt.from(6)));
      final outer = editor.expression as FractionNode;
      expect(outer.numerator, isA<FractionNode>());
    });
  });

  group('deleting', () {
    test('backspace removes the digit before the caret', () {
      final editor = ExpressionEditor.empty();
      type(editor, '123');
      editor.deleteBackward();
      expect(editor.expression, const NumberNode('12'));
    });

    test('deleting the last digit leaves an empty slot, not nothing', () {
      final editor = ExpressionEditor.empty();
      type(editor, '7');
      editor.deleteBackward();
      expect(editor.isEmpty, isTrue);
      expect(text(editor), '▢');
    });

    test('backspace across an operator joins what was either side', () {
      final editor = ExpressionEditor.empty();
      type(editor, '3');
      editor.insertOperator(BinaryOperator.add);
      type(editor, '4');
      // Caret is after the 4; two deletes take the 4 and then the plus.
      editor.deleteBackward();
      editor.deleteBackward();
      expect(text(editor), '3');
    });

    test('deleting at the start of a numerator keeps what was in it', () {
      final editor = ExpressionEditor.empty();
      type(editor, '12');
      editor.insertFraction();
      type(editor, '4');

      // Back to the front of the numerator and delete the fraction.
      editor.moveToStart();
      editor.moveRight();
      editor.deleteBackward();

      // The numerator survives; throwing away everything typed would be
      // the unfriendly reading of "delete the fraction".
      expect(text(editor), '12');
    });

    test('clear goes back to a single empty slot', () {
      final editor = ExpressionEditor.empty();
      type(editor, '123');
      editor.insertOperator(BinaryOperator.add);
      type(editor, '456');
      editor.clear();
      expect(editor.isEmpty, isTrue);
    });
  });

  group('moving the caret', () {
    test('arrows step through every position in reading order', () {
      final editor = ExpressionEditor.empty();
      type(editor, '25');
      // |25, 2|5, 25|
      expect(editor.stops.length, 3);
      editor.moveToStart();
      expect(editor.cursor.offset, 0);
      editor.moveRight();
      expect(editor.cursor.offset, 1);
      editor.moveRight();
      expect(editor.cursor.offset, 2);
      // And stops at the end rather than falling off.
      editor.moveRight();
      expect(editor.cursor.offset, 2);
    });

    test('arrows walk into a fraction and out the other side', () {
      final editor = ExpressionEditor.empty();
      type(editor, '1');
      editor.insertFraction();
      type(editor, '2');

      editor.moveToStart();
      final visited = <String>[];
      for (var i = 0; i < editor.stops.length; i++) {
        visited.add(editor.cursor.toString());
        editor.moveRight();
      }
      // Outside, through the numerator, through the denominator, outside.
      expect(visited.first, '@0');
      expect(visited.last, '@1');
      expect(visited.length, 6);
    });

    test('tab jumps to the next empty slot and wraps', () {
      final editor = ExpressionEditor.empty();
      editor.insertFraction();
      expect(editor.nodeAtCursor, isA<PlaceholderNode>());
      type(editor, '1');
      expect(editor.moveToNextPlaceholder(), isTrue);
      type(editor, '2');
      // Nothing left to fill.
      expect(editor.moveToNextPlaceholder(), isFalse);
      expect(editor.hasPlaceholders, isFalse);
    });
  });

  group('undo and redo', () {
    test('undo steps back one edit at a time', () {
      final editor = ExpressionEditor.empty();
      type(editor, '12');
      expect(editor.canUndo, isTrue);
      editor.undo();
      expect(editor.expression, const NumberNode('1'));
      editor.undo();
      expect(editor.isEmpty, isTrue);
      expect(editor.canUndo, isFalse);
    });

    test('redo puts it back', () {
      final editor = ExpressionEditor.empty();
      type(editor, '12');
      editor.undo();
      expect(editor.canRedo, isTrue);
      editor.redo();
      expect(editor.expression, const NumberNode('12'));
    });

    test('a new edit after undo discards the redone future', () {
      final editor = ExpressionEditor.empty();
      type(editor, '12');
      editor.undo();
      editor.insertDigit('9');
      expect(editor.expression, const NumberNode('19'));
      expect(editor.canRedo, isFalse);
    });

    test('undo restores where the caret was, not just what was there', () {
      final editor = ExpressionEditor.empty();
      type(editor, '34');
      editor.moveToStart();
      editor.insertDigit('9');
      expect(editor.expression, const NumberNode('934'));
      editor.undo();
      expect(editor.expression, const NumberNode('34'));
      expect(editor.cursor.offset, 0);
    });

    test('undo covers structural edits as well as typing', () {
      final editor = ExpressionEditor.empty();
      type(editor, '3');
      editor.insertFraction();
      editor.undo();
      expect(editor.expression, const NumberNode('3'));
    });
  });

  group('starting from something that already exists', () {
    test('an expression can be reopened and added to', () {
      final editor = ExpressionEditor.parse('2+3');
      expect(text(editor), '2 + 3');
      editor.insertOperator(BinaryOperator.multiply);
      type(editor, '4');
      expect(value(editor), RationalValue.fromInt(14));
    });

    test('the caret starts at the end, ready to continue', () {
      final editor = ExpressionEditor.parse('42');
      expect(editor.cursor.offset, 2);
    });

    test('an expression with placeholders is not ready to evaluate', () {
      final editor = ExpressionEditor.empty();
      type(editor, '3');
      editor.insertOperator(BinaryOperator.add);
      expect(editor.hasPlaceholders, isTrue);
      expect(() => value(editor), throwsA(isA<MathError>()));
    });
  });

  group('the cursor stop model', () {
    test('a leaf has one more stop than it has characters', () {
      expect(CursorStops.stopsIn(const NumberNode('25')), 3);
      expect(CursorStops.stopsIn(const VariableNode('x')), 2);
    });

    test('an empty slot is a single position, with no inside', () {
      expect(CursorStops.stopsIn(const PlaceholderNode()), 1);
    });

    test('a structure has an outside as well as an inside', () {
      final stops = CursorStops.of(
        const FractionNode(NumberNode('1'), NumberNode('2')),
      );
      expect(stops[0].offset, 0);
      expect(stops[0].path, isEmpty);
      expect(stops[stops.length - 1].offset, 1);
      expect(stops[stops.length - 1].path, isEmpty);
    });

    test('an nth root lists its index first, where it is written', () {
      // Children are in reading order by contract, and the caret follows
      // them. ⁿ√x is spoken "nth root of x", so the index has to come
      // first or arrow keys visit the two slots backwards.
      const cubeRoot = RootNode(NumberNode('8'), index: NumberNode('3'));
      expect(cubeRoot.children, const [NumberNode('3'), NumberNode('8')]);
      expect(
        cubeRoot.withChildren(const [NumberNode('4'), NumberNode('16')]),
        const RootNode(NumberNode('16'), index: NumberNode('4')),
      );
    });

    test('operators contribute no stops of their own', () {
      // 3+4 has the stops of "3" and "4" and nothing extra: the caret
      // before the plus and after it are the ends of those two numbers.
      final stops = CursorStops.of(const BinaryNode(
        BinaryOperator.add,
        NumberNode('3'),
        NumberNode('4'),
      ));
      expect(stops.length, 4);
    });
  });
}
