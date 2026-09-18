import '../expression/expression.dart';
import '../expression/parse/expression_parser.dart';
import 'cursor.dart';
import 'linear_slice.dart';

/// Slot names, used for the dotted boxes and for what a screen reader
/// says when the caret lands in an empty one.
class SlotRole {
  static const numerator = 'numerator';
  static const denominator = 'denominator';
  static const exponent = 'exponent';
  static const base = 'base';
  static const radicand = 'radicand';
  static const index = 'index';
  static const argument = 'argument';
  static const value = 'value';
}

/// One step of editing history: what the expression was, and where the
/// caret was sitting in it.
class EditorState {
  const EditorState(this.expression, this.cursor);

  final ExpressionNode expression;
  final EditorCursor cursor;
}

/// Edits an expression tree with a caret.
///
/// Two rules shape everything here.
///
/// **The tree is the document.** There is no text buffer that the tree is
/// derived from; the tree is what the user is editing, which is what lets
/// a fraction stay a fraction through an edit rather than collapsing into
/// a division the moment anything is typed near it.
///
/// **Precedence belongs to the parser.** When an edit changes how things
/// group, this flattens the affected run, hands it to the same parser the
/// keyboard and the microphone use, and puts the result back. The editor
/// therefore cannot disagree with the parser about what `+` does, because
/// it never decides.
class ExpressionEditor {
  ExpressionEditor._(this._expression, this._cursor);

  /// A fresh editor holding a single empty slot.
  factory ExpressionEditor.empty() =>
      ExpressionEditor._(const PlaceholderNode(), const EditorCursor.atRoot());

  factory ExpressionEditor.of(ExpressionNode expression) {
    final stops = CursorStops.of(expression);
    return ExpressionEditor._(
      expression,
      stops.length == 0 ? const EditorCursor.atRoot() : stops[stops.length - 1].cursor,
    );
  }

  /// Starts from text, which is how a saved formula or a history entry
  /// is reopened for editing.
  factory ExpressionEditor.parse(String source) =>
      ExpressionEditor.of(const ExpressionParser().parse(source));

  ExpressionNode _expression;
  EditorCursor _cursor;

  final List<EditorState> _undoStack = [];
  final List<EditorState> _redoStack = [];

  /// Bounded so a long session cannot grow without limit. Trees are
  /// immutable and share their untouched parts, so each entry costs
  /// little, but not nothing.
  static const _historyLimit = 100;

  ExpressionNode get expression => _expression;
  EditorCursor get cursor => _cursor;
  bool get isEmpty => _expression is PlaceholderNode;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Whether the expression still has empty slots, and so is not ready
  /// to evaluate.
  bool get hasPlaceholders => _expression.hasPlaceholder;

  CursorStops get stops => CursorStops.of(_expression);

  /// The leaf the caret is in.
  ExpressionNode? get nodeAtCursor => _expression.nodeAt(_cursor.path);

  // ---------------------------------------------------------------- moving

  void moveLeft() => _step(-1);
  void moveRight() => _step(1);

  void moveToStart() {
    final all = stops;
    if (all.length > 0) _cursor = all[0].cursor;
  }

  void moveToEnd() {
    final all = stops;
    if (all.length > 0) _cursor = all[all.length - 1].cursor;
  }

  void moveTo(EditorCursor cursor) => _cursor = cursor;

  void _step(int delta) {
    final all = stops;
    if (all.length == 0) return;
    final index = all.indexOf(_cursor) + delta;
    if (index < 0 || index >= all.length) return;
    _cursor = all[index].cursor;
  }

  /// Jumps to the next empty slot, wrapping around — the behaviour the
  /// Tab key has in a form, and the fastest way to fill in a structure
  /// that was just inserted.
  bool moveToNextPlaceholder() => _moveToPlaceholder(forwards: true);

  bool moveToPreviousPlaceholder() => _moveToPlaceholder(forwards: false);

  bool _moveToPlaceholder({required bool forwards}) {
    final all = stops;
    if (all.length == 0) return false;
    final from = all.indexOf(_cursor);
    for (var step = 1; step <= all.length; step++) {
      // Dart's % is Euclidean, so this stays in range going backwards.
      final index = (forwards ? from + step : from - step) % all.length;
      if (all[index].node is PlaceholderNode) {
        _cursor = all[index].cursor;
        return true;
      }
    }
    return false;
  }

