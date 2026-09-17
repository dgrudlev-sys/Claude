import 'math_vocabulary.dart';

/// Danish is the hardest of the languages here, because it is vigesimal
/// *and* it reverses, and it writes the result as a single word.
///
/// The tens above forty are counted in twenties, and the names still
/// carry the arithmetic:
///
///   tres          3 × 20                = 60
///   halvtreds     "half-third" × 20     = 2½ × 20 = 50
///   halvfjerds    "half-fourth" × 20    = 3½ × 20 = 70
///   firs          4 × 20                = 80
///   halvfems      "half-fifth" × 20     = 4½ × 20 = 90
///
/// No parser can derive those, so they are listed. On top of that the
/// units come first and join with "og", all in one token:
///
///   femoghalvfjerds   5 + 70 = 75
///
/// Note that "halvtreds" (50) contains "tres" (60) as a substring, so
/// this decomposes by exact lookup rather than by searching for known
/// words inside the token — the one approach that would seem to work and
/// would be wrong.
class DanishNumberParser implements SpokenNumberParser {
  const DanishNumberParser();

  static const _units = {
    'nul': 0, 'en': 1, 'et': 1, 'to': 2, 'tre': 3, 'fire': 4, 'fem': 5,
    'seks': 6, 'syv': 7, 'otte': 8, 'ni': 9, 'ti': 10, 'elleve': 11,
    'tolv': 12, 'tretten': 13, 'fjorten': 14, 'femten': 15, 'seksten': 16,
    'sytten': 17, 'atten': 18, 'nitten': 19,
  };

  static const _tens = {
    'tyve': 20, 'tredive': 30, 'fyrre': 40, 'fyrretyve': 40,
    'halvtreds': 50, 'halvtredsindstyve': 50,
    'tres': 60, 'tresindstyve': 60,
    'halvfjerds': 70, 'halvfjerdsindstyve': 70,
    'firs': 80, 'firsindstyve': 80,
    'halvfems': 90, 'halvfemsindstyve': 90,
  };

  /// Longest first: "hundrede" has to be found before "hundred", or the
  /// trailing "e" would be left behind and fail to parse.
  static const _scales = [
    (word: 'millioner', value: 1000000),
    (word: 'million', value: 1000000),
    (word: 'tusinde', value: 1000),
    (word: 'tusind', value: 1000),
    (word: 'hundrede', value: 100),
    (word: 'hundred', value: 100),
  ];

  static String _key(String word) => foldDiacritics(word.toLowerCase());

  @override
  bool isNumberWord(String word) => _decompose(_key(word)) != null;

  @override
  ({String digits, int wordsConsumed})? parseAt(List<String> words, int start) {
    if (start >= words.length) return null;
    final first = _decompose(_key(words[start]));
    if (first == null) return null;
    var value = first;
    var consumed = 1;

    // "to hundrede og fem" — the separated form, where "og" joins a round
    // hundred to what follows. The everyday form writes it as one word,
    // which the decomposition above already handled.
    var index = start + 1;
    while (index + 1 < words.length && _key(words[index]) == 'og') {
      final next = _decompose(_key(words[index + 1]));
      if (next == null || next >= 100 || value % 100 != 0) break;
      value += next;
      index += 2;
      consumed = index - start;
    }

    return withDecimalTail(
      whole: '$value',
      words: words,
      start: start,
      consumed: consumed,
      separators: const {'komma'},
      digitOf: (word) => _units[_key(word)],
    );
  }

  /// Breaks a compound Danish numeral into its value.
  int? _decompose(String word) {
    if (word.isEmpty) return null;

    final exact = _units[word] ?? _tens[word];
    if (exact != null) return exact;

    for (final scale in _scales) {
      final index = word.indexOf(scale.word);
      if (index == -1) continue;

      final leftText = word.substring(0, index);
      var rightText = word.substring(index + scale.word.length);
      if (rightText.startsWith('og')) rightText = rightText.substring(2);

      // A bare "hundrede" means one hundred, not zero hundreds.
      final left = leftText.isEmpty ? 1 : _decompose(leftText);
      final right = rightText.isEmpty ? 0 : _decompose(rightText);
      if (left == null || right == null) return null;
      return left * scale.value + right;
    }

    // "femogtyve" → 5 + 20. The unit is spoken first, which is the
    // reverse of how the digits are written.
    final ogIndex = word.indexOf('og');
    if (ogIndex > 0) {
      final unit = _units[word.substring(0, ogIndex)];
      final ten = _tens[word.substring(ogIndex + 2)];
      if (unit != null && ten != null) return ten + unit;
    }

    return null;
  }
}

