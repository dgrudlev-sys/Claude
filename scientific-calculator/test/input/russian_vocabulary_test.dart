import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/input/language/russian_vocabulary.dart';
import 'package:scientific_calculator/input/voice/spoken_math_parser.dart';

void main() {
  const russian = RussianMathVocabulary();
  const numbers = RussianNumberParser();
  const spoken = SpokenMathParser(vocabulary: russian);
  const evaluator = Evaluator();
  const parser = ExpressionParser();

  String digitsOf(String phrase) =>
      numbers.parseAt(phrase.split(' '), 0)!.digits;

  NumberValue say(String phrase) =>
      evaluator.evaluate(spoken.parse(phrase).expression);

  group('Russian numbers, which inflect rather than compound', () {
    test('units and teens', () {
      expect(digitsOf('семь'), '7');
      expect(digitsOf('семнадцать'), '17');
    });

    test('the irregular tens', () {
      // Neither follows the -дцать or -десят pattern of the others.
      expect(digitsOf('сорок'), '40');
      expect(digitsOf('девяносто'), '90');
      expect(digitsOf('пятьдесят'), '50');
    });

    test('parts arrive in descending order', () {
      expect(digitsOf('двадцать пять'), '25');
      expect(digitsOf('девяносто девять'), '99');
      expect(digitsOf('сто двадцать пять'), '125');
      expect(digitsOf('двести пятьдесят три'), '253');
    });

    test('thousands agree with what they count', () {
      // одна тысяча, две тысячи, пять тысяч — three forms, one value.
      expect(digitsOf('тысяча'), '1000');
      expect(digitsOf('две тысячи'), '2000');
      expect(digitsOf('пять тысяч'), '5000');
      expect(digitsOf('тысяча девятьсот восемьдесят четыре'), '1984');
    });

    test('gendered forms of one and two are both accepted', () {
      expect(digitsOf('один'), '1');
      expect(digitsOf('одна'), '1');
      expect(digitsOf('два'), '2');
      expect(digitsOf('две'), '2');
    });

    test('oblique forms are accepted, which is what follows a preposition', () {
      // "корень из шестнадцати" — genitive, not nominative. Without
      // these, every root in Russian would fail to parse.
      expect(digitsOf('шестнадцати'), '16');
      expect(digitsOf('девяти'), '9');
      expect(digitsOf('двадцати пяти'), '25');
      expect(digitsOf('ста'), '100');
    });

    test('a decimal uses a comma', () {
      final parsed = numbers.parseAt(['три', 'запятая', 'один', 'четыре'], 0)!;
      expect(parsed.digits, '3.14');
      expect(parsed.wordsConsumed, 4);
    });

    test('a non-number word yields nothing', () {
      expect(numbers.parseAt(['плюс'], 0), isNull);
    });
  });

  group('Russian spoken arithmetic', () {
    test('the four operations', () {
      expect(say('три плюс четыре'), RationalValue.fromInt(7));
      expect(say('десять минус четыре'), RationalValue.fromInt(6));
      expect(say('шесть умножить на семь'), RationalValue.fromInt(42));
      expect(say('десять разделить на четыре'),
          RationalValue(BigInt.from(5), BigInt.from(2)));
    });

    test('precedence', () {
      expect(say('три плюс четыре умножить на два'), RationalValue.fromInt(11));
    });

    test('compound numbers in a full expression', () {
      expect(say('двадцать пять плюс семнадцать'), RationalValue.fromInt(42));
      expect(say('сто двадцать пять минус двадцать пять'),
          RationalValue.fromInt(100));
    });

    test('powers and roots, where the number turns genitive', () {
      expect(say('пять в квадрате'), RationalValue.fromInt(25));
      expect(say('два в степени десять'), RationalValue.fromInt(1024));
      expect(say('квадратный корень из шестнадцати'), RationalValue.fromInt(4));
      expect(say('корень из девяти'), RationalValue.fromInt(3));
    });

    test('filler words are dropped', () {
      expect(say('сколько будет три плюс четыре'), RationalValue.fromInt(7));
      expect(say('вычисли пожалуйста три плюс четыре'),
          RationalValue.fromInt(7));
    });

    test('parentheses', () {
      expect(
        say('открыть скобку три плюс четыре закрыть скобку умножить на два'),
        RationalValue.fromInt(14),
      );
    });

    test('exactness survives Russian input', () {
      expect(
        say('один разделить на три плюс один разделить на три '
            'плюс один разделить на три'),
        RationalValue.fromInt(1),
      );
    });
  });

  group('Russian speech output', () {
    const renderer = SpeechRenderer(vocabulary: russian);

    test('operators', () {
      expect(renderer.render(parser.parse('3+4')), '3 плюс 4');
      expect(renderer.render(parser.parse('6/2')), '6 разделить на 2');
      expect(renderer.render(parser.parse('6*2')), '6 умножить на 2');
    });

    test('powers and roots', () {
      expect(renderer.render(parser.parse('x^2')), 'x в квадрате');
      expect(renderer.render(parser.parse('x^5')), 'x в степени 5');
      expect(renderer.render(parser.parse('sqrt(9)')),
          'квадратный корень из 9');
      expect(
        renderer.render(parser.parse('sqrt(x+1)')),
        'квадратный корень из x плюс 1, конец корня',
      );
    });

    test('functions use the Russian joining word', () {
      expect(renderer.render(parser.parse('sin(x)')), 'синус от x');
      expect(
        renderer.render(parser.parse('ln(x+1)')),
        'натуральный логарифм от x плюс 1, натуральный логарифм конец',
      );
    });

    test('decimals are read with a comma', () {
      expect(renderer.render(parser.parse('3.14')), '3 запятая 1 4');
    });

    test('fractions take an ordinal that agrees with the numerator', () {
      expect(
        renderer.render(const FractionNode(NumberNode('1'), NumberNode('2'))),
        'одна вторая',
      );
      expect(
        renderer.render(const FractionNode(NumberNode('3'), NumberNode('4'))),
        '3 четвёртых',
      );
    });
  });
}
