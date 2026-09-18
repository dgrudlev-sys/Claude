import '../../engine/number/number.dart';
import 'currency.dart';

/// A set of exchange rates as they stood at one moment.
///
/// The timestamp is not decoration. Every other conversion in this app is
/// a fact that will still be true next year; an exchange rate is a
/// measurement that was true once. A converter that shows a number
/// without saying when it was taken is lying by omission, so the date
/// travels with the rates and comes back attached to every result.
class ExchangeRateSnapshot {
  const ExchangeRateSnapshot({
    required this.base,
    required this.rates,
    required this.asOf,
    required this.source,
  });

  /// The currency every rate is quoted against.
  final String base;

  /// How many units of each currency one [base] unit buys, as quoted.
  ///
  /// Kept as [NumberValue] rather than double so the quote is stored
  /// exactly as it was published, and a cross-rate between two quotes is
  /// an exact ratio rather than a double divided by a double.
  final Map<String, NumberValue> rates;

  /// When these rates were published — not when they were downloaded.
  final DateTime asOf;

  /// Where they came from, shown to the user so the number is
  /// attributable.
  final String source;

  Duration ageAt(DateTime now) => now.difference(asOf);

  bool hasRateFor(String code) => code == base || rates.containsKey(code);

  Set<String> get availableCodes => {base, ...rates.keys};
}

/// Where rates come from.
///
/// Deliberately an interface with nothing network-shaped in it. Rates can
/// arrive from a web service, from a file the user placed, or from rates
/// typed in by hand — the converter does not care, and can be tested
/// without any of them.
abstract class ExchangeRateSource {
  /// The most recent rates this source can offer, or null when it has
  /// none — offline with an empty cache, for instance.
  Future<ExchangeRateSnapshot?> latest();
}

/// Serves rates that were stored on the device, and nothing else.
///
/// This is the offline case, and it is the default: the calculator works
/// without a network, so currency conversion shows the last rates it saw
/// along with their date rather than failing or silently going stale.
class CachedExchangeRateSource implements ExchangeRateSource {
  CachedExchangeRateSource([this._snapshot]);

  ExchangeRateSnapshot? _snapshot;

  void store(ExchangeRateSnapshot snapshot) => _snapshot = snapshot;

  @override
  Future<ExchangeRateSnapshot?> latest() async => _snapshot;
}

class CurrencyConversionError implements Exception {
  const CurrencyConversionError(this.message);

  final String message;

  @override
  String toString() => message;
}

class CurrencyConversionResult {
  const CurrencyConversionResult({
    required this.amount,
    required this.from,
    required this.to,
    required this.rate,
    required this.asOf,
    required this.source,
    required this.age,
    required this.isStale,
  });

  /// The converted amount, rounded to the target currency's minor unit.
  final NumberValue amount;

  final Currency from;
  final Currency to;

  /// The rate actually used, so the user can check the arithmetic.
  final NumberValue rate;

  final DateTime asOf;
  final String source;
  final Duration age;

  /// Whether these rates are older than the caller's tolerance. The
  /// number is still shown — a day-old rate is usually close enough to
  /// be useful — but the UI has to say so.
  final bool isStale;

  /// The line shown under every currency result.
  String get provenance {
    final days = age.inDays;
    final when = switch (days) {
      0 when age.inHours == 0 => 'updated in the last hour',
      0 => 'updated ${age.inHours} hours ago',
      1 => 'updated yesterday',
      _ => 'updated $days days ago',
    };
    return 'Rate from $source, $when.';
  }
}

/// Converts between currencies using a rate snapshot.
///
/// Two rules this will not bend on: it never invents a rate it does not
/// have, and it never presents one without its date. Everywhere else in
/// this app an unavailable answer is a bug; here it is the honest result
/// of having no recent data, and it is reported as such.
class CurrencyConverter {
  const CurrencyConverter({this.staleAfter = const Duration(days: 1)});

  /// How old rates may be before results are marked stale.
  final Duration staleAfter;

  CurrencyConversionResult convert(
    NumberValue amount,
    Currency from,
    Currency to,
    ExchangeRateSnapshot snapshot, {
    DateTime? now,
  }) {
    final rate = crossRate(from.code, to.code, snapshot);
    final at = now ?? DateTime.now();
    final age = snapshot.ageAt(at);

    return CurrencyConversionResult(
      amount: roundToMinorUnit(amount.multiply(rate), to),
      from: from,
      to: to,
      rate: rate,
      asOf: snapshot.asOf,
      source: snapshot.source,
      age: age,
      isStale: age > staleAfter,
    );
  }

  /// Convenience for typed and spoken input: "100 usd to eur".
  Future<CurrencyConversionResult> convertNamed(
    NumberValue amount,
    String from,
    String to,
    ExchangeRateSource source, {
    DateTime? now,
  }) async {
    final fromCurrency = findCurrency(from);
    if (fromCurrency == null) {
      throw CurrencyConversionError('Unknown currency "$from"');
    }
    final toCurrency = findCurrency(to);
    if (toCurrency == null) {
      throw CurrencyConversionError('Unknown currency "$to"');
    }
    final snapshot = await source.latest();
    if (snapshot == null) {
      throw const CurrencyConversionError(
        'No exchange rates have been downloaded yet. Connect once to fetch '
        'them, and they will then work offline.',
      );
    }
    return convert(amount, fromCurrency, toCurrency, snapshot, now: now);
  }

  /// The rate from one currency to another, derived through the
  /// snapshot's base currency when neither is the base.
  NumberValue crossRate(String from, String to, ExchangeRateSnapshot snapshot) {
    if (from == to) return RationalValue.fromInt(1);

    NumberValue rateOf(String code) {
      if (code == snapshot.base) return RationalValue.fromInt(1);
      final rate = snapshot.rates[code];
      if (rate == null) {
        throw CurrencyConversionError(
          'No rate for $code in the rates from ${snapshot.source}.',
        );
      }
      return rate;
    }

    // base→to divided by base→from. Both quotes are exact rationals, so
    // the cross-rate is an exact ratio rather than a double of a double.
    return rateOf(to).divide(rateOf(from));
  }

  /// Rounds to the currency's smallest unit, half away from zero — the
  /// rule a till uses. The yen rounds to whole yen and the dinar to
  /// thousandths, which is why this asks the currency instead of
  /// assuming cents.
  NumberValue roundToMinorUnit(NumberValue value, Currency currency) {
    if (value is! RationalValue) return value;
    final scale = BigInt.from(10).pow(currency.decimalDigits);
    final numerator = value.numerator * scale;
    final denominator = value.denominator;

    // (2n + d) ÷ 2d, floored, is half-away-from-zero without ever
    // dividing anything in half — which matters because d may be odd.
    final magnitude =
        (BigInt.two * numerator.abs() + denominator) ~/ (BigInt.two * denominator);
    final rounded = numerator.isNegative ? -magnitude : magnitude;
    return RationalValue(rounded, scale);
  }
}
