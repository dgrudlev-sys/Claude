/// Which languages this app's *maths* layer understands, as distinct
/// from which languages the device can speak.
///
/// These are different questions and conflating them would mislead
/// users. A phone may ship 70 text-to-speech voices, but voice input
/// only works where we can turn spoken words into an expression
/// ("sixteen divided by four"), and spoken read-back only works where we
/// have the phrases to say ("square root of", "end fraction").
///
/// Adding a language means adding a [MathVocabulary] — data and one
/// number-composition strategy — and registering it below. No changes to
/// the parser, the renderer, or any maths are needed.
library;

/// How a language builds numbers out of words.
///
/// This cannot be a flat word-to-value table, because languages compose
/// numbers differently, not just name them differently:
///
///   English  "twenty five"      → 20 + 5, two words, in order
///   German   "fünfundzwanzig"   → 5-and-20, reversed, and one word
///   French   "quatre-vingt-dix" → 4 × 20 + 10 = 90
///   Danish   "halvfems"         → 90, from a vigesimal "half-fifth × 20"
///
/// So each language supplies its own composition strategy rather than
/// just its own vocabulary.
abstract class SpokenNumberParser {
  /// Consumes number words starting at [start], returning the digits and
  /// how many words were used, or null when [start] isn't a number.
  ({String digits, int wordsConsumed})? parseAt(List<String> words, int start);

  bool isNumberWord(String word);
}

/// Maps accented Latin letters onto their base letters.
///
/// Speech recognisers are inconsistent about accents, and people typing a
/// number word often skip them — "dieciseis" for "dieciséis", "tva" for
/// "två". Folding both the lookup tables and the input through this means
/// the tables can keep the correct orthography while still matching what
/// actually arrives.
///
/// Not applied to German, whose umlauts have their own established
/// transliterations ("ü" → "ue") that this would get wrong.
String foldDiacritics(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final character = String.fromCharCode(rune);
    buffer.write(_folded[character] ?? character);
  }
  return buffer.toString();
}

const _folded = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'œ': 'oe',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  // Russian writes ё as е in most text, including what recognisers emit.
  'ё': 'е',
};

/// Reads the digits spoken after a decimal separator and appends them.
///
/// Every language does this the same way — the digits after the
/// separator are read singly, "three point one four" rather than "three
/// point fourteen" — so only the separator word and the digit table
/// differ. Shared rather than copied into each parser, because a bug
/// fixed here should be fixed for every language at once.
({String digits, int wordsConsumed}) withDecimalTail({
  required String whole,
  required List<String> words,
  required int start,
  required int consumed,
  required Set<String> separators,
  required int? Function(String word) digitOf,
}) {
  final separatorAt = start + consumed;
  if (separatorAt >= words.length ||
      !separators.contains(words[separatorAt].toLowerCase())) {
    return (digits: whole, wordsConsumed: consumed);
  }

  final decimals = StringBuffer();
  var scan = separatorAt + 1;
  while (scan < words.length) {
    final digit = digitOf(words[scan].toLowerCase());
    if (digit == null || digit < 0 || digit > 9) break;
    decimals.write(digit);
    scan++;
  }

  // A separator with no digits after it was not a decimal point at all.
  if (decimals.isEmpty) return (digits: whole, wordsConsumed: consumed);
  return (digits: '$whole.$decimals', wordsConsumed: scan - start);
}

/// The words used when speaking an expression back.
///
/// Held as data rather than scattered through the renderer, so a
/// translator only has to fill in this object.
class SpeechTerms {
  const SpeechTerms({
    required this.plus,
    required this.minus,
    required this.times,
    required this.dividedBy,
    required this.modulo,
    required this.negative,
    required this.factorial,
    required this.percent,
    required this.openParen,
    required this.closeParen,
    required this.fractionOpen,
    required this.fractionOver,
    required this.fractionEnd,
    required this.squared,
    required this.cubed,
    required this.toThePowerOf,
    required this.powerEnd,
    required this.squareRootOf,
    required this.cubeRootOf,
    required this.nthRootOf,
    required this.rootEnd,
    required this.absoluteValueOf,
    required this.absoluteEnd,
    required this.decimalPoint,
    required this.emptySlot,
    required this.emptyNamedSlot,
    required this.matrixSize,
    required this.matrixRow,
    required this.matrixEnd,
    required this.equals,
    required this.and,
    required this.plusOrMinus,
    required this.relation,
    required this.functionNames,
    required this.functionOf,
    required this.functionEnd,
    required this.simpleFraction,
  });

