/// Currencies, as data.
///
/// Unlike every other unit in this app, a currency has no fixed
/// conversion factor. A metre will always be 100 centimetres; a euro is
/// worth whatever it is worth this morning. So currencies live apart
/// from [UnitCatalog] rather than pretending to be units, and everything
/// downstream has to carry a date.
library;

class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalDigits = 2,
  });

  /// ISO 4217 code, e.g. `'EUR'`.
  final String code;

  final String name;
  final String symbol;

  /// How many decimal places this currency's minor unit has. Most have
  /// two, the yen has none, and the dinars have three — so rounding a
  /// result needs to ask rather than assume cents.
  final int decimalDigits;

  @override
  String toString() => '$code ($symbol)';
}

/// The currencies the app offers by name.
///
/// This list says nothing about whether a rate is available for any of
/// them — that depends entirely on what the rate source last returned,
/// and is a separate question the converter answers honestly.
const currencies = <Currency>[
  Currency(code: 'USD', name: 'US dollar', symbol: r'$'),
  Currency(code: 'EUR', name: 'Euro', symbol: '€'),
  Currency(code: 'GBP', name: 'Pound sterling', symbol: '£'),
  Currency(code: 'JPY', name: 'Japanese yen', symbol: '¥', decimalDigits: 0),
  Currency(code: 'CHF', name: 'Swiss franc', symbol: 'CHF'),
  Currency(code: 'CAD', name: 'Canadian dollar', symbol: r'C$'),
  Currency(code: 'AUD', name: 'Australian dollar', symbol: r'A$'),
  Currency(code: 'NZD', name: 'New Zealand dollar', symbol: r'NZ$'),
  Currency(code: 'CNY', name: 'Chinese yuan', symbol: '¥'),
  Currency(code: 'HKD', name: 'Hong Kong dollar', symbol: r'HK$'),
  Currency(code: 'SGD', name: 'Singapore dollar', symbol: r'S$'),
  Currency(code: 'INR', name: 'Indian rupee', symbol: '₹'),
  Currency(code: 'KRW', name: 'South Korean won', symbol: '₩', decimalDigits: 0),
  Currency(code: 'SEK', name: 'Swedish krona', symbol: 'kr'),
  Currency(code: 'NOK', name: 'Norwegian krone', symbol: 'kr'),
  Currency(code: 'DKK', name: 'Danish krone', symbol: 'kr'),
  Currency(code: 'PLN', name: 'Polish złoty', symbol: 'zł'),
  Currency(code: 'CZK', name: 'Czech koruna', symbol: 'Kč'),
  Currency(code: 'HUF', name: 'Hungarian forint', symbol: 'Ft'),
  Currency(code: 'RON', name: 'Romanian leu', symbol: 'lei'),
  Currency(code: 'TRY', name: 'Turkish lira', symbol: '₺'),
  Currency(code: 'RUB', name: 'Russian rouble', symbol: '₽'),
  Currency(code: 'UAH', name: 'Ukrainian hryvnia', symbol: '₴'),
  Currency(code: 'BRL', name: 'Brazilian real', symbol: r'R$'),
  Currency(code: 'MXN', name: 'Mexican peso', symbol: r'$'),
  Currency(code: 'ARS', name: 'Argentine peso', symbol: r'$'),
  Currency(code: 'CLP', name: 'Chilean peso', symbol: r'$', decimalDigits: 0),
  Currency(code: 'COP', name: 'Colombian peso', symbol: r'$'),
  Currency(code: 'ZAR', name: 'South African rand', symbol: 'R'),
  Currency(code: 'NGN', name: 'Nigerian naira', symbol: '₦'),
  Currency(code: 'EGP', name: 'Egyptian pound', symbol: 'E£'),
  Currency(code: 'KES', name: 'Kenyan shilling', symbol: 'KSh'),
  Currency(code: 'MAD', name: 'Moroccan dirham', symbol: 'DH'),
  Currency(code: 'AED', name: 'UAE dirham', symbol: 'د.إ'),
  Currency(code: 'SAR', name: 'Saudi riyal', symbol: '﷼'),
  Currency(code: 'QAR', name: 'Qatari riyal', symbol: '﷼'),
  Currency(code: 'ILS', name: 'Israeli new shekel', symbol: '₪'),
  Currency(code: 'KWD', name: 'Kuwaiti dinar', symbol: 'KD', decimalDigits: 3),
  Currency(code: 'BHD', name: 'Bahraini dinar', symbol: 'BD', decimalDigits: 3),
  Currency(code: 'JOD', name: 'Jordanian dinar', symbol: 'JD', decimalDigits: 3),
  Currency(code: 'PKR', name: 'Pakistani rupee', symbol: '₨'),
  Currency(code: 'BDT', name: 'Bangladeshi taka', symbol: '৳'),
  Currency(code: 'LKR', name: 'Sri Lankan rupee', symbol: 'Rs'),
  Currency(code: 'THB', name: 'Thai baht', symbol: '฿'),
  Currency(code: 'VND', name: 'Vietnamese dong', symbol: '₫', decimalDigits: 0),
  Currency(code: 'IDR', name: 'Indonesian rupiah', symbol: 'Rp'),
  Currency(code: 'MYR', name: 'Malaysian ringgit', symbol: 'RM'),
  Currency(code: 'PHP', name: 'Philippine peso', symbol: '₱'),
  Currency(code: 'TWD', name: 'New Taiwan dollar', symbol: r'NT$'),
  Currency(code: 'ISK', name: 'Icelandic króna', symbol: 'kr', decimalDigits: 0),
];

final Map<String, Currency> currenciesByCode = {
  for (final c in currencies) c.code: c,
};

Currency? findCurrency(String text) {
  final key = text.trim().toUpperCase();
  final byCode = currenciesByCode[key];
  if (byCode != null) return byCode;
  final lower = text.trim().toLowerCase();
  for (final currency in currencies) {
    if (currency.name.toLowerCase() == lower) return currency;
  }
  return null;
}
