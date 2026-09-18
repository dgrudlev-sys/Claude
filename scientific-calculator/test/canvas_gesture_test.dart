import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/graphing/graph_controller.dart';
import 'package:scientific_calculator/graphing3d/surface_controller.dart';
import 'package:scientific_calculator/screens/graph_screen.dart';
import 'package:scientific_calculator/screens/surface3d_screen.dart';
import 'package:scientific_calculator/theme/app_theme.dart';

/// Mirrors HomeShell's actual structure (a screen hosted as one page of a
/// NeverScrollableScrollPhysics TabBarView) — the fix for the gesture-arena
/// bug (PageView's own drag recognizer swallowing onPan*/onScale* on any
/// descendant, even for a plain tap) only matters when reproduced in this
/// exact shape, not with the canvas pumped standalone.
Widget _wrapInTabShell(Widget child) {
  return MaterialApp(
    theme: buildAppTheme(Appearance.light),
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
}
