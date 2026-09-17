/// A single text element recognised in a camera frame, with where it sat
/// on the page. Mirrors what ML Kit's on-device text recogniser returns
/// (`TextElement.text` plus `boundingBox`), so the platform adapter that
/// produces these stays thin.
class RecognizedGlyph {
  const RecognizedGlyph({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.confidence = 1.0,
  });

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;
  final double confidence;

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;

  @override
  String toString() => '"$text"@($left,$top ${width}x$height)';
}

class OcrMathResult {
  const OcrMathResult({
    required this.normalizedSource,
    required this.warnings,
    required this.confidence,
  });

  /// The reconstructed expression in ordinary notation, ready for the
  /// shared [ExpressionParser]. Kept as text rather than a tree so the
  /// preview screen can show exactly what was read before anything is
  /// calculated — the blueprint's "equation preview before solving".
  final String normalizedSource;

  /// Things that were inferred rather than clearly seen, so the UI can
  /// point at what most likely needs correcting.
  final List<String> warnings;

  /// Lowest glyph confidence in the reconstruction, as a rough signal of
  /// how much the user should check it.
  final double confidence;
}

/// Rebuilds two-dimensional mathematical structure from flat OCR output.
///
/// This is the part a text recogniser can't do. ML Kit reads "x", "2",
/// "+", "1" and tells you where each sat; it has no idea the 2 was a
/// superscript or that a horizontal line meant division. Reconstructing
/// that layout — superscripts into powers, bars into fractions, radical
/// signs into roots — is the actual work of reading maths from a page.
///
/// The output is notation text rather than a tree, so the preview screen
/// can show what was read and let the user fix it before it's parsed.
class MathLayoutReconstructor {
  const MathLayoutReconstructor();

  /// How far above the running baseline a glyph must sit, as a fraction
  /// of the baseline glyph height, before it counts as a superscript.
  static const _superscriptRise = 0.28;

  /// A superscript is also smaller; anything at least this large
  /// relative to its neighbour is treated as ordinary text.
  static const _superscriptMaxRelativeHeight = 0.88;

  /// Width-to-height ratio past which a dash is a fraction bar rather
  /// than a minus sign.
  static const _fractionBarAspect = 3.0;

  OcrMathResult reconstruct(List<RecognizedGlyph> glyphs) {
    if (glyphs.isEmpty) {
      return const OcrMathResult(
        normalizedSource: '',
        warnings: ['Nothing was recognised in the image'],
        confidence: 0,
      );
    }

    final warnings = <String>[];
    final source = _reconstruct(glyphs, warnings);
    final confidence =
        glyphs.map((g) => g.confidence).reduce((a, b) => a < b ? a : b);

    if (confidence < 0.7) {
      warnings.add('Some characters were hard to read — check before calculating');
    }

    return OcrMathResult(
      normalizedSource: source,
      warnings: warnings,
      confidence: confidence,
    );
  }

  String _reconstruct(List<RecognizedGlyph> glyphs, List<String> warnings) {
    if (glyphs.isEmpty) return '';

    final bar = _findMainFractionBar(glyphs);
    if (bar != null) {
      final above = <RecognizedGlyph>[];
      final below = <RecognizedGlyph>[];
      final before = <RecognizedGlyph>[];
      final after = <RecognizedGlyph>[];

      for (final glyph in glyphs) {
        if (identical(glyph, bar)) continue;
        if (glyph.right <= bar.left + bar.width * 0.1) {
          before.add(glyph);
        } else if (glyph.left >= bar.right - bar.width * 0.1) {
          after.add(glyph);
        } else if (glyph.centerY < bar.centerY) {
          above.add(glyph);
        } else {
          below.add(glyph);
        }
      }

      if (above.isEmpty || below.isEmpty) {
        // A bar with nothing on one side was probably a minus sign.
        final rest = [...glyphs]..remove(bar);
        return '${_reconstructLinear([bar], warnings)}${_reconstruct(rest, warnings)}';
      }

      final numerator = _reconstruct(above, warnings);
      final denominator = _reconstruct(below, warnings);
      final prefix = before.isEmpty ? '' : _reconstruct(before, warnings);
      final suffix = after.isEmpty ? '' : _reconstruct(after, warnings);
      return '$prefix($numerator)/($denominator)$suffix';
    }

    return _reconstructLinear(glyphs, warnings);
  }

