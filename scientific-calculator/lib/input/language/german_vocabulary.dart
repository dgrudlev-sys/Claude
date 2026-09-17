import 'math_vocabulary.dart';

/// German writes compound numbers as a single word, and reverses the
/// units and tens: "fünfundzwanzig" is literally *five-and-twenty*, and
/// "hundertfünfundzwanzig" is 125 in one token.
///
/// A speech recogniser therefore hands back one long word where English
/// gives several, so parsing means decomposing the word itself rather
/// than accumulating across tokens. This is exactly why
/// [SpokenNumberParser] is a strategy and not a lookup table.
class GermanNumberParser implements SpokenNumberParser {
  const GermanNumberParser();

  /// Forms used inside compounds. "eins" only stands alone — inside a
  /// compound it is "ein" ("einundzwanzig", never "einsundzwanzig").
  static const _units = {
    'null': 0,
    'eins': 1, 'ein': 1, 'eine': 1,
    'zwei': 2, 'drei': 3, 'vier': 4, 'fünf': 5, 'fuenf': 5,
    'sechs': 6, 'sieben': 7, 'acht': 8, 'neun': 9,
    'zehn': 10, 'elf': 11, 'zwölf': 12, 'zwoelf': 12,
    'dreizehn': 13, 'vierzehn': 14, 'fünfzehn': 15, 'fuenfzehn': 15,
    // Irregular: the s of sechs and the en of sieben are dropped.
    'sechzehn': 16, 'siebzehn': 17, 'achtzehn': 18, 'neunzehn': 19,
  };

  static const _tens = {
    'zwanzig': 20,
    'dreißig': 30, 'dreissig': 30,
    'vierzig': 40, 'fünfzig': 50, 'fuenfzig': 50,
    'sechzig': 60, 'siebzig': 70, 'achtzig': 80, 'neunzig': 90,
  };

  @override
  bool isNumberWord(String word) => _decompose(word.toLowerCase()) != null;

  @override
  ({String digits, int wordsConsumed})? parseAt(List<String> words, int start) {
    if (start >= words.length) return null;
    final value = _decompose(words[start].toLowerCase());
    if (value == null) return null;

    var digits = '$value';
    var consumed = 1;

    // German uses a comma as the decimal separator, spoken "komma", and
    // the digits after it are read singly: "drei komma eins vier".
    final next = start + 1;
    if (next < words.length && (words[next] == 'komma' || words[next] == 'comma')) {
      final decimals = StringBuffer();
      var scan = next + 1;
      while (scan < words.length) {
        final digit = _units[words[scan].toLowerCase()];
        if (digit == null || digit > 9) break;
        decimals.write(digit);
        scan++;
      }
      if (decimals.isNotEmpty) {
        digits = '$digits.$decimals';
        consumed = scan - start;
      }
    }

    return (digits: digits, wordsConsumed: consumed);
  }

  /// Breaks a compound German numeral into its value.
  ///
  /// Order matters: "hundert" itself contains the letters "und", so the
  /// scale words have to be split off before the und-infix is looked for,
  /// or every hundred would be misread as an addition.
  int? _decompose(String word) {
    if (word.isEmpty) return null;

    for (final scale in const [
      (word: 'million', value: 1000000),
      (word: 'tausend', value: 1000),
      (word: 'hundert', value: 100),
    ]) {
      final index = word.indexOf(scale.word);
      if (index == -1) continue;

      final leftText = word.substring(0, index);
      var rightText = word.substring(index + scale.word.length);
      // "zweihundertundfünf" — the older joining "und" carries no value.
      if (rightText.startsWith('und')) rightText = rightText.substring(3);

      // A bare "hundert" means one hundred, not zero hundreds.
      final left = leftText.isEmpty ? 1 : _decompose(leftText);
      final right = rightText.isEmpty ? 0 : _decompose(rightText);
      if (left == null || right == null) return null;
      return left * scale.value + right;
    }

    // "fünfundzwanzig" → 5 + 20. The units come first in speech and in
    // spelling, which is the reverse of the written digits.
    final undIndex = word.indexOf('und');
    if (undIndex > 0) {
      final unit = _units[word.substring(0, undIndex)];
      final ten = _tens[word.substring(undIndex + 3)];
      if (unit != null && ten != null) return ten + unit;
    }

    return _units[word] ?? _tens[word];
  }
}

class GermanMathVocabulary extends MathVocabulary {
  const GermanMathVocabulary();

