/// Which languages this app's *maths* layer understands, as distinct
/// from which languages the device can speak.
///
/// These are different questions and conflating them would mislead
/// users. A phone may ship 70 text-to-speech voices, but voice input
/// only works where we can turn spoken words into an expression
/// ("sixteen divided by four"), and spoken read-back only works where we
/// have the phrases to say ("square root of", "end fraction"). Today
/// that is English alone.
///
/// Adding a language means adding a [MathVocabulary] — a data file, not
/// new logic — and registering it here.
library;

/// How a language builds numbers out of words.
///
/// This cannot be a flat word-to-value table, because languages compose
/// numbers differently, not just name them differently:
///
///   English  "twenty five"      → 20 + 5, in that order
///   German   "fünfundzwanzig"   → 5-and-20, reversed, and one word
///   French   "quatre-vingt-dix" → 4 × 20 + 10 = 90
///   Danish   "halvfems"         → 90, from a vigesimal "half-fifth × 20"
///
/// So each language supplies its own composition strategy rather than
/// just its own vocabulary. English's is the simple accumulate-and-add
/// rule; others genuinely need their own.
abstract class SpokenNumberParser {
  /// Consumes number words starting at [start], returning the digits and
  /// how many words were used, or null when [start] isn't a number.
  ({String digits, int wordsConsumed})? parseAt(List<String> words, int start);

  bool isNumberWord(String word);
}

/// The language-specific words the spoken-maths layer needs, in both
/// directions: recognising what was said, and saying results back.
abstract class MathVocabulary {
  /// BCP-47 tag this vocabulary covers, e.g. "en".
  String get languageCode;

  String get displayName;

  /// How this language composes spoken numbers.
  SpokenNumberParser get numbers;

  /// Multi-word spoken phrases mapped to mathematical notation, longest
  /// matched first ("divided by" before "by").
  Map<List<String>, String> get phrases;

  /// Words carrying no mathematical meaning, dropped before parsing.
  Set<String> get fillerWords;

  /// Terms used when speaking an expression back.
  String get fractionOpen;
  String get fractionSeparator;
  String get fractionEnd;
  String get squared;
  String get cubed;
  String get squareRootOf;
  String get endRoot;
}

/// The vocabularies actually implemented.
///
/// Deliberately a small, checkable list rather than an assumption: the
/// UI asks this before telling a user that voice features will work in
/// their language.
class MathVocabularyRegistry {
  const MathVocabularyRegistry();

  /// Language codes the maths layer handles. Kept as codes rather than
  /// full locales because "en-GB" and "en-US" share their maths words.
  static const supportedLanguageCodes = {'en'};

  bool supportsLanguage(String localeTag) {
    final code = languageCodeOf(localeTag);
    return supportedLanguageCodes.contains(code);
  }

  /// "en-US" -> "en", "da" -> "da".
  static String languageCodeOf(String localeTag) {
    final separator = localeTag.indexOf(RegExp('[-_]'));
    final code = separator == -1 ? localeTag : localeTag.substring(0, separator);
    return code.toLowerCase();
  }
}
