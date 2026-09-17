import 'math_vocabulary.dart';

/// Swedish compounds into one word like Danish and German, but in the
/// opposite order to both: the ten comes first and the unit follows, the
/// way the digits are written.
///
///   tjugofem      20 + 5 = 25   (Danish: femogtyve, German: fünfundzwanzig)
///   nittionio     90 + 9 = 99
///
/// So this decomposes by stripping a leading tens word rather than by
/// splitting on a joining particle. The tens have to be matched longest
/// first: "sextiosex" starts with both "sex" and "sextio", and only the
/// longer reading leaves a valid remainder.
class SwedishNumberParser implements SpokenNumberParser {
  const SwedishNumberParser();

  static const _units = {
    'noll': 0, 'en': 1, 'ett': 1, 'två': 2, 'tre': 3, 'fyra': 4, 'fem': 5,
    'sex': 6, 'sju': 7, 'åtta': 8, 'nio': 9, 'tio': 10, 'elva': 11,
    'tolv': 12, 'tretton': 13, 'fjorton': 14, 'femton': 15, 'sexton': 16,
    'sjutton': 17, 'arton': 18, 'aderton': 18, 'nitton': 19,
  };

  static const _tens = {
    'tjugo': 20, 'trettio': 30, 'fyrtio': 40, 'förtio': 40, 'femtio': 50,
    'sextio': 60, 'sjuttio': 70, 'åttio': 80, 'nittio': 90,
  };

  static const _scales = [
    (word: 'miljoner', value: 1000000),
    (word: 'miljon', value: 1000000),
    (word: 'tusen', value: 1000),
    (word: 'hundra', value: 100),
  ];

  static final _foldedUnits = _fold(_units);
  static final _foldedTens = _fold(_tens);

  /// The tens, longest first, so "sextio" is tried before "sex" could
  /// strand an unparseable "tiosex" behind it.
  static final List<MapEntry<String, int>> _tensByLength = _foldedTens.entries
      .toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));

  static Map<String, int> _fold(Map<String, int> table) =>
      {for (final entry in table.entries) foldDiacritics(entry.key): entry.value};

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

    // "hundra och fem" — the separated form. The everyday form writes it
    // as one word, which the decomposition above already handled.
    var index = start + 1;
    while (index + 1 < words.length && _key(words[index]) == 'och') {
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
      digitOf: (word) => _foldedUnits[_key(word)],
    );
  }

  int? _decompose(String word) {
    if (word.isEmpty) return null;

    final exact = _foldedUnits[word] ?? _foldedTens[word];
    if (exact != null) return exact;

    for (final scale in _scales) {
      // Matched against the folded spelling, and measured with it too —
      // the two can differ in length for a word carrying diacritics.
      final needle = foldDiacritics(scale.word);
      final index = word.indexOf(needle);
      if (index == -1) continue;

      final leftText = word.substring(0, index);
      var rightText = word.substring(index + needle.length);
      if (rightText.startsWith('och')) rightText = rightText.substring(3);

      // A bare "hundra" means one hundred, not zero hundreds.
      final left = leftText.isEmpty ? 1 : _decompose(leftText);
      final right = rightText.isEmpty ? 0 : _decompose(rightText);
      if (left == null || right == null) return null;
      return left * scale.value + right;
    }

    // "tjugofem" → 20 + 5, the ten stripped from the front.
    for (final ten in _tensByLength) {
      if (!word.startsWith(ten.key)) continue;
      final rest = word.substring(ten.key.length);
      if (rest.isEmpty) return ten.value;
      final unit = _foldedUnits[rest];
      if (unit != null) return ten.value + unit;
    }

    return null;
  }
}

class SwedishMathVocabulary extends MathVocabulary {
  const SwedishMathVocabulary();

  @override
  String get languageCode => 'sv';

  @override
  String get displayName => 'Svenska';

  @override
  SpokenNumberParser get numbers => const SwedishNumberParser();

