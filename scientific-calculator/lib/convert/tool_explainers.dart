import '../core/explanation.dart';
import '../finance/money_math.dart';
import 'convert_engine.dart';
import 'currency_service.dart';
import 'fraction_math.dart';
import 'percent_math.dart';

export '../core/explanation.dart';

/// Plain-language walkthroughs for everyday tools (percent, fractions, convert, money).
class ToolExplainers {
  ToolExplainers._();

  static Explanation percentOf({required double percent, required double ofValue}) {
    final p = formatExplainNumber(percent);
    final n = formatExplainNumber(ofValue);
    final decimal = formatExplainNumber(percent / 100);
    final result = formatExplainNumber(PercentMath.percentOf(percent: percent, ofValue: ofValue));
    return Explanation(steps: [
      ExplanationStep(
        words: '$p% is the fraction $p/100, or $decimal.',
        symbols: '$p% = $p/100 = $decimal',
      ),
      ExplanationStep(
        words: 'Applied to $n that is $result.',
        symbols: '$decimal × $n = $result',
      ),
    ]);
  }

  static Explanation whatPercent({required double part, required double whole}) {
    final a = formatExplainNumber(part);
    final b = formatExplainNumber(whole);
    final ratio = formatExplainNumber(part / whole);
    final result = formatExplainNumber(PercentMath.whatPercent(part: part, whole: whole));
    return Explanation(steps: [
      ExplanationStep(
        words: '$a as a share of $b is $ratio.',
        symbols: '$a ÷ $b = $ratio',
      ),
      ExplanationStep(
        words: 'As a percent that is $result%.',
        symbols: '$ratio × 100 = $result%',
      ),
    ]);
  }

  static Explanation percentChange({required double amount, required double percent}) {
    final a = formatExplainNumber(amount);
    final p = formatExplainNumber(percent);
    final change = amount * percent / 100;
    final delta = formatExplainNumber(change);
    final result = formatExplainNumber(PercentMath.changeBy(amount: amount, percent: percent));
    final down = percent < 0;
    return Explanation(steps: [
      ExplanationStep(
        words: '${p.replaceFirst('-', '')} percent of $a is $delta.',
        symbols: '$a × ($p/100) = $delta',
      ),
      ExplanationStep(
        words: down ? 'The percent is negative, so subtract that change.' : 'Add that change to the starting amount.',
        symbols: down ? '$a − ${formatExplainNumber(change.abs())} = $result' : '$a + $delta = $result',
      ),
    ]);
  }

  static Explanation fractions(Fraction a, FractionOp op, Fraction b) {
    final result = evalFractions(a, op, b);
    return switch (op) {
      FractionOp.add => _fractionAddSub(a, b, result, add: true),
      FractionOp.subtract => _fractionAddSub(a, b, result, add: false),
      FractionOp.multiply => _fractionMul(a, b, result),
      FractionOp.divide => _fractionDiv(a, b, result),
    };
  }

  static Explanation _fractionAddSub(Fraction a, Fraction b, Fraction result, {required bool add}) {
    final common = a.denominator * b.denominator;
    final aTop = a.numerator * b.denominator;
    final bTop = b.numerator * a.denominator;
    final rawTop = add ? aTop + bTop : aTop - bTop;
    final raw = Fraction(rawTop, common);
    final sym = add ? '+' : '−';
    final steps = <ExplanationStep>[
      ExplanationStep(
        words: 'A common denominator of $common lets us rewrite ${a.improperLabel} as $aTop/$common and ${b.improperLabel} as $bTop/$common.',
        symbols: '${a.improperLabel} = $aTop/$common,  ${b.improperLabel} = $bTop/$common',
      ),
      ExplanationStep(
        words: add ? 'Adding the numerators keeps the denominator $common.' : 'Subtracting the numerators keeps the denominator $common.',
        symbols: '$aTop/$common $sym $bTop/$common = $rawTop/$common',
      ),
    ];
    if (raw.numerator != result.numerator || raw.denominator != result.denominator) {
      steps.add(ExplanationStep(
        words: 'Simplify by dividing numerator and denominator by their greatest common factor.',
        symbols: '$rawTop/$common = ${result.improperLabel}',
      ));
    } else {
      steps.add(ExplanationStep(
        words: 'This fraction is already in lowest terms.',
        symbols: result.improperLabel,
      ));
    }
    return Explanation(steps: steps);
  }

  static Explanation _fractionMul(Fraction a, Fraction b, Fraction result) {
    final rawN = a.numerator * b.numerator;
    final rawD = a.denominator * b.denominator;
    return Explanation(steps: [
      ExplanationStep(
        words: 'Multiply the numerators. Multiply the denominators.',
        symbols: '${a.improperLabel} × ${b.improperLabel} = $rawN/$rawD',
      ),
      ExplanationStep(
        words: rawN == result.numerator && rawD == result.denominator
            ? 'Already in lowest terms.'
            : 'Simplify to lowest terms.',
        symbols: '$rawN/$rawD = ${result.improperLabel}',
      ),
    ]);
  }

