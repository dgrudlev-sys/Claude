import 'catalog/data_units.dart';
import 'catalog/matter_units.dart';
import 'catalog/motion_units.dart';
import 'catalog/space_units.dart';
import 'unit.dart';

/// Every unit the app knows, and how to find one from what a user typed
/// or said.
///
/// Lookup is deliberately layered rather than one big case-insensitive
/// map, because unit symbols are case-sensitive by definition and
/// flattening them loses real information: mW and MW differ by a factor
/// of a billion, and b and B differ by a factor of eight. So an exact
/// symbol match is tried before any case-insensitive matching, and the
/// looser matching only ever sees the spelled-out names and aliases.
class UnitCatalog {
  const UnitCatalog._();

  static const all = <Unit>[
    ...lengthUnits,
    ...areaUnits,
    ...volumeUnits,
    ...massUnits,
    ...forceUnits,
    ...pressureUnits,
    ...energyUnits,
    ...powerUnits,
    ...temperatureUnits,
    ...timeUnits,
    ...speedUnits,
    ...angleUnits,
    ...frequencyUnits,
    ...digitalStorageUnits,
    ...dataRateUnits,
  ];

  static List<Unit> inCategory(UnitCategory category) =>
      all.where((u) => u.category == category).toList(growable: false);

  /// The base unit of a category — the one everything else is defined
  /// against, and the one conversions pass through.
  static Unit baseOf(UnitCategory category) =>
      inCategory(category).firstWhere((u) => u.toBase == '1' && u.offsetToBase == '0');

  static final Map<String, Unit> _byId = {for (final u in all) u.id: u};

  static final Map<String, List<Unit>> _bySymbol = () {
    final map = <String, List<Unit>>{};
    for (final unit in all) {
      map.putIfAbsent(unit.symbol, () => []).add(unit);
    }
    return map;
  }();

  static final Map<String, List<Unit>> _byLooseKey = () {
    final map = <String, List<Unit>>{};
    for (final unit in all) {
      for (final key in [unit.name, unit.id, ...unit.aliases]) {
        map.putIfAbsent(_normalize(key), () => []).add(unit);
      }
    }
    return map;
  }();

  /// Lowercases and collapses the punctuation people vary on, so
  /// "Square Feet", "square-feet" and "square  feet" all agree.
  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Unit? byId(String id) => _byId[id];

  /// Finds the unit a piece of text names, or null.
  ///
  /// [category] narrows the search, which is how the converter screen
  /// resolves "pt" to a pint rather than to a typographic point.
  ///
  /// [preferSystem] breaks the remaining tie between units that several
  /// measurement systems name the same way. "Pint" is a US pint and an
  /// imperial pint, 20% apart, and only the context says which is meant
  /// — so converting *from* an imperial gallon asks for imperial pints.
  /// With no preference, catalog order decides.
  static Unit? find(
    String text, {
    UnitCategory? category,
    UnitSystem? preferSystem,
  }) {
    bool matches(Unit u) => category == null || u.category == category;

    Unit? best(List<Unit>? candidates) {
      if (candidates == null) return null;
      final viable = candidates.where(matches).toList();
      if (viable.isEmpty) return null;
      if (preferSystem != null) {
        for (final unit in viable) {
          if (unit.system == preferSystem) return unit;
        }
      }
      return viable.first;
    }

    // Exact symbol first: SI symbols are case-sensitive, and mW and MW
    // are a billion apart.
    final bySymbol = best(_bySymbol[text.trim()]);
    if (bySymbol != null) return bySymbol;

    final normalized = _normalize(text);
    final byName = best(_byLooseKey[normalized]);
    if (byName != null) return byName;

    // A symbol typed in the wrong case is still worth resolving, but only
    // once everything unambiguous has been tried.
    return best(
      all.where((u) => _normalize(u.symbol) == normalized).toList(),
    );
  }

  /// Every unit whose name, symbol or aliases contain [query] — for the
  /// unit picker's search field.
  static List<Unit> search(String query, {UnitCategory? category}) {
    final needle = _normalize(query);
    if (needle.isEmpty) {
      return category == null ? all : inCategory(category);
    }
    return all
        .where((u) => category == null || u.category == category)
        .where((u) => [u.name, u.symbol, ...u.aliases]
            .any((key) => _normalize(key).contains(needle)))
        .toList(growable: false);
  }

  /// A curated cross-category list for a cooking screen.
  ///
  /// Cooking measures are not a separate kind of quantity — a cup is a
  /// volume like any other — so they live in their own categories and
  /// this is only a shortlist of what a recipe actually uses.
  static final List<Unit> cookingUnits = [
    for (final id in const [
      'millilitre',
      'litre',
      'teaspoon_us',
      'teaspoon_metric',
      'tablespoon_us',
      'tablespoon_metric',
      'tablespoon_australian',
      'cup_us_customary',
      'cup_us_legal',
      'cup_metric',
      'fluid_ounce_us',
      'fluid_ounce_imperial',
      'pint_us',
      'pint_imperial',
      'quart_us',
      'gallon_us',
      'gram',
      'kilogram',
      'ounce',
      'pound',
      'celsius',
      'fahrenheit',
    ])
      _byId[id]!,
  ];
}