  /// The widest bar-shaped glyph that actually has content above and
  /// below it — that's the division at this level of nesting.
  RecognizedGlyph? _findMainFractionBar(List<RecognizedGlyph> glyphs) {
    RecognizedGlyph? best;
    for (final glyph in glyphs) {
      if (!_isBarShaped(glyph)) continue;
      final hasAbove = glyphs.any((g) =>
          !identical(g, glyph) &&
          g.centerY < glyph.centerY &&
          g.centerX > glyph.left &&
          g.centerX < glyph.right);
      final hasBelow = glyphs.any((g) =>
          !identical(g, glyph) &&
          g.centerY > glyph.centerY &&
          g.centerX > glyph.left &&
          g.centerX < glyph.right);
      if (!hasAbove || !hasBelow) continue;
      if (best == null || glyph.width > best.width) best = glyph;
    }
    return best;
  }

  bool _isBarShaped(RecognizedGlyph glyph) {
    const barTexts = {'-', '−', '—', '–', '_', '/'};
    if (!barTexts.contains(glyph.text.trim())) return false;
    if (glyph.height <= 0) return true;
    return glyph.width / glyph.height >= _fractionBarAspect;
  }

  String _reconstructLinear(List<RecognizedGlyph> glyphs, List<String> warnings) {
    final ordered = [...glyphs]..sort((a, b) => a.left.compareTo(b.left));
    final out = StringBuffer();

    var i = 0;
    RecognizedGlyph? previousBase;

    while (i < ordered.length) {
      final glyph = ordered[i];

      if (glyph.text.trim() == '√') {
        // Everything under the radical's horizontal extent belongs to it,
        // when the recogniser gives the sign a wide box. Otherwise take
        // the next glyph and say so.
        final covered = ordered
            .skip(i + 1)
            .where((g) => g.left < glyph.right && glyph.width > glyph.height * 1.5)
            .toList();
        if (covered.isNotEmpty) {
          out.write('sqrt(${_reconstructLinear(covered, warnings)})');
          i = ordered.indexOf(covered.last) + 1;
        } else if (i + 1 < ordered.length) {
          out.write('sqrt(${ordered[i + 1].text})');
          warnings.add(
            'Assumed the square root covers only "${ordered[i + 1].text}" — '
            'check if it should cover more',
          );
          i += 2;
        } else {
          out.write('sqrt(');
          i++;
        }
        previousBase = glyph;
        continue;
      }

      final isSuperscript = previousBase != null &&
          _isSuperscript(glyph, previousBase);

      if (isSuperscript) {
        // Gather the whole raised run, so x^10 doesn't become x^1 times 0.
        final exponent = StringBuffer(glyph.text);
        var j = i + 1;
        while (j < ordered.length &&
            _isSuperscript(ordered[j], previousBase)) {
          exponent.write(ordered[j].text);
          j++;
        }
        out.write('^($exponent)');
        i = j;
        continue;
      }

      out.write(_normalizeGlyph(glyph.text));
      previousBase = glyph;
      i++;
    }

    return out.toString();
  }

  /// A superscript is judged against the glyph it attaches to, not
  /// against a page-wide average: in "x¹⁰" two of the three glyphs are
  /// raised, so any global measure of "normal size" gets dragged up by
  /// the very superscripts it is meant to identify.
  bool _isSuperscript(RecognizedGlyph glyph, RecognizedGlyph base) {
    final rise = base.centerY - glyph.centerY;
    final tallEnoughToBeNormal =
        glyph.height > base.height * _superscriptMaxRelativeHeight;
    return rise > base.height * _superscriptRise && !tallEnoughToBeNormal;
  }

  /// Fixes the characters OCR most often mangles in mathematical text.
  String _normalizeGlyph(String text) {
    final trimmed = text.trim();
    // Note "x" is deliberately absent: in maths it is far more often the
    // variable than a multiplication sign.
    return switch (trimmed) {
      '×' || '·' => '*',
      '÷' => '/',
      '−' || '–' || '—' => '-',
      _ => trimmed,
    };
  }
}
