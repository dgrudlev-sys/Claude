import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/convert/convert_engine.dart';

void main() {
  group('temperature', () {
    test('0 C is 32 F', () {
      expect(
        ConvertEngine.convert(category: ConvertCategory.temperature, fromId: 'c', toId: 'f', value: 0),
        closeTo(32, 1e-9),
      );
    });

    test('100 C is 212 F', () {
      expect(
        ConvertEngine.convert(category: ConvertCategory.temperature, fromId: 'c', toId: 'f', value: 100),
        closeTo(212, 1e-9),
      );
    });

    test('32 F is 0 C', () {
      expect(
        ConvertEngine.convert(category: ConvertCategory.temperature, fromId: 'f', toId: 'c', value: 32),
        closeTo(0, 1e-9),
      );
    });

    test('0 C is 273.15 K', () {
      expect(
        ConvertEngine.convert(category: ConvertCategory.temperature, fromId: 'c', toId: 'k', value: 0),
        closeTo(273.15, 1e-9),
      );
    });
  });

  group('cooking', () {
    test('1 cup is about 237 millilitres', () {
      expect(
        ConvertEngine.convert(category: ConvertCategory.cooking, fromId: 'cup', toId: 'ml', value: 1),
        closeTo(236.5882365, 1e-6),
      );
    });

    test('3 teaspoons is 1 tablespoon', () {
      expect(
        ConvertEngine.convert(category: ConvertCategory.cooking, fromId: 'tsp', toId: 'tbsp', value: 3),
        closeTo(1, 1e-9),
      );
    });
  });

  group('length', () {
    test('1 meter is 100 centimeters', () {
      expect(
        ConvertEngine.convert(category: ConvertCategory.length, fromId: 'm', toId: 'cm', value: 1),
        closeTo(100, 1e-9),
      );
    });

    test('1 inch is 2.54 centimeters', () {
      expect(
        ConvertEngine.convert(category: ConvertCategory.length, fromId: 'in', toId: 'cm', value: 1),
        closeTo(2.54, 1e-9),
      );
    });
  });

  group('tip', () {
    test('15 percent of 100 is 15, total 115, split 2 ways is 57.5', () {
      final result = ConvertEngine.tip(bill: 100, tipPercent: 15, people: 2);
      expect(result.tipAmount, closeTo(15, 1e-9));
      expect(result.total, closeTo(115, 1e-9));
      expect(result.perPerson, closeTo(57.5, 1e-9));
    });

    test('one person has no per-person split', () {
      final result = ConvertEngine.tip(bill: 40, tipPercent: 10, people: 1);
      expect(result.tipAmount, closeTo(4, 1e-9));
      expect(result.perPerson, isNull);
    });
  });
}
