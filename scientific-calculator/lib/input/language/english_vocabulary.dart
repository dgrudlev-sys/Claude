import 'math_vocabulary.dart';

/// English composes numbers by accumulation, left to right: "twenty
/// five" is 20 then 5, "three hundred forty two" multiplies then adds.
/// Words arrive separately, which makes this the simple case — see
/// [GermanNumberParser] for a language where they don't.
class EnglishNumberParser implements SpokenNumberParser {
  const EnglishNumberParser();

  static const units = {
    'zero': 0, 'oh': 0, 'nought': 0,
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
    'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18,
    'nineteen': 19,
  };

  static const tens = {
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
  };

  static const scales = {
    'hundred': 100,
    'thousand': 1000,
    'million': 1000000,
    'billion': 1000000000,
    'trillion': 1000000000000,
  };

  @override
  bool isNumberWord(String word) =>
      units.containsKey(word) || tens.containsKey(word) || scales.containsKey(word);

  @override
  ({String digits, int wordsConsumed})? parseAt(List<String> words, int start) {
    if (start >= words.length || !isNumberWord(words[start])) return null;

    var total = 0;
    var current = 0;
    var index = start;
    var sawAny = false;

    while (index < words.length) {
      final word = words[index];

      if (units.containsKey(word)) {
        // "twenty five" continues; "five five" does not — a second unit
        // after a complete unit means a new number has started.
        if (sawAny && current % 10 != 0 && current != 0) break;
        current += units[word]!;
        sawAny = true;
        index++;
        continue;
      }

      if (tens.containsKey(word)) {
        if (sawAny && current != 0 && current % 100 != 0) break;
        current += tens[word]!;
        sawAny = true;
        index++;
        continue;
      }

      if (word == 'hundred' && sawAny) {
        current = (current == 0 ? 1 : current) * 100;
        index++;
        continue;
      }

      final scale = scales[word];
      if (scale != null && scale >= 1000 && sawAny) {
        total += (current == 0 ? 1 : current) * scale;
        current = 0;
        index++;
        continue;
      }

      // "one hundred and five" — "and" only counts inside a number.
      if (word == 'and' &&
          sawAny &&
          index + 1 < words.length &&
          isNumberWord(words[index + 1]) &&
          !scales.containsKey(words[index + 1])) {
        index++;
        continue;
      }

      break;
    }

    if (!sawAny) return null;
    var digits = '${total + current}';

    // "three point one four" — after "point", digits are read singly.
    if (index < words.length && words[index] == 'point') {
      final decimals = StringBuffer();
      var scan = index + 1;
      while (scan < words.length && units.containsKey(words[scan])) {
        decimals.write(units[words[scan]]);
        scan++;
      }
      if (decimals.isNotEmpty) {
        digits = '$digits.$decimals';
        index = scan;
      }
    }

    return (digits: digits, wordsConsumed: index - start);
  }
}

class EnglishMathVocabulary extends MathVocabulary {
  const EnglishMathVocabulary();

  @override
  String get languageCode => 'en';

  @override
  String get displayName => 'English';

  @override
  SpokenNumberParser get numbers => const EnglishNumberParser();

  @override
  Map<List<String>, String> get phrases => const {
        ['square', 'root', 'of']: 'sqrt(',
        ['the', 'square', 'root', 'of']: 'sqrt(',
        ['cube', 'root', 'of']: 'cbrt(',
        ['absolute', 'value', 'of']: 'abs(',
        ['to', 'the', 'power', 'of']: '^',
        ['raised', 'to', 'the', 'power', 'of']: '^',
        ['multiplied', 'by']: '*',
        ['multiply', 'by']: '*',
        ['divided', 'by']: '/',
        ['divide', 'by']: '/',
        ['take', 'away']: '-',
        ['open', 'parenthesis']: '(',
        ['open', 'parentheses']: '(',
        ['open', 'paren']: '(',
        ['open', 'bracket']: '(',
        ['close', 'parenthesis']: ')',
        ['close', 'parentheses']: ')',
        ['close', 'paren']: ')',
        ['close', 'bracket']: ')',
        ['sine', 'of']: 'sin(',
        ['sin', 'of']: 'sin(',
        ['cosine', 'of']: 'cos(',
        ['cos', 'of']: 'cos(',
        ['tangent', 'of']: 'tan(',
        ['tan', 'of']: 'tan(',
        ['natural', 'log', 'of']: 'ln(',
        ['log', 'of']: 'log(',
        ['log', 'base']: 'log(',
        // The sanitiser drops the apostrophe before any matching, so
        // "what's" arrives as two tokens. Matched here rather than added
        // to the filler words, because a lone "s" is a usable variable.
        ['what', 's']: '',
      };

