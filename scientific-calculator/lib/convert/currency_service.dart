import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ECB daily table via Frankfurter (no API key). Amounts convert through EUR.
///
/// The table is saved on the device and refreshed at most once per local day.
/// It is not a live ticker.
class CurrencyRates {
  const CurrencyRates({
    required this.date,
    required this.perEuro,
    required this.fetchedAt,
  });

  /// Calendar date the ECB published, e.g. 2026-08-27.
  final String date;

  /// 1 euro in this currency. EUR itself is 1.
  final Map<String, double> perEuro;
  final DateTime fetchedAt;

  double convert({required double amount, required String from, required String to}) {
    final fromRate = perEuro[from];
    final toRate = perEuro[to];
    if (fromRate == null || toRate == null) {
      throw ArgumentError('Unknown currency');
    }
    return amount / fromRate * toRate;
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'perEuro': perEuro,
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      };

  factory CurrencyRates.fromJson(Map<String, dynamic> json) {
    final raw = json['perEuro'] as Map<String, dynamic>;
    return CurrencyRates(
      date: json['date'] as String? ?? '',
      perEuro: {
        for (final e in raw.entries) e.key: (e.value as num).toDouble(),
      },
      fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class CurrencyInfo {
  const CurrencyInfo(this.code, this.name);
  final String code;
  final String name;
  String get menuLabel => '$name ($code)';
}

enum FxMove { up, down, unchanged }

/// Latest ECB table plus the previous published table, when we have it.
class CurrencyBook {
  const CurrencyBook({required this.latest, this.prior});

  final CurrencyRates latest;
  final CurrencyRates? prior;

  /// Direction of `1 from → to` versus the previous table. Null if we have no prior.
  FxMove? move({required String from, required String to}) {
    final previous = prior;
    if (previous == null) return null;
    final now = latest.convert(amount: 1, from: from, to: to);
    final then = previous.convert(amount: 1, from: from, to: to);
    final delta = now - then;
    if (delta.abs() < 1e-8) return FxMove.unchanged;
    if (then != 0 && (delta / then).abs() < 1e-6) return FxMove.unchanged;
    return delta > 0 ? FxMove.up : FxMove.down;
  }

  Map<String, dynamic> toJson() => {
        'latest': latest.toJson(),
        'prior': prior?.toJson(),
      };

  factory CurrencyBook.fromJson(Map<String, dynamic> json) {
    return CurrencyBook(
      latest: CurrencyRates.fromJson(json['latest'] as Map<String, dynamic>),
      prior: json['prior'] is Map<String, dynamic>
          ? CurrencyRates.fromJson(json['prior'] as Map<String, dynamic>)
          : null,
    );
  }
}

typedef CurrencyFetcher = Future<String> Function(Uri uri);

const _kDailyRatesKeyV1 = 'currency_daily_rates_v1';
const _kDailyRatesKey = 'currency_daily_rates_v2';

const _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// ECB table date `yyyy-MM-dd` → `27 August 2026`.
String formatEcbDate(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null || month < 1 || month > 12) {
    return isoDate;
  }
  return '$day ${_monthNames[month - 1]} $year';
}

class CurrencyService {
  CurrencyService({
    CurrencyFetcher? fetch,
    SharedPreferences? prefs,
    DateTime Function()? clock,
  })  : _fetch = fetch ?? _httpGet,
        _prefs = prefs,
        _clock = clock ?? DateTime.now;

  /// Overridable for tests.
  static CurrencyService instance = CurrencyService();

  final CurrencyFetcher _fetch;
  SharedPreferences? _prefs;
  final DateTime Function() _clock;
  CurrencyBook? _memory;

  /// Keep the current fetcher (tests may stub it) and add on-device storage.
  void attachPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  static const catalog = <CurrencyInfo>[
    CurrencyInfo('EUR', 'Euro'),
    CurrencyInfo('USD', 'US dollar'),
    CurrencyInfo('GBP', 'British pound'),
    CurrencyInfo('BGN', 'Bulgarian lev'),
    CurrencyInfo('JPY', 'Japanese yen'),
    CurrencyInfo('CNY', 'Chinese yuan'),
    CurrencyInfo('INR', 'Indian rupee'),
    CurrencyInfo('CHF', 'Swiss franc'),
    CurrencyInfo('CAD', 'Canadian dollar'),
    CurrencyInfo('AUD', 'Australian dollar'),
    CurrencyInfo('SEK', 'Swedish krona'),
    CurrencyInfo('NOK', 'Norwegian krone'),
    CurrencyInfo('DKK', 'Danish krone'),
    CurrencyInfo('PLN', 'Polish zloty'),
    CurrencyInfo('CZK', 'Czech koruna'),
    CurrencyInfo('HUF', 'Hungarian forint'),
    CurrencyInfo('RON', 'Romanian leu'),
    CurrencyInfo('TRY', 'Turkish lira'),
    CurrencyInfo('BRL', 'Brazilian real'),
    CurrencyInfo('MXN', 'Mexican peso'),
    CurrencyInfo('KRW', 'South Korean won'),
    CurrencyInfo('SGD', 'Singapore dollar'),
    CurrencyInfo('HKD', 'Hong Kong dollar'),
    CurrencyInfo('NZD', 'New Zealand dollar'),
    CurrencyInfo('ZAR', 'South African rand'),
    CurrencyInfo('THB', 'Thai baht'),
    CurrencyInfo('IDR', 'Indonesian rupiah'),
    CurrencyInfo('ILS', 'Israeli shekel'),
    CurrencyInfo('PHP', 'Philippine peso'),
    CurrencyInfo('MYR', 'Malaysian ringgit'),
  ];

  /// Returns the saved daily book, fetching from the network only when
  /// this device has no table for the current local day.
  Future<CurrencyBook> load({bool force = false}) async {
    if (!force) {
      final cached = _memory ?? _readPrefs();
      if (cached != null && _isSameLocalDay(cached.latest.fetchedAt, _clock())) {
        _memory = cached;
        await _writePrefs(cached);
        return cached;
      }
      _memory = cached;
    }

    try {
      final fresh = await _fetchRemote();
      CurrencyRates? prior;
      final stored = _memory;
      if (stored != null) {
        if (fresh.date != stored.latest.date) {
          prior = stored.latest;
        } else {
          prior = stored.prior;
        }
      }
      prior ??= await _fetchPrior(fresh);
      final book = CurrencyBook(latest: fresh, prior: prior);
      _memory = book;
      await _writePrefs(book);
      return book;
    } catch (_) {
      if (_memory != null) return _memory!;
      final disk = _readPrefs();
      if (disk != null) {
        _memory = disk;
        return disk;
      }
      rethrow;
    }
  }

  Future<CurrencyRates> _fetchRemote({String? isoDate}) async {
    // v1 on frankfurter.dev keeps the old JSON shape. The .app host 301s
    // without CORS headers, so the web app cannot load rates in a browser.
    final path = isoDate ?? 'latest';
    final body = await _fetch(Uri.parse('https://api.frankfurter.dev/v1/$path'));
    return _parseFrankfurter(body);
  }

  CurrencyRates _parseFrankfurter(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final rates = <String, double>{'EUR': 1};
    final raw = json['rates'] as Map<String, dynamic>;
    for (final e in raw.entries) {
      rates[e.key] = (e.value as num).toDouble();
    }
    return CurrencyRates(
      date: json['date'] as String? ?? '',
      perEuro: rates,
      fetchedAt: _clock().toUtc(),
    );
  }

  /// Previous published table. Weekends/holidays echo the latest date, so we
  /// walk back a few calendar days until the ECB date actually changes.
  Future<CurrencyRates?> _fetchPrior(CurrencyRates latest) async {
    final parsed = _parseIsoDate(latest.date);
    if (parsed == null) return null;
    for (var back = 1; back <= 5; back++) {
      final day = parsed.subtract(Duration(days: back));
      try {
        final historical = await _fetchRemote(isoDate: _isoDate(day));
        if (historical.date != latest.date) return historical;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  CurrencyBook? _readPrefs() {
    final v2 = _prefs?.getString(_kDailyRatesKey);
    if (v2 != null && v2.isNotEmpty) {
      try {
        return CurrencyBook.fromJson(jsonDecode(v2) as Map<String, dynamic>);
      } catch (_) {
        // Fall through to v1.
      }
    }
    final v1 = _prefs?.getString(_kDailyRatesKeyV1);
    if (v1 == null || v1.isEmpty) return null;
    try {
      return CurrencyBook(
        latest: CurrencyRates.fromJson(jsonDecode(v1) as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePrefs(CurrencyBook book) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_kDailyRatesKey, jsonEncode(book.toJson()));
  }

  static DateTime? _parseIsoDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime.utc(year, month, day);
  }

  static String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static bool _isSameLocalDay(DateTime a, DateTime b) {
    final left = a.toLocal();
    final right = b.toLocal();
    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  static Future<String> _httpGet(Uri uri) async {
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Rates unavailable (${response.statusCode})');
    }
    return response.body;
  }
}
