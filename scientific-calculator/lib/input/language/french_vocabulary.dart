import 'math_vocabulary.dart';

/// French numbers are partly vigesimal — counted in twenties — which is
/// the one thing a purely additive parser cannot handle.
///
///   soixante-dix        60 + 10        = 70
///   quatre-vingts       4 × 20         = 80
///   quatre-vingt-dix    4 × 20 + 10    = 90
///   quatre-vingt-dix-neuf              = 99, four words for one number
///
/// So this parser has one multiplicative rule ("quatre" immediately
/// before "vingt") sitting inside an otherwise additive accumulator.
///
/// It also has to cope with hyphens. The 1990 spelling reform joins every
/// part of a compound number with them, so a recogniser may hand back
/// "quatre-vingt-dix" as a single token where an older one gives three
/// words. Both are read the same way here.
class FrenchNumberParser implements SpokenNumberParser {
  const FrenchNumberParser();

  /// Values that can be added to a running total. Seventeen upward are
  /// compounds, not words, so they are absent by design.
  static const _small = {
    'zéro': 0, 'zero': 0,
    'un': 1, 'une': 1, 'deux': 2, 'trois': 3, 'quatre': 4, 'cinq': 5,
    'six': 6, 'sept': 7, 'huit': 8, 'neuf': 9, 'dix': 10,
    'onze': 11, 'douze': 12, 'treize': 13, 'quatorze': 14, 'quinze': 15,
    'seize': 16,
  };

  static const _tens = {
    'vingt': 20, 'vingts': 20,
    'trente': 30, 'quarante': 40, 'cinquante': 50, 'soixante': 60,
    // Belgian and Swiss French, which are regular exactly where standard
    // French turns vigesimal. Accepting them costs nothing and means a
    // Belgian speaker is not told their own numbers are not numbers.
    'septante': 70, 'octante': 80, 'huitante': 80, 'nonante': 90,
  };

  static const _scales = {
    'cent': 100, 'cents': 100,
    'mille': 1000, 'mil': 1000,
    'million': 1000000, 'millions': 1000000,
    'milliard': 1000000000, 'milliards': 1000000000,
  };

  static final _foldedSmall = _fold(_small);
  static final _foldedTens = _fold(_tens);
  static final _foldedScales = _fold(_scales);

  static Map<String, int> _fold(Map<String, int> table) =>
      {for (final entry in table.entries) foldDiacritics(entry.key): entry.value};

  static String _key(String word) => foldDiacritics(word.toLowerCase());

  @override
  bool isNumberWord(String word) {
    final key = _key(word);
    return _foldedSmall.containsKey(key) ||
        _foldedTens.containsKey(key) ||
        _foldedScales.containsKey(key);
  }