  static Explanation _fractionDiv(Fraction a, Fraction b, Fraction result) {
    final flipped = Fraction(b.denominator, b.numerator);
    final rawN = a.numerator * flipped.numerator;
    final rawD = a.denominator * flipped.denominator;
    return Explanation(steps: [
      ExplanationStep(
        words: 'Dividing by a fraction is multiplication by its reciprocal (numerator and denominator swapped).',
        symbols: '${a.improperLabel} ÷ ${b.improperLabel} = ${a.improperLabel} × ${flipped.improperLabel}',
      ),
      ExplanationStep(
        words: 'Multiply numerators and denominators, then simplify if needed.',
        symbols: '${a.improperLabel} × ${flipped.improperLabel} = $rawN/$rawD = ${result.improperLabel}',
      ),
    ]);
  }

  static Explanation unitConvert({
    required ConvertCategory category,
    required ConvertUnit from,
    required ConvertUnit to,
    required double amount,
    required double value,
  }) {
    final a = formatExplainNumber(amount);
    final v = formatExplainNumber(value);
    if (from.id == to.id) {
      return Explanation(steps: [
        ExplanationStep(
          words: 'Both sides use the same unit, so the number stays the same.',
          symbols: '$a ${from.symbol} = $v ${to.symbol}',
        ),
      ]);
    }
    if (category == ConvertCategory.temperature) {
      return _temperature(from, to, amount, value);
    }
    final factor = from.toBase / to.toBase;
    final f = formatExplainNumber(factor);
    return Explanation(steps: [
      ExplanationStep(
        words: 'One ${from.name.toLowerCase()} is $f ${to.name.toLowerCase()}.',
        symbols: '1 ${from.symbol} = $f ${to.symbol}',
      ),
      ExplanationStep(
        words: 'So $a times that factor is $v.',
        symbols: '$a × $f = $v ${to.symbol}',
      ),
    ]);
  }

  static Explanation _temperature(ConvertUnit from, ConvertUnit to, double amount, double value) {
    final a = formatExplainNumber(amount);
    final v = formatExplainNumber(value);
    final formula = switch ((from.id, to.id)) {
      ('c', 'f') => 'F = C × 9/5 + 32',
      ('f', 'c') => 'C = (F − 32) × 5/9',
      ('c', 'k') => 'K = C + 273.15',
      ('k', 'c') => 'C = K − 273.15',
      ('f', 'k') => 'K = (F − 32) × 5/9 + 273.15',
      ('k', 'f') => 'F = (K − 273.15) × 9/5 + 32',
      _ => '${from.symbol} → ${to.symbol}',
    };
    return Explanation(steps: [
      ExplanationStep(
        words: 'Temperature uses a formula, not a simple scale factor.',
        symbols: formula,
      ),
      ExplanationStep(
        words: 'Substituting $a ${from.name} into that formula.',
        symbols: '$a ${from.symbol} → $v ${to.symbol}',
      ),
    ]);
  }

  static Explanation currency({
    required CurrencyRates rates,
    required CurrencyInfo from,
    required CurrencyInfo to,
    required double amount,
    required double value,
  }) {
    final a = formatExplainNumber(amount);
    final v = formatExplainNumber(value);
    final fromPerEuro = formatExplainNumber(rates.perEuro[from.code] ?? 1);
    final toPerEuro = formatExplainNumber(rates.perEuro[to.code] ?? 1);
    final steps = <ExplanationStep>[
      ExplanationStep(
        words: 'The ECB table for ${formatEcbDate(rates.date)} quotes each currency against the euro. This app refreshes that table at most once a day.',
        symbols: '1 EUR = $fromPerEuro ${from.code},  1 EUR = $toPerEuro ${to.code}',
      ),
    ];
    if (from.code == 'EUR') {
      steps.add(ExplanationStep(
        words: 'The amount is already in euros. Multiply by the daily ${to.name} rate.',
        symbols: '$a × $toPerEuro = $v ${to.code}',
      ));
    } else if (to.code == 'EUR') {
      steps.add(ExplanationStep(
        words: 'Divide by the ${from.name} rate to get euros.',
        symbols: '$a ÷ $fromPerEuro = $v EUR',
      ));
    } else {
      final euros = formatExplainNumber(amount / (rates.perEuro[from.code] ?? 1));
      steps.add(ExplanationStep(
        words: 'Convert ${from.name} into euros first.',
        symbols: '$a ${from.code} ÷ $fromPerEuro = $euros EUR',
      ));
      steps.add(ExplanationStep(
        words: 'Then convert those euros into ${to.name}.',
        symbols: '$euros EUR × $toPerEuro = $v ${to.code}',
      ));
    }
    return Explanation(steps: steps);
  }