  final String plus;
  final String minus;
  final String times;
  final String dividedBy;
  final String modulo;

  /// "plus or minus" — the ± of the quadratic formula.
  final String plusOrMinus;

  /// How a relation is read, given the operator's name: equals, lessThan
  /// and so on. A function rather than seven fields because the set is
  /// closed and the phrasing is regular within a language.
  final String Function(String relationName) relation;

  final String negative;
  final String factorial;
  final String percent;

  final String openParen;
  final String closeParen;

  /// "fraction … over … end fraction". The closing marker is what lets a
  /// listener tell where a fraction stops without seeing it.
  final String fractionOpen;
  final String fractionOver;
  final String fractionEnd;

  final String squared;
  final String cubed;
  final String toThePowerOf;
  final String powerEnd;

  final String squareRootOf;
  final String cubeRootOf;

  /// Given the index, produces "5th root of" or the language's equivalent.
  final String Function(String index) nthRootOf;
  final String rootEnd;

  final String absoluteValueOf;
  final String absoluteEnd;

  final String decimalPoint;

  final String emptySlot;

  /// Given a role name, produces "empty numerator" or its equivalent.
  final String Function(String role) emptyNamedSlot;

  /// Given rows and columns, produces "2 by 3 matrix".
  final String Function(String rows, String columns) matrixSize;

  /// Given a row number, produces "row 1: ".
  final String Function(String number) matrixRow;
  final String matrixEnd;

  final String equals;

  /// Joins a whole number and a fraction: "3 and one half".
  final String and;

  /// Function name to spoken name: sin → "sine".
  final Map<String, String> functionNames;

  /// Joins a function to its argument: "sine **of** x", "Sinus **von** x".
  final String functionOf;

  /// Closes a function whose argument was long enough to need it: given
  /// the spoken name, produces "end sine" or "Sinus Ende".
  final String Function(String spokenName) functionEnd;

  /// The natural spoken name for a common fraction ("one half", "drei
  /// Viertel"), or null when the language has none for that denominator
  /// and the general "fraction … over …" form should be used instead.
  ///
  /// A function rather than a table because languages inflect these
  /// differently: English pluralises the denominator ("3 quarters"),
  /// German does not ("drei Viertel").
  final String? Function(String numerator, String denominator) simpleFraction;
}

/// Everything the spoken-maths layer needs for one language, in both
/// directions: understanding what was said, and saying results back.
abstract class MathVocabulary {
  const MathVocabulary();

  /// Language code this vocabulary covers, e.g. "en". Regional variants
  /// share one vocabulary — "en-GB" and "en-US" do the same maths.
  String get languageCode;

  String get displayName;

  /// How this language composes spoken numbers.
  SpokenNumberParser get numbers;

  /// Multi-word spoken phrases mapped to mathematical notation. Longest
  /// match wins, so "divided by" beats "by".
  Map<List<String>, String> get phrases;

  /// Single spoken words mapped to notation.
  Map<String, String> get singleWords;

  /// Words carrying no mathematical meaning, dropped before parsing.
  Set<String> get fillerWords;

  /// The words used when speaking an expression back.
  SpeechTerms get speech;
}

/// The vocabularies actually implemented.
///
/// Deliberately a small, checkable list rather than an assumption: the
/// UI asks this before telling a user that voice features will work in
/// their language.
///
/// The map is passed in rather than filled by registration calls at
/// startup, so the set of supported languages is a compile-time constant
/// that cannot silently be empty because some `main` forgot to register.
/// The shipped set lives in `vocabularies.dart`; tests pass their own.
class MathVocabularyRegistry {
  const MathVocabularyRegistry({required this.vocabularies});

  /// Vocabularies by language code, e.g. `'de'`.
  final Map<String, MathVocabulary> vocabularies;

  Set<String> get supportedLanguageCodes => vocabularies.keys.toSet();

  bool supportsLanguage(String localeTag) =>
      vocabularies.containsKey(languageCodeOf(localeTag));

  /// The vocabulary for a locale, or null when unsupported.
  MathVocabulary? forLocale(String localeTag) =>
      vocabularies[languageCodeOf(localeTag)];

  /// "en-US" → "en", "da" → "da".
  static String languageCodeOf(String localeTag) {
    final separator = localeTag.indexOf(RegExp('[-_]'));
    final code = separator == -1 ? localeTag : localeTag.substring(0, separator);
    return code.toLowerCase();
  }
}
