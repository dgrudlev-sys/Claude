import '../../expression/expression.dart';
import '../../expression/parse/expression_parser.dart';
import '../../expression/render/speech_renderer.dart';
import '../language/english_vocabulary.dart';
import '../language/math_vocabulary.dart';

/// A reading of a spoken phrase that the app isn't certain about, along
/// with the alternative — so the UI can ask instead of guessing.
///
/// "Square root of nine plus four" is genuinely ambiguous in speech:
/// √9 + 4 = 7, or √(9+4) ≈ 3.61. Silently picking one and being wrong is
/// worse than a one-tap confirmation.
class SpokenAmbiguity {
  const SpokenAmbiguity({
    required this.reason,
    required this.chosenReading,
    required this.alternativeReading,
    required this.alternative,
  });

  final String reason;

  /// How the chosen interpretation reads aloud, for the confirmation UI.
  final String chosenReading;
  final String alternativeReading;

  /// The other tree, ready to swap in if the user picks it.
  final ExpressionNode alternative;
}

class SpokenMathResult {
  const SpokenMathResult({
    required this.expression,
    required this.normalizedSource,
    required this.confirmation,
    required this.ambiguities,
  });

  /// The parsed tree — the same Expression Model every other input
  /// method produces, so evaluation and editing come free.
  final ExpressionNode expression;

  /// The parser-ready text the phrase was normalised into, shown so the
  /// user can see what was understood.
  final String normalizedSource;

  /// The expression read back in words, for spoken confirmation.
  final String confirmation;

  final List<SpokenAmbiguity> ambiguities;

  bool get needsConfirmation => ambiguities.isNotEmpty;
}

class SpokenMathError implements Exception {
  const SpokenMathError(this.message, {this.heardAs});

  final String message;

  /// What the recogniser produced, so the error can show it back.
  final String? heardAs;

  @override
  String toString() => message;
}

/// Converts a speech transcript into an [ExpressionNode].
///
/// Works by normalising spoken phrasing into ordinary mathematical
/// notation and then handing that to the same [ExpressionParser] the
/// keyboard uses — so voice input can't drift out of sync with typed
/// input, because there's only one parser.
class SpokenMathParser {
  const SpokenMathParser({this.vocabulary = const EnglishMathVocabulary()});

  /// The language being spoken. Everything language-specific — number
  /// composition, phrases, filler — comes from here, so supporting a new
  /// language means supplying a vocabulary, not touching this class.
  final MathVocabulary vocabulary;

  static const _parser = ExpressionParser();

  SpokenNumberParser get _numberWords => vocabulary.numbers;
  SpeechRenderer get _speech => SpeechRenderer(vocabulary: vocabulary);

  /// Functions that open a paren and need it closed again.
  static const _openers = {'sqrt(', 'cbrt(', 'abs(', 'sin(', 'cos(', 'tan(', 'ln(', 'log('};

