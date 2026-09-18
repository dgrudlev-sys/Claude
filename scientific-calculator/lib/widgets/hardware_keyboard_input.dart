import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/calculator_controller.dart';

/// Lets a real keyboard drive the calculator.
///
/// Until now the app ignored every keystroke. On a phone that is easy to
/// miss; everywhere else it is the first thing anyone tries. It also shut
/// out two groups entirely — anyone using a Bluetooth keyboard because a
/// touchscreen is hard to hit accurately, and anyone using a refreshable
/// braille display, which talks to the system as an ordinary keyboard.
///
/// The mapping follows what people already have in their fingers from
/// every other calculator: the digits, the four operators, Enter for
/// equals, Backspace to delete, Escape to clear. `^` for a power and
/// `,` for an argument separator come along because the keypad has them.
class HardwareKeyboardInput extends StatelessWidget {
  const HardwareKeyboardInput({
    super.key,
    required this.controller,
    required this.child,
    this.onKey,
  });

  final CalculatorController controller;
  final Widget child;

  /// Fired for any keystroke that was understood, so the screen can give
  /// the same click or haptic a tapped key would.
  final VoidCallback? onKey;

  /// Characters that go straight into the expression. The value is what
  /// the engine wants, which is not always what was typed: the keyboard
  /// has no ÷ or ×, and the engine has no ÷ or ×.
  static const _characters = <String, String>{
    '0': '0', '1': '1', '2': '2', '3': '3', '4': '4',
    '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
    '.': '.', ',': ',',
    '+': '+', '-': '-', '*': '*', '/': '/',
    '(': '(', ')': ')', '^': '^',
    // The typographic forms, in case they arrive from a paste or from a
    // layout that produces them.
    '−': '-', '×': '*', '÷': '/',
    '%': '/100',
  };

  /// The numeric keypad, mapped by key rather than by character.
  ///
  /// Not redundant with [_characters]: a numpad key does not always
  /// arrive with a character attached, and the numpad is precisely what
  /// someone doing arithmetic on a keyboard reaches for.
  static final _numpad = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
    LogicalKeyboardKey.numpadAdd: '+',
    LogicalKeyboardKey.numpadSubtract: '-',
    LogicalKeyboardKey.numpadMultiply: '*',
    LogicalKeyboardKey.numpadDivide: '/',
    LogicalKeyboardKey.numpadDecimal: '.',
  };

  /// True when this keystroke was handled, so it does not also go
  /// somewhere else.
  bool _handle(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    final fromNumpad = _numpad[event.logicalKey];
    if (fromNumpad != null) {
      controller.input(fromNumpad);
      return true;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        controller.evaluate();
        return true;
      case LogicalKeyboardKey.backspace:
        controller.backspace();
        return true;
      case LogicalKeyboardKey.escape:
        controller.clear();
        return true;
    }

    final typed = event.character;
    if (typed == null || typed.isEmpty) return false;

    // "=" is equals rather than a character, which is what every
    // calculator keyboard has done since they had keyboards.
    if (typed == '=') {
      controller.evaluate();
      return true;
    }

    final token = _characters[typed];
    if (token == null) return false;
    controller.input(token);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      // Not a text field, so it takes keystrokes without asking the
      // system for an on-screen keyboard — which on a phone would cover
      // the keypad the user is actually using.
      onKeyEvent: (node, event) {
        final handled = _handle(event);
        if (handled) onKey?.call();
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
