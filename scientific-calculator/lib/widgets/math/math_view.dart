import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../expression/expression.dart';
import '../../expression/render/speech_renderer.dart';
import '../../input/language/english_vocabulary.dart';
import '../../input/language/math_vocabulary.dart';

/// Draws an expression the way it is written, rather than the way it is
/// typed.
///
/// `(3/4 + √16) × 2²` has been rendering as `(3)/(4)+√(16)*2^(2)` — a
/// faithful transcription of the tree and an unfaithful picture of the
/// maths. A fraction is two things stacked with a rule between them, a
/// root has a bar over everything it covers, and an exponent sits up and
/// to the right. Those are not decoration; they are how the structure is
/// read, and a flat string asks the reader to reconstruct it.
///
/// The tree already knows all of this, because a [FractionNode] was kept
/// distinct from a division all the way through. This is the third
/// renderer over that model, beside speech and braille — and it borrows
/// the first one for its accessibility label, so what a sighted user sees
/// and what a screen-reader user hears are generated from the same node
/// and cannot drift apart.
class MathView extends StatelessWidget {
  const MathView({
    super.key,
    required this.expression,
    this.style,
    this.vocabulary = const EnglishMathVocabulary(),
    this.cursor,
    this.shrinkToFit = true,
  });

  final ExpressionNode expression;

  /// The base size. Exponents and indices are drawn relative to it, so
  /// this is the only number that needs to change with Dynamic Type.
  final TextStyle? style;

  /// Used for the spoken description. The same vocabulary that drives
  /// read-aloud, so the label is in the user's language rather than
  /// always in English.
  final MathVocabulary vocabulary;

  /// Where the caret sits, when this view is being edited rather than
  /// read.
  final ExpressionPath? cursor;

  /// Scale the whole expression down when it is wider than the space it
  /// has, the way a calculator display does. Written maths does not wrap
  /// — breaking a fraction across two lines would say something the
  /// maths does not — so the choice is to shrink it or to cut it off, and
  /// cutting it off loses the part most recently typed.
  ///
  /// Only ever downwards: an expression that already fits is left at the
  /// size it was asked for rather than being blown up to fill the width.
  final bool shrinkToFit;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteAccess.of(context);
    final base = (style ?? AppType.displayResult).copyWith(
      color: style?.color ?? palette.label,
    );

    final Widget drawn = _Node(
      node: expression,
      style: base,
      palette: palette,
      depth: 0,
      path: const [],
      cursor: cursor,
    );

    return Semantics(
      // One label for the whole expression, not one per glyph: a screen
      // reader should say "three quarters plus the square root of 16",
      // not read out a pile of disconnected numbers and symbols.
      label: SpeechRenderer(vocabulary: vocabulary).render(expression),
      excludeSemantics: true,
      child: shrinkToFit
          ? FittedBox(
              fit: BoxFit.scaleDown,
              // Anchored right, so the end of the expression — where the
              // caret is and where the last thing typed appears — stays
              // put as it grows.
              alignment: Alignment.centerRight,
              child: drawn,
            )
          : drawn,
    );
  }
}

/// Reads the palette without forcing a dependency on the theme library,
/// so this widget can be pumped on its own in a test.
abstract final class AppPaletteAccess {
  static Palette of(BuildContext context) {
    final theme = Theme.of(context);
    for (final extension in theme.extensions.values) {
      final palette = _paletteOf(extension);
      if (palette != null) return palette;
    }
    return Palette.of(
      theme.brightness == Brightness.dark ? Appearance.dark : Appearance.light,
    );
  }

