import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';

void main() {
  RationalValue rat(int n, [int d = 1]) =>
      RationalValue(BigInt.from(n), BigInt.from(d));

  group('rational exactness', () {
    test('1/3 + 1/3 + 1/3 is exactly 1, not 0.9999...', () {
      final third = rat(1, 3);
      final sum = third.add(third).add(third);
      expect(sum, rat(1));
      expect(sum.isExact, isTrue);
    });

    test('0.1 + 0.2 is exactly 0.3 when parsed as a literal', () {
      // The canonical floating-point embarrassment, avoided by parsing
      // decimal literals into exact rationals.
      final sum = NumberValue.parse('0.1').add(NumberValue.parse('0.2'));
      expect(sum, rat(3, 10));
      expect(sum.isExact, isTrue);
      expect(sum.toDouble(), closeTo(0.3, 1e-15));
    });

    test('fractions normalize to lowest terms with a positive denominator', () {
      expect(rat(6, 8), rat(3, 4));
      expect(rat(1, -2), rat(-1, 2));
      expect(rat(-6, -8), rat(3, 4));
    });

    test('division by zero throws a typed error', () {
      expect(
        () => rat(1).divide(rat(0)),
        throwsA(isA<MathError>().having((e) => e.kind, 'kind', MathErrorKind.divisionByZero)),
      );
    });
  });

  group('exact vs approximate promotion', () {
    test('sqrt of a perfect square stays exact', () {
      final result = rat(9).sqrt();
      expect(result, rat(3));
      expect(result.isExact, isTrue);
    });

    test('sqrt of a perfect square fraction stays exact', () {
      final result = rat(9, 4).sqrt();
      expect(result, rat(3, 2));
      expect(result.isExact, isTrue);
    });

    test('sqrt of a non-square becomes approximate', () {
      final result = rat(2).sqrt();
      expect(result.isExact, isFalse);
      expect(result.toDouble(), closeTo(1.4142135623730951, 1e-15));
    });

    test('a rational plus a real gives a real', () {
      final result = rat(1, 2).add(const RealValue(0.25));
      expect(result.isExact, isFalse);
      expect(result.toDouble(), closeTo(0.75, 1e-15));
    });

    test('exact cube root of 8 is 2', () {
      final result = rat(8).power(rat(1, 3));
      expect(result, rat(2));
      expect(result.isExact, isTrue);
    });

    test('non-exact cube root falls back to approximate', () {
      final result = rat(7).power(rat(1, 3));
      expect(result.isExact, isFalse);
      expect(result.toDouble(), closeTo(1.912931182772389, 1e-12));
    });

    test('integer powers stay exact, including negative exponents', () {
      expect(rat(2).power(rat(10)), rat(1024));
      expect(rat(2).power(rat(-2)), rat(1, 4));
      expect(rat(2, 3).power(rat(3)), rat(8, 27));
    });
  });

  group('repeating decimals', () {
    test('1/3 repeats as 3', () {
      final d = rat(1, 3).toDecimalExpansion();
      expect(d.integerPart, '0');
      expect(d.nonRepeating, '');
      expect(d.repeating, '3');
      expect(d.terminates, isFalse);
    });

    test('1/6 has a non-repeating digit before the cycle', () {
      final d = rat(1, 6).toDecimalExpansion();
      expect(d.nonRepeating, '1');
      expect(d.repeating, '6');
    });

    test('1/7 has a six-digit cycle', () {
      final d = rat(1, 7).toDecimalExpansion();
      expect(d.repeating, '142857');
    });

    test('1/4 terminates', () {
      final d = rat(1, 4).toDecimalExpansion();
      expect(d.nonRepeating, '25');
      expect(d.repeating, '');
      expect(d.terminates, isTrue);
    });

    test('an integer has no fractional part at all', () {
      final d = rat(5).toDecimalExpansion();
      expect(d.integerPart, '5');
      expect(d.nonRepeating, '');
      expect(d.terminates, isTrue);
    });

    test('negative values carry the sign separately', () {
      final d = rat(-1, 3).toDecimalExpansion();
      expect(d.isNegative, isTrue);
      expect(d.repeating, '3');
    });
  });

  group('mixed numbers', () {
    test('7/2 splits into 3 and 1/2', () {
      final mixed = rat(7, 2).toMixedNumber()!;
      expect(mixed.whole, BigInt.from(3));
      expect(mixed.fraction, rat(1, 2));
    });

    test('a proper fraction has no mixed form', () {
      expect(rat(1, 2).toMixedNumber(), isNull);
    });

    test('an integer has no mixed form', () {
      expect(rat(4).toMixedNumber(), isNull);
    });
  });

  group('complex numbers', () {
    test('sqrt of -4 is exactly 2i', () {
      final result = rat(-4).sqrt() as ComplexValue;
      expect(result.real, rat(0));
      expect(result.imaginary, rat(2));
      expect(result.isExact, isTrue);
    });

    test('i squared is -1', () {
      final i = ComplexValue(rat(0), rat(1));
      expect(i.multiply(i), rat(-1));
    });

    test('conjugates multiply to a real number', () {
      final a = ComplexValue(rat(3), rat(4));
      final b = ComplexValue(rat(3), rat(-4));
      expect(a.multiply(b), rat(25));
    });

    test('complex division works out exactly', () {
      // (3+4i)/(1+2i) = (11 - 2i)/5
      final result = ComplexValue(rat(3), rat(4))
          .divide(ComplexValue(rat(1), rat(2))) as ComplexValue;
      expect(result.real, rat(11, 5));
      expect(result.imaginary, rat(-2, 5));
    });

    test('an imaginary part that cancels collapses back to a real value', () {
      final sum = ComplexValue(rat(2), rat(3)).add(ComplexValue(rat(1), rat(-3)));
      expect(sum, rat(3));
      expect(sum, isNot(isA<ComplexValue>()));
    });

    test('a negative base with a fractional exponent goes complex, not NaN', () {
      final result = const RealValue(-8).power(rat(1, 2));
      expect(result, isA<ComplexValue>());
    });
  });

  group('parsing literals', () {
    test('plain integers', () {
      expect(NumberValue.parse('42'), rat(42));
    });

    test('decimals become exact fractions', () {
      expect(NumberValue.parse('0.25'), rat(1, 4));
      expect(NumberValue.parse('1.5'), rat(3, 2));
    });

    test('scientific notation stays exact', () {
      expect(NumberValue.parse('1.5e3'), rat(1500));
      expect(NumberValue.parse('2e-2'), rat(1, 50));
    });

    test('very large integers survive without precision loss', () {
      final huge = NumberValue.parse('123456789012345678901234567890');
      expect(huge.isExact, isTrue);
      expect(huge.toString(), '123456789012345678901234567890');
    });

    test('garbage throws a typed error', () {
      expect(() => NumberValue.parse('nonsense'), throwsA(isA<MathError>()));
      expect(() => NumberValue.parse(''), throwsA(isA<MathError>()));
    });
  });

  group('error handling', () {
    test('0^0 is reported as undefined rather than guessed', () {
      expect(
        () => rat(0).power(rat(0)),
        throwsA(isA<MathError>().having((e) => e.kind, 'kind', MathErrorKind.undefined)),
      );
    });

    test('overflow is reported rather than returning infinity', () {
      expect(
        () => const RealValue(1e308).multiply(const RealValue(1e10)),
        throwsA(isA<MathError>().having((e) => e.kind, 'kind', MathErrorKind.overflow)),
      );
    });
  });
}
