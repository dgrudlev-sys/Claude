import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/convert/fraction_math.dart';

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
}
