import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/core/calculator_controller.dart';
import 'package:scientific_calculator/widgets/hardware_keyboard_input.dart';

/// A real keyboard driving the calculator.
///
/// The app ignored every keystroke until now. On a phone that is easy to
/// miss; everywhere else it is the first thing anyone tries. It also shut
/// out two groups outright — anyone on a Bluetooth keyboard because a
/// touchscreen is hard to hit accurately, and anyone on a refreshable
/// braille display, which talks to the system as an ordinary keyboard.
void main() {
  late CalculatorController controller;

  setUp(() => controller = CalculatorController());
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HardwareKeyboardInput(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    for (final character in text.split('')) {
      await tester.sendKeyEvent(_keyFor(character));
      await tester.pump();
    }
  }

  group('typing goes into the expression', () {
    testWidgets('digits and operators arrive as typed', (tester) async {
      await pump(tester);
      await type(tester, '12+34');
      expect(controller.expression, '12+34');
    });

    testWidgets('enter evaluates, as it does on every other calculator',
        (tester) async {
      await pump(tester);
      await type(tester, '7*6');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(controller.display, '42');
    });

    testWidgets('equals evaluates too', (tester) async {
      await pump(tester);
      await type(tester, '2+3');
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.pump();
      expect(controller.display, '5');
    });

    testWidgets('backspace deletes and escape clears', (tester) async {
      await pump(tester);
      await type(tester, '123');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.expression, '12');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.expression, isEmpty);
    });
  });

  group('keys that mean nothing here are left alone', () {
    testWidgets('a letter does not end up in the expression',
        (tester) async {
      // Passing it through would let "q" into an expression and turn a
      // typo into a parse error two steps later.
      await pump(tester);
      await type(tester, '5');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();
      expect(controller.expression, '5');
    });

    testWidgets('and an arrow key is ignored rather than swallowed',
        (tester) async {
      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(controller.expression, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('the press is felt as well as seen', () {
    testWidgets('an understood key reports itself so it can click',
        (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HardwareKeyboardInput(
              controller: controller,
              onKey: () => presses++,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await type(tester, '42');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();

      // Two understood keys; the letter is not one of them, and a click
      // for a key that did nothing would be a lie.
      expect(presses, 2);
    });
  });
}

LogicalKeyboardKey _keyFor(String character) => switch (character) {
      '0' => LogicalKeyboardKey.digit0,
      '1' => LogicalKeyboardKey.digit1,
      '2' => LogicalKeyboardKey.digit2,
      '3' => LogicalKeyboardKey.digit3,
      '4' => LogicalKeyboardKey.digit4,
      '5' => LogicalKeyboardKey.digit5,
      '6' => LogicalKeyboardKey.digit6,
      '7' => LogicalKeyboardKey.digit7,
      '8' => LogicalKeyboardKey.digit8,
      '9' => LogicalKeyboardKey.digit9,
      // The numpad forms, because they are the ones the test harness
      // can map to a physical key. They carry the same characters.
      '+' => LogicalKeyboardKey.numpadAdd,
      '-' => LogicalKeyboardKey.numpadSubtract,
      '*' => LogicalKeyboardKey.numpadMultiply,
      '/' => LogicalKeyboardKey.numpadDivide,
      '.' => LogicalKeyboardKey.numpadDecimal,
      _ => throw ArgumentError('no key mapped for "$character"'),
    };
