import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/convert/percent_math.dart';

void main() {
  test('15 percent of 80 is 12', () {
    expect(PercentMath.percentOf(percent: 15, ofValue: 80), 12);
  });

  test('20 is 40 percent of 50', () {
    expect(PercentMath.whatPercent(part: 20, whole: 50), 40);
  });

  test('50 plus 10 percent is 55', () {
    expect(PercentMath.changeBy(amount: 50, percent: 10), 55);
  });

  test('50 minus 10 percent is 45', () {
    expect(PercentMath.changeBy(amount: 50, percent: -10), 45);
  });
}
