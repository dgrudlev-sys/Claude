import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/input/language/danish_vocabulary.dart';
import 'package:scientific_calculator/input/voice/spoken_math_parser.dart';

void main() {
  const danish = DanishMathVocabulary();
  const numbers = DanishNumberParser();
  const spoken = SpokenMathParser(vocabulary: danish);
  const evaluator = Evaluator();
  const parser = ExpressionParser();

  String digitsOf(String word) => numbers.parseAt([word], 0)!.digits;

  NumberValue say(String phrase) =>
      evaluator.evaluate(spoken.parse(phrase).expression);

  group('Danish numbers, which are vigesimal and reversed at once', () {
    test('units and teens', () {
      expect(digitsOf('syv'), '7');
      expect(digitsOf('tolv'), '12');
      expect(digitsOf('seksten'), '16');
    });

    test('the tens above forty are counted in twenties', () {
      // tres is 3 × 20; halvtreds is "half-third" × 20, meaning 2½ × 20.
      expect(digitsOf('tyve'), '20');
      expect(digitsOf('fyrre'), '40');
      expect(digitsOf('halvtreds'), '50');
      expect(digitsOf('tres'), '60');
      expect(digitsOf('halvfjerds'), '70');
      expect(digitsOf('firs'), '80');
      expect(digitsOf('halvfems'), '90');
    });

    test('"halvtreds" contains "tres" and must not be misread', () {
      // 50 has 60 sitting inside it as a substring. Searching for known
      // words inside a token — the approach that seems to work — would
      // read this as something built out of sixty.
      expect(digitsOf('halvtreds'), '50');
      expect(digitsOf('tres'), '60');
    });

    test('compounds put the unit first and join with og, in one word', () {
      expect(digitsOf('femogtyve'), '25');
      expect(digitsOf('enogtyve'), '21');
      expect(digitsOf('femoghalvfjerds'), '75');
      expect(digitsOf('enoghalvfems'), '91');
      expect(digitsOf('otteogfirs'), '88');
    });

    test('hundreds and thousands fold into the same word', () {
      expect(digitsOf('hundrede'), '100');
      expect(digitsOf('tohundrede'), '200');
      expect(digitsOf('tohundredeogfem'), '205');
      expect(digitsOf('tusind'), '1000');
      expect(digitsOf('totusind'), '2000');
      expect(digitsOf('femtusindsekshundrede'), '5600');
    });

    test('the separated form works too', () {
      final parsed = numbers.parseAt(['to', 'hundrede', 'og', 'fem'], 1);
      expect(parsed!.digits, '105');
      expect(parsed.wordsConsumed, 3);
    });

    test('a decimal uses a comma', () {
      final parsed = numbers.parseAt(['tre', 'komma', 'en', 'fire'], 0)!;
      expect(parsed.digits, '3.14');
      expect(parsed.wordsConsumed, 4);
    });

    test('a non-number word yields nothing', () {
      expect(numbers.parseAt(['plus'], 0), isNull);
    });
  });

  group('Danish spoken arithmetic', () {
    test('the four operations', () {
      expect(say('tre plus fire'), RationalValue.fromInt(7));
      expect(say('ti minus fire'), RationalValue.fromInt(6));
      expect(say('seks gange syv'), RationalValue.fromInt(42));
      expect(say('ti divideret med fire'),
          RationalValue(BigInt.from(5), BigInt.from(2)));
    });

    test('precedence', () {
      expect(say('tre plus fire gange to'), RationalValue.fromInt(11));
    });

    test('vigesimal compounds survive a whole expression', () {
      expect(say('femogtyve plus sytten'), RationalValue.fromInt(42));
      expect(say('femoghalvfjerds minus femogtyve'), RationalValue.fromInt(50));
      expect(say('enoghalvfems plus ni'), RationalValue.fromInt(100));
    });

    test('powers and roots', () {
      expect(say('fem i anden'), RationalValue.fromInt(25));
      expect(say('to opløftet i ti'), RationalValue.fromInt(1024));
      expect(say('kvadratroden af seksten'), RationalValue.fromInt(4));
      expect(say('roden af ni'), RationalValue.fromInt(3));
    });

    test('filler words are dropped', () {
      expect(say('hvad er tre plus fire'), RationalValue.fromInt(7));
      expect(say('beregn venligst tre plus fire'), RationalValue.fromInt(7));
    });

    test('parentheses', () {
      expect(
        say('parentes start tre plus fire parentes slut gange to'),
        RationalValue.fromInt(14),
      );
    });

    test('exactness survives Danish input', () {
      expect(
        say('en divideret med tre plus en divideret med tre '
            'plus en divideret med tre'),
        RationalValue.fromInt(1),
      );
    });
  });

  group('Danish speech output', () {
    const renderer = SpeechRenderer(vocabulary: danish);

    test('operators', () {
      expect(renderer.render(parser.parse('3+4')), '3 plus 4');
      expect(renderer.render(parser.parse('6/2')), '6 divideret med 2');
      expect(renderer.render(parser.parse('6*2')), '6 gange 2');
    });

    test('powers and roots', () {
      expect(renderer.render(parser.parse('x^2')), 'x i anden');
      expect(renderer.render(parser.parse('x^5')), 'x opløftet i 5');
      expect(renderer.render(parser.parse('sqrt(9)')), 'kvadratroden af 9');
      expect(
        renderer.render(parser.parse('sqrt(x+1)')),
        'kvadratroden af x plus 1, rod slut',
      );
    });

    test('functions close with a trailing marker', () {
      expect(renderer.render(parser.parse('sin(x)')), 'sinus af x');
      expect(
        renderer.render(parser.parse('ln(x+1)')),
        'naturlig logaritme af x plus 1, naturlig logaritme slut',
      );
    });

    test('decimals are read with a comma', () {
      expect(renderer.render(parser.parse('3.14')), '3 komma 1 4');
    });

    test('fractions', () {
      expect(
        renderer.render(const FractionNode(NumberNode('3'), NumberNode('4'))),
        '3 fjerdedele',
      );
      expect(
        renderer.render(const FractionNode(NumberNode('1'), NumberNode('2'))),
        'en halv',
      );
    });
  });
}
