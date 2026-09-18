import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/input/language/swedish_vocabulary.dart';
import 'package:scientific_calculator/input/voice/spoken_math_parser.dart';

void main() {
  const swedish = SwedishMathVocabulary();
  const numbers = SwedishNumberParser();
  const spoken = SpokenMathParser(vocabulary: swedish);
  const evaluator = Evaluator();
  const parser = ExpressionParser();

  String digitsOf(String word) => numbers.parseAt([word], 0)!.digits;

  NumberValue say(String phrase) =>
      evaluator.evaluate(spoken.parse(phrase).expression);

  group('Swedish numbers, compounded in the order they are written', () {
    test('units and teens', () {
      expect(digitsOf('sju'), '7');
      expect(digitsOf('tolv'), '12');
      expect(digitsOf('sexton'), '16');
      expect(digitsOf('åtta'), '8');
    });

    test('the ten comes first, unlike Danish and German', () {
      // Swedish tjugofem is 20-5; Danish femogtyve is 5-and-20.
      expect(digitsOf('tjugofem'), '25');
      expect(digitsOf('trettiotvå'), '32');
      expect(digitsOf('nittionio'), '99');
    });

    test('a tens word that starts with a unit is still read as the ten', () {
      // "sextiosex" begins with both "sex" and "sextio", and only the
      // longer reading leaves a remainder that parses.
      expect(digitsOf('sextiosex'), '66');
      expect(digitsOf('sextio'), '60');
      expect(digitsOf('sex'), '6');
    });

    test('accents are optional, because recognisers drop them', () {
      expect(digitsOf('tva'), '2');
      expect(digitsOf('två'), '2');
      expect(digitsOf('atta'), '8');
    });

    test('hundreds and thousands fold into the same word', () {
      expect(digitsOf('hundra'), '100');
      expect(digitsOf('tvåhundra'), '200');
      expect(digitsOf('etthundratjugofem'), '125');
      expect(digitsOf('tusen'), '1000');
      expect(digitsOf('tiotusen'), '10000');
      expect(digitsOf('tvåtusenfemhundra'), '2500');
    });

    test('the separated form works too', () {
      final parsed = numbers.parseAt(['hundra', 'och', 'fem'], 0)!;
      expect(parsed.digits, '105');
      expect(parsed.wordsConsumed, 3);
    });

    test('a decimal uses a comma', () {
      final parsed = numbers.parseAt(['tre', 'komma', 'ett', 'fyra'], 0)!;
      expect(parsed.digits, '3.14');
      expect(parsed.wordsConsumed, 4);
    });

    test('a non-number word yields nothing', () {
      expect(numbers.parseAt(['plus'], 0), isNull);
    });
  });

  group('Swedish spoken arithmetic', () {
    test('the four operations', () {
      expect(say('tre plus fyra'), RationalValue.fromInt(7));
      expect(say('tio minus fyra'), RationalValue.fromInt(6));
      expect(say('sex gånger sju'), RationalValue.fromInt(42));
      expect(say('tio delat med fyra'),
          RationalValue(BigInt.from(5), BigInt.from(2)));
    });

    test('precedence', () {
      expect(say('tre plus fyra gånger två'), RationalValue.fromInt(11));
    });

    test('compounds survive a whole expression', () {
      expect(say('tjugofem plus sjutton'), RationalValue.fromInt(42));
      expect(say('etthundratjugofem minus tjugofem'),
          RationalValue.fromInt(100));
      expect(say('nittionio plus ett'), RationalValue.fromInt(100));
    });

    test('powers and roots', () {
      expect(say('fem i kvadrat'), RationalValue.fromInt(25));
      expect(say('två upphöjt till tio'), RationalValue.fromInt(1024));
      expect(say('kvadratroten ur sexton'), RationalValue.fromInt(4));
      expect(say('roten ur nio'), RationalValue.fromInt(3));
    });

    test('filler words are dropped', () {
      expect(say('vad är tre plus fyra'), RationalValue.fromInt(7));
      expect(say('beräkna snälla tre plus fyra'), RationalValue.fromInt(7));
    });

    test('parentheses', () {
      expect(
        say('parentes börjar tre plus fyra parentes slutar gånger två'),
        RationalValue.fromInt(14),
      );
    });

    test('exactness survives Swedish input', () {
      expect(
        say('ett delat med tre plus ett delat med tre '
            'plus ett delat med tre'),
        RationalValue.fromInt(1),
      );
    });
  });

  group('Swedish speech output', () {
    const renderer = SpeechRenderer(vocabulary: swedish);

    test('operators', () {
      expect(renderer.render(parser.parse('3+4')), '3 plus 4');
      expect(renderer.render(parser.parse('6/2')), '6 delat med 2');
      expect(renderer.render(parser.parse('6*2')), '6 gånger 2');
    });

    test('powers and roots', () {
      expect(renderer.render(parser.parse('x^2')), 'x i kvadrat');
      expect(renderer.render(parser.parse('x^5')), 'x upphöjt till 5');
      expect(renderer.render(parser.parse('sqrt(9)')), 'kvadratroten ur 9');
      expect(
        renderer.render(parser.parse('sqrt(x+1)')),
        'kvadratroten ur x plus 1, slut rot',
      );
    });

    test('functions close with a leading marker', () {
      expect(renderer.render(parser.parse('sin(x)')), 'sinus av x');
      expect(
        renderer.render(parser.parse('ln(x+1)')),
        'naturliga logaritmen av x plus 1, slut naturliga logaritmen',
      );
    });

    test('decimals are read with a comma', () {
      expect(renderer.render(parser.parse('3.14')), '3 komma 1 4');
    });

    test('fractions', () {
      expect(
        renderer.render(const FractionNode(NumberNode('3'), NumberNode('4'))),
        '3 fjärdedelar',
      );
      expect(
        renderer.render(const FractionNode(NumberNode('1'), NumberNode('2'))),
        'en halv',
      );
    });
  });
}
