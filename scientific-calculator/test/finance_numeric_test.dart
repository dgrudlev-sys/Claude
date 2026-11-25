import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scientific_calculator/screens/finance_screen.dart';
import 'package:scientific_calculator/theme/app_theme.dart';
import 'package:scientific_calculator/theme/layout_style.dart';

/// Finance is off the scientific chooser; these tests host the worksheets
/// directly so the math UI stays covered without a home-screen tile.
Widget _financeApp() {
  return MaterialApp(
    theme: buildAppTheme(LayoutStyle.classic),
    home: const Scaffold(body: FinanceScreen()),
  );
}

void main() {
  testWidgets('finance fields reject letters and keep the previous number', (tester) async {
    tester.view.physicalSize = const Size(411, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_financeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance-simple')));
    await tester.pumpAndSettle();

    final principal = find.byKey(const Key('finance-principal'));
    expect(principal, findsOneWidget);

    await tester.enterText(principal, 'abc');
    await tester.pump();
    expect(find.widgetWithText(TextFormField, '1000'), findsWidgets);

    await tester.enterText(principal, '2500');
    await tester.pump();
    expect(find.widgetWithText(TextFormField, '2500'), findsOneWidget);
  });

  testWidgets('simple interest matches a known value', (tester) async {
    tester.view.physicalSize = const Size(411, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_financeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance-simple')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('finance-principal')), '1000');
    await tester.enterText(find.byKey(const Key('finance-rate')), '5');
    await tester.enterText(find.byKey(const Key('finance-years')), '2');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finance-result')), findsOneWidget);
    expect(find.textContaining('Interest 100'), findsOneWidget);
    expect(find.textContaining('Total 1100'), findsOneWidget);
  });
}
