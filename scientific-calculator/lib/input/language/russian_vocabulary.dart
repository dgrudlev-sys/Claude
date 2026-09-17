import 'math_vocabulary.dart';

/// Russian composes numbers in plain descending order, which makes the
/// arithmetic of parsing easy. What it does instead is inflect: nearly
/// every number word has several forms, and the recogniser returns
/// whichever one the sentence called for.
///
///   один / одна / одно      one, by gender
///   два / две               two, by gender
///   тысяча / тысячи / тысяч thousand, by case and count
///
/// So the tables carry the forms rather than trying to derive them, and
/// the irregular tens (сорок for 40, девяносто for 90, which break the
/// -дцать and -десят patterns) are simply listed.
class RussianNumberParser implements SpokenNumberParser {
  const RussianNumberParser();

  static const _small = {
    'ноль': 0, 'нуль': 0,
    'один': 1, 'одна': 1, 'одно': 1,
    'два': 2, 'две': 2,
    'три': 3, 'четыре': 4, 'пять': 5, 'шесть': 6, 'семь': 7,
    'восемь': 8, 'девять': 9, 'десять': 10,
    'одиннадцать': 11, 'двенадцать': 12, 'тринадцать': 13,
    'четырнадцать': 14, 'пятнадцать': 15, 'шестнадцать': 16,
    'семнадцать': 17, 'восемнадцать': 18, 'девятнадцать': 19,
    // Oblique forms, which is what actually arrives after a preposition:
    // "корень из шестнадцати", not "из шестнадцать". Without these,
    // every root and logarithm in Russian would fail to parse.
    'одного': 1, 'одной': 1, 'двух': 2, 'трёх': 3, 'четырёх': 4,
    'пяти': 5, 'шести': 6, 'семи': 7, 'восьми': 8, 'девяти': 9,
    'десяти': 10, 'одиннадцати': 11, 'двенадцати': 12, 'тринадцати': 13,
    'четырнадцати': 14, 'пятнадцати': 15, 'шестнадцати': 16,
    'семнадцати': 17, 'восемнадцати': 18, 'девятнадцати': 19,
  };

  static const _tens = {
    'двадцать': 20, 'тридцать': 30,
    // Neither of these follows the pattern of the others.
    'сорок': 40, 'девяносто': 90,
    'пятьдесят': 50, 'шестьдесят': 60, 'семьдесят': 70, 'восемьдесят': 80,
    'двадцати': 20, 'тридцати': 30, 'сорока': 40, 'девяноста': 90,
    'пятидесяти': 50, 'шестидесяти': 60, 'семидесяти': 70,
    'восьмидесяти': 80,
  };

  static const _hundreds = {
    'сто': 100, 'двести': 200, 'триста': 300, 'четыреста': 400,
    'пятьсот': 500, 'шестьсот': 600, 'семьсот': 700, 'восемьсот': 800,
    'девятьсот': 900,
    'ста': 100, 'двухсот': 200, 'трёхсот': 300, 'четырёхсот': 400,
    'пятисот': 500, 'шестисот': 600, 'семисот': 700, 'восьмисот': 800,
    'девятисот': 900,
  };

  /// Each scale word in the three forms a count can demand: одна тысяча,
  /// две тысячи, пять тысяч.
  static const _scales = {
    'тысяча': 1000, 'тысячи': 1000, 'тысяч': 1000,
    'миллион': 1000000, 'миллиона': 1000000, 'миллионов': 1000000,
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
    var rank = 0; // 0 nothing yet, 1 after hundreds, 2 after tens, 3 done
    var index = start;

    while (index < words.length) {
      final word = _key(words[index]);

      final scale = _foldedScales[word];
      if (scale != null) {
        total += (current == 0 ? 1 : current) * scale;
        current = 0;
        rank = 0;
        sawAny = true;
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
        // Nothing follows a teen: "двадцать двенадцать" is not a number.
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
      separators: const {'запятая', 'точка'},
      digitOf: (word) => _foldedSmall[_key(word)],
    );
  }
}

class RussianMathVocabulary extends MathVocabulary {
  const RussianMathVocabulary();

  @override
  String get languageCode => 'ru';

  @override
  String get displayName => 'Русский';

