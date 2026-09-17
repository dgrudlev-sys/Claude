import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/input/voice/number_words.dart';
import 'package:scientific_calculator/input/voice/spoken_math_parser.dart';

void main() {
  const numbers = NumberWordParser();
  const spoken = SpokenMathParser();
  const evaluator = Evaluator();

  String digitsOf(String phrase) {
    final words = phrase.split(' ');
    return numbers.parseAt(words, 0)!.digits;
  }

  /// Parses a spoken phrase and evaluates it, which is the whole point:
  /// speech lands in the same Expression Model as everything else.
  NumberValue say(String phrase) =>
      evaluator.evaluate(spoken.parse(phrase).expression);

  group('number words', () {
    test('units and teens', () {
      expect(digitsOf('seven'), '7');
      expect(digitsOf('seventeen'), '17');
    });

    test('compound tens', () {
      expect(digitsOf('twenty five'), '25');
      expect(digitsOf('ninety nine'), '99');
    });

    test('hundreds and thousands', () {
      expect(digitsOf('three hundred'), '300');
      expect(digitsOf('three hundred forty two'), '342');
      expect(digitsOf('two thousand'), '2000');
      expect(digitsOf('twelve thousand five hundred'), '12500');
    });

    test('"and" inside a number is absorbed', () {
      expect(digitsOf('one hundred and five'), '105');
    });

    test('decimals are read digit by digit after "point"', () {
      expect(digitsOf('three point one four'), '3.14');
      expect(digitsOf('zero point five'), '0.5');
    });

    test('a non-number word yields nothing', () {
      expect(numbers.parseAt(['plus'], 0), isNull);
    });
  });

  group('spoken arithmetic', () {
    test('simple sums', () {
      expect(say('three plus four'), RationalValue.fromInt(7));
      expect(say('ten minus four'), RationalValue.fromInt(6));
    });

    test('precedence is the parser\'s, not the order spoken', () {
      expect(say('three plus four times two'), RationalValue.fromInt(11));
    });

    test('spoken parentheses group correctly', () {
      expect(
        say('open paren three plus four close paren times two'),
        RationalValue.fromInt(14),
      );
    });

    test('division phrasings', () {
      expect(say('ten divided by four'), RationalValue(BigInt.from(5), BigInt.from(2)));
      expect(say('ten over four'), RationalValue(BigInt.from(5), BigInt.from(2)));
    });

    test('filler words are ignored', () {
      expect(say('what is three plus four'), RationalValue.fromInt(7));
      expect(say('calculate three plus four please'), RationalValue.fromInt(7));
    });

    test('powers spoken as squared and cubed', () {
      expect(say('five squared'), RationalValue.fromInt(25));
      expect(say('two cubed'), RationalValue.fromInt(8));
    });

    test('explicit powers', () {
      expect(say('two to the power of ten'), RationalValue.fromInt(1024));
    });

    test('roots', () {
      expect(say('square root of sixteen'), RationalValue.fromInt(4));
      expect(say('cube root of twenty seven'), RationalValue.fromInt(3));
    });

    test('percent and factorial', () {
      expect(say('fifty percent'), RationalValue(BigInt.one, BigInt.two));
      expect(say('five factorial'), RationalValue.fromInt(120));
    });

    test('trig functions', () {
      expect(say('sine of zero'), const RealValue(0.0));
    });

    test('large spoken numbers stay exact', () {
      expect(say('twelve thousand five hundred plus one'),
          RationalValue.fromInt(12501));
    });
  });

  group('ambiguity is surfaced, not guessed at', () {
    test('"square root of nine plus four" offers both readings', () {
      final result = spoken.parse('square root of nine plus four');

      // The default is the tight reading: sqrt(9) + 4 = 7.
      expect(evaluator.evaluate(result.expression), RationalValue.fromInt(7));
      expect(result.needsConfirmation, isTrue);

      final alternative = result.ambiguities.single.alternative;
      // The other reading is sqrt(9 + 4), which is not a whole number.
      expect(evaluator.evaluate(alternative).toDouble(), closeTo(3.6055, 1e-3));
    });

    test('the ambiguity carries both readings spoken aloud for confirmation', () {
      final result = spoken.parse('square root of nine plus four');
      final ambiguity = result.ambiguities.single;
      expect(ambiguity.chosenReading, contains('square root of 9'));
      expect(ambiguity.alternativeReading, contains('plus 4'));
      expect(ambiguity.reason, contains('inside'));
    });

    test('an unambiguous root needs no confirmation', () {
      final result = spoken.parse('square root of sixteen');
      expect(result.needsConfirmation, isFalse);
    });

    test('explicit spoken parentheses remove the ambiguity', () {
      final result =
          spoken.parse('square root of open paren nine plus sixteen close paren');
      expect(evaluator.evaluate(result.expression), RationalValue.fromInt(5));
      expect(result.needsConfirmation, isFalse);
    });
  });

  group('confirmation and transparency', () {
    test('the normalized source shows what was understood', () {
      final result = spoken.parse('three plus four times two');
      expect(result.normalizedSource, '3+4*2');
    });

    test('the confirmation reads the expression back in words', () {
      final result = spoken.parse('five squared');
      expect(result.confirmation, '5 squared');
    });
  });

  group('errors', () {
    test('an unrecognised word reports what it heard', () {
      try {
        spoken.parse('three plus banana');
        fail('should have thrown');
      } on SpokenMathError catch (e) {
        expect(e.message, contains('banana'));
        expect(e.heardAs, 'three plus banana');
      }
    });

    test('empty input is reported', () {
      expect(() => spoken.parse('   '), throwsA(isA<SpokenMathError>()));
    });

    test('a phrase that is not maths fails cleanly', () {
      expect(() => spoken.parse('plus times'), throwsA(isA<SpokenMathError>()));
    });
  });

  group('variables', () {
    test('single letters become variables', () {
      final result = spoken.parse('two x plus one');
      expect(result.normalizedSource, '2x+1');
      expect(
        evaluator
            .evaluate(result.expression,
                const EvaluationContext(variables: {'x': RealValue(5)}))
            .toDouble(),
        closeTo(11, 1e-12),
      );
    });
  });
}
