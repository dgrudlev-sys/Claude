import 'dart:math' as math;

class MoneyMathError implements Exception {
  const MoneyMathError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Everyday money formulas with worded inputs (principal, percent, months).
class MoneyMath {
  MoneyMath._();

  /// I = P × r × t. [ratePercent] is annual (5 means 5%).
  static double simpleInterest({
    required double principal,
    required double ratePercent,
    required double years,
  }) {
    return principal * (ratePercent / 100) * years;
  }

  static double simpleTotal({
    required double principal,
    required double ratePercent,
    required double years,
  }) {
    return principal + simpleInterest(principal: principal, ratePercent: ratePercent, years: years);
  }

  /// A = P (1 + r/n)^(n t). [timesPerYear] is compounding frequency (1 = yearly).
  static double compoundAmount({
    required double principal,
    required double ratePercent,
    required double years,
    int timesPerYear = 1,
  }) {
    if (timesPerYear <= 0) {
      throw const MoneyMathError('How often it grows must be greater than zero.');
    }
    final r = ratePercent / 100;
    return principal * math.pow(1 + r / timesPerYear, timesPerYear * years);
  }

  /// Standard amortized monthly payment for a loan.
  static double monthlyLoanPayment({
    required double principal,
    required double annualRatePercent,
    required int months,
  }) {
    if (months <= 0) {
      throw const MoneyMathError('How many months must be greater than zero.');
    }
    final r = annualRatePercent / 100 / 12;
    if (r.abs() < 1e-15) return principal / months;
    final growth = math.pow(1 + r, months).toDouble();
    return principal * r * growth / (growth - 1);
  }

  /// Future value of a starting amount plus a deposit every month.
  static double savingsFutureValue({
    required double startAmount,
    required double monthlyAdd,
    required double annualRatePercent,
    required int months,
  }) {
    if (months < 0) {
      throw const MoneyMathError('How many months cannot be negative.');
    }
    final r = annualRatePercent / 100 / 12;
    if (r.abs() < 1e-15) return startAmount + monthlyAdd * months;
    final growth = math.pow(1 + r, months).toDouble();
    return startAmount * growth + monthlyAdd * ((growth - 1) / r);
  }
}
