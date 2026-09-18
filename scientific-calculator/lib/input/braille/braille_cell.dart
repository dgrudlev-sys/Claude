/// A braille cell, and the three ways one travels between a display, a
/// file and this app.
///
/// Cells are written here as the set of raised dots — `BrailleCell({3, 4,
/// 6})` — never as a pasted glyph. A braille chart lists dots, so a table
/// written in dots can be checked against one; a table written in ⠬ can
/// only be checked by someone who already knows what ⠬ is, and a single
/// mis-copied character would be invisible in review and wrong on a
/// display.
library;

/// Dots are numbered down the left column then down the right:
///
///     1 ● ● 4
///     2 ● ● 5
///     3 ● ● 6
///     7 ● ● 8   (eight-dot computer braille)
class BrailleCell {
  BrailleCell(Set<int> dots) : bits = _bitsOf(dots);

  const BrailleCell.fromBits(this.bits);

  /// One bit per dot, dot 1 in the lowest bit — the same packing the
  /// Unicode braille block uses, which is why [character] is an addition
  /// and not a lookup table.
  final int bits;

  static int _bitsOf(Set<int> dots) {
    var bits = 0;
    for (final dot in dots) {
      if (dot < 1 || dot > 8) {
        throw ArgumentError.value(dot, 'dot', 'Braille dots are numbered 1 to 8');
      }
      bits |= 1 << (dot - 1);
    }
    return bits;
  }

  Set<int> get dots => {
        for (var dot = 1; dot <= 8; dot++)
          if (bits & (1 << (dot - 1)) != 0) dot,
      };

  bool hasDot(int dot) => bits & (1 << (dot - 1)) != 0;

  bool get isBlank => bits == 0;

  /// True when only the top six dots are used, which is what a paper
  /// braille code like Nemeth is written in.
  bool get isSixDot => bits < 64;

  /// The Unicode braille pattern. U+2800 is the blank cell and the block
  /// is laid out so the dot numbers are the bit positions.
  String get character => String.fromCharCode(0x2800 + bits);

  static BrailleCell fromCharacter(String character) {
    final code = character.runes.first;
    if (code < 0x2800 || code > 0x28FF) {
      throw ArgumentError.value(character, 'character', 'Not a braille pattern');
    }
    return BrailleCell.fromBits(code - 0x2800);
  }

  static bool isBraillePattern(String character) {
    if (character.isEmpty) return false;
    final code = character.runes.first;
    return code >= 0x2800 && code <= 0x28FF;
  }

  /// The ASCII character this cell is written as in a BRF file or by a
  /// braille display in computer-braille mode.
  ///
  /// This is the North American Braille Computer Code ordering. It is
  /// worth knowing that it was chosen to line up with Nemeth: the cell
  /// for plus is ASCII `+`, for minus `-`, for the fraction line `/`.
  /// That correspondence is not a coincidence and the tests lean on it,
  /// because it lets a Nemeth table be checked twice over.
  String get ascii {
    if (!isSixDot) {
      throw StateError('Eight-dot cells have no ASCII braille form');
    }
    return _asciiTable[bits];
  }

  static BrailleCell fromAscii(String character) {
    final index = _asciiTable.indexOf(character.toUpperCase());
    if (index == -1) {
      throw ArgumentError.value(character, 'character', 'Not ASCII braille');
    }
    return BrailleCell.fromBits(index);
  }

  static bool isAsciiBraille(String character) =>
      character.isNotEmpty && _asciiTable.contains(character.toUpperCase());

  /// Indexed by dot bits, so `_asciiTable[44]` — dots 3, 4 and 6 — is the
  /// plus sign.
  static const _asciiTable =
      ' A1B\'K2L@CIF/MSP"E3H9O6R^DJG>NTQ,*5<-U8V.%[\$+X!&;:4\\0Z7(_?W]#Y)=';

  @override
  bool operator ==(Object other) => other is BrailleCell && other.bits == bits;

  @override
  int get hashCode => bits;

  @override
  String toString() => 'BrailleCell(${dots.join(',')})';
}

/// Turns whatever a braille display or file hands over into cells.
///
/// The same expression arrives as Unicode patterns from a screen reader,
/// as ASCII from a BRF file, and as either from a display depending on
/// how it is configured. Accepting all of them costs nothing and means a
/// user is never told their own braille is unreadable.
class BrailleText {
  const BrailleText(this.cells);

  factory BrailleText.decode(String input) {
    final cells = <BrailleCell>[];
    for (final rune in input.runes) {
      final character = String.fromCharCode(rune);
      if (BrailleCell.isBraillePattern(character)) {
        cells.add(BrailleCell.fromCharacter(character));
      } else if (BrailleCell.isAsciiBraille(character)) {
        cells.add(BrailleCell.fromAscii(character));
      } else {
        throw FormatException(
          'Not braille: "$character". Expected Unicode braille patterns or '
          'ASCII braille.',
          input,
        );
      }
    }
    return BrailleText(cells);
  }

  final List<BrailleCell> cells;

  String get unicode => cells.map((c) => c.character).join();

  String get ascii => cells.map((c) => c.ascii).join();

  int get length => cells.length;

  bool get isEmpty => cells.isEmpty;

  @override
  String toString() => unicode;
}