  @override
  String get languageCode => 'de';

  @override
  String get displayName => 'Deutsch';

  @override
  SpokenNumberParser get numbers => const GermanNumberParser();

  @override
  Map<List<String>, String> get phrases => const {
        ['quadratwurzel', 'aus']: 'sqrt(',
        ['wurzel', 'aus']: 'sqrt(',
        ['kubikwurzel', 'aus']: 'cbrt(',
        ['dritte', 'wurzel', 'aus']: 'cbrt(',
        ['betrag', 'von']: 'abs(',
        ['geteilt', 'durch']: '/',
        ['dividiert', 'durch']: '/',
        ['multipliziert', 'mit']: '*',
        ['zum', 'quadrat']: '^2',
        ['hoch', 'zwei']: '^2',
        ['hoch', 'drei']: '^3',
        ['klammer', 'auf']: '(',
        ['klammer', 'zu']: ')',
        ['sinus', 'von']: 'sin(',
        ['kosinus', 'von']: 'cos(',
        ['cosinus', 'von']: 'cos(',
        ['tangens', 'von']: 'tan(',
        ['natürlicher', 'logarithmus', 'von']: 'ln(',
        ['logarithmus', 'von']: 'log(',
      };

  @override
  Map<String, String> get singleWords => const {
        'plus': '+',
        'minus': '-',
        'mal': '*',
        'durch': '/',
        'geteilt': '/',
        'hoch': '^',
        'prozent': '%',
        'fakultät': '!',
        'fakultaet': '!',
        'pi': 'pi',
        'wurzel': 'sqrt(',
      };

  @override
  Set<String> get fillerWords => const {
        'was', 'ist', 'wie', 'viel', 'bitte', 'berechne', 'rechne', 'gleich',
        'das', 'der', 'die', 'ergebnis', 'sag', 'mir',
      };

  @override
  SpeechTerms get speech => SpeechTerms(
        plus: 'plus',
        minus: 'minus',
        times: 'mal',
        dividedBy: 'geteilt durch',
        modulo: 'modulo',
        negative: 'minus',
        factorial: 'Fakultät',
        percent: 'Prozent',
        openParen: 'Klammer auf',
        closeParen: 'Klammer zu',
        fractionOpen: 'Bruch',
        fractionOver: 'durch',
        fractionEnd: 'Bruch Ende',
        squared: 'zum Quadrat',
        cubed: 'hoch drei',
        toThePowerOf: 'hoch',
        powerEnd: 'Potenz Ende',
        squareRootOf: 'Quadratwurzel aus',
        cubeRootOf: 'Kubikwurzel aus',
        nthRootOf: (index) => '$index-te Wurzel aus',
        rootEnd: 'Wurzel Ende',
        absoluteValueOf: 'Betrag von',
        absoluteEnd: 'Betrag Ende',
        decimalPoint: 'Komma',
        emptySlot: 'leeres Feld',
        emptyNamedSlot: (role) => 'leeres Feld: $role',
        matrixSize: (rows, columns) => '$rows mal $columns Matrix',
        matrixRow: (number) => 'Zeile $number: ',
        matrixEnd: 'Matrix Ende',
        equals: 'gleich',
        and: 'und',
        functionNames: const {
          'sin': 'Sinus',
          'cos': 'Kosinus',
          'tan': 'Tangens',
          'asin': 'Arkussinus',
          'arcsin': 'Arkussinus',
          'acos': 'Arkuskosinus',
          'arccos': 'Arkuskosinus',
          'atan': 'Arkustangens',
          'arctan': 'Arkustangens',
          'sinh': 'Sinus hyperbolicus',
          'cosh': 'Kosinus hyperbolicus',
          'tanh': 'Tangens hyperbolicus',
          'ln': 'natürlicher Logarithmus',
          'log': 'Logarithmus',
          'exp': 'e hoch',
          'abs': 'Betrag',
        },
        functionOf: 'von',
        // German closes with a trailing marker rather than a leading one:
        // "Sinus Ende", not "Ende Sinus".
        functionEnd: (spokenName) => '$spokenName Ende',
        // German does not pluralise these: "drei Viertel", not "Viertels".
        simpleFraction: (numerator, denominator) {
          const names = {'2': 'Halb', '3': 'Drittel', '4': 'Viertel'};
          final name = names[denominator];
          if (name == null) return null;
          return numerator == '1' ? 'ein $name' : '$numerator $name';
        },
      );
}
