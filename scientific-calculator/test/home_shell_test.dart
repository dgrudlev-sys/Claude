import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/theme/app_theme.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('chooser lists Convert, Percentage, Fractions, Graph, and Solve up front',
      (tester) async {
    await pumpApp(tester);
    await openChooser(tester);
    expect(find.text('Choose a calculator'), findsOneWidget);
    expect(find.byKey(const Key('mode-calculator')), findsOneWidget);
    expect(find.byKey(const Key('mode-convert')), findsOneWidget);
    expect(find.byKey(const Key('mode-percentage')), findsOneWidget);
    expect(find.byKey(const Key('mode-fractions')), findsOneWidget);
    expect(find.byKey(const Key('mode-graph')), findsOneWidget);
    expect(find.byKey(const Key('mode-solve')), findsOneWidget);
    expect(find.byKey(const Key('mode-finance')), findsNothing);
    expect(find.byKey(const Key('mode-matrix')), findsNothing);
    expect(find.byKey(const Key('mode-geometry')), findsNothing);
    expect(find.byKey(const Key('mode-statistics')), findsNothing);
    expect(find.byKey(const Key('mode-surface3d')), findsNothing);
  });

  testWidgets('Finance is absent from home and the chooser', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('calculator-display')), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.byKey(const Key('mode-finance')), findsNothing);
    expect(find.text('Finance'), findsNothing);

    await openChooser(tester);
    expect(find.byKey(const Key('mode-finance')), findsNothing);
    expect(find.text('Finance'), findsNothing);
    expect(find.text('Money'), findsNothing);
  });

  testWidgets('More contains Statistics, Matrix, Geometry, and 3D', (tester) async {
    await pumpApp(tester);
    await openChooser(tester);

    expect(find.byKey(const Key('chooser-more')), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.byKey(const Key('mode-matrix')), findsNothing);

    await tester.tap(find.byKey(const Key('chooser-more')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mode-statistics')), findsOneWidget);
    expect(find.byKey(const Key('mode-matrix')), findsOneWidget);
    expect(find.byKey(const Key('mode-geometry')), findsOneWidget);
    expect(find.byKey(const Key('mode-surface3d')), findsOneWidget);
    expect(find.byKey(const Key('mode-finance')), findsNothing);

    final moreTop = tester.getTopLeft(find.byKey(const Key('chooser-more'))).dy;
    expect(moreTop > tester.getBottomLeft(find.byKey(const Key('mode-solve'))).dy, isTrue);
    expect(
      tester.getTopLeft(find.byKey(const Key('mode-statistics'))).dy > moreTop,
      isTrue,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('mode-matrix'))).dy >
          tester.getTopLeft(find.byKey(const Key('mode-statistics'))).dy,
      isTrue,
    );
  });

  testWidgets('Convert shortcut on calculator chrome opens Convert', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('convert-shortcut')), findsOneWidget);
    await tester.tap(find.byKey(const Key('convert-shortcut')));
    await tester.pumpAndSettle();
    expect(find.text('What do you want to convert?'), findsOneWidget);
    expect(find.byKey(const Key('convert-currency')), findsOneWidget);
    expect(find.byKey(const Key('calculator-display')), findsNothing);
  });

  testWidgets('chooser rows are full-bleed with no gap', (tester) async {
    await pumpApp(tester);
    await openChooser(tester);

    final calc = tester.getRect(find.byKey(const Key('mode-calculator')));
    final convert = tester.getRect(find.byKey(const Key('mode-convert')));
    final scaffold = tester.getRect(find.byType(Scaffold).first);
    expect(calc.left, scaffold.left);
    expect(calc.right, scaffold.right);
    // Settings-style hairline Divider between tiles — not an 8–16px gap.
    expect(convert.top - calc.bottom, lessThanOrEqualTo(1.5));
    expect(convert.top, greaterThanOrEqualTo(calc.bottom));
  });

  testWidgets('chooser has no trailing chevrons', (tester) async {
    await pumpApp(tester);
    await openChooser(tester);
    expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
  });

  testWidgets('last used icon uses ColorStory highlight', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'percentage');
    await openChooser(tester);

    final context = tester.element(find.byKey(const Key('mode-percentage')));
    final highlight = Theme.of(context).extension<CalculatorPalette>()!.equalsButton;
    final percentIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('mode-percentage')),
        matching: find.byIcon(Icons.percent),
      ),
    );
    expect(percentIcon.color, highlight);

    final calcIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('mode-calculator')),
        matching: find.byIcon(Icons.calculate_outlined),
      ),
    );
    expect(calcIcon.color, Theme.of(context).colorScheme.onSurface);
  });

  testWidgets('percentage questions are full-bleed rows, not cards', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'percentage');
    final row = tester.getRect(find.byKey(const Key('percent-of')));
    final scaffold = tester.getRect(find.byType(Scaffold).first);
    expect(row.left, scaffold.left);
    expect(row.right, scaffold.right);
    expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
  });

  testWidgets('last used is a check and label, not a card outline', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'percentage');
    await openChooser(tester);
    expect(find.text('Last used'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('mode-percentage')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('primary tools sit above More', (tester) async {
    await pumpApp(tester);
    await openChooser(tester);

    final fractionsBottom = tester.getBottomLeft(find.byKey(const Key('mode-fractions'))).dy;
    expect(fractionsBottom < tester.getTopLeft(find.byKey(const Key('mode-graph'))).dy, isTrue);
    expect(
      tester.getTopLeft(find.byKey(const Key('mode-graph'))).dy <
          tester.getTopLeft(find.byKey(const Key('mode-solve'))).dy,
      isTrue,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('mode-solve'))).dy <
          tester.getTopLeft(find.byKey(const Key('chooser-more'))).dy,
      isTrue,
    );
  });

  testWidgets('each mode opens distinct content from the chooser', (tester) async {
    await pumpApp(tester);

    await chooseMode(tester, 'calculator');
    expect(find.byKey(const Key('calculator-display')), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'graph');
    expect(find.text('Function'), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'surface3d');
    expect(find.text('Plot'), findsOneWidget);
    expect(find.text('Drag to rotate'), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'geometry');
    expect(find.byKey(const Key('geometry-canvas')), findsOneWidget);
    expect(find.text('Measure angle'), findsOneWidget);
    expect(find.byKey(const Key('geometry-tool-point')), findsOneWidget);
    expect(find.byKey(const Key('geometry-tool-segment')), findsOneWidget);
    expect(find.byKey(const Key('geometry-tool-line')), findsOneWidget);
    expect(find.byKey(const Key('geometry-tool-circle')), findsOneWidget);
    expect(find.byKey(const Key('geometry-tool-midpoint')), findsOneWidget);
    expect(find.byKey(const Key('geometry-tool-measureDistance')), findsOneWidget);
    expect(find.byKey(const Key('geometry-tool-measureAngle')), findsOneWidget);
    expect(find.byKey(const Key('geometry-tool-select')), findsOneWidget);
    expect(find.byKey(const Key('geometry-add-point')), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'matrix');
    expect(find.text('Matrix A'), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'statistics');
    expect(find.text('Average'), findsWidgets);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'percentage');
    expect(find.text('Pick one question.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mode-fractions')), findsOneWidget);

    await chooseMode(tester, 'convert');
    expect(find.text('What do you want to convert?'), findsOneWidget);
    expect(find.byKey(const Key('convert-currency')), findsOneWidget);
    expect(find.byKey(const Key('convert-cooking')), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'solve');
    expect(find.text('Solve for x'), findsWidgets);
  });

  testWidgets('settings screen is reachable from the chooser', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Layout'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sound on key press'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sound on key press'), findsOneWidget);
    expect(find.text('High contrast, color-blind safe'), findsOneWidget);
  });

  testWidgets('matrix determinant computes end to end through the UI', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'matrix');

    await tester.ensureVisible(find.text('det(A)'));
    await tester.tap(find.text('det(A)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Result: 1'), findsOneWidget);
  });

  testWidgets('geometry: tapping the canvas twice with Measure distance selected reports a distance',
      (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'geometry');

    await tester.ensureVisible(find.text('Measure distance'));
    await tester.tap(find.text('Measure distance'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const Key('geometry-canvas'));
    final topLeft = tester.getTopLeft(canvas);

    await tester.tapAt(topLeft + const Offset(80, 80));
    await tester.pumpAndSettle();
    await tester.tapAt(topLeft + const Offset(160, 80));
    await tester.pumpAndSettle();

    expect(find.textContaining('AB ='), findsWidgets);
  });
}
