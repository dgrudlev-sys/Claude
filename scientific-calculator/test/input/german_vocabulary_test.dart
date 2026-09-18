import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/expression.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/input/language/english_vocabulary.dart';
import 'package:scientific_calculator/input/language/german_vocabulary.dart';
import 'package:scientific_calculator/input/language/math_vocabulary.dart';
import 'package:scientific_calculator/input/language/vocabularies.dart';
import 'package:scientific_calculator/input/voice/spoken_math_parser.dart';

void main() {
  const german = GermanMathVocabulary();
  const numbers = GermanNumberParser();
  const spoken = SpokenMathParser(vocabulary: german);
  const evaluator = Evaluator();
  const parser = ExpressionParser();

  String digitsOf(String word) => numbers.parseAt([word], 0)!.digits;

  NumberValue say(String phrase) =>
      evaluator.evaluate(spoken.parse(phrase).expression);

  group('German number decomposition', () {
    test('simple units and teens', () {
      expect(digitsOf('sieben'), '7');
      expect(digitsOf('zwölf'), '12');
      // Irregular: sechs loses its s, sieben loses its en.
      expect(digitsOf('sechzehn'), '16');
      expect(digitsOf('siebzehn'), '17');
    });

    test('compounds are one word, and reversed', () {
      // "five-and-twenty" — the units are spoken first.
      expect(digitsOf('fünfundzwanzig'), '25');
      expect(digitsOf('einundzwanzig'), '21');
      expect(digitsOf('neunundneunzig'), '99');
    });

    test('hundreds fold into the same single word', () {
      expect(digitsOf('hundert'), '100');
      expect(digitsOf('zweihundert'), '200');
      expect(digitsOf('hundertfünfundzwanzig'), '125');
      expect(digitsOf('dreihundertzweiundvierzig'), '342');
    });

    test('thousands too', () {
      expect(digitsOf('tausend'), '1000');
      expect(digitsOf('zweitausend'), '2000');
      expect(digitsOf('zwölftausendfünfhundert'), '12500');
    });

    test('"hundert" contains the letters "und" and must not be misread', () {
      // Naively splitting on "und" first would turn 100 into 1 + something.
      expect(digitsOf('hundert'), '100');
      expect(digitsOf('einhundert'), '100');
    });

    test('the older joining und is absorbed', () {
      expect(digitsOf('zweihundertundfünf'), '205');
    });

    test('ss spellings are accepted alongside ß', () {
      expect(digitsOf('dreißig'), '30');
      expect(digitsOf('dreissig'), '30');
    });

    test('German uses a comma for decimals', () {
      final parsed = numbers.parseAt(['drei', 'komma', 'eins', 'vier'], 0)!;
      expect(parsed.digits, '3.14');
      expect(parsed.wordsConsumed, 4);
    });

    test('a non-number word yields nothing', () {
      expect(numbers.parseAt(['plus'], 0), isNull);
    });
  });

  group('German spoken arithmetic', () {
    test('simple sums', () {
      expect(say('drei plus vier'), RationalValue.fromInt(7));
      expect(say('zehn minus vier'), RationalValue.fromInt(6));
    });

    test('multiplication and division', () {
      expect(say('sechs mal sieben'), RationalValue.fromInt(42));
      expect(say('zehn geteilt durch vier'),
          RationalValue(BigInt.from(5), BigInt.from(2)));
    });

    test('precedence holds, as it must — the parser is shared', () {
      expect(say('drei plus vier mal zwei'), RationalValue.fromInt(11));
    });

    test('compound numbers work in a full expression', () {
      expect(say('fünfundzwanzig plus siebzehn'), RationalValue.fromInt(42));
      expect(say('hundertfünfundzwanzig minus fünfundzwanzig'),
          RationalValue.fromInt(100));
    });

    test('powers', () {
      expect(say('fünf zum Quadrat'), RationalValue.fromInt(25));
      expect(say('zwei hoch zehn'), RationalValue.fromInt(1024));
    });

    test('roots', () {
      expect(say('Quadratwurzel aus sechzehn'), RationalValue.fromInt(4));
      expect(say('Wurzel aus neun'), RationalValue.fromInt(3));
    });

    test('German filler words are dropped', () {
      expect(say('was ist drei plus vier'), RationalValue.fromInt(7));
      expect(say('berechne bitte drei plus vier'), RationalValue.fromInt(7));
    });

    test('parentheses', () {
      expect(
        say('Klammer auf drei plus vier Klammer zu mal zwei'),
        RationalValue.fromInt(14),
      );
    });

    test('exactness survives German input exactly as it does English', () {
      // Thirds cannot be written as a decimal, so this only lands on
      // exactly 1 if the German path reached the same exact rationals the
      // typed path does — the whole point of the shared model.
      expect(
        say('eins geteilt durch drei plus eins geteilt durch drei '
            'plus eins geteilt durch drei'),
        RationalValue.fromInt(1),
      );
      expect(say('zehn geteilt durch vier').isExact, isTrue);
    });
  });

  group('German speech output', () {
    const renderer = SpeechRenderer(vocabulary: german);

    test('operators are German', () {
      expect(renderer.render(parser.parse('3+4')), '3 plus 4');
      expect(renderer.render(parser.parse('6/2')), '6 geteilt durch 2');
      expect(renderer.render(parser.parse('6*2')), '6 mal 2');
    });

    test('powers use German forms', () {
      expect(renderer.render(parser.parse('x^2')), 'x zum Quadrat');
      expect(renderer.render(parser.parse('x^5')), 'x hoch 5');
    });

    test('roots open and close in German', () {
      expect(renderer.render(parser.parse('sqrt(9)')), 'Quadratwurzel aus 9');
      expect(
        renderer.render(parser.parse('sqrt(x+1)')),
        'Quadratwurzel aus x plus 1, Wurzel Ende',
      );
    });

    test('fractions are named the German way, without pluralising', () {
      const threeQuarters = FractionNode(NumberNode('3'), NumberNode('4'));
      const oneHalf = FractionNode(NumberNode('1'), NumberNode('2'));
      // English pluralises the denominator, German does not — which is
      // why the naming is a function and not a singular/plural table.
      // The numerator stays a digit in both, as the screen reader will
      // say it in the user's own language anyway.
      expect(renderer.render(threeQuarters), '3 Viertel');
      expect(renderer.render(oneHalf), 'ein Halb');
      expect(
        const SpeechRenderer(vocabulary: EnglishMathVocabulary())
            .render(threeQuarters),
        '3 quarters',
      );
    });

    test('a denominator with no natural name falls back to the long form', () {
      const sevenths = FractionNode(NumberNode('3'), NumberNode('7'));
      expect(renderer.render(sevenths), 'Bruch 3 durch 7');
    });

    test('function names and the joining word are German', () {
      expect(renderer.render(parser.parse('sin(x)')), 'Sinus von x');
      expect(
        renderer.render(parser.parse('ln(x+1)')),
        'natürlicher Logarithmus von x plus 1, natürlicher Logarithmus Ende',
      );
    });

    test('decimals use Komma, not point', () {
      expect(renderer.render(parser.parse('3.14')), '3 Komma 1 4');
    });
  });

  group('the seam itself', () {
    test('the same tree speaks differently in each language', () {
      final tree = parser.parse('sqrt(x^2+1)');
      expect(
        const SpeechRenderer(vocabulary: EnglishMathVocabulary()).render(tree),
        'square root of x squared plus 1, end root',
      );
      expect(
        const SpeechRenderer(vocabulary: GermanMathVocabulary()).render(tree),
        'Quadratwurzel aus x zum Quadrat plus 1, Wurzel Ende',
      );
    });

    test('both languages land on the identical Expression Model', () {
      const englishParser = SpokenMathParser();
      final fromEnglish = englishParser.parse('twenty five plus seventeen');
      final fromGerman = spoken.parse('fünfundzwanzig plus siebzehn');

      // Different words in, same structure out, same value.
      expect(fromEnglish.normalizedSource, fromGerman.normalizedSource);
      expect(
        evaluator.evaluate(fromEnglish.expression),
        evaluator.evaluate(fromGerman.expression),
      );
    });

    test('a registry answers by language, ignoring the region', () {
      const registry = MathVocabularyRegistry(vocabularies: {
        'en': EnglishMathVocabulary(),
        'de': GermanMathVocabulary(),
      });
      expect(registry.supportsLanguage('de-DE'), isTrue);
      expect(registry.supportsLanguage('de'), isTrue);
      expect(registry.supportsLanguage('fr-FR'), isFalse);
      // Austrian German gets German maths — regions share a vocabulary.
      expect(registry.forLocale('de-AT')?.displayName, 'Deutsch');
    });

    test('German is in the shipped set, so the picker will promise it', () {
      // The language notice is driven by this list, so a vocabulary that
      // exists but is not shipped would be invisible to users. The full
      // shipped set is pinned in shipped_languages_test.dart.
      expect(shippedMathVocabularies.supportsLanguage('de-DE'), isTrue);
      expect(shippedMathVocabularies.forLocale('de-CH'),
          isA<GermanMathVocabulary>());
    });
  });
}
