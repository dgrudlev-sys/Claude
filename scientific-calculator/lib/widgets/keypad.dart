import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../l10n/l10n.dart';
import '../services/feedback_service.dart';
import '../theme/app_metrics.dart';
import '../theme/app_theme.dart';
import '../theme/layout_style.dart';
import 'calculator_button.dart';

enum _Action {
  input,
  wrapSquare,
  wrapSqrt,
  wrapReciprocal,
  wrapNegate,
  wrapAbs,
  paren,
  clear,
  backspace,
  cursorLeft,
  cursorRight,
  speak,
  evaluate,
  toggleAngle,
  toggleShift,
  toggleScientific,
  insertAns,
}

class _KeySpec {
  const _KeySpec({
    required this.label,
    required this.role,
    required this.action,
    this.token = '',
    this.shiftedLabel,
    this.shiftedToken,
    this.semanticLabel,
    this.shiftedSemanticLabel,
    this.icon,
    this.buttonKey,
  });

  final String label;
  final ButtonRole role;
  final _Action action;
  final String token;
  final String? shiftedLabel;
  final String? shiftedToken;
  final String? semanticLabel;
  final String? shiftedSemanticLabel;
  final IconData? icon;
  final Key? buttonKey;
}

/// Editor chrome above the pad — not part of the Samsung square grid.
const _editorKeys = <_KeySpec>[
  _KeySpec(
    label: '◀',
    role: ButtonRole.action,
    action: _Action.cursorLeft,
    semanticLabel: 'Move cursor left',
    buttonKey: Key('key-left'),
  ),
  _KeySpec(
    label: '▶',
    role: ButtonRole.action,
    action: _Action.cursorRight,
    semanticLabel: 'Move cursor right',
    buttonKey: Key('key-right'),
  ),
  _KeySpec(
    label: '⌫',
    role: ButtonRole.action,
    action: _Action.backspace,
    semanticLabel: 'Backspace, delete character before cursor',
    buttonKey: Key('key-backspace'),
  ),
  _KeySpec(
    label: '',
    role: ButtonRole.action,
    action: _Action.speak,
    icon: Icons.volume_up,
    semanticLabel: 'Read the equation',
    buttonKey: Key('key-speak'),
  ),
  _KeySpec(
    label: 'SCI',
    role: ButtonRole.action,
    action: _Action.toggleScientific,
    buttonKey: Key('key-sci'),
  ),
];

const _ansKey = _KeySpec(
  label: 'Ans',
  role: ButtonRole.action,
  action: _Action.insertAns,
  semanticLabel: 'Last answer',
  buttonKey: Key('key-ans'),
);

/// Samsung portrait number pad. C is always top-left of this grid.
const _numpadKeys = <_KeySpec>[
  _KeySpec(
    label: 'C',
    role: ButtonRole.clear,
    action: _Action.clear,
    buttonKey: Key('key-ac'),
  ),
  _KeySpec(
    label: '( )',
    role: ButtonRole.function,
    action: _Action.paren,
    semanticLabel: 'parenthesis',
  ),
  _KeySpec(label: '%', role: ButtonRole.function, action: _Action.input, token: '/100'),
  _KeySpec(label: '÷', role: ButtonRole.operatorKey, action: _Action.input, token: '/'),
  _KeySpec(label: '7', role: ButtonRole.number, action: _Action.input, token: '7'),
  _KeySpec(label: '8', role: ButtonRole.number, action: _Action.input, token: '8'),
  _KeySpec(label: '9', role: ButtonRole.number, action: _Action.input, token: '9'),
  _KeySpec(label: '×', role: ButtonRole.operatorKey, action: _Action.input, token: '*'),
  _KeySpec(label: '4', role: ButtonRole.number, action: _Action.input, token: '4'),
  _KeySpec(label: '5', role: ButtonRole.number, action: _Action.input, token: '5'),
  _KeySpec(label: '6', role: ButtonRole.number, action: _Action.input, token: '6'),
  _KeySpec(label: '−', role: ButtonRole.operatorKey, action: _Action.input, token: '-'),
  _KeySpec(label: '1', role: ButtonRole.number, action: _Action.input, token: '1'),
  _KeySpec(label: '2', role: ButtonRole.number, action: _Action.input, token: '2'),
  _KeySpec(label: '3', role: ButtonRole.number, action: _Action.input, token: '3'),
  _KeySpec(label: '+', role: ButtonRole.operatorKey, action: _Action.input, token: '+'),
  _KeySpec(
    label: '±',
    role: ButtonRole.function,
    action: _Action.wrapNegate,
    semanticLabel: 'toggle sign',
  ),
  _KeySpec(label: '0', role: ButtonRole.number, action: _Action.input, token: '0'),
  _KeySpec(label: '.', role: ButtonRole.number, action: _Action.input, token: '.'),
  _KeySpec(label: '=', role: ButtonRole.equals, action: _Action.evaluate),
];

