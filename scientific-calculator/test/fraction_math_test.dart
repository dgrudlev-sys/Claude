import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/convert/fraction_math.dart';
import 'package:scientific_calculator/convert/tool_explainers.dart';

void main() {
  test('1/2 plus 1/3 is 5/6', () {
    final c = Fraction(1, 2) + Fraction(1, 3);
    expect(c.numerator, 5);
    expect(c.denominator, 6);
    expect(c.mixedLabel, '5/6');
  });

  test('simplifies 2/4 to 1/2', () {
    final f = Fraction(2, 4);
    expect(f.improperLabel, '1/2');
  });

  test('1 1/2 mixed plus 1/2 is 2', () {
    final a = Fraction.mixed(whole: 1, numerator: 1, denominator: 2);
    final b = Fraction(1, 2);
    final c = a + b;
    expect(c.mixedLabel, '2');
  });

  test('3/4 is bigger than 1/2', () {
    expect(Fraction(3, 4).compareTo(Fraction(1, 2)), greaterThan(0));
  });

  test('divide by zero fraction throws', () {
    expect(() => Fraction(1, 2) / Fraction(0, 1), throwsArgumentError);
  });

  test('1/2 plus 1/3 plus 1/6 is 1', () {
    final c = evalFractionTerms([
      Fraction(1, 2),
      Fraction(1, 3),
      Fraction(1, 6),
    ], FractionOp.add);
    expect(c.mixedLabel, '1');
    expect(c.numerator, 1);
    expect(c.denominator, 1);
  });

  test('subtracts three fractions in order', () {
    final c = evalFractionTerms([
      Fraction(3, 4),
      Fraction(1, 4),
      Fraction(1, 4),
    ], FractionOp.subtract);
    expect(c.mixedLabel, '1/4');
  });

  test('multiplies three fractions', () {
    final c = evalFractionTerms([
      Fraction(1, 2),
      Fraction(1, 3),
      Fraction(1, 4),
    ], FractionOp.multiply);
    expect(c.improperLabel, '1/24');
  });

  test('divides three fractions left to right', () {
    final c = evalFractionTerms([
      Fraction(1, 2),
      Fraction(1, 2),
      Fraction(1, 2),
    ], FractionOp.divide);
    expect(c.mixedLabel, '2');
  });

  test('add walkthrough rewrites three terms on a common denominator', () {
    final steps = ToolExplainers.fractions(
      Fraction(1, 2),
      FractionOp.add,
      Fraction(1, 3),
      [Fraction(1, 6)],
    ).steps;
    expect(steps.first.words.toLowerCase(), contains('common denominator'));
    expect(steps.first.words, contains('3/6'));
    expect(steps.first.words, contains('2/6'));
    expect(steps.first.words, contains('1/6'));
    expect(steps.any((s) => s.symbols.contains('6/6')), isTrue);
    expect(steps.any((s) => s.symbols.contains('1/1')), isTrue);
  });
}
