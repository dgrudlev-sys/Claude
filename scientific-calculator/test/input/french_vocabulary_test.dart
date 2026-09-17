import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/input/language/french_vocabulary.dart';
import 'package:scientific_calculator/input/voice/spoken_math_parser.dart';

void main() {
  const french = FrenchMathVocabulary();
  const numbers = FrenchNumberParser();
  const spoken = SpokenMathParser(vocabulary: french);
  const evaluator = Evaluator();
  const parser = ExpressionParser();

  String digitsOf(String phrase) =>
      numbers.parseAt(phrase.split(' '), 0)!.digits;

  NumberValue say(String phrase) =>
      evaluator.evaluate(spoken.parse(phrase).expression);

  group('French numbers, which are partly counted in twenties', () {
    test('units and the teens that have their own words', () {
      expect(digitsOf('sept'), '7');
      expect(digitsOf('seize'), '16');
    });

    test('seventeen upward are compounds, not words', () {
      expect(digitsOf('dix-sept'), '17');
      expect(digitsOf('dix-neuf'), '19');
    });

    test('the vigesimal tens', () {
      // 60 + 10, not a word of its own.
      expect(digitsOf('soixante-dix'), '70');
      expect(digitsOf('soixante-quinze'), '75');
      // 4 × 20 — the one multiplicative compound in the language.
      expect(digitsOf('quatre-vingts'), '80');
      expect(digitsOf('quatre-vingt-quatre'), '84');
      // 4 × 20 + 10.
      expect(digitsOf('quatre-vingt-dix'), '90');
      expect(digitsOf('quatre-vingt-dix-neuf'), '99');
    });

    test('hyphenated or spaced, both are read the same way', () {
      expect(digitsOf('quatre-vingt-dix-neuf'), '99');
      expect(digitsOf('quatre vingt dix neuf'), '99');
      expect(numbers.parseAt('quatre-vingt-dix-neuf'.split(' '), 0)!.wordsConsumed, 1);
      expect(numbers.parseAt('quatre vingt dix neuf'.split(' '), 0)!.wordsConsumed, 4);
    });

    test('the joining "et" carries no value', () {
      expect(digitsOf('vingt et un'), '21');
      expect(digitsOf('soixante et onze'), '71');
    });

    test('hundreds and thousands', () {
      expect(digitsOf('cent'), '100');
      expect(digitsOf('deux cents'), '200');
      expect(digitsOf('cent vingt-cinq'), '125');
      expect(digitsOf('mille'), '1000');
      expect(digitsOf('deux mille cinq cents'), '2500');
      expect(digitsOf('mille neuf cent quatre-vingt-quatre'), '1984');
    });

    test('Belgian and Swiss forms are accepted too', () {
      // Regular exactly where standard French turns vigesimal.
      expect(digitsOf('septante-cinq'), '75');
      expect(digitsOf('nonante-neuf'), '99');
      expect(digitsOf('huitante'), '80');
    });

    test('a decimal uses a comma, as it is written', () {
      final parsed = numbers.parseAt(['trois', 'virgule', 'un', 'quatre'], 0)!;
      expect(parsed.digits, '3.14');
      expect(parsed.wordsConsumed, 4);
    });

    test('a repeated unit starts a new number rather than adding', () {
      // "cinq cinq" is two numbers, not ten.
      expect(numbers.parseAt(['cinq', 'cinq'], 0)!.wordsConsumed, 1);
    });

    test('a non-number word yields nothing', () {
      expect(numbers.parseAt(['plus'], 0), isNull);
    });
  });

  group('French spoken arithmetic', () {
    test('the four operations', () {
      expect(say('trois plus quatre'), RationalValue.fromInt(7));
      expect(say('dix moins quatre'), RationalValue.fromInt(6));
      expect(say('six fois sept'), RationalValue.fromInt(42));
      expect(say('dix divisé par quatre'),
          RationalValue(BigInt.from(5), BigInt.from(2)));
    });

    test('precedence is the shared parser\'s', () {
      expect(say('trois plus quatre fois deux'), RationalValue.fromInt(11));
    });

    test('vigesimal numbers survive a whole expression', () {
      expect(say('quatre-vingt-dix-neuf plus un'), RationalValue.fromInt(100));
      expect(say('soixante-quinze moins vingt-cinq'), RationalValue.fromInt(50));
    });

    test('powers and roots', () {
      expect(say('cinq au carré'), RationalValue.fromInt(25));
      expect(say('deux puissance dix'), RationalValue.fromInt(1024));
      expect(say('racine carrée de seize'), RationalValue.fromInt(4));
      expect(say('racine de neuf'), RationalValue.fromInt(3));
    });

    test('filler words are dropped', () {
      expect(say('combien font trois plus quatre'), RationalValue.fromInt(7));
      expect(say('calcule trois plus quatre s\'il vous plaît'),
          RationalValue.fromInt(7));
    });

    test('parentheses', () {
      expect(
        say('parenthèse ouvrante trois plus quatre parenthèse fermante fois deux'),
        RationalValue.fromInt(14),
      );
    });

    test('"pour cent" is a percentage, not a hundred', () {
      // "cent" alone is 100, so this had to be matched as a phrase first.
      expect(say('cinquante pour cent'),
          RationalValue(BigInt.one, BigInt.two));
    });

    test('exactness survives French input', () {
      expect(
        say('un divisé par trois plus un divisé par trois '
            'plus un divisé par trois'),
        RationalValue.fromInt(1),
      );
    });
  });

  group('French speech output', () {
    const renderer = SpeechRenderer(vocabulary: french);

    test('operators', () {
      expect(renderer.render(parser.parse('3+4')), '3 plus 4');
      expect(renderer.render(parser.parse('6/2')), '6 divisé par 2');
      expect(renderer.render(parser.parse('6*2')), '6 fois 2');
    });

    test('powers and roots', () {
      expect(renderer.render(parser.parse('x^2')), 'x au carré');
      expect(renderer.render(parser.parse('x^5')), 'x puissance 5');
      expect(renderer.render(parser.parse('sqrt(9)')), 'racine carrée de 9');
      expect(
        renderer.render(parser.parse('sqrt(x+1)')),
        'racine carrée de x plus 1, fin de racine',
      );
    });

    test('functions use the French joining word', () {
      expect(renderer.render(parser.parse('sin(x)')), 'sinus de x');
      expect(
        renderer.render(parser.parse('ln(x+1)')),
        'logarithme népérien de x plus 1, fin de logarithme népérien',
      );
    });

    test('decimals are read with a comma', () {
      expect(renderer.render(parser.parse('3.14')), '3 virgule 1 4');
    });

    test('fractions inflect the French way', () {
      // "quart" takes a plural s; "tiers" is invariable and already
      // ends in one, which is why the naming is a function.
      expect(
        renderer.render(const FractionNode(NumberNode('3'), NumberNode('4'))),
        '3 quarts',
      );
      expect(
        renderer.render(const FractionNode(NumberNode('2'), NumberNode('3'))),
        '2 tiers',
      );
      expect(
        renderer.render(const FractionNode(NumberNode('1'), NumberNode('2'))),
        'un demi',
      );
    });
  });
}
