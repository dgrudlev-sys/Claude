import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scientific_calculator/app.dart';
import 'package:scientific_calculator/services/settings_controller.dart';

void main() {
  Future<SettingsController> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.create();
    await tester.pumpWidget(CalculatorApp(settings: settings));
    await tester.pumpAndSettle();
    return settings;
  }

  /// Back out to the Formulas tab, which is where every tool is reached
  /// from now that the app has four destinations rather than a wall of
  /// tiles.
  Future<void> goHome(WidgetTester tester) async {
    while (find.byType(BackButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    }
    // By label rather than by icon: the selected destination swaps to a
    // filled icon, so the outlined one is not there once you have
    // arrived.
    await tester.tap(find.text('Formulas'));
    await tester.pumpAndSettle();
  }

  /// Opens a tool by name, searching for it rather than remembering
  /// which group it sits in — which is also the shortest path a person
  /// has, and the one that proves the search is wired to the catalog.
  Future<void> openMode(WidgetTester tester, String name) async {
    await goHome(tester);
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pumpAndSettle();

    // The search field now also contains the name, so the row is the
    // last match rather than the only one.
    final row = find.text(name).last;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  testWidgets('every tool is named on the home screen and opens from it', (tester) async {
    await pumpApp(tester);

    // The calculator is the app's own tab rather than something you
    // open, so it is checked where it lives.
    expect(find.byKey(const Key('calculator-display')), findsOneWidget);

    await openMode(tester, 'Graphs');
    expect(find.text('Function'), findsOneWidget); // graph mode segmented button

    await openMode(tester, 'Surfaces in 3D');
    expect(find.text('Plot'), findsOneWidget);
    expect(find.text('Drag to rotate'), findsOneWidget);

    await openMode(tester, 'Geometry');
    expect(find.byKey(const Key('geometry-canvas')), findsOneWidget);
    expect(find.text('Measure angle'), findsOneWidget);

    await openMode(tester, 'Matrices');
    expect(find.text('Matrix A'), findsOneWidget);

    await openMode(tester, 'Statistics');
    expect(find.text('1-Var'), findsOneWidget);

    await openMode(tester, 'Finance');
    expect(find.textContaining('N (periods)'), findsOneWidget);

    await openMode(tester, 'Solve an equation');
    expect(find.text('Solve for x'), findsWidgets);
  });

  testWidgets('settings is a destination of its own', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Layout'), findsOneWidget);
    expect(find.text('Sound on key press'), findsOneWidget);
  });

  testWidgets('matrix determinant computes end to end through the UI', (tester) async {
    await pumpApp(tester);
    await openMode(tester, 'Matrices');

    await tester.ensureVisible(find.text('det(A)'));
    await tester.tap(find.text('det(A)'));
    await tester.pumpAndSettle();

    // Default A is the 2x2 identity matrix -> determinant 1.
    expect(find.textContaining('Result: 1'), findsOneWidget);
  });

  testWidgets('geometry: tapping the canvas twice with Measure distance selected reports a distance',
      (tester) async {
    await pumpApp(tester);
    await openMode(tester, 'Geometry');

    await tester.ensureVisible(find.text('Measure distance'));
    await tester.tap(find.text('Measure distance'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const Key('geometry-canvas'));
    final topLeft = tester.getTopLeft(canvas);

    await tester.tapAt(topLeft + const Offset(80, 80));
    await tester.pumpAndSettle();
    await tester.tapAt(topLeft + const Offset(160, 80));
    await tester.pumpAndSettle();

    expect(find.textContaining('='), findsOneWidget);
  });
}