/// Scientific cluster — left of the numpad when wide; leftover above when SCI.
const _functionKeys = <_KeySpec>[
  _KeySpec(label: '2nd', role: ButtonRole.action, action: _Action.toggleShift),
  _KeySpec(
    label: 'DEG',
    role: ButtonRole.action,
    action: _Action.toggleAngle,
    semanticLabel: 'Toggle angle mode',
  ),
  _KeySpec(
    label: 'sin',
    role: ButtonRole.function,
    action: _Action.input,
    token: 'sin(',
    shiftedLabel: 'sin⁻¹',
    shiftedToken: 'arcsin(',
    semanticLabel: 'sine',
    shiftedSemanticLabel: 'inverse sine',
  ),
  _KeySpec(
    label: 'cos',
    role: ButtonRole.function,
    action: _Action.input,
    token: 'cos(',
    shiftedLabel: 'cos⁻¹',
    shiftedToken: 'arccos(',
    semanticLabel: 'cosine',
    shiftedSemanticLabel: 'inverse cosine',
  ),
  _KeySpec(
    label: 'tan',
    role: ButtonRole.function,
    action: _Action.input,
    token: 'tan(',
    shiftedLabel: 'tan⁻¹',
    shiftedToken: 'arctan(',
    semanticLabel: 'tangent',
    shiftedSemanticLabel: 'inverse tangent',
  ),
  _KeySpec(label: '√', role: ButtonRole.function, action: _Action.wrapSqrt),
  _KeySpec(
    label: 'log',
    role: ButtonRole.function,
    action: _Action.input,
    token: 'log(10,',
    shiftedLabel: '10^x',
    shiftedToken: '10^(',
    semanticLabel: 'log base 10',
    shiftedSemanticLabel: 'ten to the power of',
  ),
  _KeySpec(
    label: 'ln',
    role: ButtonRole.function,
    action: _Action.input,
    token: 'ln(',
    shiftedLabel: 'e^x',
    shiftedToken: 'e^(',
    semanticLabel: 'natural log',
    shiftedSemanticLabel: 'e to the power of',
  ),
  _KeySpec(label: 'π', role: ButtonRole.function, action: _Action.input, token: 'pi', semanticLabel: 'pi'),
  _KeySpec(
    label: 'e',
    role: ButtonRole.function,
    action: _Action.input,
    token: 'e',
    semanticLabel: "euler's number",
  ),
  _KeySpec(label: '^', role: ButtonRole.function, action: _Action.input, token: '^'),
  _KeySpec(
    label: '!',
    role: ButtonRole.function,
    action: _Action.input,
    token: '!',
    semanticLabel: 'factorial',
  ),
  _KeySpec(label: 'x²', role: ButtonRole.function, action: _Action.wrapSquare),
  _KeySpec(
    label: '1/x',
    role: ButtonRole.function,
    action: _Action.wrapReciprocal,
    semanticLabel: 'reciprocal',
  ),
  _KeySpec(label: '(', role: ButtonRole.function, action: _Action.input, token: '('),
  _KeySpec(label: ')', role: ButtonRole.function, action: _Action.input, token: ')'),
  _KeySpec(
    label: '|x|',
    role: ButtonRole.function,
    action: _Action.wrapAbs,
    semanticLabel: 'absolute value',
  ),
  _KeySpec(
    label: 'x^y',
    role: ButtonRole.function,
    action: _Action.input,
    token: '^',
    semanticLabel: 'power',
  ),
  _KeySpec(label: '( )', role: ButtonRole.function, action: _Action.paren, semanticLabel: 'parenthesis'),
  _KeySpec(label: '%', role: ButtonRole.function, action: _Action.input, token: '/100'),
];

