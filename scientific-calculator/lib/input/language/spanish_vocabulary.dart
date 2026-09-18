import 'math_vocabulary.dart';

/// Spanish fuses its compounds only in the twenties, and names its
/// hundreds rather than composing them.
///
///   dieciséis        16, one word
///   veinticinco      25, one word — but "treinta y cinco" is three
///   quinientos       500, not "cinco cientos"
///
/// So the parser needs three separate tables — hundreds, tens, and a
/// units table that runs all the way to 29 because of the fused
/// twenties — combined in strictly descending order.
class SpanishNumberParser implements SpokenNumberParser {
  const SpanishNumberParser();

  static const _small = {
    'cero': 0,
    'uno': 1, 'un': 1, 'una': 1, 'dos': 2, 'tres': 3, 'cuatro': 4,
    'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10,
    'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
    // Sixteen through nineteen fuse "diez y …" into one word.
    'dieciséis': 16, 'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19,
    // As do the whole of the twenties.
    'veintiuno': 21, 'veintiún': 21, 'veintiuna': 21, 'veintidós': 22,
    'veintitrés': 23, 'veinticuatro': 24, 'veinticinco': 25,
    'veintiséis': 26, 'veintisiete': 27, 'veintiocho': 28,
    'veintinueve': 29,
  };

  static const _tens = {
    'veinte': 20, 'treinta': 30, 'cuarenta': 40, 'cincuenta': 50,
    'sesenta': 60, 'setenta': 70, 'ochenta': 80, 'noventa': 90,
  };

  /// Named outright, and irregular at 500, 700 and 900. The feminine
  /// forms appear whenever the thing counted is feminine.
  static const _hundreds = {
    'cien': 100, 'ciento': 100,
    'doscientos': 200, 'doscientas': 200,
    'trescientos': 300, 'trescientas': 300,
    'cuatrocientos': 400, 'cuatrocientas': 400,
    'quinientos': 500, 'quinientas': 500,
    'seiscientos': 600, 'seiscientas': 600,
    'setecientos': 700, 'setecientas': 700,
    'ochocientos': 800, 'ochocientas': 800,
    'novecientos': 900, 'novecientas': 900,
  };

  static const _scales = {
    'mil': 1000,
    'millón': 1000000, 'millon': 1000000, 'millones': 1000000,
  };

  static final _foldedSmall = _fold(_small);
  static final _foldedTens = _fold(_tens);
  static final _foldedHundreds = _fold(_hundreds);
  static final _foldedScales = _fold(_scales);

  static Map<String, int> _fold(Map<String, int> table) =>
      {for (final entry in table.entries) foldDiacritics(entry.key): entry.value};

  static String _key(String word) => foldDiacritics(word.toLowerCase());

  @override
  bool isNumberWord(String word) {
    final key = _key(word);
    return _foldedSmall.containsKey(key) ||
        _foldedTens.containsKey(key) ||
        _foldedHundreds.containsKey(key) ||
        _foldedScales.containsKey(key);
  }

  @override
  ({String digits, int wordsConsumed})? parseAt(List<String> words, int start) {
    var total = 0;
    var current = 0;
    var sawAny = false;
    // Parts of a number arrive largest first and never repeat, so one
    // rank counter is enough to reject "cinco cinco".
    var rank = 0; // 0 nothing yet, 1 after hundreds, 2 after tens, 3 done
    var index = start;

    while (index < words.length) {
      final word = _key(words[index]);

      final scale = _foldedScales[word];
      if (scale != null) {
        // "mil" alone is a thousand, not zero thousands.
        total += (current == 0 ? 1 : current) * scale;
        current = 0;
        rank = 0;
        sawAny = true;
        index++;
        continue;
      }

      // "treinta y cinco" — the joining "y" carries no value.
      if (word == 'y' &&
          rank == 2 &&
          index + 1 < words.length &&
          _foldedSmall.containsKey(_key(words[index + 1]))) {
        index++;
        continue;
      }

      final hundreds = _foldedHundreds[word];
      if (hundreds != null) {
        if (rank > 0) break;
        current += hundreds;
        rank = 1;
        sawAny = true;
        index++;
        continue;
      }

      final ten = _foldedTens[word];
      if (ten != null) {
        if (rank > 1) break;
        current += ten;
        rank = 2;
        sawAny = true;
        index++;
        continue;
      }

      final small = _foldedSmall[word];
      if (small != null) {
        if (rank > 2) break;
        // Nothing follows a fused twenty or a teen.
        if (rank == 2 && small > 9) break;
        current += small;
        rank = 3;
        sawAny = true;
        index++;
        continue;
      }

      break;
    }

    if (!sawAny) return null;

    return withDecimalTail(
      whole: '${total + current}',
      words: words,
      start: start,
      consumed: index - start,
      separators: const {'coma', 'punto'},
      digitOf: (word) => _foldedSmall[_key(word)],
    );
  }
}

class SpanishMathVocabulary extends MathVocabulary {
  const SpanishMathVocabulary();

  @override
  String get languageCode => 'es';

  @override
  String get displayName => 'Español';

