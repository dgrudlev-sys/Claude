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

  /// Back out to the home list. Every mode is opened from there, so the
  /// test walks the app the way a person does rather than assuming the
  /// modes all sit side by side.
  Future<void> goHome(WidgetTester tester) async {
    while (find.byType(BackButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    }
  }

  /// Opens a tool by its name on the home screen, scrolling it into view
  /// first — the list is longer than a small window, exactly as it is on
  /// a phone.
  Future<void> openMode(WidgetTester tester, String name) async {
    await goHome(tester);
    final tile = find.text(name);
    await tester.scrollUntilVisible(tile, 120, scrollable: find.byType(Scrollable).first);
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  testWidgets('every tool is named on the home screen and opens from it', (tester) async {
    await pumpApp(tester);

    // Every tool is named on the home screen before it is opened.
    await openMode(tester, 'Calculator');
    expect(find.byKey(const Key('calculator-display')), findsOneWidget);
    await openMode(tester, 'Graph');
    expect(find.text('Function'), findsOneWidget); // graph mode segmented button

    await openMode(tester, '3D surfaces');
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

    await openMode(tester, 'Solve');
    expect(find.text('Solve for x'), findsWidgets);
  });

  testWidgets('settings is reachable from the home screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
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
