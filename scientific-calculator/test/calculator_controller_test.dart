import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/core/calculator_controller.dart';

void main() {
  test('input inserts at the cursor, not only at the end', () {
    final c = CalculatorController();
    c.input('123');
    c.moveCursorLeft();
    c.moveCursorLeft();
    c.input('0');
    expect(c.expression, '1023');
    expect(c.cursor, 2);
  });

  test('backspace deletes the character before the cursor', () {
    final c = CalculatorController();
    c.input('57');
    c.moveCursorLeft();
    c.backspace();
    expect(c.expression, '7');
    expect(c.cursor, 0);
  });

  test('evaluate stores history and recall restores the result', () {
    final c = CalculatorController();
    c.input('5+3');
    c.evaluate();
    expect(c.display, '8');
    expect(c.visibleHistory, hasLength(1));
    expect(c.visibleHistory.single.expression, '5+3');

    c.clear();
    c.recall(c.visibleHistory.single);
    expect(c.expression, '8');
  });

  test('pin, hide, and delete history', () {
    final c = CalculatorController();
    c
      ..input('1+1')
      ..evaluate()
      ..clear()
      ..input('2+2')
      ..evaluate()
      ..clear()
      ..input('3+3')
      ..evaluate();
    expect(c.visibleHistory, hasLength(3));

    final newest = c.visibleHistory.first;
    c.pinHistory(newest.id);
    expect(c.visibleHistory.first.pinned, isTrue);
    expect(c.visibleHistory.first.result, '6');

    final toHide = c.visibleHistory.firstWhere((e) => e.result == '4');
    c.hideHistory(toHide.id);
    expect(c.visibleHistory.map((e) => e.result), isNot(contains('4')));
    expect(c.visibleHistory, hasLength(2));

    final remaining = c.visibleHistory.firstWhere((e) => !e.pinned);
    c.deleteHistory(remaining.id);
    expect(c.visibleHistory, hasLength(1));
    expect(c.visibleHistory.single.pinned, isTrue);
  });

  test('history keeps at most 30 visible unpinned entries', () {
    final c = CalculatorController();
    for (var i = 0; i < 35; i++) {
      c.input('$i+0');
      c.evaluate();
      c.clear();
    }
    expect(c.visibleHistory.length, lessThanOrEqualTo(30));
  });
}