  @override
  ({String digits, int wordsConsumed})? parseAt(List<String> words, int start) {
    final tokens = _tokenize(words, start);
    if (tokens.isEmpty) return null;

    var total = 0;
    var current = 0;
    int? lastAdded;
    var sawAny = false;
    var consumedTokens = 0;

    /// Whether [value] can follow what was just added, which is what
    /// stops "cinq cinq" becoming ten while letting "soixante-quinze"
    /// become 75.
    bool accepts(int value) {
      final previous = lastAdded;
      if (previous == null) return true;
      // After a ten — including the 80 from "quatre-vingt" — anything up
      // to sixteen may follow: "soixante-quinze", "quatre-vingt-seize".
      if (previous >= 20) return value <= 16;
      // After "dix", only a unit: "dix-sept".
      if (previous == 10) return value >= 1 && value <= 9;
      return false;
    }

    var i = 0;
    while (i < tokens.length) {
      final word = _key(tokens[i].text);

      // The one multiplicative compound in the language.
      if (word == 'quatre' &&
          i + 1 < tokens.length &&
          _foldedTens[_key(tokens[i + 1].text)] == 20) {
        if (lastAdded != null) break;
        current += 80;
        lastAdded = 80;
        sawAny = true;
        i += 2;
        consumedTokens = i;
        continue;
      }

      // "vingt et un" — the joining "et" carries no value of its own.
      if (word == 'et' &&
          sawAny &&
          i + 1 < tokens.length &&
          _foldedSmall.containsKey(_key(tokens[i + 1].text))) {
        i++;
        continue;
      }

      final scale = _foldedScales[word];
      if (scale != null) {
        if (scale == 100) {
          // "cent" alone is one hundred, not zero hundreds.
          current = (current == 0 ? 1 : current) * 100;
        } else {
          total += (current == 0 ? 1 : current) * scale;
          current = 0;
        }
        lastAdded = null;
        sawAny = true;
        i++;
        consumedTokens = i;
        continue;
      }

      final ten = _foldedTens[word];
      if (ten != null) {
        if (lastAdded != null) break;
        current += ten;
        lastAdded = ten;
        sawAny = true;
        i++;
        consumedTokens = i;
        continue;
      }

      final small = _foldedSmall[word];
      if (small != null) {
        if (!accepts(small)) break;
        current += small;
        lastAdded = small;
        sawAny = true;
        i++;
        consumedTokens = i;
        continue;
      }

      break;
    }

    if (!sawAny || consumedTokens == 0) return null;

    // Sub-tokens map back to whole words: a hyphenated compound is one
    // word however many pieces it was read in.
    final consumed = tokens[consumedTokens - 1].wordIndex - start + 1;

    return withDecimalTail(
      whole: '${total + current}',
      words: words,
      start: start,
      consumed: consumed,
      separators: const {'virgule'},
      digitOf: (word) => _foldedSmall[_key(word)],
    );
  }

  /// Flattens hyphenated compounds into separate tokens while remembering
  /// which word each came from.
  static List<({String text, int wordIndex})> _tokenize(
    List<String> words,
    int start,
  ) {
    final tokens = <({String text, int wordIndex})>[];
    for (var i = start; i < words.length; i++) {
      for (final part in words[i].split('-')) {
        if (part.isNotEmpty) tokens.add((text: part, wordIndex: i));
      }
    }
    return tokens;
  }
}

class FrenchMathVocabulary extends MathVocabulary {
  const FrenchMathVocabulary();

  @override
  String get languageCode => 'fr';

  @override
  String get displayName => 'Français';

  @override
  SpokenNumberParser get numbers => const FrenchNumberParser();

  @override
  Map<List<String>, String> get phrases => const {
        ['racine', 'carrée', 'de']: 'sqrt(',
        ['racine', 'carree', 'de']: 'sqrt(',
        ['racine', 'de']: 'sqrt(',
        ['racine', 'cubique', 'de']: 'cbrt(',
        ['valeur', 'absolue', 'de']: 'abs(',
        ['divisé', 'par']: '/',
        ['divise', 'par']: '/',
        ['multiplié', 'par']: '*',
        ['multiplie', 'par']: '*',
        ['au', 'carré']: '^2',
        ['au', 'carre']: '^2',
        ['au', 'cube']: '^3',
        ['puissance', 'de']: '^',
        ['parenthèse', 'ouvrante']: '(',
        ['parenthese', 'ouvrante']: '(',
        ['parenthèse', 'fermante']: ')',
        ['parenthese', 'fermante']: ')',
        ['ouvre', 'la', 'parenthèse']: '(',
        ['ferme', 'la', 'parenthèse']: ')',
        // "pour cent" would otherwise be read as "for a hundred", since
        // "cent" is the number word for 100.
        ['pour', 'cent']: '%',
        // The sanitiser drops apostrophes before any of this is matched,
        // so "s'il vous plaît" arrives as four tokens. Matched as a
        // phrase rather than added to the filler words, because a lone
        // "s" is still a usable variable name.
        ['s', 'il', 'vous', 'plaît']: '',
        ['s', 'il', 'vous', 'plait']: '',
        ['sinus', 'de']: 'sin(',
        ['cosinus', 'de']: 'cos(',
        ['tangente', 'de']: 'tan(',
        ['logarithme', 'népérien', 'de']: 'ln(',
        ['logarithme', 'neperien', 'de']: 'ln(',
        ['logarithme', 'de']: 'log(',
      };

