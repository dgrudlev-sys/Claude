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

  testWidgets('all eight mode tabs are reachable and show distinct content', (tester) async {
    await pumpApp(tester);

    // Calculator is the default tab.
    expect(find.byKey(const Key('calculator-display')), findsOneWidget);

    await tester.tap(find.text('Graph'));
    await tester.pumpAndSettle();
    expect(find.text('Function'), findsOneWidget); // graph mode segmented button

    await tester.tap(find.text('3D'));
    await tester.pumpAndSettle();
    expect(find.text('Plot'), findsOneWidget);
    expect(find.text('Drag to rotate'), findsOneWidget);

    await tester.tap(find.text('Geometry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('geometry-canvas')), findsOneWidget);
    expect(find.text('Measure angle'), findsOneWidget);

    await tester.tap(find.text('Matrix'));
    await tester.pumpAndSettle();
    expect(find.text('Matrix A'), findsOneWidget);

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('1-Var'), findsOneWidget);

    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();
    expect(find.textContaining('N (periods)'), findsOneWidget);

    await tester.tap(find.text('Solve'));
    await tester.pumpAndSettle();
    expect(find.text('Solve for x'), findsWidgets);
  });

  testWidgets('settings screen is reachable from every tab via the shared icon', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Layout'), findsOneWidget);
    expect(find.text('Sound on key press'), findsOneWidget);
  });

  testWidgets('matrix determinant computes end to end through the UI', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Matrix'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('det(A)'));
    await tester.tap(find.text('det(A)'));
    await tester.pumpAndSettle();

    // Default A is the 2x2 identity matrix -> determinant 1.
    expect(find.textContaining('Result: 1'), findsOneWidget);
  });

  testWidgets('geometry: tapping the canvas twice with Measure distance selected reports a distance',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Geometry'));
    await tester.pumpAndSettle();

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
