import 'danish_vocabulary.dart';
import 'english_vocabulary.dart';
import 'french_vocabulary.dart';
import 'german_vocabulary.dart';
import 'math_vocabulary.dart';
import 'russian_vocabulary.dart';
import 'spanish_vocabulary.dart';
import 'swedish_vocabulary.dart';

/// The languages this app's maths layer actually understands.
///
/// This list is the single source of truth for that claim. The language
/// picker reads it to decide whether to promise a user voice input and
/// spoken results in their language, or to warn them that maths will
/// fall back to English — so adding a language here is what makes the
/// promise, and nothing else needs changing.
///
/// Adding one means writing a [MathVocabulary] (phrases, speech terms,
/// and a number-composition strategy) and adding a line below.
const shippedMathVocabularies = MathVocabularyRegistry(vocabularies: {
  'en': EnglishMathVocabulary(),
  'de': GermanMathVocabulary(),
  'fr': FrenchMathVocabulary(),
  'es': SpanishMathVocabulary(),
  'ru': RussianMathVocabulary(),
  'da': DanishMathVocabulary(),
  'sv': SwedishMathVocabulary(),
});