  // -------------------------------------------------------------- inserting

  /// Types a digit or a decimal point.
  bool insertDigit(String digit) {
    if (nodeAtCursor is PlaceholderNode) {
      // A decimal point on its own is not a number, so an empty slot
      // takes the leading zero a person would write by hand.
      return _replacePlaceholder(NumberNode(digit == '.' ? '0.' : digit));
    }
    return _insertText(digit);
  }

  /// Types a variable name. Next to a number this becomes an implicit
  /// multiplication, because that is what `2x` means — and the parser,
  /// not this method, is what decides that.
  bool insertVariable(String name) =>
      _insertAtom(VariableNode(name), text: name);

  bool insertConstant(MathConstant constant) =>
      _insertAtom(ConstantNode(constant), text: constant.symbol);

  bool insertOperator(BinaryOperator operator) {
    final symbol = switch (operator) {
      BinaryOperator.add => '+',
      BinaryOperator.subtract => '-',
      BinaryOperator.multiply => '*',
      BinaryOperator.divide => '/',
      BinaryOperator.plusMinus => '\u00B1',
      BinaryOperator.modulo => ' mod ',
    };
    return _insertText(symbol, landOnPlaceholder: true);
  }

  /// A factorial or a percent sign, which attach to what precedes them.
  bool insertPostfix(UnaryOperator operator) {
    if (operator == UnaryOperator.negate) return insertOperator(BinaryOperator.subtract);
    return _insertText(operator == UnaryOperator.factorial ? '!' : '%');
  }

  /// Inserts a stacked fraction.
  ///
  /// Typing it after a value captures that value as the numerator, the
  /// way pressing ÷ on a calculator does: 3 then ÷ gives three over an
  /// empty slot, not an empty fraction sitting next to a 3.
  bool insertFraction() => _insertCapturing(
        (captured) => FractionNode(
          captured ?? const PlaceholderNode(role: SlotRole.numerator),
          const PlaceholderNode(role: SlotRole.denominator),
        ),
        emptySlotIndex: 1,
      );

  /// Inserts a power, capturing what precedes it as the base.
  bool insertPower() => _insertCapturing(
        (captured) => PowerNode(
          captured ?? const PlaceholderNode(role: SlotRole.base),
          const PlaceholderNode(role: SlotRole.exponent),
        ),
        emptySlotIndex: 1,
      );

  /// A square root does not capture: it is written before what it
  /// applies to, so it opens an empty slot to type into.
  bool insertSquareRoot() =>
      _insertStructure(const RootNode(PlaceholderNode(role: SlotRole.radicand)));

  bool insertNthRoot() => _insertStructure(const RootNode(
        PlaceholderNode(role: SlotRole.radicand),
        index: PlaceholderNode(role: SlotRole.index),
      ));

  bool insertAbsolute() =>
      _insertStructure(const AbsoluteNode(PlaceholderNode(role: SlotRole.value)));

  bool insertGroup() =>
      _insertStructure(const GroupNode(PlaceholderNode(role: SlotRole.value)));

  bool insertFunction(String name, {int arity = 1}) => _insertStructure(
        FunctionNode(name, [
          for (var i = 0; i < arity; i++)
            const PlaceholderNode(role: SlotRole.argument),
        ]),
      );

  // --------------------------------------------------------------- deleting