  static Explanation tip({required double bill, required double tipPercent, required int people}) {
    final result = ConvertEngine.tip(bill: bill, tipPercent: tipPercent, people: people);
    final b = formatExplainNumber(bill);
    final p = formatExplainNumber(tipPercent);
    final tipAmt = formatExplainNumber(result.tipAmount);
    final total = formatExplainNumber(result.total);
    final steps = <ExplanationStep>[
      ExplanationStep(
        words: 'Tip is $p percent of the bill $b.',
        symbols: '$b × ($p/100) = $tipAmt',
      ),
      ExplanationStep(
        words: 'Total is the bill plus the tip.',
        symbols: '$b + $tipAmt = $total',
      ),
    ];
    if (result.perPerson != null) {
      steps.add(ExplanationStep(
        words: 'Split the total between $people people.',
        symbols: '$total ÷ $people = ${formatExplainNumber(result.perPerson!)}',
      ));
    }
    return Explanation(steps: steps);
  }

  static Explanation simpleInterest({
    required double principal,
    required double ratePercent,
    required double years,
  }) {
    final interest = MoneyMath.simpleInterest(principal: principal, ratePercent: ratePercent, years: years);
    final total = principal + interest;
    final p = formatExplainNumber(principal);
    final r = formatExplainNumber(ratePercent);
    final t = formatExplainNumber(years);
    final i = formatExplainNumber(interest);
    final tot = formatExplainNumber(total);
    final decimal = formatExplainNumber(ratePercent / 100);
    return Explanation(steps: [
      ExplanationStep(
        words: 'Simple interest is principal × yearly rate × time in years. Rate is the yearly percent as a decimal.',
        symbols: 'I = P × r × t',
      ),
      ExplanationStep(
        words: '$r percent as a decimal is $decimal.',
        symbols: '$r/100 = $decimal',
      ),
      ExplanationStep(
        words: 'Interest is principal × rate × years.',
        symbols: 'I = $p × $decimal × $t = $i',
      ),
      ExplanationStep(
        words: 'The total is the principal plus the interest.',
        symbols: '$p + $i = $tot',
      ),
    ]);
  }

  static Explanation compoundInterest({
    required double principal,
    required double ratePercent,
    required double years,
    required int timesPerYear,
  }) {
    final amount = MoneyMath.compoundAmount(
      principal: principal,
      ratePercent: ratePercent,
      years: years,
      timesPerYear: timesPerYear,
    );
    final p = formatExplainNumber(principal);
    final r = formatExplainNumber(ratePercent);
    final t = formatExplainNumber(years);
    final n = timesPerYear.toString();
    final a = formatExplainNumber(amount);
    final decimal = formatExplainNumber(ratePercent / 100);
    return Explanation(steps: [
      ExplanationStep(
        words: 'Compound interest uses A = P (1 + r/n)^(n t). Interest itself earns interest.',
        symbols: 'A = P (1 + r/n)^(n t)',
      ),
      ExplanationStep(
        words: 'r is $r percent as a decimal. n is how many times it grows each year ($n). t is $t years.',
        symbols: 'r = $decimal,  n = $n,  t = $t',
      ),
      ExplanationStep(
        words: 'Put the principal $p into the formula.',
        symbols: 'A = $p (1 + $decimal/$n)^($n × $t) = $a',
      ),
    ]);
  }

  static Explanation loan({
    required double principal,
    required double annualRatePercent,
    required int months,
  }) {
    final payment = MoneyMath.monthlyLoanPayment(
      principal: principal,
      annualRatePercent: annualRatePercent,
      months: months,
    );
    final p = formatExplainNumber(principal);
    final yearly = formatExplainNumber(annualRatePercent);
    final monthly = formatExplainNumber(annualRatePercent / 100 / 12);
    final pay = formatExplainNumber(payment);
    return Explanation(steps: [
      ExplanationStep(
        words: 'A loan payment uses monthly rate r = yearly percent ÷ 100 ÷ 12, over N months.',
        symbols: 'r = $yearly/100/12 = $monthly,  N = $months',
      ),
      ExplanationStep(
        words: 'Payment = P × r × (1+r)^N / ((1+r)^N − 1). That spreads principal plus interest across the months.',
        symbols: 'PMT = $p × $monthly × (1+$monthly)^$months / ((1+$monthly)^$months − 1) = $pay',
      ),
    ]);
  }

  static Explanation savings({
    required double startAmount,
    required double monthlyAdd,
    required double annualRatePercent,
    required int months,
  }) {
    final future = MoneyMath.savingsFutureValue(
      startAmount: startAmount,
      monthlyAdd: monthlyAdd,
      annualRatePercent: annualRatePercent,
      months: months,
    );
    final start = formatExplainNumber(startAmount);
    final add = formatExplainNumber(monthlyAdd);
    final r = formatExplainNumber(annualRatePercent / 100 / 12);
    final fv = formatExplainNumber(future);
    return Explanation(steps: [
      ExplanationStep(
        words: 'The starting amount grows for $months months. Each monthly add grows from the month it is deposited.',
        symbols: 'r = ${formatExplainNumber(annualRatePercent)}%/12 = $r per month',
      ),
      ExplanationStep(
        words: 'Future value = start × (1+r)^N + monthly add × ((1+r)^N − 1)/r.',
        symbols: 'FV = $start × (1+$r)^$months + $add × ((1+$r)^$months − 1)/$r = $fv',
      ),
    ]);
  }
}
