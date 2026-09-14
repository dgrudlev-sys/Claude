/// One beat of a walkthrough: a sentence a person can hear, plus the matching symbols.
class ExplanationStep {
  const ExplanationStep({required this.words, required this.symbols});

  final String words;
  final String symbols;
}

/// Ordered beats for how a result was reached. Empty means nothing to show.
class Explanation {
  const Explanation({required this.steps});

  final List<ExplanationStep> steps;

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;

  /// Screen-reader version of every beat. No "Step N" prefixes.
  String get spoken => steps.map((step) => '${step.words} ${step.symbols}').join(' Then ');
}

/// Pretty-print a number for steps (no trailing zeros, no IEEE dust).
String formatExplainNumber(num value) {
  final v = value.toDouble();
  if (v.isNaN || v.isInfinite) return v.toString();
  if ((v - v.roundToDouble()).abs() < 1e-9 && v.abs() < 1e12) {
    return v.round().toString();
  }
  var text = v.abs() >= 1e6 || (v.abs() < 1e-4 && v != 0)
      ? v.toStringAsExponential(6)
      : v.toStringAsFixed(6);
  if (text.contains('.') && !text.contains('e') && !text.contains('E')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}