  @override
  SpokenNumberParser get numbers => const RussianNumberParser();

  @override
  Map<List<String>, String> get phrases => const {
        ['квадратный', 'корень', 'из']: 'sqrt(',
        ['корень', 'из']: 'sqrt(',
        ['кубический', 'корень', 'из']: 'cbrt(',
        ['модуль', 'от']: 'abs(',
        ['разделить', 'на']: '/',
        ['делить', 'на']: '/',
        ['поделить', 'на']: '/',
        ['умножить', 'на']: '*',
        ['в', 'квадрате']: '^2',
        ['в', 'кубе']: '^3',
        ['в', 'степени']: '^',
        ['открыть', 'скобку']: '(',
        ['закрыть', 'скобку']: ')',
        ['синус', 'от']: 'sin(',
        ['косинус', 'от']: 'cos(',
        ['тангенс', 'от']: 'tan(',
        ['натуральный', 'логарифм', 'от']: 'ln(',
        ['логарифм', 'от']: 'log(',
      };

  @override
  Map<String, String> get singleWords => const {
        'плюс': '+',
        'минус': '-',
        'умножить': '*',
        'разделить': '/',
        'делить': '/',
        'процент': '%',
        'процентов': '%',
        'факториал': '!',
        'пи': 'pi',
        'корень': 'sqrt(',
      };

  @override
  Set<String> get fillerWords => const {
        'сколько', 'будет', 'чему', 'равно', 'равняется', 'посчитай',
        'вычисли', 'пожалуйста', 'это', 'и',
      };

  @override
  SpeechTerms get speech => SpeechTerms(
        plus: 'плюс',
        minus: 'минус',
        times: 'умножить на',
        dividedBy: 'разделить на',
        modulo: 'по модулю',
        negative: 'минус',
        factorial: 'факториал',
        percent: 'процентов',
        openParen: 'открыть скобку',
        closeParen: 'закрыть скобку',
        fractionOpen: 'дробь',
        fractionOver: 'делить на',
        fractionEnd: 'конец дроби',
        squared: 'в квадрате',
        cubed: 'в кубе',
        toThePowerOf: 'в степени',
        powerEnd: 'конец степени',
        squareRootOf: 'квадратный корень из',
        cubeRootOf: 'кубический корень из',
        nthRootOf: (index) => 'корень $index-й степени из',
        rootEnd: 'конец корня',
        absoluteValueOf: 'модуль от',
        absoluteEnd: 'конец модуля',
        decimalPoint: 'запятая',
        emptySlot: 'пустое поле',
        emptyNamedSlot: (role) => 'пустое поле: $role',
        matrixSize: (rows, columns) => 'матрица $rows на $columns',
        matrixRow: (number) => 'строка $number: ',
        matrixEnd: 'конец матрицы',
        equals: 'равно',
        and: 'и',
        functionOf: 'от',
        // "конец синуса" would need the genitive of a name this cannot
        // inflect, so the label goes first and stays in the nominative —
        // "синус, конец" rather than ungrammatical "конец синус".
        functionEnd: (spokenName) => '$spokenName конец',
        functionNames: const {
          'sin': 'синус',
          'cos': 'косинус',
          'tan': 'тангенс',
          'asin': 'арксинус',
          'arcsin': 'арксинус',
          'acos': 'арккосинус',
          'arccos': 'арккосинус',
          'atan': 'арктангенс',
          'arctan': 'арктангенс',
          'sinh': 'гиперболический синус',
          'cosh': 'гиперболический косинус',
          'tanh': 'гиперболический тангенс',
          'ln': 'натуральный логарифм',
          'log': 'логарифм',
          'exp': 'экспонента',
          'abs': 'модуль',
        },
        simpleFraction: (numerator, denominator) {
          // Russian names fractions with an ordinal that agrees with the
          // numerator: одна вторая, but три четвёртых.
          const singular = {'2': 'вторая', '3': 'третья', '4': 'четвёртая'};
          const plural = {'2': 'вторых', '3': 'третьих', '4': 'четвёртых'};
          if (!singular.containsKey(denominator)) return null;
          return numerator == '1'
              ? 'одна ${singular[denominator]}'
              : '$numerator ${plural[denominator]}';
        },
      );
}
