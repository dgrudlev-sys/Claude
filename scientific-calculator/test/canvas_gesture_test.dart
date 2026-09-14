import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/graphing/graph_controller.dart';
import 'package:scientific_calculator/graphing3d/surface_controller.dart';
import 'package:scientific_calculator/geometry/geometry_controller.dart';
import 'package:scientific_calculator/screens/geometry_screen.dart';
import 'package:scientific_calculator/screens/graph_screen.dart';
import 'package:scientific_calculator/screens/surface3d_screen.dart';
import 'package:scientific_calculator/theme/app_theme.dart';
import 'package:scientific_calculator/theme/layout_style.dart';

import 'test_helpers.dart';

/// Mirrors HomeShell's actual structure (a screen hosted as one page of a
/// NeverScrollableScrollPhysics TabBarView) — the fix for the gesture-arena
/// bug (PageView's own drag recognizer swallowing onPan*/onScale* on any
/// descendant, even for a plain tap) only matters when reproduced in this
/// exact shape, not with the canvas pumped standalone.
Widget _wrapInTabShell(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(LayoutStyle.classic),
    home: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(bottom: const TabBar(tabs: [Tab(text: 'Other'), Tab(text: 'Target')])),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [const SizedBox(), child],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Graph canvas: a pan drag actually reaches the controller', (tester) async {
    final controller = GraphController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrapInTabShell(GraphScreen(controller: controller)));
    await tester.tap(find.text('Target'));
    await tester.pumpAndSettle();

    final before = controller.viewport;
    final canvas = find.byKey(const Key('graph-canvas'));
    expect(canvas, findsOneWidget);

    await tester.drag(canvas, const Offset(50, 0));
    await tester.pumpAndSettle();

    // A silent-no-op gesture (the bug this regression-tests) would leave
    // the viewport completely unchanged.
    expect(controller.viewport.xMin, isNot(before.xMin));
  });

  testWidgets('3D canvas: a drag actually reaches the controller and changes rotation',
      (tester) async {
    final controller = SurfaceController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrapInTabShell(Surface3dScreen(controller: controller)));
    await tester.tap(find.text('Target'));
    await tester.pumpAndSettle();

    final beforeAzimuth = controller.azimuth;
    final beforeElevation = controller.elevation;
    final canvas = find.byKey(const Key('surface3d-canvas'));
    expect(canvas, findsOneWidget);

    await tester.drag(canvas, const Offset(40, 25));
    await tester.pumpAndSettle();

    expect(controller.azimuth, isNot(beforeAzimuth));
    expect(controller.elevation, isNot(beforeElevation));
  });

  testWidgets('Geometry canvas: a tap places a point through pointer events', (tester) async {
    final controller = GeometryController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrapInTabShell(GeometryScreen(controller: controller)));
    await tester.tap(find.text('Target'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const Key('geometry-canvas'));
    expect(canvas, findsOneWidget);
    expect(controller.points, isEmpty);

    await tester.tap(canvas);
    await tester.pumpAndSettle();

    expect(controller.points, hasLength(1));
    expect(controller.points.single.label, 'A');
  });

  testWidgets('Geometry canvas: a tiny mouse jitter still counts as a tap, not a pan', (tester) async {
    final controller = GeometryController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrapInTabShell(GeometryScreen(controller: controller)));
    await tester.tap(find.text('Target'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const Key('geometry-canvas'));
    final center = tester.getCenter(canvas);

    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(3, 2));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.points, hasLength(1));
  });

  testWidgets('Geometry mouse click through HomeShell phone frame places a point', (tester) async {
    await pumpApp(tester, physicalSize: const Size(1400, 1000));
    await chooseMode(tester, 'geometry');

    expect(find.textContaining('Phone preview'), findsOneWidget);

    final canvas = find.byKey(const Key('geometry-canvas'));
    expect(canvas, findsOneWidget);
    final center = tester.getCenter(canvas);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: center);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.down(center);
    await tester.pump();
    // Flutter web mouse clicks often include a few move events. The live
    // bug ignored the tap when movement exceeded a slop threshold.
    await gesture.moveBy(const Offset(8, 5));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('geometry-status'))).data,
      contains('1 point'),
    );

    await gesture.down(center + const Offset(40, 30));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('geometry-status'))).data,
      contains('2 points'),
    );
  });

  testWidgets('Geometry typed coordinates plot labeled points A and B', (tester) async {
    await pumpApp(tester, physicalSize: const Size(1400, 1000));
    await chooseMode(tester, 'geometry');

    await tester.enterText(find.byKey(const Key('geometry-x')), '2');
    await tester.enterText(find.byKey(const Key('geometry-y')), '3');
    await tester.tap(find.byKey(const Key('geometry-add-point')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Point A at 2, 3'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('geometry-x')), '5');
    await tester.enterText(find.byKey(const Key('geometry-y')), '1');
    await tester.tap(find.byKey(const Key('geometry-add-point')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Point B at 5, 1'), findsOneWidget);
    expect(find.textContaining('2 points'), findsOneWidget);
  });
}
