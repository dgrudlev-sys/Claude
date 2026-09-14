import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/finance/money_math.dart';

void main() {
  test('simple interest 1000 at 5% for 2 years is 100', () {
    expect(
      MoneyMath.simpleInterest(principal: 1000, ratePercent: 5, years: 2),
      closeTo(100, 1e-9),
    );
    expect(
      MoneyMath.simpleTotal(principal: 1000, ratePercent: 5, years: 2),
      closeTo(1100, 1e-9),
    );
  });

  test('compound interest 1000 at 5% yearly for 2 years is 1102.50', () {
    expect(
      MoneyMath.compoundAmount(principal: 1000, ratePercent: 5, years: 2, timesPerYear: 1),
      closeTo(1102.50, 1e-9),
    );
  });

  test('loan payment for 1000 at 12% yearly over 12 months', () {
    // Monthly rate 1%. Known PMT ≈ 88.8488
    final pmt = MoneyMath.monthlyLoanPayment(principal: 1000, annualRatePercent: 12, months: 12);
    expect(pmt, closeTo(88.84878867834168, 1e-6));
  });
}
