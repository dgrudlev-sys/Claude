import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:financial_calculator/budget_entry.dart';
import 'package:financial_calculator/models/plan_month.dart';
import 'package:financial_calculator/widgets/budget_home.dart';
import 'package:financial_calculator/widgets/budget_add.dart';
import 'package:financial_calculator/widgets/budget_overview.dart';
import 'package:financial_calculator/widgets/budget_catalog.dart';
import 'package:financial_calculator/services/clock.dart';
import 'test/test_helpers.dart';
import 'dart:convert';
import 'package:financial_calculator/domain/budget_book.dart';
import 'package:financial_calculator/domain/monthly_plan.dart';
import 'package:financial_calculator/data/monthly_plan_store.dart';

void main() {
  group('budgetAddDefaultDate helper', () {
    test('defaults to target month preserving day, clamped to month length', () {
      final target = PlanMonth(2026, 10);
      final now = DateTime(2026, 11, 12);
      final result = budgetAddDefaultDate(target, now);
      expect(result, DateTime(2026, 10, 12));
    });

    test('returns now date when month matches now', () {
      final target = PlanMonth(2026, 11);
      final now = DateTime(2026, 11, 5, 14, 30, 45);
      final result = budgetAddDefaultDate(target, now);
      expect(result, DateTime(2026, 11, 5));
    });

    test('clamps day to last day of February when day exceeds month length', () {
      final target = PlanMonth(2026, 2);
      final now = DateTime(2026, 1, 31);
      final result = budgetAddDefaultDate(target, now);
      // 2026 is not a leap year, Feb has 28 days
      expect(result, DateTime(2026, 2, 28));
    });
  });

  group('budget overview calculations', () {
    test('groceries expense appears in overview amounts', () async {
      // Setup a simple plan with October 2026 month and a groceries line
      final month = PlanMonth(2026, 10);
      // Assume a helper to create a starter plan exists; otherwise this will
      // fail until the production code provides the necessary API.
      await createStarterPlanForMonth(month);

      // Add a groceries expense of 42.5 for the month
      await addBudgetEntry(
        month: month,
        category: 'groceries',
        amount: 42.5,
        date: DateTime(2026, 10, 15),
      );

      // Verify overview calculations
      final lineAmount = budgetLineOverviewAmount(month, 'groceries');
      expect(lineAmount, closeTo(42.5, 0.001));

      final categorySlices = budgetOverviewCategorySlices(month);
      final groceriesSlice = categorySlices.firstWhere(
          (s) => s.categoryId == 'groceries',
          orElse: () => null);
      expect(groceriesSlice?.amount, closeTo(42.5, 0.001));

      final groupSections = budgetCatalogGroupSections(month);
      final foodGroup = groupSections.firstWhere(
          (g) => g.groupId == 'food',
          orElse: () => null);
      expect(foodGroup?.totalAmount, closeTo(42.5, 0.001));
    });
  });

  group('budget add UI defaults to selected month', () {
    testWidgets('date defaults to overview month, not current now',
        (WidgetTester tester) async {
      // Freeze clock to November 12, 2026
      Clock.override(() => DateTime.utc(2026, 11, 12));

      // Pump the app with seeded October plan
      await pumpApp(tester, extraPrefs: {
        monthlyPlanPrefsKey: jsonEncode(BudgetBook(
          currentMonth: PlanMonth(2026, 10),
          intentAsked: true,
          months: {
            PlanMonth(2026, 10): MonthlyPlan.starter(
              currencyCode: 'USD',
              month: PlanMonth(2026, 10),
            ),
          },
        ).toJson()),
      });

      // Open budget home and navigate to October 2026
      await openBudgetHome(tester);


      // Open the Add Expense screen
      await tapVisible(tester, find.byKey(const Key('budget-nav-add')));
      await tester.pumpAndSettle();

      // Verify the date tile shows an October date
      final dateFinder = find.byKey(const Key('budget-add-date'));
      expect(dateFinder, findsOneWidget);
      final dateTile = tester.widget<ListTile>(dateFinder);
      final displayedDate = (dateTile.title as Text).data!;
      expect(displayedDate.startsWith('2026-10'), isTrue,
          reason: 'Add screen should default to the selected month (Oct 2026)');

      // Fill amount and save
      await fillNumeric(tester, '42.50');
      await tapVisible(tester, find.byKey(const Key('budget-add-save')));
      await tester.pumpAndSettle();

      // Verify the Add screen is closed
      expect(find.byKey(const Key('budget-add-save')), findsNothing);

      // Verify the expense appears in Recent/Activity
      expect(find.textContaining('Groceries'), findsOneWidget);
      expect(find.textContaining('42.50'), findsOneWidget);

      // Expand food group if needed and verify overview amount
      await tapVisible(tester, find.byKey(const Key('budget-group-food')));
      await tester.pumpAndSettle();
      expect(find.textContaining('42.50'), findsWidgets);
    });
  });
}