class DanishMathVocabulary extends MathVocabulary {
  const DanishMathVocabulary();

  @override
  String get languageCode => 'da';

  @override
  String get displayName => 'Dansk';

  @override
  SpokenNumberParser get numbers => const DanishNumberParser();

  @override
  Map<List<String>, String> get phrases => const {
        ['kvadratroden', 'af']: 'sqrt(',
        ['kvadratrod', 'af']: 'sqrt(',
        ['roden', 'af']: 'sqrt(',
        ['rod', 'af']: 'sqrt(',
        ['kubikroden', 'af']: 'cbrt(',
        ['kubikrod', 'af']: 'cbrt(',
        ['absolut', 'værdi', 'af']: 'abs(',
        ['numerisk', 'værdi', 'af']: 'abs(',
        ['divideret', 'med']: '/',
        ['delt', 'med']: '/',
        ['ganget', 'med']: '*',
        ['gange', 'med']: '*',
        ['i', 'anden']: '^2',
        ['i', 'tredje']: '^3',
        ['opløftet', 'i']: '^',
        ['parentes', 'start']: '(',
        ['parentes', 'slut']: ')',
        ['venstre', 'parentes']: '(',
        ['højre', 'parentes']: ')',
        ['sinus', 'af']: 'sin(',
        ['cosinus', 'af']: 'cos(',
        ['tangens', 'af']: 'tan(',
        ['naturlig', 'logaritme', 'af']: 'ln(',
        ['logaritme', 'af']: 'log(',
      };

  @override
  Map<String, String> get singleWords => const {
        'plus': '+',
        'minus': '-',
        'gange': '*',
        'gang': '*',
        'divideret': '/',
        'delt': '/',
        'procent': '%',
        'fakultet': '!',
        'pi': 'pi',
        'rod': 'sqrt(',
      };

  @override
  Set<String> get fillerWords => const {
        'hvad', 'er', 'hvor', 'meget', 'beregn', 'udregn', 'venligst',
        'lig', 'resultatet', 'giver', 'sig', 'mig',
      };

  @override
  SpeechTerms get speech => SpeechTerms(
        plus: 'plus',
        minus: 'minus',
        times: 'gange',
        dividedBy: 'divideret med',
        modulo: 'modulo',
        negative: 'minus',
        factorial: 'fakultet',
        percent: 'procent',
        openParen: 'parentes start',
        closeParen: 'parentes slut',
        fractionOpen: 'brøk',
        fractionOver: 'divideret med',
        fractionEnd: 'brøk slut',
        squared: 'i anden',
        cubed: 'i tredje',
        toThePowerOf: 'opløftet i',
        powerEnd: 'potens slut',
        squareRootOf: 'kvadratroden af',
        cubeRootOf: 'kubikroden af',
        nthRootOf: (index) => '$index-te rod af',
        rootEnd: 'rod slut',
        absoluteValueOf: 'absolut værdi af',
        absoluteEnd: 'absolut værdi slut',
        decimalPoint: 'komma',
        emptySlot: 'tomt felt',
        emptyNamedSlot: (role) => 'tomt felt: $role',
        matrixSize: (rows, columns) => '$rows gange $columns matrix',
        matrixRow: (number) => 'række $number: ',
        matrixEnd: 'matrix slut',
        equals: 'er lig med',
        and: 'og',
        functionOf: 'af',
        functionEnd: (spokenName) => '$spokenName slut',
        functionNames: const {
          'sin': 'sinus',
          'cos': 'cosinus',
          'tan': 'tangens',
          'asin': 'arcus sinus',
          'arcsin': 'arcus sinus',
          'acos': 'arcus cosinus',
          'arccos': 'arcus cosinus',
          'atan': 'arcus tangens',
          'arctan': 'arcus tangens',
          'sinh': 'sinus hyperbolsk',
          'cosh': 'cosinus hyperbolsk',
          'tanh': 'tangens hyperbolsk',
          'ln': 'naturlig logaritme',
          'log': 'logaritme',
          'exp': 'eksponentialfunktion',
          'abs': 'absolut værdi',
        },
        simpleFraction: (numerator, denominator) {
          const names = {
            '2': (singular: 'halv', plural: 'halve'),
            '3': (singular: 'tredjedel', plural: 'tredjedele'),
            '4': (singular: 'fjerdedel', plural: 'fjerdedele'),
          };
          final name = names[denominator];
          if (name == null) return null;
          return numerator == '1'
              ? 'en ${name.singular}'
              : '$numerator ${name.plural}';
        },
      );
}