const _numpadCols = 4;
const _numpadRows = 5;
const _functionCols = 4;
const _functionRows = 5;

class Keypad extends StatefulWidget {
  const Keypad({
    super.key,
    required this.controller,
    required this.layoutStyle,
    required this.feedback,
    required this.onSpeak,
    required this.scientific,
    required this.onScientificChanged,
  });

  final CalculatorController controller;
  final LayoutStyle layoutStyle;
  final FeedbackService feedback;
  final VoidCallback onSpeak;
  final bool scientific;
  final ValueChanged<bool> onScientificChanged;

  @override
  State<Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<Keypad> {
  bool _shiftActive = false;

  void _handle(_KeySpec key) {
    widget.feedback.onKeyPress();
    switch (key.action) {
      case _Action.input:
        final token = _shiftActive ? (key.shiftedToken ?? key.token) : key.token;
        widget.controller.input(token);
      case _Action.wrapSquare:
        widget.controller.wrap('(', ')^2');
      case _Action.wrapSqrt:
        widget.controller.wrap('sqrt(', ')');
      case _Action.wrapReciprocal:
        widget.controller.wrap('1/(', ')');
      case _Action.wrapNegate:
        widget.controller.wrap('-(', ')');
      case _Action.wrapAbs:
        widget.controller.wrap('abs(', ')');
      case _Action.paren:
        _insertParen();
      case _Action.clear:
        widget.controller.clear();
      case _Action.backspace:
        widget.controller.backspace();
      case _Action.cursorLeft:
        widget.controller.moveCursorLeft();
      case _Action.cursorRight:
        widget.controller.moveCursorRight();
      case _Action.speak:
        widget.onSpeak();
        return;
      case _Action.evaluate:
        widget.controller.evaluate();
      case _Action.toggleAngle:
        widget.controller.toggleAngleMode();
      case _Action.toggleShift:
        setState(() => _shiftActive = !_shiftActive);
        return;
      case _Action.toggleScientific:
        if (_shiftActive) setState(() => _shiftActive = false);
        widget.onScientificChanged(!widget.scientific);
        return;
      case _Action.insertAns:
        widget.controller.insertAns();
    }
    if (_shiftActive) {
      setState(() => _shiftActive = false);
    }
  }

  void _insertParen() {
    final expr = widget.controller.expression;
    final open = '('.allMatches(expr).length;
    final close = ')'.allMatches(expr).length;
    widget.controller.input(open > close ? ')' : '(');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.keypadInset,
        AppMetrics.keypadGutter,
        AppMetrics.keypadInset,
        AppMetrics.keypadInset,
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => _editorBar(context, constraints.maxWidth),
          ),
          const SizedBox(height: AppMetrics.keypadGutter),
          Expanded(
            child: OrientationBuilder(
              builder: (context, orientation) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final media = MediaQuery.sizeOf(context);
                    final wide = orientation == Orientation.landscape ||
                        media.width > media.height ||
                        media.width >= AppMetrics.keypadWideMinWidth;
                    return wide
                        ? _widePad(context, constraints)
                        : _portraitPad(context, constraints);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorBar(BuildContext context, double maxWidth) {
    const g = AppMetrics.keypadGutter;
    final n = _editorKeys.length;
    final size = math.min(
      widget.layoutStyle.minTouchTarget,
      math.max(0.0, (maxWidth - (n - 1) * g) / n),
    );
    final used = n * size + (n - 1) * g;
    final ansFits = maxWidth - used >= size;
    return SizedBox(
      height: size,
      child: Row(
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(width: g),
            SizedBox(
              width: size,
              height: size,
              child: _buildButton(context, _editorKeys[i]),
            ),
          ],
          const Spacer(),
          if (ansFits)
            SizedBox(
              width: size,
              height: size,
              child: _buildButton(context, _ansKey),
            ),
        ],
      ),
    );
  }

  /// Portrait: Samsung 5×4 numpad, flush bottom-right. SCI uses leftover above
  /// without rescaling C, numbers, or operators.
  Widget _portraitPad(BuildContext context, BoxConstraints constraints) {
    const g = AppMetrics.keypadGutter;
    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;
    final sizeW = (maxW - (_numpadCols - 1) * g) / _numpadCols;
    final sizeH = (maxH - (_numpadRows - 1) * g) / _numpadRows;
    final keySize = math.max(0.0, math.min(sizeW, sizeH));
    final numpadW = _numpadCols * keySize + (_numpadCols - 1) * g;
    final numpadH = _numpadRows * keySize + (_numpadRows - 1) * g;
    final leftoverH = math.max(0.0, maxH - numpadH);
    final leftoverW = math.max(0.0, maxW - numpadW);
    final showFunctions = widget.scientific;
    var functionKeySize = keySize;
    var functionRowsFit = leftoverH > g
        ? math.min(_functionRows, (leftoverH / (keySize + g)).floor())
        : 0;
    if (showFunctions && functionRowsFit == 0 && leftoverH >= 40) {
      functionKeySize = math.min(leftoverH, keySize);
      functionRowsFit = 1;
    }

    final functionH = functionRowsFit > 0
        ? functionRowsFit * functionKeySize + (functionRowsFit - 1) * g
        : 0.0;

    return Stack(
      children: [
        if (showFunctions && functionRowsFit > 0)
          Positioned(
            left: leftoverW,
            bottom: numpadH,
            width: numpadW,
            height: functionH,
            child: _functionCluster(
              context,
              keySize: functionKeySize,
              columns: _functionCols,
              visibleRows: functionRowsFit,
            ),
          ),
        Positioned(
          right: 0,
          bottom: 0,
          width: numpadW,
          height: numpadH,
          child: _numpadGrid(context, keySize: keySize, equalsHeight: keySize),
        ),
      ],
    );
  }

  /// Landscape / wide window: functions left, identical numpad right.
  Widget _widePad(BuildContext context, BoxConstraints constraints) {
    const g = AppMetrics.keypadGutter;
    const panel = AppMetrics.keypadPanelGutter;
    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;
    final cols = _functionCols + _numpadCols;
    final gutters = (cols - 1) * g + panel;
    final sizeW = (maxW - gutters) / cols;
    final sizeH = (maxH - (_numpadRows - 1) * g) / _numpadRows;
    final keySize = math.max(0.0, math.min(sizeW, sizeH));
    final numpadW = _numpadCols * keySize + (_numpadCols - 1) * g;
    final numpadH = _numpadRows * keySize + (_numpadRows - 1) * g;
    final funcW = _functionCols * keySize + (_functionCols - 1) * g;
    final funcH = _functionRows * keySize + (_functionRows - 1) * g;

    return Align(
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: funcW,
            height: funcH,
            child: _functionCluster(
              context,
              keySize: keySize,
              columns: _functionCols,
              visibleRows: _functionRows,
            ),
          ),
          const SizedBox(width: panel),
          SizedBox(
            width: numpadW,
            height: numpadH,
            child: _numpadGrid(context, keySize: keySize, equalsHeight: keySize),
          ),
        ],
      ),
    );
  }

  Widget _numpadGrid(
    BuildContext context, {
    required double keySize,
    required double equalsHeight,
  }) {
    const g = AppMetrics.keypadGutter;
    final rows = <List<_KeySpec>>[
      for (var i = 0; i < _numpadKeys.length; i += _numpadCols)
        _numpadKeys.sublist(i, i + _numpadCols),
    ];
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: g),
          SizedBox(
            height: r == rows.length - 1 ? math.max(keySize, equalsHeight) : keySize,
            child: _numpadRow(
              context,
              rows[r],
              keySize: keySize,
              equalsHeight: r == rows.length - 1 ? equalsHeight : keySize,
            ),
          ),
        ],
      ],
    );
  }

  Widget _numpadRow(
    BuildContext context,
    List<_KeySpec> row, {
    required double keySize,
    required double equalsHeight,
  }) {
    const g = AppMetrics.keypadGutter;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < row.length; i++) ...[
          if (i > 0) const SizedBox(width: g),
          SizedBox(
            width: keySize,
            height: row[i].action == _Action.evaluate ? equalsHeight : keySize,
            child: _buildButton(context, row[i]),
          ),
        ],
      ],
    );
  }

  Widget _functionCluster(
    BuildContext context, {
    required double keySize,
    required int columns,
    required int visibleRows,
  }) {
    const g = AppMetrics.keypadGutter;
    final keys = _functionKeys;
    final totalRows = (keys.length / columns).ceil();
    final rows = <List<_KeySpec>>[
      for (var i = 0; i < keys.length; i += columns)
        keys.sublist(i, math.min(i + columns, keys.length)),
    ];
    final scroll = totalRows > visibleRows;

    Widget grid = Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: g),
          SizedBox(
            height: keySize,
            child: Row(
              children: [
                for (var i = 0; i < rows[r].length; i++) ...[
                  if (i > 0) const SizedBox(width: g),
                  SizedBox(
                    width: keySize,
                    height: keySize,
                    child: _buildButton(context, rows[r][i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );

    if (!scroll) return grid;
    return SingleChildScrollView(child: grid);
  }

  Widget _buildButton(BuildContext context, _KeySpec key) {
    final language = L10n.languageOf(context);
    final strings = L10n.stringsOf(context);
    final isAngleToggle = key.action == _Action.toggleAngle;
    final isDecimal = key.token == '.';
    var label = isAngleToggle
        ? widget.controller.angleMode.label
        : (_shiftActive ? (key.shiftedLabel ?? key.label) : key.label);
    if (key.action == _Action.toggleShift) label = language.secondKey;
    if (key.action == _Action.clear) label = 'C';
    if (key.action == _Action.toggleScientific) label = strings.scientificKeypad;
    if (isDecimal) label = language.decimalSeparator;
    final semantic = isAngleToggle
        ? '${strings.angleMode}: ${widget.controller.angleMode.label}'
        : key.action == _Action.clear
            ? strings.clear
            : key.action == _Action.backspace
                ? strings.backspace
                : key.action == _Action.cursorLeft
                    ? strings.cursorLeft
                    : key.action == _Action.cursorRight
                        ? strings.cursorRight
                        : key.action == _Action.speak
                            ? strings.readEquation
                            : key.action == _Action.toggleScientific
                                ? (widget.scientific
                                    ? strings.scientificKeypadOn
                                    : strings.scientificKeypadOff)
                                : (_shiftActive
                                    ? (key.shiftedSemanticLabel ?? key.shiftedLabel ?? key.label)
                                    : (key.semanticLabel ?? key.label));
    final role = key.action == _Action.toggleShift && _shiftActive
        ? ButtonRole.action
        : key.role;
    final selected = (key.action == _Action.toggleShift && _shiftActive) ||
        (key.action == _Action.toggleScientific && widget.scientific);

    return CalculatorButton(
      key: key.buttonKey,
      label: label,
      role: role,
      style: widget.layoutStyle,
      semanticLabel: semantic,
      selected: selected,
      icon: key.icon,
      onPressed: () => _handle(key),
    );
  }
}
