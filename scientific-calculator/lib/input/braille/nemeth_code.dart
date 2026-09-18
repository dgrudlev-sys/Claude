import 'braille_cell.dart';

/// The Nemeth Braille Code for Mathematics, as far as a scientific
/// calculator needs it.
///
/// Every cell below is written as its dot numbers so it can be checked
/// against a published Nemeth chart without anyone having to recognise a
/// glyph. The tests check them a second way, through the ASCII braille
/// table, which was laid out to line up with Nemeth — the plus cell is
/// ASCII `+`, the fraction line is `/`, the radical is `>`. Two
/// independent representations agreeing is what makes this table
/// trustworthy rather than merely confident.
///
/// **What is not here.** Nemeth is a large code and this is the part a
/// calculator uses: numerals, the four operations, fractions, powers,
/// roots, grouping, factorial and π. Comparison signs, percent, matrices,
/// modifiers below and above, and the full rules for when the English
/// letter indicator is required are not implemented. Where a symbol was
/// not certain enough to encode, it was left out rather than guessed at —
/// a wrong cell on a braille display is worse than a missing one, because
/// it reads as something else entirely.
class NemethCode {
  const NemethCode._();

  // --- numerals -----------------------------------------------------
  //
  // Nemeth numerals are the letters a–j moved down one row, which is why
  // they need no numeric indicator: a digit cannot be mistaken for a
  // letter, since letters never use the lower dots alone.

  static final digits = <String, BrailleCell>{
    '1': BrailleCell({2}),
    '2': BrailleCell({2, 3}),
    '3': BrailleCell({2, 5}),
    '4': BrailleCell({2, 5, 6}),
    '5': BrailleCell({2, 6}),
    '6': BrailleCell({2, 3, 5}),
    '7': BrailleCell({2, 3, 5, 6}),
    '8': BrailleCell({2, 3, 6}),
    '9': BrailleCell({3, 5}),
    '0': BrailleCell({3, 5, 6}),
  };

  static final digitByCell = {
    for (final entry in digits.entries) entry.value: entry.key,
  };

  // --- letters ------------------------------------------------------

  static final letters = <String, BrailleCell>{
    'a': BrailleCell({1}),
    'b': BrailleCell({1, 2}),
    'c': BrailleCell({1, 4}),
    'd': BrailleCell({1, 4, 5}),
    'e': BrailleCell({1, 5}),
    'f': BrailleCell({1, 2, 4}),
    'g': BrailleCell({1, 2, 4, 5}),
    'h': BrailleCell({1, 2, 5}),
    'i': BrailleCell({2, 4}),
    'j': BrailleCell({2, 4, 5}),
    'k': BrailleCell({1, 3}),
    'l': BrailleCell({1, 2, 3}),
    'm': BrailleCell({1, 3, 4}),
    'n': BrailleCell({1, 3, 4, 5}),
    'o': BrailleCell({1, 3, 5}),
    'p': BrailleCell({1, 2, 3, 4}),
    'q': BrailleCell({1, 2, 3, 4, 5}),
    'r': BrailleCell({1, 2, 3, 5}),
    's': BrailleCell({2, 3, 4}),
    't': BrailleCell({2, 3, 4, 5}),
    'u': BrailleCell({1, 3, 6}),
    'v': BrailleCell({1, 2, 3, 6}),
    'w': BrailleCell({2, 4, 5, 6}),
    'x': BrailleCell({1, 3, 4, 6}),
    'y': BrailleCell({1, 3, 4, 5, 6}),
    'z': BrailleCell({1, 3, 5, 6}),
  };

  static final letterByCell = {
    for (final entry in letters.entries) entry.value: entry.key,
  };

  // --- operators ----------------------------------------------------

  static final plus = BrailleCell({3, 4, 6});
  static final minus = BrailleCell({3, 6});

  /// The raised dot form of multiplication, a · b.
  static final timesDot = BrailleCell({1, 6});

  /// The cross form, a × b, which is two cells.
  static final timesCrossPrefix = BrailleCell({4});
  static final timesCross = BrailleCell({1, 6});

  // --- structure ----------------------------------------------------

  static final fractionOpen = BrailleCell({1, 4, 5, 6});
  static final fractionLine = BrailleCell({3, 4});
  static final fractionClose = BrailleCell({3, 4, 5, 6});

  static final superscript = BrailleCell({4, 5});

  /// Returns the reader to the main line after a superscript, so that
  /// what follows is not read as still being up there.
  static final baseline = BrailleCell({5});

  static final radical = BrailleCell({3, 4, 5});
  static final radicalEnd = BrailleCell({1, 2, 4, 5, 6});

  /// Precedes the index of a root: this cell, the index, then the
  /// radical — which is the order ⁿ√x is written and spoken in.
  static final radicalIndex = BrailleCell({1, 2, 6});

  static final openParen = BrailleCell({1, 2, 3, 5, 6});
  static final closeParen = BrailleCell({2, 3, 4, 5, 6});

  static final factorial = BrailleCell({1, 2, 3, 4, 6});

  /// Dots 4-6 does three jobs, told apart by what follows it: a digit
  /// makes it a decimal point, the fraction-line cell makes it division,
  /// and a letter makes it the Greek letter indicator. This overload is
  /// Nemeth's, not ours.
  static final prefix46 = BrailleCell({4, 6});

  static final decimalPoint = prefix46;
  static final greekIndicator = prefix46;
  static final divideSecondCell = BrailleCell({3, 4});

  /// Accepted on input and never emitted. Nemeth's rules for when this
  /// is required are context-sensitive and not implemented here; since
  /// its numerals cannot be confused with letters, leaving it off is
  /// unambiguous for the expressions a calculator handles.
  static final letterIndicator = BrailleCell({5, 6});

  /// Greek letters, written as the indicator followed by the Latin
  /// letter that names them.
  static final greekLetters = <String, String>{
    'p': 'pi',
    'f': 'phi',
  };

  /// Function names are spelled out in letters. A run of letters that
  /// spells one of these is read as a function applied to what follows;
  /// any other run is read as variables multiplied together, which is
  /// what `xy` means.
  static const functionNames = {
    'sin', 'cos', 'tan',
    'arcsin', 'arccos', 'arctan',
    'sinh', 'cosh', 'tanh',
    'ln', 'log', 'exp',
  };
}