  @override
  Map<String, String> get singleWords => const {
        'plus': '+',
        'moins': '-',
        'fois': '*',
        'sur': '/',
        'divisé': '/',
        'divise': '/',
        'puissance': '^',
        'pourcent': '%',
        'factorielle': '!',
        'pi': 'pi',
        'racine': 'sqrt(',
      };

  @override
  Set<String> get fillerWords => const {
        'combien', 'font', 'fait', 'est', 'quel', 'quelle', 'le', 'la', 'les',
        'calcule', 'calculer', 'résultat', 'resultat', 'égal', 'egal',
        'égale', 'egale', 'du', 'vaut', 'ça', 'ca',
      };

  @override
  SpeechTerms get speech => SpeechTerms(
        plus: 'plus',
        minus: 'moins',
        times: 'fois',
        dividedBy: 'divisé par',
        modulo: 'modulo',
        negative: 'moins',
        factorial: 'factorielle',
        percent: 'pour cent',
        openParen: 'parenthèse ouvrante',
        closeParen: 'parenthèse fermante',
        fractionOpen: 'fraction',
        fractionOver: 'sur',
        fractionEnd: 'fin de fraction',
        squared: 'au carré',
        cubed: 'au cube',
        toThePowerOf: 'puissance',
        powerEnd: 'fin de puissance',
        squareRootOf: 'racine carrée de',
        cubeRootOf: 'racine cubique de',
        nthRootOf: (index) => 'racine $index-ième de',
        rootEnd: 'fin de racine',
        absoluteValueOf: 'valeur absolue de',
        absoluteEnd: 'fin de valeur absolue',
        decimalPoint: 'virgule',
        emptySlot: 'case vide',
        emptyNamedSlot: (role) => 'case vide : $role',
        matrixSize: (rows, columns) => 'matrice $rows par $columns',
        matrixRow: (number) => 'ligne $number : ',
        matrixEnd: 'fin de matrice',
        equals: 'égale',
        and: 'et',
        functionOf: 'de',
        functionEnd: (spokenName) => 'fin de $spokenName',
        plusOrMinus: 'plus ou moins',
        relation: (name) => switch (name) {
          'equals' => 'égale',
          'notEquals' => 'différent de',
          'lessThan' => 'inférieur à',
          'lessOrEqual' => 'inférieur ou égal à',
          'greaterThan' => 'supérieur à',
          'greaterOrEqual' => 'supérieur ou égal à',
          'approximately' => 'environ',
          _ => name,
        },
        functionNames: const {
          'sin': 'sinus',
          'cos': 'cosinus',
          'tan': 'tangente',
          'asin': 'arc sinus',
          'arcsin': 'arc sinus',
          'acos': 'arc cosinus',
          'arccos': 'arc cosinus',
          'atan': 'arc tangente',
          'arctan': 'arc tangente',
          'sinh': 'sinus hyperbolique',
          'cosh': 'cosinus hyperbolique',
          'tanh': 'tangente hyperbolique',
          'ln': 'logarithme népérien',
          'log': 'logarithme',
          'exp': 'exponentielle',
          'abs': 'valeur absolue',
        },
        simpleFraction: (numerator, denominator) {
          // "tiers" is invariable; "demi" and "quart" take a plural s.
          const names = {
            '2': (singular: 'demi', plural: 'demis'),
            '3': (singular: 'tiers', plural: 'tiers'),
            '4': (singular: 'quart', plural: 'quarts'),
          };
          final name = names[denominator];
          if (name == null) return null;
          return numerator == '1'
              ? 'un ${name.singular}'
              : '$numerator ${name.plural}';
        },
      );
}
