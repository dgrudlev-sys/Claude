import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/input/language/spanish_vocabulary.dart';
import 'package:scientific_calculator/input/voice/spoken_math_parser.dart';

void main() {
  const spanish = SpanishMathVocabulary();
  const numbers = SpanishNumberParser();
  const spoken = SpokenMathParser(vocabulary: spanish);
  const evaluator = Evaluator();
  const parser = ExpressionParser();

  String digitsOf(String phrase) =>
      numbers.parseAt(phrase.split(' '), 0)!.digits;

  NumberValue say(String phrase) =>
      evaluator.evaluate(spoken.parse(phrase).expression);

  group('Spanish numbers, fused in the twenties and named in the hundreds', () {
    test('units and teens', () {
      expect(digitsOf('siete'), '7');
      expect(digitsOf('quince'), '15');
    });

    test('sixteen to nineteen are single fused words', () {
      expect(digitsOf('dieciséis'), '16');
      expect(digitsOf('diecinueve'), '19');
    });

    test('accents are optional, because recognisers drop them', () {
      expect(digitsOf('dieciseis'), '16');
      expect(digitsOf('veintidos'), '22');
      expect(digitsOf('veintidós'), '22');
    });

    test('the whole of the twenties fuses, but the thirties do not', () {
      expect(digitsOf('veinticinco'), '25');
      expect(numbers.parseAt(['veinticinco'], 0)!.wordsConsumed, 1);
      // Three words for the same shape of number.
      expect(digitsOf('treinta y cinco'), '35');
      expect(numbers.parseAt('treinta y cinco'.split(' '), 0)!.wordsConsumed, 3);
    });

    test('hundreds are named outright, and irregular at 500, 700 and 900', () {
      expect(digitsOf('cien'), '100');
      expect(digitsOf('quinientos'), '500');
      expect(digitsOf('setecientos'), '700');
      expect(digitsOf('novecientos'), '900');
      expect(digitsOf('doscientas'), '200');
    });

    test('combinations descend through the ranks', () {
      expect(digitsOf('ciento veinticinco'), '125');
      expect(digitsOf('doscientos cincuenta y tres'), '253');
      expect(digitsOf('mil'), '1000');
      expect(digitsOf('dos mil quinientos'), '2500');
      expect(digitsOf('mil novecientos ochenta y cuatro'), '1984');
    });

    test('a decimal uses a comma', () {
      final parsed = numbers.parseAt(['tres', 'coma', 'uno', 'cuatro'], 0)!;
      expect(parsed.digits, '3.14');
      expect(parsed.wordsConsumed, 4);
    });

    test('nothing follows a fused twenty', () {
      // "veinticinco tres" is two numbers, not 28.
      expect(numbers.parseAt(['veinticinco', 'tres'], 0)!.wordsConsumed, 1);
    });

    test('a non-number word yields nothing', () {
      expect(numbers.parseAt(['más'], 0), isNull);
    });
  });

  group('Spanish spoken arithmetic', () {
    test('the four operations', () {
      expect(say('tres más cuatro'), RationalValue.fromInt(7));
      expect(say('diez menos cuatro'), RationalValue.fromInt(6));
      expect(say('seis por siete'), RationalValue.fromInt(42));
      expect(say('diez entre cuatro'),
          RationalValue(BigInt.from(5), BigInt.from(2)));
      expect(say('diez dividido entre cuatro'),
          RationalValue(BigInt.from(5), BigInt.from(2)));
    });

    test('precedence', () {
      expect(say('tres más cuatro por dos'), RationalValue.fromInt(11));
    });

    test('compound numbers in a full expression', () {
      expect(say('veinticinco más diecisiete'), RationalValue.fromInt(42));
      expect(say('ciento veinticinco menos veinticinco'),
          RationalValue.fromInt(100));
    });

    test('powers and roots', () {
      expect(say('cinco al cuadrado'), RationalValue.fromInt(25));
      expect(say('dos elevado a diez'), RationalValue.fromInt(1024));
      expect(say('raíz cuadrada de dieciséis'), RationalValue.fromInt(4));
      expect(say('raíz de nueve'), RationalValue.fromInt(3));
    });

    test('filler words are dropped', () {
      expect(say('cuánto es tres más cuatro'), RationalValue.fromInt(7));
      expect(say('calcula tres más cuatro por favor'), RationalValue.fromInt(7));
    });

    test('parentheses', () {
      expect(
        say('abrir paréntesis tres más cuatro cerrar paréntesis por dos'),
        RationalValue.fromInt(14),
      );
    });

    test('"por ciento" is a percentage, and bare "por" is multiplication', () {
      expect(say('cincuenta por ciento'), RationalValue(BigInt.one, BigInt.two));
      expect(say('cincuenta por dos'), RationalValue.fromInt(100));
    });

    test('exactness survives Spanish input', () {
      expect(
        say('uno entre tres más uno entre tres más uno entre tres'),
        RationalValue.fromInt(1),
      );
    });
  });

  group('Spanish speech output', () {
    const renderer = SpeechRenderer(vocabulary: spanish);

    test('operators', () {
      expect(renderer.render(parser.parse('3+4')), '3 más 4');
      expect(renderer.render(parser.parse('6/2')), '6 entre 2');
      expect(renderer.render(parser.parse('6*2')), '6 por 2');
    });

    test('powers and roots', () {
      expect(renderer.render(parser.parse('x^2')), 'x al cuadrado');
      expect(renderer.render(parser.parse('x^5')), 'x elevado a 5');
      expect(renderer.render(parser.parse('sqrt(9)')), 'raíz cuadrada de 9');
      expect(
        renderer.render(parser.parse('sqrt(x+1)')),
        'raíz cuadrada de x más 1, fin de raíz',
      );
    });

    test('functions', () {
      expect(renderer.render(parser.parse('sin(x)')), 'seno de x');
      expect(
        renderer.render(parser.parse('ln(x+1)')),
        'logaritmo natural de x más 1, fin de logaritmo natural',
      );
    });

    test('decimals are read with a comma', () {
      expect(renderer.render(parser.parse('3.14')), '3 coma 1 4');
    });

    test('fractions', () {
      expect(
        renderer.render(const FractionNode(NumberNode('3'), NumberNode('4'))),
        '3 cuartos',
      );
      expect(
        renderer.render(const FractionNode(NumberNode('1'), NumberNode('2'))),
        'un medio',
      );
    });
  });
}