  static Palette? _paletteOf(Object extension) {
    try {
      return (extension as dynamic).palette as Palette?;
    } catch (_) {
      return null;
    }
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.node,
    required this.style,
    required this.palette,
    required this.depth,
    required this.path,
    required this.cursor,
  });

  final ExpressionNode node;
  final TextStyle style;
  final Palette palette;

  /// How many levels of superscript or fraction deep this is. Each level
  /// shrinks the type, but only so far — past a point smaller text stops
  /// being readable and starts being a texture.
  final int depth;

  final ExpressionPath path;
  final ExpressionPath? cursor;

  static const _shrink = 0.72;
  static const _smallestScale = 0.45;

  TextStyle get _smaller {
    final scale = (_shrink * (depth + 1) / (depth + 1)).clamp(_smallestScale, 1.0);
    final size = (style.fontSize ?? 20) * scale;
    return style.copyWith(
      fontSize: size < (style.fontSize ?? 20) * _smallestScale
          ? (style.fontSize ?? 20) * _smallestScale
          : size,
    );
  }

  _Node _child(ExpressionNode child, int index, {TextStyle? at, int? deeper}) =>
      _Node(
        node: child,
        style: at ?? style,
        palette: palette,
        depth: deeper ?? depth,
        path: [...path, index],
        cursor: cursor,
      );

  @override
  Widget build(BuildContext context) {
    return switch (node) {
      NumberNode(:final literal) => _text(literal),
      VariableNode(:final name) => _text(name, italic: true),
      ConstantNode(:final constant) => _text(constant.symbol, italic: true),
      PlaceholderNode(:final role) => _Placeholder(
          role: role,
          style: style,
          palette: palette,
        ),
      GroupNode(:final inner) => _Fenced(
          style: style,
          child: _child(inner, 0),
        ),
      AbsoluteNode() => _Bars(style: style, child: _child(node.children.first, 0)),
      BinaryNode(:final operator, :final isImplicit) => _Row(
          children: [
            _child(node.children[0], 0),
            if (!(isImplicit && operator == BinaryOperator.multiply))
              _operator(operator),
            _child(node.children[1], 1),
          ],
        ),
      UnaryNode(:final operator) => switch (operator) {
          UnaryOperator.negate =>
            _Row(children: [_text('−'), _child(node.children.first, 0)]),
          UnaryOperator.factorial =>
            _Row(children: [_child(node.children.first, 0), _text('!')]),
          UnaryOperator.percent =>
            _Row(children: [_child(node.children.first, 0), _text('%')]),
        },
      FractionNode() => _Fraction(
          numerator: _child(node.children[0], 0, at: _smaller, deeper: depth + 1),
          denominator: _child(node.children[1], 1, at: _smaller, deeper: depth + 1),
          style: style,
          palette: palette,
        ),
      PowerNode() => _Power(
          base: _child(node.children[0], 0),
          exponent: _child(node.children[1], 1, at: _smaller, deeper: depth + 1),
          style: style,
        ),
      RootNode(:final index) => _Radical(
          // Children are in reading order, so an nth root has its index
          // first — which is also where it is drawn.
          index: index == null
              ? null
              : _child(node.children[0], 0, at: _smaller, deeper: depth + 1),
          radicand: _child(
            node.children[index == null ? 0 : 1],
            index == null ? 0 : 1,
          ),
          style: style,
          palette: palette,
        ),
      FunctionNode(:final name, :final arguments) => _Row(
          children: [
            _text(name, upright: true),
            _Fenced(
              style: style,
              child: _Row(
                children: [
                  for (var i = 0; i < arguments.length; i++) ...[
                    if (i > 0) _text(', '),
                    _child(arguments[i], i),
                  ],
                ],
              ),
            ),
          ],
        ),
      MatrixNode(:final rows) => _Fenced(
          style: style,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < rows.length; r++)
                _Row(
                  children: [
                    for (var c = 0; c < rows[r].length; c++) ...[
                      if (c > 0) SizedBox(width: (style.fontSize ?? 20) * 0.4),
                      _Node(
                        node: rows[r][c],
                        style: _smaller,
                        palette: palette,
                        depth: depth + 1,
                        path: [...path, r * rows[r].length + c],
                        cursor: cursor,
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
    };
  }

  Widget _text(String value, {bool italic = false, bool upright = false}) => Text(
        value,
        style: style.copyWith(
          // Variables are set in italic and function names upright, which
          // is the convention that tells x-the-unknown from x-the-letter
          // in "max".
          fontStyle: italic && !upright ? FontStyle.italic : FontStyle.normal,
        ),
      );

  Widget _operator(BinaryOperator operator) {
    final symbol = switch (operator) {
      BinaryOperator.add => '+',
      BinaryOperator.subtract => '−',
      BinaryOperator.multiply => '×',
      BinaryOperator.divide => '÷',
      BinaryOperator.modulo => 'mod',
    };
    final space = (style.fontSize ?? 20) * 0.22;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: space),
      child: Text(symbol, style: style),
    );
  }
}

/// A run of pieces on one line, centred on the row's middle.
///
/// Proper maths typesetting aligns on an axis a little above the
/// baseline; centring is a close enough approximation for the depths a
/// calculator reaches, and it keeps a fraction sitting correctly against
/// the symbols either side of it.
class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
}

