import 'package:flutter/material.dart';

import '../core/calculator_controller.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../theme/layout_style.dart';
import 'calculator_button.dart';

enum _Action {
  input,
  wrapSquare,
  wrapSqrt,
  wrapReciprocal,
  wrapNegate,
  clear,
  backspace,
  evaluate,
  toggleAngle,
  toggleShift,
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
  });

  final String label;
  final ButtonRole role;
  final _Action action;
  final String token;
  final String? shiftedLabel;
  final String? shiftedToken;
  final String? semanticLabel;
  final String? shiftedSemanticLabel;
}

/// The full button set, in reading order. Every layout skin renders this
/// same list — only the grid's column count and button sizing change per
/// [LayoutStyle] (see [LayoutStyle]), so "accessible" isn't a stripped-down
/// second app, it's the same calculator at a different density.
const _keys = <_KeySpec>[
  _KeySpec(label: '2nd', role: ButtonRole.action, action: _Action.toggleShift),
  _KeySpec(label: ',', role: ButtonRole.function, action: _Action.input, token: ',',
      semanticLabel: 'comma, separates arguments'),
  _KeySpec(label: '(', role: ButtonRole.function, action: _Action.input, token: '('),
  _KeySpec(label: ')', role: ButtonRole.function, action: _Action.input, token: ')'),
  _KeySpec(label: 'DEL', role: ButtonRole.action, action: _Action.backspace),

  _KeySpec(label: 'x²', role: ButtonRole.function, action: _Action.wrapSquare),
  _KeySpec(label: 'x^y', role: ButtonRole.function, action: _Action.input, token: '^'),
  _KeySpec(label: '√', role: ButtonRole.function, action: _Action.wrapSqrt),
  _KeySpec(label: '%', role: ButtonRole.function, action: _Action.input, token: '/100'),
  _KeySpec(label: 'AC', role: ButtonRole.action, action: _Action.clear),

  _KeySpec(
      label: 'sin', role: ButtonRole.function, action: _Action.input,
      token: 'sin(', shiftedLabel: 'sin⁻¹', shiftedToken: 'arcsin(',
      semanticLabel: 'sine', shiftedSemanticLabel: 'inverse sine'),
  _KeySpec(
      label: 'cos', role: ButtonRole.function, action: _Action.input,
      token: 'cos(', shiftedLabel: 'cos⁻¹', shiftedToken: 'arccos(',
      semanticLabel: 'cosine', shiftedSemanticLabel: 'inverse cosine'),
  _KeySpec(
      label: 'tan', role: ButtonRole.function, action: _Action.input,
      token: 'tan(', shiftedLabel: 'tan⁻¹', shiftedToken: 'arctan(',
      semanticLabel: 'tangent', shiftedSemanticLabel: 'inverse tangent'),
  _KeySpec(
      label: 'log', role: ButtonRole.function, action: _Action.input,
      token: 'log(10,', shiftedLabel: '10^x', shiftedToken: '10^(',
      semanticLabel: 'log base 10', shiftedSemanticLabel: 'ten to the power of'),
  _KeySpec(
      label: 'ln', role: ButtonRole.function, action: _Action.input,
      token: 'ln(', shiftedLabel: 'e^x', shiftedToken: 'e^(',
      semanticLabel: 'natural log', shiftedSemanticLabel: 'e to the power of'),

  _KeySpec(label: '7', role: ButtonRole.number, action: _Action.input, token: '7'),
  _KeySpec(label: '8', role: ButtonRole.number, action: _Action.input, token: '8'),
  _KeySpec(label: '9', role: ButtonRole.number, action: _Action.input, token: '9'),
  _KeySpec(label: '1/x', role: ButtonRole.function, action: _Action.wrapReciprocal,
      semanticLabel: 'reciprocal'),
  _KeySpec(label: '÷', role: ButtonRole.operatorKey, action: _Action.input, token: '/'),

  _KeySpec(label: '4', role: ButtonRole.number, action: _Action.input, token: '4'),
  _KeySpec(label: '5', role: ButtonRole.number, action: _Action.input, token: '5'),
  _KeySpec(label: '6', role: ButtonRole.number, action: _Action.input, token: '6'),
  _KeySpec(label: 'π', role: ButtonRole.function, action: _Action.input, token: 'pi',
      semanticLabel: 'pi'),
  _KeySpec(label: '×', role: ButtonRole.operatorKey, action: _Action.input, token: '*'),

  _KeySpec(label: '1', role: ButtonRole.number, action: _Action.input, token: '1'),
  _KeySpec(label: '2', role: ButtonRole.number, action: _Action.input, token: '2'),
  _KeySpec(label: '3', role: ButtonRole.number, action: _Action.input, token: '3'),
  _KeySpec(label: 'e', role: ButtonRole.function, action: _Action.input, token: 'e',
      semanticLabel: 'euler\'s number'),
  _KeySpec(label: '−', role: ButtonRole.operatorKey, action: _Action.input, token: '-'),

  _KeySpec(label: '0', role: ButtonRole.number, action: _Action.input, token: '0'),
  _KeySpec(label: '.', role: ButtonRole.number, action: _Action.input, token: '.'),
  _KeySpec(label: '±', role: ButtonRole.function, action: _Action.wrapNegate,
      semanticLabel: 'toggle sign'),
  _KeySpec(label: '+', role: ButtonRole.operatorKey, action: _Action.input, token: '+'),
  _KeySpec(label: '=', role: ButtonRole.equals, action: _Action.evaluate),
];