  /// Deletes what is immediately before the caret.
  ///
  /// At the very start of a structure's slot this unwraps the structure
  /// instead, keeping what was inside it. Deleting a fraction should
  /// leave the numerator behind rather than throwing away everything the
  /// user typed into it.
  bool deleteBackward() {
    final slotPath = _structuralSlotPath();
    if (slotPath != null && _atStartOfSlot(slotPath)) {
      return _unwrapStructure(slotPath);
    }

    final rootPath = _linearRootPath();
    final root = _expression.nodeAt(rootPath);
    if (root == null) return false;

    final slice = LinearSlice.of(root);
    final offset = slice.offsetOf(_relativePath(rootPath, _cursor.path), _cursor.offset);
    if (offset <= 0) return false;

    // Backspacing out of an empty slot takes the slot with it. Deleting
    // the `+` in "3 + ▢" has to remove the waiting slot too, or the
    // operator comes back as an implied multiplication against it and
    // "3" ends up as "3▢".
    final takesSlotToo = nodeAtCursor is PlaceholderNode && _cursor.offset == 0;
    final after = takesSlotToo ? offset + 1 : offset;

    final edited = slice.text.substring(0, offset - 1) + slice.text.substring(after);
    return _commitSlice(rootPath, slice, edited, offset - 1);
  }

  /// Clears everything back to a single empty slot.
  void clear() {
    _push();
    _expression = const PlaceholderNode();
    _cursor = const EditorCursor.atRoot();
  }

  // ------------------------------------------------------------ undo / redo

