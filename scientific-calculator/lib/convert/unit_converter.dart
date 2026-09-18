import '../engine/number/number.dart';
import 'unit.dart';
import 'unit_catalog.dart';

class ConversionError implements Exception {
  const ConversionError(this.message);

  final String message;

  @override
  String toString() => message;
}

class ConversionResult {
  const ConversionResult({
    required this.value,
    required this.from,
    required this.to,
    this.warning,
  });

  final NumberValue value;
  final Unit from;
  final Unit to;

  /// Something true but surprising about this particular conversion —
  /// a temperature below absolute zero, for instance. Not an error: the
  /// arithmetic is fine, the physics is not.
  final String? warning;

  /// The notes attached to either unit, which the UI shows alongside the
  /// result. This is where "a US cup is not a metric cup" surfaces.
  List<String> get notes => [
        if (from.note != null) from.note!,
        if (to.note != null) to.note!,
      ];

  bool get isExact => value.isExact;
}

/// Converts between units of the same category.
///
/// Conversion goes through the category's base unit in both directions,
/// which keeps the catalog to one number per unit instead of a table of
/// every pair. The arithmetic runs on the calculator's own numeric tower
/// rather than on doubles, so conversions between units that are defined
/// exactly in terms of each other come out exactly: a mile is 5280 feet,
/// not 5279.999999999999, and 100 °C is 212 °F, not 211.99999999999997.
class UnitConverter {
  const UnitConverter();

  ConversionResult convert(NumberValue value, Unit from, Unit to) {
    if (from.category != to.category) {
      throw ConversionError(
        'Cannot convert ${from.name.toLowerCase()} to '
        '${to.name.toLowerCase()}: one measures '
        '${from.category.displayName.toLowerCase()} and the other measures '
        '${to.category.displayName.toLowerCase()}.',
      );
    }

    // base = value × factor + offset, and back the other way.
    final base = value.multiply(from.factorValue).add(from.offsetValue);
    final converted = base.subtract(to.offsetValue).divide(to.factorValue);

    return ConversionResult(
      value: converted,
      from: from,
      to: to,
      warning: _warningFor(from.category, base),
    );
  }

  /// Convenience for text and voice input: "25 km to miles".
  ConversionResult convertNamed(NumberValue value, String from, String to) {
    final fromUnit = UnitCatalog.find(from);
    if (fromUnit == null) throw ConversionError('Unknown unit "$from"');
    // Resolving the target within the source's category *and* system is
    // what makes "1 imperial gallon in pints" give 8 imperial pints
    // rather than 9.6 US ones.
    final toUnit = UnitCatalog.find(
          to,
          category: fromUnit.category,
          preferSystem: fromUnit.system,
        ) ??
        UnitCatalog.find(to);
    if (toUnit == null) throw ConversionError('Unknown unit "$to"');
    return convert(value, fromUnit, toUnit);
  }

  /// The same quantity expressed in every unit of its category — what the
  /// converter screen shows as a list, so a user sees the whole picture
  /// rather than one pairing at a time.
  List<ConversionResult> convertToAll(NumberValue value, Unit from) => [
        for (final unit in UnitCatalog.inCategory(from.category))
          if (unit.id != from.id) convert(value, from, unit),
      ];

  String? _warningFor(UnitCategory category, NumberValue base) {
    if (category != UnitCategory.temperature) return null;
    if (base.toDouble() >= 0) return null;
    return 'That is below absolute zero, which nothing can reach.';
  }
}
