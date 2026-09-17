import '../expression/expression.dart';
import '../expression/parse/expression_parser.dart';

/// Where one leaf's text sits inside a [LinearSlice].
typedef LeafSpan = ({ExpressionPath path, int start, int end});

/// A run of the tree rendered as parser-ready text, with every nested
/// structure swapped for an opaque token.
///
/// This exists to solve one problem. Inserting an operator has to respect
/// precedence: typing `*` after the 3 in `3+4` has to restructure the
/// tree so the multiplication binds tighter than the addition.
/// Reimplementing precedence inside the editor would mean two places that
/// must agree about what `+` does, and they would drift apart.
///
/// So the editor hands the affected run back to the parser instead. The
/// catch is that rendering a tree to text loses structure — a
/// [FractionNode] renders as `(a)/(b)` and would come back as a plain
/// division. Each nested structure is therefore replaced by a single
/// private-use character, which the tokenizer reads as an ordinary
/// variable the way it reads π, and put back afterwards. The parser
/// rearranges around the structures without ever seeing inside them.
class LinearSlice {
  LinearSlice._({
    required this.text,
    required this.sentinels,
    required this.spans,
  });

  /// Parser-ready text for this run.
  final String text;

  /// Sentinel character to the subtree it stands for.
  final Map<String, ExpressionNode> sentinels;

  /// Every leaf's extent in [text], in reading order.
  final List<LeafSpan> spans;

  /// Private use area: above 127, so the tokenizer reads these as
  /// identifier characters, and outside anything a user could type.
  static const _sentinelBase = 0xE000;

  late int _nextSentinel;

  /// Flattens [node], treating any structure it cannot render linearly as
  /// an opaque token.
  factory LinearSlice.of(ExpressionNode node) {
    final buffer = StringBuffer();
    final sentinels = <String, ExpressionNode>{};
    final spans = <LeafSpan>[];
    var nextSentinel = _sentinelBase;

    void leaf(ExpressionPath path, String rendered) {
      spans.add((
        path: path,
        start: buffer.length,
        end: buffer.length + rendered.length,
      ));
      buffer.write(rendered);
    }

    void write(ExpressionNode current, ExpressionPath path, int parentPrecedence) {
      switch (current) {
        case NumberNode(:final literal):
          leaf(path, literal);

        case VariableNode(:final name):
          leaf(path, name);

        case ConstantNode(:final constant):
          leaf(path, constant.symbol);

        case BinaryNode(:final operator, :final left, :final right, :final isImplicit):
          final precedence = operator.precedence;
          final needsParens = precedence < parentPrecedence;
          if (needsParens) buffer.write('(');
          write(left, [...path, 0], precedence);
          if (!(isImplicit && operator == BinaryOperator.multiply)) {
            buffer.write(_asciiOperator(operator));
          }
          write(right, [...path, 1], precedence + 1);
          if (needsParens) buffer.write(')');

        case UnaryNode(:final operator, :final operand):
          switch (operator) {
            case UnaryOperator.negate:
              buffer.write('-');
              write(operand, [...path, 0], 3);
            case UnaryOperator.factorial:
              write(operand, [...path, 0], 4);
              buffer.write('!');
            case UnaryOperator.percent:
              write(operand, [...path, 0], 4);
              buffer.write('%');
          }

        // Everything else is structure the parser must not see inside,
        // placeholders included — an empty slot has no text at all.
        default:
          final name = String.fromCharCode(nextSentinel++);
          sentinels[name] = current;
          leaf(path, name);
      }
    }

    write(node, const [], 0);
    return LinearSlice._(
      text: buffer.toString(),
      sentinels: sentinels,
      spans: spans,
    ).._nextSentinel = nextSentinel;
  }

  /// Registers [node] as a new opaque token and returns the character
  /// that stands for it, so a structure can be spliced into the text and
  /// come back out as itself.
  String registerSentinel(ExpressionNode node) {
    final name = String.fromCharCode(_nextSentinel++);
    sentinels[name] = node;
    return name;
  }

  /// Where the caret sits in [text], given where it sits in the tree.
  int offsetOf(ExpressionPath path, int offsetInLeaf) {
    for (final span in spans) {
      if (_samePath(span.path, path)) return span.start + offsetInLeaf;
    }
    return text.length;
  }

  /// The tree position for a character offset — the inverse of
  /// [offsetOf], used to put the caret back after the parser has
  /// rearranged things.
  ///
  /// Where two leaves meet, as in the implicit multiplication of `2x`,
  /// the earlier one wins: a caret at that boundary reads as "after the
  /// 2" rather than "before the x", which is where the user left it.
  ({ExpressionPath path, int offset})? locate(int textOffset) {
    for (final span in spans) {
      if (textOffset >= span.start && textOffset <= span.end) {
        return (path: span.path, offset: textOffset - span.start);
      }
    }
    return null;
  }

  /// Parses [source] and puts the structures back where the parser left
  /// their sentinels.
  ExpressionNode restore(String source) =>
      _restore(const ExpressionParser().parse(source));

  ExpressionNode _restore(ExpressionNode node) {
    if (node is VariableNode) return sentinels[node.name] ?? node;
    if (node.children.isEmpty) return node;
    return node.withChildren(node.children.map(_restore).toList());
  }

  static bool _samePath(ExpressionPath a, ExpressionPath b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static String _asciiOperator(BinaryOperator operator) => switch (operator) {
        BinaryOperator.add => '+',
        BinaryOperator.subtract => '-',
        BinaryOperator.multiply => '*',
        BinaryOperator.divide => '/',
        BinaryOperator.modulo => ' mod ',
      };
}
