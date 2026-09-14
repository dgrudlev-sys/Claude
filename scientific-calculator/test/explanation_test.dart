import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/convert/convert_engine.dart';
import 'package:scientific_calculator/convert/fraction_math.dart';
import 'package:scientific_calculator/convert/tool_explainers.dart';
import 'package:scientific_calculator/core/angle_mode.dart';
import 'package:scientific_calculator/core/calculator_controller.dart';
import 'package:scientific_calculator/core/expression_explainer.dart';

void main() {
  group('expression steps', () {
    final explainer = ExpressionExplainer();

    test('2 + 3 × 4 multiplies first, then adds', () {
      final steps = explainer.explain('2+3*4', AngleMode.degrees).steps;
      expect(steps, hasLength(2));
      expect(steps.first.symbols, '3 × 4 = 12');
      expect(steps.first.words, contains('Multiply'));
      expect(steps.last.symbols, '2 + 12 = 14');
      expect(steps.last.words, contains('Add'));
    });

    test('parentheses add before multiply', () {
      final steps = explainer.explain('2*(3+4)', AngleMode.degrees).steps;
      expect(steps.first.symbols, '3 + 4 = 7');
      expect(steps.last.symbols, '2 × 7 = 14');
    });

    test('sin(90) in degrees is 1, with a degrees hint', () {
      final steps = explainer.explain('sin(90)', AngleMode.degrees).steps;
      expect(steps, isNotEmpty);
      expect(steps.last.symbols, 'sin(90) = 1');
      expect(steps.last.words.toLowerCase(), contains('degrees'));
    });
  });

  test('controller exposes steps after equals', () {
    final c = CalculatorController();
    c.input('5+3');
    c.evaluate();
    final steps = c.lastExplanation?.steps ?? [];
    expect(steps, isNotEmpty);
    expect(steps.last.symbols, '5 + 3 = 8');
    expect(steps.last.words, contains('Add'));
  });

  test('percent of 15% of 80', () {
    final steps = ToolExplainers.percentOf(percent: 15, ofValue: 80).steps;
    expect(steps.first.symbols, contains('15/100'));
    expect(steps.last.symbols, contains('12'));
    expect(steps.first.words.toLowerCase(), contains('15/100'));
    expect(steps.first.words, contains('0.15'));
  });

  test('1/2 plus 1/3 shows a common denominator', () {
    final steps = ToolExplainers.fractions(Fraction(1, 2), FractionOp.add, Fraction(1, 3)).steps;
    expect(steps.any((s) => s.symbols.contains('3/6')), isTrue);
    expect(steps.any((s) => s.symbols.contains('5/6')), isTrue);
    expect(steps.first.words.toLowerCase(), contains('denominator'));
  });

  test('1 meter to centimetre names the factor', () {
    final from = ConvertEngine.unitsFor(ConvertCategory.length).firstWhere((u) => u.id == 'm');
    final to = ConvertEngine.unitsFor(ConvertCategory.length).firstWhere((u) => u.id == 'cm');
    final value = ConvertEngine.convert(category: ConvertCategory.length, fromId: 'm', toId: 'cm', value: 1);
    final steps = ToolExplainers.unitConvert(
      category: ConvertCategory.length,
      from: from,
      to: to,
      amount: 1,
      value: value,
    ).steps;
    expect(steps.last.symbols, contains('100'));
    expect(steps.first.symbols, contains('1 m'));
  });

  test('spoken joins beats without Step N', () {
    const explanation = Explanation(steps: [
      ExplanationStep(words: 'Adding 5 and 3.', symbols: '5 + 3 = 8'),
      ExplanationStep(words: 'Done.', symbols: '8'),
    ]);
    expect(explanation.spoken, 'Adding 5 and 3. 5 + 3 = 8 Then Done. 8');
    expect(explanation.spoken.toLowerCase(), isNot(contains('step 1')));
  });
}