  @override
  Map<String, String> get singleWords => const {
        'plus': '+',
        'add': '+',
        'minus': '-',
        'subtract': '-',
        'negative': '-',
        'times': '*',
        'over': '/',
        'squared': '^2',
        'cubed': '^3',
        'percent': '%',
        'factorial': '!',
        'pi': 'pi',
        'sqrt': 'sqrt(',
      };

  @override
  Set<String> get fillerWords => const {
        'what', 'whats', "what's", 'is', 'the', 'of', 'please', 'calculate',
        'compute', 'equals', 'equal', 'result', 'answer', 'me', 'tell', 'can',
        'you', 'could', 'would', 'a',
      };

  @override
  SpeechTerms get speech => SpeechTerms(
        plus: 'plus',
        minus: 'minus',
        times: 'times',
        dividedBy: 'divided by',
        modulo: 'mod',
        negative: 'negative',
        factorial: 'factorial',
        percent: 'percent',
        openParen: 'open paren',
        closeParen: 'close paren',
        fractionOpen: 'fraction',
        fractionOver: 'over',
        fractionEnd: 'end fraction',
        squared: 'squared',
        cubed: 'cubed',
        toThePowerOf: 'to the power of',
        powerEnd: 'end power',
        squareRootOf: 'square root of',
        cubeRootOf: 'cube root of',
        nthRootOf: (index) => '${index}th root of',
        rootEnd: 'end root',
        absoluteValueOf: 'absolute value of',
        absoluteEnd: 'end absolute value',
        decimalPoint: 'point',
        emptySlot: 'empty slot',
        emptyNamedSlot: (role) => 'empty $role',
        matrixSize: (rows, columns) => '$rows by $columns matrix',
        matrixRow: (number) => 'row $number: ',
        matrixEnd: 'end matrix',
        equals: 'equals',
        and: 'and',
        plusOrMinus: 'plus or minus',
        relation: (name) => switch (name) {
          'equals' => 'equals',
          'notEquals' => 'is not equal to',
          'lessThan' => 'is less than',
          'lessOrEqual' => 'is less than or equal to',
          'greaterThan' => 'is greater than',
          'greaterOrEqual' => 'is greater than or equal to',
          'approximately' => 'is approximately',
          _ => name,
        },
        functionNames: const {
          'sin': 'sine',
          'cos': 'cosine',
          'tan': 'tangent',
          'asin': 'inverse sine',
          'arcsin': 'inverse sine',
          'acos': 'inverse cosine',
          'arccos': 'inverse cosine',
          'atan': 'inverse tangent',
          'arctan': 'inverse tangent',
          'sinh': 'hyperbolic sine',
          'cosh': 'hyperbolic cosine',
          'tanh': 'hyperbolic tangent',
          'ln': 'natural log',
          'log': 'log',
          'exp': 'e to the power of',
          'abs': 'absolute value',
        },
        functionOf: 'of',
        functionEnd: (spokenName) => 'end $spokenName',
        simpleFraction: (numerator, denominator) {
          const names = {
            '2': (singular: 'half', plural: 'halves'),
            '3': (singular: 'third', plural: 'thirds'),
            '4': (singular: 'quarter', plural: 'quarters'),
          };
          final name = names[denominator];
          if (name == null) return null;
          return numerator == '1'
              ? 'one ${name.singular}'
              : '$numerator ${name.plural}';
        },
      );
}
