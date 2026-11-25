/// Catalog of UI languages. Search matches English names, native names, and
/// aliases (including other-language names such as Bulgarian "руски" for
/// Russian) in one list.
///
/// Keypad research (TI-84 language packs, Casio ClassWiz EU, ISO 80000):
/// - Trig glyphs (sin, cos, tan, log, ln) stay Latin on TI and Casio worldwide.
///   Menus and messages localize; the physical key letters do not become
///   кириллица or 正弦.
/// - Decimal separator *does* change on European school calculators (comma)
///   and argument lists then use semicolon. US/UK/TI-84 OS keep a period.
/// - Variable x is Latin even in Russian/Bulgarian textbooks' calculator apps.
/// - French TI packs: "2nde" instead of "2nd"; Window → Fenêtre, Trace → Trace.
/// We overlay decimal/argument separators and localized chrome (C, 2nd,
/// mode titles) without copying TI navy/silver trade dress.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
    required this.decimalSeparator,
    this.argumentSeparator = ',',
    this.secondKey = '2nd',
    this.allClear = 'C',
    this.rtl = false,
    this.searchAliases = const [],
  });

  final String code;
  final String englishName;
  final String nativeName;
  final String flag;

  /// `.` (US/UK/TI-84) or `,` (most of continental Europe).
  final String decimalSeparator;
  final String argumentSeparator;
  final String secondKey;
  final String allClear;
  final bool rtl;
  final List<String> searchAliases;

  bool get usesCommaDecimal => decimalSeparator == ',';

  /// "Bulgarian · Български"
  String get listLabel => '$englishName · $nativeName';

  String get semanticLabel => '$englishName, $nativeName';

  /// Title-case English + native for the picker row.
  String get titleLine => listLabel;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (englishName.toLowerCase().contains(q)) return true;
    if (nativeName.toLowerCase().contains(q)) return true;
    if (code.toLowerCase().contains(q)) return true;
    for (final alias in searchAliases) {
      if (alias.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  static AppLanguage byCode(String? code) {
    for (final lang in supported) {
      if (lang.code == code) return lang;
    }
    return english;
  }

  static const english = AppLanguage(
    code: 'en',
    englishName: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
    decimalSeparator: '.',
    searchAliases: ['english', 'uk', 'us', 'american', 'british'],
  );

  static const supported = <AppLanguage>[
    english,
    AppLanguage(
      code: 'es',
      englishName: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['spanish', 'español', 'espanol', 'castellano'],
    ),
    AppLanguage(
      code: 'fr',
      englishName: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      decimalSeparator: ',',
      argumentSeparator: ';',
      secondKey: '2nde',
      searchAliases: ['french', 'français', 'francais'],
    ),
    AppLanguage(
      code: 'de',
      englishName: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['german', 'deutsch'],
    ),
    AppLanguage(
      code: 'pt',
      englishName: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['portuguese', 'português', 'portugues', 'brasil', 'brazilian'],
    ),
    AppLanguage(
      code: 'it',
      englishName: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['italian', 'italiano'],
    ),
    AppLanguage(
      code: 'nl',
      englishName: 'Dutch',
      nativeName: 'Nederlands',
      flag: '🇳🇱',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['dutch', 'nederlands', 'flemish', 'hollands'],
    ),
    AppLanguage(
      code: 'da',
      englishName: 'Danish',
      nativeName: 'Dansk',
      flag: '🇩🇰',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['danish', 'dansk'],
    ),
    AppLanguage(
      code: 'sv',
      englishName: 'Swedish',
      nativeName: 'Svenska',
      flag: '🇸🇪',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['swedish', 'svenska'],
    ),
    AppLanguage(
      code: 'nb',
      englishName: 'Norwegian',
      nativeName: 'Norsk',
      flag: '🇳🇴',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['norwegian', 'norsk', 'bokmål', 'bokmal'],
    ),
    AppLanguage(
      code: 'fi',
      englishName: 'Finnish',
      nativeName: 'Suomi',
      flag: '🇫🇮',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['finnish', 'suomi', 'suomen'],
    ),
    AppLanguage(
      code: 'pl',
      englishName: 'Polish',
      nativeName: 'Polski',
      flag: '🇵🇱',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['polish', 'polski'],
    ),
    AppLanguage(
      code: 'cs',
      englishName: 'Czech',
      nativeName: 'Čeština',
      flag: '🇨🇿',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['czech', 'čeština', 'cestina'],
    ),
    AppLanguage(
      code: 'sk',
      englishName: 'Slovak',
      nativeName: 'Slovenčina',
      flag: '🇸🇰',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['slovak', 'slovenčina', 'slovencina'],
    ),
    AppLanguage(
      code: 'hu',
      englishName: 'Hungarian',
      nativeName: 'Magyar',
      flag: '🇭🇺',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['hungarian', 'magyar'],
    ),
    AppLanguage(
      code: 'ro',
      englishName: 'Romanian',
      nativeName: 'Română',
      flag: '🇷🇴',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['romanian', 'română', 'romana'],
    ),
    AppLanguage(
      code: 'bg',
      englishName: 'Bulgarian',
      nativeName: 'Български',
      flag: '🇧🇬',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['bulgarian', 'български', 'bulgarski', 'bulgarisch'],
    ),
    AppLanguage(
      code: 'ru',
      englishName: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: [
        'russian',
        'русский',
        'руски', // Bulgarian/Macedonian name for Russian
        'russkiy',
        'russki',
      ],
    ),
    AppLanguage(
      code: 'uk',
      englishName: 'Ukrainian',
      nativeName: 'Українська',
      flag: '🇺🇦',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['ukrainian', 'українська', 'ukrainska'],
    ),
    AppLanguage(
      code: 'el',
      englishName: 'Greek',
      nativeName: 'Ελληνικά',
      flag: '🇬🇷',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['greek', 'ελληνικά', 'ellinika'],
    ),
    AppLanguage(
      code: 'tr',
      englishName: 'Turkish',
      nativeName: 'Türkçe',
      flag: '🇹🇷',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['turkish', 'türkçe', 'turkce'],
    ),
    AppLanguage(
      code: 'ar',
      englishName: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      decimalSeparator: '.',
      rtl: true,
      searchAliases: ['arabic', 'العربية', 'arabi'],
    ),
    AppLanguage(
      code: 'he',
      englishName: 'Hebrew',
      nativeName: 'עברית',
      flag: '🇮🇱',
      decimalSeparator: '.',
      rtl: true,
      searchAliases: ['hebrew', 'עברית', 'ivrit'],
    ),
    AppLanguage(
      code: 'zh',
      englishName: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
      decimalSeparator: '.',
      searchAliases: ['chinese', '中文', 'mandarin', '汉语', '漢語'],
    ),
    AppLanguage(
      code: 'ja',
      englishName: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
      decimalSeparator: '.',
      searchAliases: ['japanese', '日本語', 'nihongo'],
    ),
    AppLanguage(
      code: 'ko',
      englishName: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
      decimalSeparator: '.',
      searchAliases: ['korean', '한국어', 'hangul', 'hangugeo'],
    ),
    AppLanguage(
      code: 'hi',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
      decimalSeparator: '.',
      searchAliases: ['hindi', 'हिन्दी', 'हिंदी'],
    ),
    AppLanguage(
      code: 'vi',
      englishName: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flag: '🇻🇳',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['vietnamese', 'tiếng việt', 'tieng viet'],
    ),
    AppLanguage(
      code: 'id',
      englishName: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      flag: '🇮🇩',
      decimalSeparator: ',',
      argumentSeparator: ';',
      searchAliases: ['indonesian', 'bahasa', 'indonesia'],
    ),
    AppLanguage(
      code: 'th',
      englishName: 'Thai',
      nativeName: 'ไทย',
      flag: '🇹🇭',
      decimalSeparator: '.',
      searchAliases: ['thai', 'ไทย'],
    ),
  ];
}

/// Formats an engine-form expression (period decimals, comma args) for display.
String formatForLocale(String expression, AppLanguage language) {
  if (!language.usesCommaDecimal) return expression;
  final protected = expression.replaceAllMapped(
    RegExp(r'(\d)\.(\d)'),
    (m) => '${m[1]}\uE000${m[2]}',
  );
  return protected.replaceAll(',', language.argumentSeparator).replaceAll('\uE000', language.decimalSeparator);
}
