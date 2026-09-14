import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/numeric_input.dart';

void main() {
  test('scalar accepts numbers, signs, decimals, and exponents', () {
    expect(NumericInput.isAllowedScalar('12.5'), isTrue);
    expect(NumericInput.isAllowedScalar('-3'), isTrue);
    expect(NumericInput.isAllowedScalar('1e-3'), isTrue);
    expect(NumericInput.isAllowedScalar(''), isTrue);
    expect(NumericInput.isAllowedScalar('-'), isTrue);
  });

  test('scalar rejects letters and other text', () {
    expect(NumericInput.isAllowedScalar('abc'), isFalse);
    expect(NumericInput.isAllowedScalar('12a'), isFalse);
    expect(NumericInput.isAllowedScalar('N=12'), isFalse);
  });

  test('sanitizeScalar strips letters', () {
    expect(NumericInput.sanitizeScalar('12abc.5'), '12.5');
  });
}
