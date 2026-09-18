import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/engine/number/number_display.dart';

/// Where exactness gets spent.
///
/// The engine keeps values exact as long as it can; a display cannot.
/// The question these tests answer is whether the app is honest about
/// which of the two it is showing — because "1609.344" and "1609.34"
/// look alike and only one of them is the definition of a mile.
void main() {
  NumberValue exact(String literal) => NumberValue.parse(literal);

  group('an exact value stays exact', () {
    test('an integer is shown whole and not marked as rounded', () {
      final shown = DisplayNumber.of(exact('63360'));
      expect(shown.text, '63 360');
      expect(shown.isRounded, isFalse);
    });

    test('a terminating decimal is shown in full', () {
      // 1 mile is exactly 1609.344 m. Rounding that would misreport a
      // definition, not merely lose precision.
      final shown = DisplayNumber.of(exact('1609.344'));
      expect(shown.text, '1609.344');
      expect(shown.isRounded, isFalse);
    });

    test('trailing zeros are dropped rather than padded out', () {
      expect(DisplayNumber.of(exact('2.500')).text, '2.5');
      expect(DisplayNumber.of(exact('2.000')).text, '2');
    });

    test('a third cannot be written exactly, and says so', () {
      final third = RationalValue(BigInt.one, BigInt.from(3));
      final shown = DisplayNumber.of(third);
      expect(shown.isRounded, isTrue);
      expect(shown.text, startsWith('0.333'));
    });
  });

  group('an approximation is labelled as one', () {
    test('a rounded double reports that it was rounded', () {
      final shown = DisplayNumber.of(const RealValue(3.14159265358979));
      expect(shown.isRounded, isTrue);
    });

    test('a double that survives rounding intact does not', () {
      // 0.5 is exactly representable and fits in the digit budget, so
      // nothing was lost — claiming otherwise would cry wolf.
      expect(DisplayNumber.of(const RealValue(0.5)).isRounded, isFalse);
    });
  });

  group('extremes stay readable', () {
    test('very large and very small values switch to exponent form', () {
      expect(DisplayNumber.of(const RealValue(9.1e-31)).text, contains('e'));
      expect(DisplayNumber.of(const RealValue(6.02e23)).text, contains('e'));
    });

    test('ordinary magnitudes never do', () {
      // Scientific notation for 1500 would be technically right and
      // practically hostile.
      expect(DisplayNumber.of(exact('1500')).text, isNot(contains('e')));
      expect(DisplayNumber.of(exact('0.001')).text, isNot(contains('e')));
    });

    test('a minus sign is the typographic one, not a hyphen', () {
      expect(DisplayNumber.of(exact('-40')).text, startsWith('−'));
    });

    test('groups are thin spaces, which no decimal separator claims', () {
      // A comma would mean "decimal point" to half the world and a
      // full stop to the other half. The SI answer is neither.
      final shown = DisplayNumber.of(exact('1234567'));
      expect(shown.text, '1 234 567');
      expect(shown.text, isNot(contains(',')));
    });

    test('four digits are not grouped, so a year still reads as a year', () {
      expect(DisplayNumber.of(exact('2026')).text, '2026');
    });
  });

  group('nothing throws inside a widget build', () {
    test('infinities and NaN come out as words rather than exceptions', () {
      expect(DisplayNumber.of(const RealValue(double.nan)).text, 'undefined');
      expect(DisplayNumber.of(const RealValue(double.infinity)).text, '∞');
      expect(
        DisplayNumber.of(const RealValue(double.negativeInfinity)).text,
        '−∞',
      );
    });

    test('zero is zero in every form', () {
      expect(DisplayNumber.of(const RealValue(0)).text, '0');
      expect(DisplayNumber.of(exact('0')).text, '0');
    });
  });
}
