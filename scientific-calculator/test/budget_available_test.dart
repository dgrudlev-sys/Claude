import 'package:flutter_test/flutter_test.dart';
import 'package:financial_calculator/models/plan_month.dart';
import 'test/test_helpers.dart';

void main() {
  group('budget available balance', () {
    test('returns a numeric value for a given month', () {
      final month = PlanMonth(2026, 10);
      final available = budgetAvailableBalance(month);
      expect(available, isA<double>());
    });
  });
}
