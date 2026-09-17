import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/engine/number/number.dart';
import 'package:scientific_calculator/expression/evaluator.dart';
import 'package:scientific_calculator/expression/parse/expression_parser.dart';
import 'package:scientific_calculator/expression/render/speech_renderer.dart';
import 'package:scientific_calculator/input/language/vocabularies.dart';
import 'package:scientific_calculator/input/voice/spoken_math_parser.dart';

/// What every shipped language has to be able to do.
///
/// The per-language files test each language's own hard parts — French
/// counting in twenties, Danish reversing, Russian inflecting. This file
/// tests what they must all have in common, so a new vocabulary cannot
/// be added with a gap in it.
void main() {
  const evaluator = Evaluator();
  const parser = ExpressionParser();
  final vocabularies = shippedMathVocabularies.vocabularies;

  /// "twenty five plus seventeen" in each shipped language, chosen
  /// because the number is a compound in every one of them and is built
  /// a different way in each.
  const compoundSums = {
    'en': 'twenty five plus seventeen',
    'de': 'fünfundzwanzig plus siebzehn',
    'fr': 'vingt-cinq plus dix-sept',
    'es': 'veinticinco más diecisiete',
    'ru': 'двадцать пять плюс семнадцать',
    'da': 'femogtyve plus sytten',
    'sv': 'tjugofem plus sjutton',
  };

  group('the shipped set', () {
    test('is exactly the languages with a vocabulary behind them', () {
      // Pinned deliberately: the language picker promises full voice
      // support for everything in here, so a code appearing without a
      // working vocabulary would be a promise the app cannot keep.
      expect(shippedMathVocabularies.supportedLanguageCodes,
          {'en', 'de', 'fr', 'es', 'ru', 'da', 'sv'});
    });

    test('every entry is filed under its own language code', () {
      vocabularies.forEach((code, vocabulary) {
        expect(vocabulary.languageCode, code);
      });
    });

    test('every entry has a display name in its own language', () {
      for (final vocabulary in vocabularies.values) {
        expect(vocabulary.displayName, isNotEmpty);
      }
      expect(vocabularies['de']!.displayName, 'Deutsch');
      expect(vocabularies['ru']!.displayName, 'Русский');
      expect(vocabularies['sv']!.displayName, 'Svenska');
    });

    test('regional variants resolve to the same vocabulary', () {
      expect(shippedMathVocabularies.forLocale('fr-CA')?.languageCode, 'fr');
      expect(shippedMathVocabularies.forLocale('es-MX')?.languageCode, 'es');
      expect(shippedMathVocabularies.forLocale('sv-FI')?.languageCode, 'sv');
      // Not shipped, and said so rather than guessed at.
      expect(shippedMathVocabularies.forLocale('nl-NL'), isNull);
    });
  });

  group('every language reaches the same Expression Model', () {
    test('a compound number plus a teen is 42 in all of them', () {
      for (final entry in compoundSums.entries) {
        final vocabulary = vocabularies[entry.key]!;
        final result = SpokenMathParser(vocabulary: vocabulary).parse(entry.value);
        expect(evaluator.evaluate(result.expression), RationalValue.fromInt(42),
            reason: '${entry.key}: "${entry.value}"');
        // Different words in, identical normalised source out.
        expect(result.normalizedSource, '25+17', reason: entry.key);
      }
    });

    test('every language keeps thirds exact rather than rounding', () {
      const thirds = {
        'en': 'one divided by three plus one divided by three '
            'plus one divided by three',
        'de': 'eins geteilt durch drei plus eins geteilt durch drei '
            'plus eins geteilt durch drei',
        'fr': 'un divisé par trois plus un divisé par trois '
            'plus un divisé par trois',
        'es': 'uno entre tres más uno entre tres más uno entre tres',
        'ru': 'один разделить на три плюс один разделить на три '
            'плюс один разделить на три',
        'da': 'en divideret med tre plus en divideret med tre '
            'plus en divideret med tre',
        'sv': 'ett delat med tre plus ett delat med tre '
            'plus ett delat med tre',
      };
      for (final entry in thirds.entries) {
        final result =
            SpokenMathParser(vocabulary: vocabularies[entry.key]!).parse(entry.value);
        expect(evaluator.evaluate(result.expression), RationalValue.fromInt(1),
            reason: entry.key);
      }
    });
  });

  group('every language can say the same tree', () {
    final tree = parser.parse('sqrt(x^2+1)');

    test('and each says something different, in its own words', () {
      final spoken = <String, String>{
        for (final entry in vocabularies.entries)
          entry.key: SpeechRenderer(vocabulary: entry.value).render(tree),
      };

      expect(spoken['en'], 'square root of x squared plus 1, end root');
      expect(spoken['de'], 'Quadratwurzel aus x zum Quadrat plus 1, Wurzel Ende');
      expect(spoken['fr'], 'racine carrée de x au carré plus 1, fin de racine');
      expect(spoken['es'], 'raíz cuadrada de x al cuadrado más 1, fin de raíz');
      expect(spoken['ru'], 'квадратный корень из x в квадрате плюс 1, конец корня');
      expect(spoken['da'], 'kvadratroden af x i anden plus 1, rod slut');
      expect(spoken['sv'], 'kvadratroten ur x i kvadrat plus 1, slut rot');

      // No two languages render it identically, which would mean one of
      // them had quietly fallen back to another's words.
      expect(spoken.values.toSet().length, spoken.length);
    });
  });

  group('no shipped vocabulary has a hole in it', () {
    test('each fills in every speech term', () {
      for (final entry in vocabularies.entries) {
        final terms = entry.value.speech;
        final strings = [
          terms.plus, terms.minus, terms.times, terms.dividedBy, terms.modulo,
          terms.negative, terms.factorial, terms.percent,
          terms.openParen, terms.closeParen,
          terms.fractionOpen, terms.fractionOver, terms.fractionEnd,
          terms.squared, terms.cubed, terms.toThePowerOf, terms.powerEnd,
          terms.squareRootOf, terms.cubeRootOf, terms.rootEnd,
          terms.absoluteValueOf, terms.absoluteEnd,
          terms.decimalPoint, terms.emptySlot, terms.matrixEnd,
          terms.equals, terms.and, terms.functionOf,
        ];
        for (final term in strings) {
          expect(term, isNotEmpty, reason: '${entry.key} has an empty term');
        }
        expect(terms.nthRootOf('5'), contains('5'), reason: entry.key);
        expect(terms.emptyNamedSlot('x'), contains('x'), reason: entry.key);
        expect(terms.matrixSize('2', '3'), contains('2'), reason: entry.key);
        expect(terms.matrixRow('1'), contains('1'), reason: entry.key);
        expect(terms.functionEnd('sin'), contains('sin'), reason: entry.key);
      }
    });

    test('each names the trigonometric and log functions', () {
      for (final entry in vocabularies.entries) {
        for (final name in ['sin', 'cos', 'tan', 'ln', 'log', 'abs']) {
          expect(entry.value.speech.functionNames[name], isNotNull,
              reason: '${entry.key} does not name $name');
        }
      }
    });

    test('each can name a half, a third and a quarter', () {
      for (final entry in vocabularies.entries) {
        for (final denominator in ['2', '3', '4']) {
          expect(entry.value.speech.simpleFraction('1', denominator), isNotNull,
              reason: '${entry.key} cannot name 1/$denominator');
        }
        // And returns null rather than inventing a name for the rest.
        expect(entry.value.speech.simpleFraction('1', '7'), isNull,
            reason: entry.key);
      }
    });

    test('each has phrases for roots, parentheses and the operations', () {
      for (final entry in vocabularies.entries) {
        final symbols = {
          ...entry.value.phrases.values,
          ...entry.value.singleWords.values,
        };
        for (final needed in ['sqrt(', '(', ')', '+', '-', '*', '/', '^']) {
          expect(symbols, contains(needed),
              reason: '${entry.key} has no way to say "$needed"');
        }
      }
    });

    test('each can read its own digits back after a decimal separator', () {
      // The separator word differs per language, so this checks the
      // parser rather than the spelling: every language must turn its
      // own "three point one four" into 3.14.
      const decimals = {
        'en': ['three', 'point', 'one', 'four'],
        'de': ['drei', 'komma', 'eins', 'vier'],
        'fr': ['trois', 'virgule', 'un', 'quatre'],
        'es': ['tres', 'coma', 'uno', 'cuatro'],
        'ru': ['три', 'запятая', 'один', 'четыре'],
        'da': ['tre', 'komma', 'en', 'fire'],
        'sv': ['tre', 'komma', 'ett', 'fyra'],
      };
      for (final entry in decimals.entries) {
        final parsed = vocabularies[entry.key]!.numbers.parseAt(entry.value, 0);
        expect(parsed?.digits, '3.14', reason: entry.key);
        expect(parsed?.wordsConsumed, 4, reason: entry.key);
      }
    });

    test('no language claims a plain operator word is a number', () {
      const operators = {
        'en': 'plus', 'de': 'plus', 'fr': 'plus', 'es': 'más',
        'ru': 'плюс', 'da': 'plus', 'sv': 'plus',
      };
      for (final entry in operators.entries) {
        expect(vocabularies[entry.key]!.numbers.parseAt([entry.value], 0), isNull,
            reason: entry.key);
        expect(vocabularies[entry.key]!.numbers.isNumberWord(entry.value), isFalse,
            reason: entry.key);
      }
    });
  });
}