class _Fraction extends StatelessWidget {
  const _Fraction({
    required this.numerator,
    required this.denominator,
    required this.style,
    required this.palette,
  });

  final Widget numerator;
  final Widget denominator;
  final TextStyle style;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 20;
    final rule = (size * 0.06).clamp(1.0, 3.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.12),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.1),
              child: numerator,
            ),
            Container(
              height: rule,
              margin: EdgeInsets.symmetric(vertical: size * 0.08),
              color: style.color ?? palette.label,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.1),
              child: denominator,
            ),
          ],
        ),
      ),
    );
  }
}

class _Power extends StatelessWidget {
  const _Power({required this.base, required this.exponent, required this.style});

  final Widget base;
  final Widget exponent;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 20;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        base,
        // Raised, not merely shrunk: the offset is what says "exponent"
        // rather than "small number next to a number".
        Transform.translate(
          offset: Offset(0, -size * 0.32),
          child: exponent,
        ),
      ],
    );
  }
}

class _Radical extends StatelessWidget {
  const _Radical({
    required this.index,
    required this.radicand,
    required this.style,
    required this.palette,
  });

  final Widget? index;
  final Widget radicand;
  final TextStyle style;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 20;
    final colour = style.color ?? palette.label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (index != null)
          Transform.translate(
            offset: Offset(size * 0.22, -size * 0.34),
            child: index,
          ),
        CustomPaint(
          painter: _RadicalSignPainter(colour: colour, stroke: (size * 0.06).clamp(1.0, 3.0)),
          child: SizedBox(width: size * 0.5, height: size * 1.1),
        ),
        // The bar over the radicand is the part that says how far the
        // root reaches. Without it √2+3 is ambiguous on the page in a way
        // it never is in the tree.
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colour, width: (size * 0.06).clamp(1.0, 3.0))),
          ),
          padding: EdgeInsets.only(top: size * 0.12, left: size * 0.1, right: size * 0.1),
          child: radicand,
        ),
      ],
    );
  }
}

class _RadicalSignPainter extends CustomPainter {
  const _RadicalSignPainter({required this.colour, required this.stroke});

  final Color colour;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.3, size.height * 0.62)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RadicalSignPainter old) =>
      old.colour != colour || old.stroke != stroke;
}

/// Brackets that grow with what they contain, rather than a fixed glyph
/// that a tall fraction would out-grow.
class _Fenced extends StatelessWidget {
  const _Fenced({required this.style, required this.child});

  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 20;
    // Brackets stretch to the height of what they hold, which is what
    // makes them grow around a fraction. Stretching needs a height to
    // stretch to, and the display measures itself against an unbounded
    // one, so the intrinsic height has to be resolved first.
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Bracket(style: style, opening: true),
          Padding(padding: EdgeInsets.symmetric(horizontal: size * 0.05), child: child),
          _Bracket(style: style, opening: false),
        ],
      ),
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({required this.style, required this.opening});

  final TextStyle style;
  final bool opening;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(opening ? '(' : ')', style: style),
      );
}

class _Bars extends StatelessWidget {
  const _Bars({required this.style, required this.child});

  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 20;
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text('|', style: style)),
          Padding(padding: EdgeInsets.symmetric(horizontal: size * 0.06), child: child),
          Center(child: Text('|', style: style)),
        ],
      ),
    );
  }
}

/// An empty slot, drawn as the dotted box the editor promises.
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.role,
    required this.style,
    required this.palette,
  });

  final String? role;
  final TextStyle style;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 20;
    return Semantics(
      label: role == null ? 'empty slot' : 'empty $role',
      child: Container(
        width: size * 0.62,
        height: size * 0.82,
        margin: EdgeInsets.symmetric(horizontal: size * 0.06),
        decoration: BoxDecoration(
          border: Border.all(color: palette.accent, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
