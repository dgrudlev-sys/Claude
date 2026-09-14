import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('chooser lists every calculator including Convert', (tester) async {
    await pumpApp(tester);
    expect(find.text('Choose a calculator'), findsOneWidget);
    expect(find.byKey(const Key('mode-calculator')), findsOneWidget);
    expect(find.byKey(const Key('mode-convert')), findsOneWidget);
    expect(find.byKey(const Key('mode-percentage')), findsOneWidget);
    expect(find.byKey(const Key('mode-fractions')), findsOneWidget);
    expect(find.byKey(const Key('mode-graph')), findsOneWidget);
    expect(find.byKey(const Key('mode-surface3d')), findsOneWidget);
    expect(find.byKey(const Key('mode-geometry')), findsOneWidget);
    expect(find.byKey(const Key('mode-matrix')), findsOneWidget);
    expect(find.byKey(const Key('mode-statistics')), findsOneWidget);
    expect(find.byKey(const Key('mode-finance')), findsOneWidget);
    expect(find.byKey(const Key('mode-solve')), findsOneWidget);
  });

  testWidgets('everyday tools sit above grouped advanced calculators', (tester) async {
    await pumpApp(tester);
    expect(find.text('Graphs and shapes'), findsOneWidget);
    expect(find.text('More math'), findsOneWidget);
    expect(find.text('Money'), findsOneWidget);

    final fractionsBottom = tester.getBottomLeft(find.byKey(const Key('mode-fractions'))).dy;
    expect(fractionsBottom < tester.getTopLeft(find.text('Graphs and shapes')).dy, isTrue);
    expect(
      tester.getTopLeft(find.text('Graphs and shapes')).dy <
          tester.getTopLeft(find.byKey(const Key('mode-graph'))).dy,
      isTrue,
    );
    expect(
      tester.getTopLeft(find.text('More math')).dy <
          tester.getTopLeft(find.byKey(const Key('mode-matrix'))).dy,
      isTrue,
    );
    expect(
      tester.getTopLeft(find.text('Money')).dy <
          tester.getTopLeft(find.byKey(const Key('mode-finance'))).dy,
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
    await chooseMode(tester, 'fractions');
    expect(find.text('Two fractions.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'convert');
    expect(find.text('What do you want to convert?'), findsOneWidget);
    expect(find.byKey(const Key('convert-currency')), findsOneWidget);
    expect(find.byKey(const Key('convert-cooking')), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-calculator')));
    await tester.pumpAndSettle();
    await chooseMode(tester, 'finance');
    expect(find.text('Simple interest'), findsOneWidget);

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