  bool undo() {
    if (_undoStack.isEmpty) return false;
    _redoStack.add(EditorState(_expression, _cursor));
    final previous = _undoStack.removeLast();
    _expression = previous.expression;
    _cursor = previous.cursor;
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) return false;
    _undoStack.add(EditorState(_expression, _cursor));
    final next = _redoStack.removeLast();
    _expression = next.expression;
    _cursor = next.cursor;
    return true;
  }

  void _push() {
    _undoStack.add(EditorState(_expression, _cursor));
    if (_undoStack.length > _historyLimit) _undoStack.removeAt(0);
    // A new edit makes any redone future unreachable, which is what
    // every editor does and what users expect.
    _redoStack.clear();
  }

  // --------------------------------------------------------------- internals

  /// The highest ancestor reachable through binary and unary operators
  /// only — the run of the expression an edit here can rearrange.
  ///
  /// Stopping at anything else is what confines an edit inside a
  /// fraction to that fraction: typing `+` in a numerator must not
  /// reach out and regroup the whole expression around it.
  ExpressionPath _linearRootPath() {
    var best = _cursor.path;
    for (var i = _cursor.path.length - 1; i >= 0; i--) {
      final ancestor = _expression.nodeAt(_cursor.path.sublist(0, i));
      if (ancestor is BinaryNode || ancestor is UnaryNode) {
        best = _cursor.path.sublist(0, i);
      } else {
        break;
      }
    }
    return best;
  }

  /// The nearest enclosing structure — the fraction, root or function
  /// whose slot the caret is in — or null at the top level.
  ExpressionPath? _structuralSlotPath() {
    for (var i = _cursor.path.length - 1; i >= 0; i--) {
      final path = _cursor.path.sublist(0, i);
      final ancestor = _expression.nodeAt(path);
      // Operators are glue between things, not containers with slots.
      if (ancestor is BinaryNode || ancestor is UnaryNode) continue;
      return path;
    }
    return null;
  }

  /// Whether the caret sits at the very first position inside the
  /// structure at [structurePath].
  bool _atStartOfSlot(ExpressionPath structurePath) {
    if (_cursor.offset != 0) return false;
    final structure = _expression.nodeAt(structurePath);
    if (structure == null) return false;
    final relative = _relativePath(structurePath, _cursor.path);
    // The structure's own first stop is the one *outside* it, so the
    // first position inside is the one after that.
    final interior = CursorStops.of(structure)
        .stops
        .where((stop) => stop.path.isNotEmpty);
    if (interior.isEmpty) return false;
    return interior.first.cursor == EditorCursor(relative, 0);
  }

  bool _unwrapStructure(ExpressionPath structurePath) {
    final structure = _expression.nodeAt(structurePath);
    if (structure == null) return false;

    // Keep the first slot that has something in it, so deleting a
    // fraction leaves the numerator rather than everything the user
    // typed vanishing at once.
    final kept = structure.children.firstWhere(
      (child) => child is! PlaceholderNode,
      orElse: () => const PlaceholderNode(),
    );

    _push();
    _expression = _expression.replaceAt(structurePath, kept);
    final stops = CursorStops.of(_expression);
    final target = [...structurePath];
    _cursor = stops.stops
            .where((s) => _isUnder(s.path, target))
            .firstOrNull
            ?.cursor ??
        (stops.length == 0 ? const EditorCursor.atRoot() : stops[0].cursor);
    return true;
  }

  bool _insertAtom(ExpressionNode node, {required String text}) {
    if (nodeAtCursor is PlaceholderNode) return _replacePlaceholder(node);
    return _insertText(text);
  }

  /// Fills an empty slot in place, rather than juxtaposing something next
  /// to it. Typing 5 into an empty numerator gives a numerator of 5.
  bool _replacePlaceholder(ExpressionNode node) {
    _push();
    _expression = _expression.replaceAt(_cursor.path, node);
    final inserted = CursorStops.of(node);
    _cursor = EditorCursor(
      _cursor.path,
      inserted.length == 0 ? 0 : inserted[inserted.length - 1].offset,
    );
    return true;
  }

  /// Splices [text] in at the caret and lets the parser decide what the
  /// result means.
  bool _insertText(String text, {bool landOnPlaceholder = false}) {
    final rootPath = _linearRootPath();
    final root = _expression.nodeAt(rootPath);
    if (root == null) return false;

    final slice = LinearSlice.of(root);
    final relative = _relativePath(rootPath, _cursor.path);
    final offset = slice.offsetOf(relative, _cursor.offset);

    var insertion = text;
    var caretAfter = offset + text.length;

    // An operator typed at the end has nothing to operate on yet, so it
    // opens an empty slot and the caret moves into it — which is what
    // pressing + on a calculator does.
    if (landOnPlaceholder) {
      if (offset >= slice.text.length) {
        final sentinel = slice.registerSentinel(const PlaceholderNode());
        insertion = '$text$sentinel';
        caretAfter = offset + insertion.length - sentinel.length;
      } else if (offset == 0 && text != '-') {
        final sentinel = slice.registerSentinel(const PlaceholderNode());
        insertion = '$sentinel$text';
        caretAfter = offset + insertion.length;
      }
    }

    final edited =
        slice.text.substring(0, offset) + insertion + slice.text.substring(offset);
    return _commitSlice(rootPath, slice, edited, caretAfter);
  }

  /// Builds a structure that swallows what precedes the caret.
  bool _insertCapturing(
    ExpressionNode Function(ExpressionNode? captured) build, {
    required int emptySlotIndex,
  }) {
    final leaf = nodeAtCursor;

    if (leaf is PlaceholderNode) {
      final structure = build(null);
      _push();
      _expression = _expression.replaceAt(_cursor.path, structure);
      _cursor = _firstEmptyInside(_cursor.path) ?? _cursor;
      return true;
    }

    if (leaf == null) return false;
    final leafLength = CursorStops.stopsIn(leaf) - 1;

    // Capturing only makes sense for what is wholly behind the caret.
    if (_cursor.offset == leafLength) {
      final structure = build(leaf);
      _push();
      _expression = _expression.replaceAt(_cursor.path, structure);
      _cursor = _firstEmptyInside(_cursor.path) ?? _cursor;
      return true;
    }

    // Mid-number: the digits before the caret are what gets captured.
    if (leaf is NumberNode && _cursor.offset > 0) {
      final before = NumberNode(leaf.literal.substring(0, _cursor.offset));
      final after = NumberNode(leaf.literal.substring(_cursor.offset));
      final structure = build(before);
      _push();
      _expression = _expression.replaceAt(
        _cursor.path,
        BinaryNode(BinaryOperator.multiply, structure, after, isImplicit: true),
      );
      _cursor = _firstEmptyInside([..._cursor.path, 0]) ?? _cursor;
      return true;
    }

    // Caret before the leaf: nothing to capture, so an empty structure
    // goes in front of it.
    return _insertStructure(build(null));
  }

  /// Splices a structure in as an opaque token and puts the caret in its
  /// first empty slot.
  bool _insertStructure(ExpressionNode structure) {
    if (nodeAtCursor is PlaceholderNode) {
      _push();
      _expression = _expression.replaceAt(_cursor.path, structure);
      _cursor = _firstEmptyInside(_cursor.path) ?? _cursor;
      return true;
    }

    final rootPath = _linearRootPath();
    final root = _expression.nodeAt(rootPath);
    if (root == null) return false;

    final slice = LinearSlice.of(root);
    final relative = _relativePath(rootPath, _cursor.path);
    final offset = slice.offsetOf(relative, _cursor.offset);
    final sentinel = slice.registerSentinel(structure);
    final edited =
        slice.text.substring(0, offset) + sentinel + slice.text.substring(offset);

    final ExpressionNode replacement;
    try {
      replacement = slice.restore(edited);
    } on ParseError {
      return false;
    }

    _push();
    _expression = _expression.replaceAt(rootPath, replacement);
    final path = _pathOfIdentical(_expression, structure);
    _cursor = (path == null ? null : _firstEmptyInside(path)) ??
        _cursorAtTextOffset(rootPath, offset + 1);
    return true;
  }

  /// Re-parses an edited run and puts it back, with the caret where the
  /// text says it should be.
  bool _commitSlice(
    ExpressionPath rootPath,
    LinearSlice slice,
    String edited,
    int caretOffset,
  ) {
    final trimmed = edited.trim();
    if (trimmed.isEmpty) {
      _push();
      _expression = _expression.replaceAt(rootPath, const PlaceholderNode());
      _cursor = EditorCursor(rootPath, 0);
      return true;
    }

    ExpressionNode? replacement;
    for (final attempt in _repairs(slice, trimmed)) {
      try {
        replacement = slice.restore(attempt);
        break;
      } on ParseError {
        continue;
      }
    }
    // An edit that cannot be made into a valid expression is refused
    // outright, leaving what the user had rather than mangling it.
    if (replacement == null) return false;

    _push();
    _expression = _expression.replaceAt(rootPath, replacement);
    _cursor = _cursorAtTextOffset(rootPath, caretOffset);
    return true;
  }

  /// The edited text, then the same text with an empty slot added where
  /// a dangling operator would otherwise fail to parse.
  Iterable<String> _repairs(LinearSlice slice, String text) sync* {
    yield text;
    final trailing = slice.registerSentinel(const PlaceholderNode());
    yield '$text$trailing';
    yield '$trailing$text';
  }

  /// Maps a character offset in a re-parsed run back to a caret.
  EditorCursor _cursorAtTextOffset(ExpressionPath rootPath, int textOffset) {
    final root = _expression.nodeAt(rootPath);
    if (root == null) return _cursor;
    final slice = LinearSlice.of(root);
    final located = slice.locate(textOffset.clamp(0, slice.text.length));
    if (located == null) {
      final all = CursorStops.of(_expression);
      return all.length == 0
          ? const EditorCursor.atRoot()
          : all[all.length - 1].cursor;
    }
    return EditorCursor([...rootPath, ...located.path], located.offset);
  }

  /// The caret position for the first empty slot inside the subtree at
  /// [path], or null when there is not one.
  EditorCursor? _firstEmptyInside(ExpressionPath path) {
    final node = _expression.nodeAt(path);
    if (node == null) return null;
    for (final stop in CursorStops.of(node).stops) {
      if (stop.node is PlaceholderNode) {
        return EditorCursor([...path, ...stop.path], stop.offset);
      }
    }
    return null;
  }

  static ExpressionPath _relativePath(ExpressionPath root, ExpressionPath full) =>
      full.length <= root.length ? const [] : full.sublist(root.length);

  static bool _isUnder(ExpressionPath candidate, ExpressionPath prefix) {
    if (candidate.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (candidate[i] != prefix[i]) return false;
    }
    return true;
  }

  /// Finds where a node ended up after the parser rearranged things
  /// around it. Identity, not equality: two empty slots are equal but
  /// only one of them is the one just inserted.
  static ExpressionPath? _pathOfIdentical(ExpressionNode root, ExpressionNode target) {
    ExpressionPath? search(ExpressionNode node, ExpressionPath path) {
      if (identical(node, target)) return path;
      final children = node.children;
      for (var i = 0; i < children.length; i++) {
        final found = search(children[i], [...path, i]);
        if (found != null) return found;
      }
      return null;
    }

    return search(root, const []);
  }
}
