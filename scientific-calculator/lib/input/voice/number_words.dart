/// Turns spoken English number words into digits.
///
/// Speech recognisers hand back "twenty five" and "three point one four"
/// rather than "25" and "3.14", so this has to run before any maths
/// parsing can happen.
class NumberWordParser {
  const NumberWordParser();

  static const _units = {
    'zero': 0, 'oh': 0, 'nought': 0,
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
    'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18,
    'nineteen': 19,
  };

  static const _tens = {
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
  };

  static const _scales = {
    'hundred': 100,
    'thousand': 1000,
    'million': 1000000,
    'billion': 1000000000,
    'trillion': 1000000000000,
  };

  /// Whether [word] could start or continue a spoken number.
  bool isNumberWord(String word) =>
      _units.containsKey(word) || _tens.containsKey(word) || _scales.containsKey(word);

  /// Consumes as many number words as possible starting at [start],
  /// returning the digits and how many words were used. Returns null when
  /// [start] isn't a number word at all.
  ({String digits, int wordsConsumed})? parseAt(List<String> words, int start) {
    if (start >= words.length || !isNumberWord(words[start])) return null;

    var total = 0;
    var current = 0;
    var index = start;
    var sawAny = false;

    while (index < words.length) {
      final word = words[index];

      if (_units.containsKey(word)) {
        // "twenty five" continues; "five five" does not — a second unit
        // after a complete unit means a new number has started.
        if (sawAny && current % 10 != 0 && current != 0) break;
        current += _units[word]!;
        sawAny = true;
        index++;
        continue;
      }

      if (_tens.containsKey(word)) {
        if (sawAny && current != 0 && current % 100 != 0) break;
        current += _tens[word]!;
        sawAny = true;
        index++;
        continue;
      }

      if (word == 'hundred' && sawAny) {
        current = (current == 0 ? 1 : current) * 100;
        index++;
        continue;
      }

      final scale = _scales[word];
      if (scale != null && scale >= 1000 && sawAny) {
        total += (current == 0 ? 1 : current) * scale;
        current = 0;
        index++;
        continue;
      }

      // "one hundred and five" — "and" only counts inside a number.
      if (word == 'and' &&
          sawAny &&
          index + 1 < words.length &&
          isNumberWord(words[index + 1]) &&
          !_scales.containsKey(words[index + 1])) {
        index++;
        continue;
      }

      break;
    }

    if (!sawAny) return null;
    var digits = '${total + current}';

    // "three point one four" — after "point", digits are read singly.
    if (index < words.length && words[index] == 'point') {
      final decimals = StringBuffer();
      var scan = index + 1;
      while (scan < words.length && _units.containsKey(words[scan])) {
        decimals.write(_units[words[scan]]);
        scan++;
      }
      if (decimals.isNotEmpty) {
        digits = '$digits.$decimals';
        index = scan;
      }
    }

    return (digits: digits, wordsConsumed: index - start);
  }
}