  @override
  Map<List<String>, String> get phrases => const {
        ['kvadratroten', 'ur']: 'sqrt(',
        ['kvadratrot', 'ur']: 'sqrt(',
        ['roten', 'ur']: 'sqrt(',
        ['rot', 'ur']: 'sqrt(',
        ['kubikroten', 'ur']: 'cbrt(',
        ['absolutbeloppet', 'av']: 'abs(',
        ['delat', 'med']: '/',
        ['dividerat', 'med']: '/',
        ['multiplicerat', 'med']: '*',
        ['i', 'kvadrat']: '^2',
        ['i', 'kubik']: '^3',
        ['upphöjt', 'till']: '^',
        ['upphojt', 'till']: '^',
        ['parentes', 'börjar']: '(',
        ['parentes', 'slutar']: ')',
        ['vänster', 'parentes']: '(',
        ['höger', 'parentes']: ')',
        ['sinus', 'av']: 'sin(',
        ['cosinus', 'av']: 'cos(',
        ['tangens', 'av']: 'tan(',
        ['naturliga', 'logaritmen', 'av']: 'ln(',
        ['logaritmen', 'av']: 'log(',
      };

  @override
  Map<String, String> get singleWords => const {
        'plus': '+',
        'minus': '-',
        'gånger': '*',
        'ganger': '*',
        'delat': '/',
        'dividerat': '/',
        'procent': '%',
        'fakultet': '!',
        'pi': 'pi',
        'roten': 'sqrt(',
      };

  @override
  Set<String> get fillerWords => const {
        'vad', 'är', 'ar', 'hur', 'mycket', 'beräkna', 'berakna', 'räkna',
        'rakna', 'ut', 'snälla', 'snalla', 'lika', 'blir', 'resultatet',
      };

  @override
  SpeechTerms get speech => SpeechTerms(
        plus: 'plus',
        minus: 'minus',
        times: 'gånger',
        dividedBy: 'delat med',
        modulo: 'modulo',
        negative: 'minus',
        factorial: 'fakultet',
        percent: 'procent',
        openParen: 'parentes börjar',
        closeParen: 'parentes slutar',
        fractionOpen: 'bråk',
        fractionOver: 'delat med',
        fractionEnd: 'slut bråk',
        squared: 'i kvadrat',
        cubed: 'i kubik',
        toThePowerOf: 'upphöjt till',
        powerEnd: 'slut potens',
        squareRootOf: 'kvadratroten ur',
        cubeRootOf: 'kubikroten ur',
        nthRootOf: (index) => '$index-te roten ur',
        rootEnd: 'slut rot',
        absoluteValueOf: 'absolutbeloppet av',
        absoluteEnd: 'slut absolutbelopp',
        decimalPoint: 'komma',
        emptySlot: 'tomt fält',
        emptyNamedSlot: (role) => 'tomt fält: $role',
        matrixSize: (rows, columns) => '$rows gånger $columns matris',
        matrixRow: (number) => 'rad $number: ',
        matrixEnd: 'slut matris',
        equals: 'är lika med',
        and: 'och',
        functionOf: 'av',
        functionEnd: (spokenName) => 'slut $spokenName',
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
          'sinh': 'sinus hyperbolicus',
          'cosh': 'cosinus hyperbolicus',
          'tanh': 'tangens hyperbolicus',
          'ln': 'naturliga logaritmen',
          'log': 'logaritmen',
          'exp': 'exponentialfunktionen',
          'abs': 'absolutbeloppet',
        },
        simpleFraction: (numerator, denominator) {
          const names = {
            '2': (singular: 'halv', plural: 'halva'),
            '3': (singular: 'tredjedel', plural: 'tredjedelar'),
            '4': (singular: 'fjärdedel', plural: 'fjärdedelar'),
          };
          final name = names[denominator];
          if (name == null) return null;
          return numerator == '1'
              ? 'en ${name.singular}'
              : '$numerator ${name.plural}';
        },
      );
}
