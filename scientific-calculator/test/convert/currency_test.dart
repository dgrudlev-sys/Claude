import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/convert/currency/currency.dart';
import 'package:scientific_calculator/convert/currency/exchange_rates.dart';
import 'package:scientific_calculator/engine/number/number.dart';

/// A source that has nothing, which is the state a freshly installed app
/// is in until it has been online once.
class EmptyRateSource implements ExchangeRateSource {
  @override
  Future<ExchangeRateSnapshot?> latest() async => null;
}

void main() {
  const converter = CurrencyConverter();

  final publishedAt = DateTime.utc(2026, 9, 15, 16);

  ExchangeRateSnapshot snapshot({DateTime? asOf}) => ExchangeRateSnapshot(
        base: 'EUR',
        asOf: asOf ?? publishedAt,
        source: 'European Central Bank',
        rates: {
          'USD': NumberValue.parse('1.0842'),
          'GBP': NumberValue.parse('0.8461'),
          'JPY': NumberValue.parse('160.23'),
          'KWD': NumberValue.parse('0.3316'),
          'SEK': NumberValue.parse('11.2395'),
        },
      );

  Currency currency(String code) => currenciesByCode[code]!;

  group('conversion through the base currency', () {
    test('base to quoted currency uses the quote directly', () {
      final result = converter.convert(
        NumberValue.parse('100'),
        currency('EUR'),
        currency('USD'),
        snapshot(),
        now: publishedAt,
      );
      expect(result.amount, NumberValue.parse('108.42'));
      expect(result.rate, NumberValue.parse('1.0842'));
    });

    test('quoted back to base inverts it', () {
      final result = converter.convert(
        NumberValue.parse('108.42'),
        currency('USD'),
        currency('EUR'),
        snapshot(),
        now: publishedAt,
      );
      expect(result.amount, NumberValue.parse('100.00'));
    });

    test('two non-base currencies cross through the base', () {
      // 1.0842 USD and 0.8461 GBP both buy one euro, so a pound is
      // 1.0842 / 0.8461 = 1.28139... dollars.
      final rate =
          converter.crossRate('GBP', 'USD', snapshot()).toDouble();
      expect(rate, closeTo(1.0842 / 0.8461, 1e-12));

      final result = converter.convert(
        NumberValue.parse('50'),
        currency('GBP'),
        currency('USD'),
        snapshot(),
        now: publishedAt,
      );
      expect(result.amount.toDouble(), closeTo(64.07, 0.005));
    });

    test('the cross rate is an exact ratio of the two quotes', () {
      final rate = converter.crossRate('GBP', 'USD', snapshot());
      expect(rate.isExact, isTrue);
      // 1.0842 / 0.8461 exactly, as published, not as a double.
      expect(rate, RationalValue(BigInt.from(10842), BigInt.from(8461)));
    });

    test('converting a currency to itself is the identity', () {
      final result = converter.convert(
        NumberValue.parse('42.50'),
        currency('SEK'),
        currency('SEK'),
        snapshot(),
        now: publishedAt,
      );
      expect(result.amount, NumberValue.parse('42.50'));
      expect(result.rate, RationalValue.fromInt(1));
    });
  });

  group('rounding respects each currency\'s minor unit', () {
    test('the yen has no decimal places', () {
      final result = converter.convert(
        NumberValue.parse('10'),
        currency('EUR'),
        currency('JPY'),
        snapshot(),
        now: publishedAt,
      );
      // 1602.3 rounds to a whole yen.
      expect(result.amount, RationalValue.fromInt(1602));
    });

    test('the Kuwaiti dinar has three', () {
      final result = converter.convert(
        NumberValue.parse('1'),
        currency('EUR'),
        currency('KWD'),
        snapshot(),
        now: publishedAt,
      );
      expect(result.amount, NumberValue.parse('0.332'));
    });

    test('halves round away from zero, the way a till does', () {
      final half = RationalValue(BigInt.one, BigInt.two);
      expect(
        converter.roundToMinorUnit(half, currency('JPY')),
        RationalValue.fromInt(1),
      );
      expect(
        converter.roundToMinorUnit(half.negate(), currency('JPY')),
        RationalValue.fromInt(-1),
      );
      // 2.345 at two places, with an odd denominator underneath.
      expect(
        converter.roundToMinorUnit(
            RationalValue(BigInt.from(469), BigInt.from(200)), currency('USD')),
        NumberValue.parse('2.35'),
      );
    });
  });

  group('every result carries its date', () {
    test('fresh rates are not stale, and say how old they are', () {
      final result = converter.convert(
        NumberValue.parse('1'),
        currency('EUR'),
        currency('USD'),
        snapshot(),
        now: publishedAt.add(const Duration(hours: 3)),
      );
      expect(result.isStale, isFalse);
      expect(result.age, const Duration(hours: 3));
      expect(result.provenance,
          'Rate from European Central Bank, updated 3 hours ago.');
    });

    test('rates older than the tolerance are flagged but still used', () {
      final result = converter.convert(
        NumberValue.parse('1'),
        currency('EUR'),
        currency('USD'),
        snapshot(),
        now: publishedAt.add(const Duration(days: 9)),
      );
      // The number is still there — a nine-day-old rate is usually close
      // enough to be worth showing. It is simply labelled.
      expect(result.amount, NumberValue.parse('1.08'));
      expect(result.isStale, isTrue);
      expect(result.provenance, contains('9 days ago'));
    });

    test('yesterday reads as yesterday', () {
      final result = converter.convert(
        NumberValue.parse('1'),
        currency('EUR'),
        currency('USD'),
        snapshot(),
        now: publishedAt.add(const Duration(days: 1, hours: 2)),
      );
      expect(result.provenance, contains('yesterday'));
    });

    test('the tolerance is the caller\'s to set', () {
      const patient = CurrencyConverter(staleAfter: Duration(days: 30));
      final result = patient.convert(
        NumberValue.parse('1'),
        currency('EUR'),
        currency('USD'),
        snapshot(),
        now: publishedAt.add(const Duration(days: 9)),
      );
      expect(result.isStale, isFalse);
    });
  });

  group('missing data is reported, never invented', () {
    test('a currency with no quote in the snapshot fails by name', () {
      expect(
        () => converter.crossRate('EUR', 'ZAR', snapshot()),
        throwsA(isA<CurrencyConversionError>()
            .having((e) => e.message, 'message', contains('ZAR'))),
      );
    });

    test('no rates at all explains what to do about it', () async {
      expect(
        () => converter.convertNamed(
          NumberValue.parse('10'),
          'USD',
          'EUR',
          EmptyRateSource(),
        ),
        throwsA(isA<CurrencyConversionError>().having(
          (e) => e.message,
          'message',
          allOf(contains('No exchange rates'), contains('offline')),
        )),
      );
    });

    test('an unknown currency code is named back', () async {
      expect(
        () => converter.convertNamed(
          NumberValue.parse('10'),
          'XYZ',
          'EUR',
          CachedExchangeRateSource(snapshot()),
        ),
        throwsA(isA<CurrencyConversionError>()
            .having((e) => e.message, 'message', contains('XYZ'))),
      );
    });

    test('the snapshot can be asked what it covers', () {
      expect(snapshot().hasRateFor('USD'), isTrue);
      // The base is always available, though it has no quote of its own.
      expect(snapshot().hasRateFor('EUR'), isTrue);
      expect(snapshot().hasRateFor('ZAR'), isFalse);
      expect(snapshot().availableCodes, {'EUR', 'USD', 'GBP', 'JPY', 'KWD', 'SEK'});
    });
  });

  group('the cached source is what makes this work offline', () {
    test('it serves the last rates it was given', () async {
      final cache = CachedExchangeRateSource();
      expect(await cache.latest(), isNull);

      cache.store(snapshot());
      final result = await converter.convertNamed(
        NumberValue.parse('100'),
        'USD',
        'EUR',
        cache,
        now: publishedAt,
      );
      expect(result.amount.toDouble(), closeTo(92.23, 0.005));
      expect(result.source, 'European Central Bank');
    });

    test('currencies are found by code or by name', () {
      expect(findCurrency('usd')?.code, 'USD');
      expect(findCurrency(' EUR ')?.code, 'EUR');
      expect(findCurrency('Japanese yen')?.code, 'JPY');
      expect(findCurrency('galleons'), isNull);
    });

    test('the currency list is well formed', () {
      final codes = currencies.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length);
      for (final currency in currencies) {
        expect(currency.code, matches(RegExp(r'^[A-Z]{3}$')));
        expect(currency.decimalDigits, inInclusiveRange(0, 3));
      }
    });
  });
}
