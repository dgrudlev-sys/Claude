import 'number.dart';

/// Turns a [NumberValue] into text a person reads.
///
/// The engine keeps values exact for as long as it can, which is the
/// right thing for arithmetic and the wrong thing for a display: nobody
/// wants to read `4877107200000/152400000` when they asked how many
/// inches are in a mile. So this is the one place where exactness is
/// spent, deliberately and visibly.
///
/// Two rules decide what comes out:
///
///  1. An exact value that terminates is shown in full, however long.
///     1 mile is exactly 1609.344 metres and rounding that would be a
///     lie about a definition.
///  2. Anything else is rounded to [significantDigits], and the caller
///     can ask whether that happened so the UI can say "≈" rather than
///     "=" — which is the difference between a conversion that is exact
///     by definition and one that never can be.
class DisplayNumber {
  const DisplayNumber({required this.text, required this.isRounded});

  final String text;

  /// True when digits were dropped to fit. The UI shows an approximation
  /// sign for these, so an exact 5280 feet never looks like a rounded
  /// one.
  final bool isRounded;

  static DisplayNumber of(NumberValue value, {int significantDigits = 10}) {
    switch (value) {
      case RationalValue():
        return _rational(value, significantDigits);
      case RealValue(:final value):
        return _real(value, significantDigits);
      case ComplexValue():
        // Complex results cannot come out of a unit conversion, but the
        // formatter is shared, so it says something true rather than
        // throwing in a widget build.
        return DisplayNumber(text: value.toString(), isRounded: true);
    }
  }

  static DisplayNumber _rational(RationalValue value, int digits) {
    if (value.isInteger) {
      return DisplayNumber(text: _group(value.numerator.toString()), isRounded: false);
    }

    final expansion = value.toDecimalExpansion(maxDigits: digits + 8);
    if (expansion.terminates) {
      final decimals = expansion.nonRepeating;
      // A terminating expansion is the exact value, so it is shown whole
      // — unless it is absurdly long, in which case rounding it is the
      // lesser evil and the flag says so.
      if (decimals.length <= digits + 6) {
        final sign = expansion.isNegative ? '−' : '';
        final trimmed = decimals.replaceFirst(RegExp(r'0+$'), '');
        return DisplayNumber(
          text: trimmed.isEmpty
              ? '$sign${_group(expansion.integerPart)}'
              : '$sign${_group(expansion.integerPart)}.$trimmed',
          isRounded: false,
        );
      }
    }
    return _real(value.toDouble(), digits);
  }

  static DisplayNumber _real(double value, int digits) {
    if (value == 0) return const DisplayNumber(text: '0', isRounded: false);
    if (value.isNaN) return const DisplayNumber(text: 'undefined', isRounded: true);
    if (value.isInfinite) {
      return DisplayNumber(text: value.isNegative ? '−∞' : '∞', isRounded: true);
    }

    final magnitude = value.abs();
    // Outside the range where plain digits stay readable, scientific
    // notation says more with less: 0.000000001 and 1e-9 carry the same
    // information but only one of them can be counted at a glance.
    if (magnitude >= 1e12 || magnitude < 1e-6) {
      final text = value
          .toStringAsExponential(digits - 1)
          .replaceAll(RegExp(r'0+e'), 'e')
          .replaceAll('.e', 'e')
          .replaceAll('e+', 'e')
          .replaceAll('-', '−');
      return DisplayNumber(text: text, isRounded: true);
    }

    final rounded = double.parse(value.toStringAsPrecision(digits));
    var text = rounded.toString();
    if (text.contains('e')) text = rounded.toStringAsFixed(digits);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }

    final negative = text.startsWith('-');
    if (negative) text = text.substring(1);
    final dot = text.indexOf('.');
    final whole = dot == -1 ? text : text.substring(0, dot);
    final rest = dot == -1 ? '' : text.substring(dot);

    return DisplayNumber(
      text: '${negative ? '−' : ''}${_group(whole)}$rest',
      // Rounding only actually happened if something was lost.
      isRounded: rounded != value,
    );
  }

  /// Thin spaces every three digits, which is the SI convention and does
  /// not collide with either decimal separator.
  static String _group(String digits) {
    final negative = digits.startsWith('-');
    final body = negative ? digits.substring(1) : digits;
    if (body.length <= 4) return negative ? '−$body' : body;

    final buffer = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      if (i > 0 && (body.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(body[i]);
    }
    return '${negative ? '−' : ''}$buffer';
  }

  @override
  String toString() => text;
}
