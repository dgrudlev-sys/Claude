import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/calculator_controller.dart';

/// What the readout is allowed to say.
///
/// Evaluating replaces the expression with its own result, so that the
/// next key carries on from the answer. That is the right behaviour and
/// it had one visible consequence: the panel showed the result twice,
/// once as what you entered and once as what it came to, which looks
/// exactly like a rendering bug.
void main() {
  late CalculatorController controller;

  setUp(() => controller = CalculatorController());
  tearDown(() => controller.dispose());

  test('before anything is evaluated there is no working to show', () {
    controller.input('1');
    controller.input('+');
    expect(controller.evaluatedExpression, isNull);
    expect(controller.expression, '1+');
  });

  test('after evaluating, the working is kept and the answer is separate', () {
    controller.input('(3+4)*5');
    controller.evaluate();

    expect(controller.evaluatedExpression, '(3+4)*5');
    expect(controller.display, '35');
    // And the expression carries the answer forward, so the next key
    // continues from it.
    expect(controller.expression, '35');
  });

  test('the working is dropped the moment you type again', () {
    controller.input('2+2');
    controller.evaluate();
    expect(controller.evaluatedExpression, '2+2');

    controller.input('+1');
    expect(controller.evaluatedExpression, isNull,
        reason: 'stale working would caption an answer it did not produce');
    expect(controller.expression, '4+1');
  });

  test('and by backspace, wrapping and clearing too', () {
    for (final act in <void Function()>[
      () => controller.backspace(),
      () => controller.wrap('sqrt(', ')'),
      () => controller.clear(),
    ]) {
      controller.clear();
      controller.input('9');
      controller.evaluate();
      expect(controller.evaluatedExpression, '9');

      act();
      expect(controller.evaluatedExpression, isNull);
    }
  });

  test('a failed evaluation leaves an error rather than a stale answer', () {
    controller.input('1/0');
    controller.evaluate();
    expect(controller.errorMessage, isNotNull);
  });
}
