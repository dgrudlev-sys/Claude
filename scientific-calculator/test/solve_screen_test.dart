import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('solve modes are a settings-style list, not a segmented pill', (tester) async {
    await pumpApp(tester);
    await chooseMode(tester, 'solve');

    expect(find.byKey(const Key('solve-tab-equation')), findsOneWidget);
    expect(find.byKey(const Key('solve-tab-polynomial')), findsOneWidget);
    expect(find.byKey(const Key('solve-tab-calculus')), findsOneWidget);
    expect(find.text('Solve for x'), findsWidgets);
    expect(find.text('Polynomial roots'), findsOneWidget);
    expect(find.text('Derivative & simplify'), findsOneWidget);
    expect(find.text('Equation'), findsOneWidget);
    expect(find.text('Solve'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('solve-tab-polynomial')));
    await tester.tap(find.byKey(const Key('solve-tab-polynomial')));
    await tester.pumpAndSettle();
    expect(find.text('Coefficients'), findsOneWidget);
    expect(find.text('Find roots'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('solve-tab-calculus')));
    await tester.tap(find.byKey(const Key('solve-tab-calculus')));
    await tester.pumpAndSettle();
    expect(find.text('f(x) ='), findsOneWidget);
    expect(find.text('Compute'), findsOneWidget);
  });
}
