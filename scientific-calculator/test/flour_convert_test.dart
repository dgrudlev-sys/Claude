import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/convert/convert_engine.dart';

void main() {
  test('1 cup of flour is 120 grams', () {
    expect(
      ConvertEngine.convertFlour(fromId: 'cup', toId: 'g', value: 1),
      closeTo(120, 1e-9),
    );
  });

  test('240 grams of flour is 2 cups', () {
    expect(
      ConvertEngine.convertFlour(fromId: 'g', toId: 'cup', value: 240),
      closeTo(2, 1e-9),
    );
  });

  test('flour mass summary includes kilograms and pounds', () {
    final text = ConvertEngine.flourMassSummary(120);
    expect(text, contains('grams'));
    expect(text, contains('kilograms'));
    expect(text, contains('pounds'));
  });
}