  SpokenMathResult parse(String transcript) {
    final words = transcript
        .toLowerCase()
        // Keep letters from any script: stripping to ASCII would turn
        // "fünfundzwanzig" into "fnfundzwanzig" and lose the number.
        .replaceAll(RegExp(r'[^\p{L}\p{N}.\s-]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      throw SpokenMathError('Nothing was heard', heardAs: transcript);
    }

    final build = _normalize(words, transcript);
    final ExpressionNode tree;
    try {
      tree = _parser.parse(build.source);
    } on ParseError catch (e) {
      throw SpokenMathError(
        'Could not turn that into a calculation: ${e.message}',
        heardAs: transcript,
      );
    }

    final ambiguities = <SpokenAmbiguity>[];
    for (final pending in build.ambiguities) {
      try {
        final alternative = _parser.parse(pending.alternativeSource);
        ambiguities.add(SpokenAmbiguity(
          reason: pending.reason,
          chosenReading: _speech.render(tree),
          alternativeReading: _speech.render(alternative),
          alternative: alternative,
        ));
      } on ParseError {
        // If the alternative doesn't parse, there was no real ambiguity.
      }
    }

    return SpokenMathResult(
      expression: tree,
      normalizedSource: build.source,
      confirmation: _speech.render(tree),
      ambiguities: ambiguities,
    );
  }

  _NormalizationResult _normalize(List<String> words, String transcript) {
    final out = StringBuffer();
    final ambiguities = <_PendingAmbiguity>[];

    // Tracks function parens we opened ourselves and closed tightly, so
    // we can offer "close at the end instead" as the alternative reading.
    final tightlyClosed = <_TightClose>[];

    var i = 0;
    while (i < words.length) {
      // Longest phrase match first.
      final phrase = _matchPhrase(words, i);
      if (phrase != null) {
        out.write(phrase.symbol);
        i += phrase.length;
        if (_openers.contains(phrase.symbol)) {
          final consumed = _writeAtom(words, i, out);
          if (consumed == 0) {
            // Nothing followed — let the parser report it properly.
            out.write(')');
          } else {
            i += consumed;
            out.write(')');
            tightlyClosed.add(_TightClose(
              functionName: phrase.symbol.replaceAll('(', ''),
              closePosition: out.length - 1,
            ));
          }
        }
        continue;
      }

      final word = words[i];

      final number = _numberWords.parseAt(words, i);
      if (number != null) {
        out.write(number.digits);
        i += number.wordsConsumed;
        continue;
      }

      final symbol = vocabulary.singleWords[word];
      if (symbol != null) {
        out.write(symbol);
        i++;
        if (_openers.contains(symbol)) {
          final consumed = _writeAtom(words, i, out);
          if (consumed == 0) {
            out.write(')');
          } else {
            i += consumed;
            out.write(')');
            tightlyClosed.add(_TightClose(
              functionName: symbol.replaceAll('(', ''),
              closePosition: out.length - 1,
            ));
          }
        }
        continue;
      }

      if (vocabulary.fillerWords.contains(word)) {
        i++;
        continue;
      }

      // A bare number already in digit form, e.g. the recogniser gave
      // "25" rather than "twenty five".
      if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(word)) {
        out.write(word);
        i++;
        continue;
      }

      // Single letters are variables: "two x plus one".
      if (RegExp(r'^[a-z]$').hasMatch(word)) {
        out.write(word);
        i++;
        continue;
      }

      throw SpokenMathError(
        'Did not understand "$word"',
        heardAs: transcript,
      );
    }

    final source = out.toString();

    // A function closed tightly, with maths continuing after it, could
    // equally have meant "everything that follows is inside the root".
    for (final close in tightlyClosed) {
      final after = source.substring(close.closePosition + 1).trim();
      if (after.isEmpty) continue;
      if (!RegExp(r'^[+\-*/^]').hasMatch(after)) continue;
      final widened =
          '${source.substring(0, close.closePosition)}${source.substring(close.closePosition + 1)})';
      ambiguities.add(_PendingAmbiguity(
        reason:
            'It is not clear how much of the expression is inside the ${close.functionName}.',
        alternativeSource: widened,
      ));
    }

    return _NormalizationResult(source: source, ambiguities: ambiguities);
  }

  /// Writes the single value a function applies to — a number, variable,
  /// or a spoken parenthesised group. Returns how many words it used.
  int _writeAtom(List<String> words, int start, StringBuffer out) {
    if (start >= words.length) return 0;

    final phrase = _matchPhrase(words, start);
    if (phrase != null && phrase.symbol == '(') {
      // "square root of open paren nine plus four close paren"
      var depth = 0;
      var i = start;
      final inner = StringBuffer();
      while (i < words.length) {
        final p = _matchPhrase(words, i);
        if (p != null && p.symbol == '(') {
          depth++;
          inner.write('(');
          i += p.length;
          continue;
        }
        if (p != null && p.symbol == ')') {
          depth--;
          inner.write(')');
          i += p.length;
          if (depth == 0) break;
          continue;
        }
        final nested = _matchPhrase(words, i);
        if (nested != null) {
          inner.write(nested.symbol);
          i += nested.length;
          continue;
        }
        final number = _numberWords.parseAt(words, i);
        if (number != null) {
          inner.write(number.digits);
          i += number.wordsConsumed;
          continue;
        }
        final symbol = vocabulary.singleWords[words[i]];
        if (symbol != null) {
          inner.write(symbol);
          i++;
          continue;
        }
        if (RegExp(r'^[a-z]$').hasMatch(words[i])) {
          inner.write(words[i]);
          i++;
          continue;
        }
        i++;
      }
      out.write(inner);
      return i - start;
    }

    final number = _numberWords.parseAt(words, start);
    if (number != null) {
      out.write(number.digits);
      return number.wordsConsumed;
    }

    if (RegExp(r'^[a-z]$').hasMatch(words[start])) {
      out.write(words[start]);
      return 1;
    }

    if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(words[start])) {
      out.write(words[start]);
      return 1;
    }

    return 0;
  }

  ({String symbol, int length})? _matchPhrase(List<String> words, int start) {
    ({String symbol, int length})? best;
    for (final entry in vocabulary.phrases.entries) {
      final phrase = entry.key;
      if (start + phrase.length > words.length) continue;
      var matches = true;
      for (var i = 0; i < phrase.length; i++) {
        if (words[start + i] != phrase[i]) {
          matches = false;
          break;
        }
      }
      if (matches && (best == null || phrase.length > best.length)) {
        best = (symbol: entry.value, length: phrase.length);
      }
    }
    return best;
  }
}

class _NormalizationResult {
  const _NormalizationResult({required this.source, required this.ambiguities});

  final String source;
  final List<_PendingAmbiguity> ambiguities;
}

class _PendingAmbiguity {
  const _PendingAmbiguity({required this.reason, required this.alternativeSource});

  final String reason;
  final String alternativeSource;
}

class _TightClose {
  const _TightClose({required this.functionName, required this.closePosition});

  final String functionName;
  final int closePosition;
}
