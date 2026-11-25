import 'package:flutter_test/flutter_test.dart';
import 'package:financial_calculator/models/plan_month.dart';
import 'test/test_helpers.dart';

void main() {
  group('budget carry‑in balance', () {
    test('returns a numeric value for a given month', () {
      final month = PlanMonth(2026, 10);
      final balance = budgetCarryInBalance(month);
      expect(balance, isA<double>());
    });
  });
}