class Keypad extends StatefulWidget {
  const Keypad({
    super.key,
    required this.controller,
    required this.layoutStyle,
    required this.feedback,
  });

  final CalculatorController controller;
  final LayoutStyle layoutStyle;
  final FeedbackService feedback;

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
      case _Action.clear:
        widget.controller.clear();
      case _Action.backspace:
        widget.controller.backspace();
      case _Action.evaluate:
        widget.controller.evaluate();
      case _Action.toggleAngle:
        widget.controller.toggleAngleMode();
      case _Action.toggleShift:
        setState(() => _shiftActive = !_shiftActive);
        return; // don't fall through to the shift-reset below
    }
    if (_shiftActive) {
      setState(() => _shiftActive = false);
    }
  }

  /// Lays out keys as equal-height rows of equal-width cells filling
  /// whatever space is available, rather than a fixed aspect ratio — a
  /// grid sized by ratio can ask for more height than a phone screen has
  /// once the display and app bar take their share, leaving keys
  /// stranded below the fold with no way to scroll to them. Filling the
  /// space exactly guarantees every key is always reachable.
  @override
  Widget build(BuildContext context) {
    final columns = widget.layoutStyle.columns;
    final rows = <List<_KeySpec>>[
      for (var i = 0; i < _keys.length; i += columns)
        _keys.sublist(i, i + columns > _keys.length ? _keys.length : i + columns),
    ];

    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (final key in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildButton(context, key),
                      ),
                    ),
                  for (var i = row.length; i < columns; i++)
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, _KeySpec key) {
    final isAngleToggle = key.action == _Action.toggleAngle;
    final label = isAngleToggle
        ? widget.controller.angleMode.label
        : (_shiftActive ? (key.shiftedLabel ?? key.label) : key.label);
    final semantic = isAngleToggle
        ? 'Angle mode: ${widget.controller.angleMode.label}'
        : (_shiftActive
            ? (key.shiftedSemanticLabel ?? key.shiftedLabel ?? key.label)
            : (key.semanticLabel ?? key.label));
    final role = key.action == _Action.toggleShift && _shiftActive
        ? ButtonRole.action
        : key.role;

    return CalculatorButton(
      label: label,
      role: role,
      style: widget.layoutStyle,
      semanticLabel: semantic,
      onPressed: () => _handle(key),
    );
  }
}
