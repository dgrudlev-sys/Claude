import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scientific_calculator/convert/currency_service.dart';

String _table(String date, {double usd = 1.1, double bgn = 1.9558}) => jsonEncode({
      'date': date,
      'rates': {'USD': usd, 'BGN': bgn},
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('formatEcbDate uses day month year', () {
    expect(formatEcbDate('2026-08-27'), '27 August 2026');
    expect(formatEcbDate('2026-01-03'), '3 January 2026');
  });

  test('converts through euro using stub rates', () async {
    final service = CurrencyService(
      fetch: (uri) async {
        if (uri.path.endsWith('/latest')) {
          return _table('2026-08-27', usd: 1.1);
        }
        return _table('2026-08-26', usd: 1.05);
      },
    );
    final book = await service.load();
    expect(book.latest.convert(amount: 10, from: 'EUR', to: 'USD'), closeTo(11, 1e-9));
    expect(book.latest.convert(amount: 11, from: 'USD', to: 'EUR'), closeTo(10, 1e-9));
  });

  test('first install fetches latest and one historical day', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final uris = <String>[];
    final service = CurrencyService(
      prefs: prefs,
      clock: () => DateTime.utc(2026, 8, 27, 10),
      fetch: (uri) async {
        uris.add(uri.toString());
        if (uri.path.endsWith('/latest')) {
          return _table('2026-08-27', usd: 1.1);
        }
        return _table('2026-08-26', usd: 1.05);
      },
    );
    final book = await service.load();
    expect(uris, hasLength(2));
    expect(uris.first, contains('/v1/latest'));
    expect(uris.last, contains('/v1/2026-08-26'));
    expect(book.latest.date, '2026-08-27');
    expect(book.prior?.date, '2026-08-26');
    expect(book.move(from: 'EUR', to: 'USD'), FxMove.up);
  });

  test('same-date historical responses are not kept as prior', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    final service = CurrencyService(
      prefs: prefs,
      clock: () => DateTime.utc(2026, 8, 27, 10),
      fetch: (_) async {
        calls++;
        return _table('2026-08-27', usd: 1.1);
      },
    );
    final book = await service.load();
    expect(calls, 6);
    expect(book.latest.date, '2026-08-27');
    expect(book.prior, isNull);
    expect(book.move(from: 'EUR', to: 'USD'), isNull);
  });

  test('pair moved down and unchanged', () {
    final latest = CurrencyRates(
      date: '2026-08-27',
      perEuro: const {'EUR': 1, 'USD': 1.05, 'GBP': 0.85},
      fetchedAt: DateTime.utc(2026, 8, 27),
    );
    final priorUp = CurrencyRates(
      date: '2026-08-26',
      perEuro: const {'EUR': 1, 'USD': 1.10, 'GBP': 0.85},
      fetchedAt: DateTime.utc(2026, 8, 26),
    );
    final priorFlat = CurrencyRates(
      date: '2026-08-26',
      perEuro: const {'EUR': 1, 'USD': 1.05, 'GBP': 0.85},
      fetchedAt: DateTime.utc(2026, 8, 26),
    );
    expect(
      CurrencyBook(latest: latest, prior: priorUp).move(from: 'EUR', to: 'USD'),
      FxMove.down,
    );
    expect(
      CurrencyBook(latest: latest, prior: priorFlat).move(from: 'EUR', to: 'USD'),
      FxMove.unchanged,
    );
    expect(
      CurrencyBook(latest: latest, prior: priorFlat).move(from: 'EUR', to: 'GBP'),
      FxMove.unchanged,
    );
  });

  test('tiny deltas count as unchanged', () {
    final latest = CurrencyRates(
      date: '2026-08-27',
      perEuro: const {'EUR': 1, 'USD': 1.1000000004},
      fetchedAt: DateTime.utc(2026, 8, 27),
    );
    final prior = CurrencyRates(
      date: '2026-08-26',
      perEuro: const {'EUR': 1, 'USD': 1.1},
      fetchedAt: DateTime.utc(2026, 8, 26),
    );
    expect(
      CurrencyBook(latest: latest, prior: prior).move(from: 'EUR', to: 'USD'),
      FxMove.unchanged,
    );
  });

  test('same local day does not fetch again', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    var now = DateTime.utc(2026, 8, 27, 10);
    final service = CurrencyService(
      prefs: prefs,
      clock: () => now,
      fetch: (uri) async {
        calls++;
        if (uri.path.endsWith('/latest')) {
          return _table('2026-08-27', usd: 1.1);
        }
        return _table('2026-08-26', usd: 1.05);
      },
    );
    await service.load();
    await service.load();
    expect(calls, 2);

    final again = CurrencyService(
      prefs: prefs,
      clock: () => DateTime.utc(2026, 8, 27, 18),
      fetch: (_) async {
        calls++;
        return _table('2026-08-27', usd: 9);
      },
    );
    final cached = await again.load();
    expect(calls, 2);
    expect(cached.latest.convert(amount: 10, from: 'EUR', to: 'USD'), closeTo(11, 1e-9));
    expect(cached.prior?.date, '2026-08-26');
  });

  test('next local day fetches latest and promotes old table to prior', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    var now = DateTime.utc(2026, 8, 27, 10);
    final service = CurrencyService(
      prefs: prefs,
      clock: () => now,
      fetch: (uri) async {
        calls++;
        if (uri.path.endsWith('/latest')) {
          return now.day == 27 ? _table('2026-08-27', usd: 1.1) : _table('2026-08-28', usd: 2);
        }
        return _table('2026-08-26', usd: 1.05);
      },
    );
    final first = await service.load();
    expect(first.latest.date, '2026-08-27');
    expect(first.prior?.date, '2026-08-26');
    expect(calls, 2);

    now = DateTime.utc(2026, 8, 28, 10);
    final next = await service.load();
    expect(calls, 3);
    expect(next.latest.date, '2026-08-28');
    expect(next.latest.convert(amount: 10, from: 'EUR', to: 'USD'), closeTo(20, 1e-9));
    expect(next.prior?.date, '2026-08-27');
    expect(next.prior?.convert(amount: 10, from: 'EUR', to: 'USD'), closeTo(11, 1e-9));
    expect(next.move(from: 'EUR', to: 'USD'), FxMove.up);
  });

  test('keeps yesterday’s table if today’s fetch fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime.utc(2026, 8, 27, 10);
    final first = CurrencyService(
      prefs: prefs,
      clock: () => now,
      fetch: (uri) async {
        if (uri.path.endsWith('/latest')) {
          return _table('2026-08-27', usd: 1.1);
        }
        return _table('2026-08-26', usd: 1.05);
      },
    );
    await first.load();

    now = DateTime.utc(2026, 8, 28, 10);
    final second = CurrencyService(
      prefs: prefs,
      clock: () => now,
      fetch: (_) async => throw StateError('offline'),
    );
    final stale = await second.load();
    expect(stale.latest.date, '2026-08-27');
    expect(stale.prior?.date, '2026-08-26');
    expect(stale.latest.convert(amount: 10, from: 'EUR', to: 'USD'), closeTo(11, 1e-9));
  });

  test('migrates v1 prefs to latest and does not refetch the same day', () async {
    final v1 = CurrencyRates(
      date: '2026-08-27',
      perEuro: const {'EUR': 1, 'USD': 1.1},
      fetchedAt: DateTime.utc(2026, 8, 27, 10),
    );
    SharedPreferences.setMockInitialValues({
      'currency_daily_rates_v1': jsonEncode(v1.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    final service = CurrencyService(
      prefs: prefs,
      clock: () => DateTime.utc(2026, 8, 27, 18),
      fetch: (_) async {
        calls++;
        return _table('2026-08-27', usd: 9);
      },
    );
    final book = await service.load();
    expect(calls, 0);
    expect(book.latest.date, '2026-08-27');
    expect(book.latest.convert(amount: 10, from: 'EUR', to: 'USD'), closeTo(11, 1e-9));
    expect(book.prior, isNull);
    expect(prefs.getString('currency_daily_rates_v2'), isNotNull);
  });

  test('historical same-date retries earlier days until the table differs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final uris = <String>[];
    final service = CurrencyService(
      prefs: prefs,
      clock: () => DateTime.utc(2026, 8, 27, 10),
      fetch: (uri) async {
        uris.add(uri.path);
        if (uri.path.endsWith('/latest') || uri.path.endsWith('/2026-08-26')) {
          return _table('2026-08-27', usd: 1.1);
        }
        return _table('2026-08-25', usd: 1.0);
      },
    );
    final book = await service.load();
    expect(uris, contains('/v1/latest'));
    expect(uris, contains('/v1/2026-08-26'));
    expect(uris, contains('/v1/2026-08-25'));
    expect(uris, hasLength(3));
    expect(book.prior?.date, '2026-08-25');
    expect(book.move(from: 'EUR', to: 'USD'), FxMove.up);
  });
}