  @override
  SpokenNumberParser get numbers => const SpanishNumberParser();

  @override
  Map<List<String>, String> get phrases => const {
        ['raíz', 'cuadrada', 'de']: 'sqrt(',
        ['raiz', 'cuadrada', 'de']: 'sqrt(',
        ['raíz', 'de']: 'sqrt(',
        ['raiz', 'de']: 'sqrt(',
        ['raíz', 'cúbica', 'de']: 'cbrt(',
        ['raiz', 'cubica', 'de']: 'cbrt(',
        ['valor', 'absoluto', 'de']: 'abs(',
        ['dividido', 'entre']: '/',
        ['dividido', 'por']: '/',
        ['multiplicado', 'por']: '*',
        ['al', 'cuadrado']: '^2',
        ['al', 'cubo']: '^3',
        ['elevado', 'a']: '^',
        ['abrir', 'paréntesis']: '(',
        ['abre', 'paréntesis']: '(',
        ['abrir', 'parentesis']: '(',
        ['cerrar', 'paréntesis']: ')',
        ['cierra', 'paréntesis']: ')',
        ['cerrar', 'parentesis']: ')',
        // "por ciento" must beat the bare "por", which is multiplication.
        ['por', 'ciento']: '%',
        ['por', 'favor']: '',
        ['seno', 'de']: 'sin(',
        ['coseno', 'de']: 'cos(',
        ['tangente', 'de']: 'tan(',
        ['logaritmo', 'natural', 'de']: 'ln(',
        ['logaritmo', 'neperiano', 'de']: 'ln(',
        ['logaritmo', 'de']: 'log(',
      };

  @override
  Map<String, String> get singleWords => const {
        'más': '+',
        'mas': '+',
        'menos': '-',
        'por': '*',
        'entre': '/',
        'dividido': '/',
        'elevado': '^',
        'porciento': '%',
        'factorial': '!',
        'pi': 'pi',
        'raíz': 'sqrt(',
        'raiz': 'sqrt(',
      };

  @override
  Set<String> get fillerWords => const {
        'cuánto', 'cuanto', 'es', 'son', 'qué', 'que', 'el', 'la', 'los',
        'las', 'calcula', 'calcular', 'resultado', 'igual', 'dime', 'vale',
      };

  @override
  SpeechTerms get speech => SpeechTerms(
        plus: 'más',
        minus: 'menos',
        times: 'por',
        dividedBy: 'entre',
        modulo: 'módulo',
        negative: 'menos',
        factorial: 'factorial',
        percent: 'por ciento',
        openParen: 'abrir paréntesis',
        closeParen: 'cerrar paréntesis',
        fractionOpen: 'fracción',
        fractionOver: 'entre',
        fractionEnd: 'fin de fracción',
        squared: 'al cuadrado',
        cubed: 'al cubo',
        toThePowerOf: 'elevado a',
        powerEnd: 'fin de potencia',
        squareRootOf: 'raíz cuadrada de',
        cubeRootOf: 'raíz cúbica de',
        nthRootOf: (index) => 'raíz $index-ésima de',
        rootEnd: 'fin de raíz',
        absoluteValueOf: 'valor absoluto de',
        absoluteEnd: 'fin de valor absoluto',
        decimalPoint: 'coma',
        emptySlot: 'casilla vacía',
        emptyNamedSlot: (role) => 'casilla vacía: $role',
        matrixSize: (rows, columns) => 'matriz $rows por $columns',
        matrixRow: (number) => 'fila $number: ',
        matrixEnd: 'fin de matriz',
        equals: 'igual a',
        and: 'y',
        functionOf: 'de',
        functionEnd: (spokenName) => 'fin de $spokenName',
        plusOrMinus: 'más menos',
        relation: (name) => switch (name) {
          'equals' => 'igual a',
          'notEquals' => 'distinto de',
          'lessThan' => 'menor que',
          'lessOrEqual' => 'menor o igual que',
          'greaterThan' => 'mayor que',
          'greaterOrEqual' => 'mayor o igual que',
          'approximately' => 'aproximadamente',
          _ => name,
        },
        functionNames: const {
          'sin': 'seno',
          'cos': 'coseno',
          'tan': 'tangente',
          'asin': 'arco seno',
          'arcsin': 'arco seno',
          'acos': 'arco coseno',
          'arccos': 'arco coseno',
          'atan': 'arco tangente',
          'arctan': 'arco tangente',
          'sinh': 'seno hiperbólico',
          'cosh': 'coseno hiperbólico',
          'tanh': 'tangente hiperbólica',
          'ln': 'logaritmo natural',
          'log': 'logaritmo',
          'exp': 'exponencial',
          'abs': 'valor absoluto',
        },
        simpleFraction: (numerator, denominator) {
          const names = {
            '2': (singular: 'medio', plural: 'medios'),
            '3': (singular: 'tercio', plural: 'tercios'),
            '4': (singular: 'cuarto', plural: 'cuartos'),
          };
          final name = names[denominator];
          if (name == null) return null;
          return numerator == '1'
              ? 'un ${name.singular}'
              : '$numerator ${name.plural}';
        },
      );
}
