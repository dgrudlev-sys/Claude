import 'package:flutter/services.dart';

/// Shared numeric-only input rules for finance, matrix, stats, and similar
/// value fields. Letters and other text are rejected — a blind user must
/// never be able to type a word into a number box and get a silent zero.
class NumericInput {
  NumericInput._();

  /// One signed decimal, optional scientific exponent: `-12.5`, `1e-3`, or `12,5`.
  static final scalarPattern = RegExp(r'^[+-]?(\d+[,.]?\d*|[.,]\d+)([eE][+-]?\d*)?$');

  /// Empty, a lone sign, a lone dot/comma, or a partial exponent while typing.
  static final scalarPartial = RegExp(r'^$|^[+-]$|^[+-]?[.,]$|^[+-]?(\d+[,.]?\d*|[.,]\d+)[eE][+-]?$');

  /// Comma-separated scalars (stats data entry).
  static final listPartial = RegExp(
    r'^$|^([+-]?(\d+\.?\d*|\.\d+)?([eE][+-]?\d*)?\s*,\s*)*[+-]?(\d+\.?\d*|\.\d+)?([eE][+-]?\d*)?$',
  );

  static bool isAllowedScalar(String text) =>
      scalarPattern.hasMatch(text) || scalarPartial.hasMatch(text);

  static bool isAllowedList(String text) => listPartial.hasMatch(text);

  /// Strips every character that cannot appear in a scalar number.
  static String sanitizeScalar(String raw) {
    final buf = StringBuffer();
    for (final rune in raw.runes) {
      final ch = String.fromCharCode(rune);
      if (RegExp(r'[0-9eE+\-.,]').hasMatch(ch)) buf.write(ch);
    }
    return buf.toString();
  }

  static final scalarFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    if (isAllowedScalar(newValue.text)) return newValue;
    return oldValue;
  });

  static final listFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    if (isAllowedList(newValue.text)) return newValue;
    return oldValue;
  });
}
