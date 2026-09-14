import 'package:flutter/material.dart';

// Unit conversion and tip math. Factors are standard SI (or US customary
// where named as such). Temperature is affine, not a simple scale.
// Flour uses an approximate all-purpose density (King Arthur: 1 cup = 120 g).

enum ConvertCategory {
  currency('Money', 'Change one currency into another. The table updates about once a day.', Icons.payments_outlined),
  cooking('Cooking', 'Teaspoons, tablespoons, cups, millilitres, and flour by weight.', Icons.restaurant_outlined),
  area('Area', 'Change one area into another.', Icons.square_foot_outlined),
  length('Length', 'Change one length into another.', Icons.straighten),
  temperature('Temperature', 'Change Celsius, Fahrenheit, or Kelvin.', Icons.thermostat),
  volume('Volume', 'Change one volume into another.', Icons.water_drop_outlined),
  mass('Mass', 'Change one mass into another.', Icons.scale_outlined),
  data('Data', 'Change computer storage sizes.', Icons.sd_storage_outlined),
  speed('Speed', 'Change one speed into another.', Icons.speed),
  time('Time', 'Change one time into another.', Icons.schedule),
  tip('Tip', 'Figure out a tip and split a bill.', Icons.volunteer_activism_outlined);

  const ConvertCategory(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;
}

class ConvertUnit {
  const ConvertUnit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.toBase,
  });

  final String id;
  final String name;
  final String symbol;

  /// Multiply a value in this unit by [toBase] to get the category's base unit.
  final double toBase;

  String get menuLabel => '$name ($symbol)';
}

class TipResult {
  const TipResult({
    required this.tipAmount,
    required this.total,
    this.perPerson,
  });

  final double tipAmount;
  final double total;
  final double? perPerson;
}

class ConvertEngine {
  ConvertEngine._();

  static List<ConvertUnit> unitsFor(ConvertCategory category) {
    return switch (category) {
      ConvertCategory.currency => const [],
      ConvertCategory.cooking => _cooking,
      ConvertCategory.area => _area,
      ConvertCategory.length => _length,
      ConvertCategory.temperature => _temperature,
      ConvertCategory.volume => _volume,
      ConvertCategory.mass => _mass,
      ConvertCategory.data => _data,
      ConvertCategory.speed => _speed,
      ConvertCategory.time => _time,
      ConvertCategory.tip => const [],
    };
  }

  static double convert({
    required ConvertCategory category,
    required String fromId,
    required String toId,
    required double value,
  }) {
    if (category == ConvertCategory.temperature) {
      return _convertTemperature(fromId, toId, value);
    }
    if (category == ConvertCategory.currency) {
      throw StateError('Use CurrencyService for money');
    }
    final units = unitsFor(category);
    final from = units.firstWhere((u) => u.id == fromId);
    final to = units.firstWhere((u) => u.id == toId);
    return value * from.toBase / to.toBase;
  }

  /// All-purpose flour, approximate. Base unit is grams.
  /// 1 US cup ≈ 120 g (King Arthur Baking).
  static const flourUnits = [
    ConvertUnit(id: 'g', name: 'Gram', symbol: 'g', toBase: 1),
    ConvertUnit(id: 'kg', name: 'Kilogram', symbol: 'kg', toBase: 1000),
    ConvertUnit(id: 'oz', name: 'Ounce', symbol: 'oz', toBase: 28.349523125),
    ConvertUnit(id: 'lb', name: 'Pound', symbol: 'lb', toBase: 453.59237),
    ConvertUnit(id: 'cup', name: 'Cup', symbol: 'cup', toBase: 120),
    ConvertUnit(id: 'tbsp', name: 'Tablespoon', symbol: 'tbsp', toBase: 7.5),
    ConvertUnit(id: 'tsp', name: 'Teaspoon', symbol: 'tsp', toBase: 2.5),
  ];

  static double convertFlour({
    required String fromId,
    required String toId,
    required double value,
  }) {
    final from = flourUnits.firstWhere((u) => u.id == fromId);
    final to = flourUnits.firstWhere((u) => u.id == toId);
    return value * from.toBase / to.toBase;
  }

  static double flourToGrams(String unitId, double value) {
    final from = flourUnits.firstWhere((u) => u.id == unitId);
    return value * from.toBase;
  }

  static String flourMassSummary(double grams) {
    final kg = grams / 1000;
    final oz = grams / 28.349523125;
    final lb = grams / 453.59237;
    String n(double v) {
      if ((v - v.roundToDouble()).abs() < 1e-9 && v.abs() < 1e6) {
        return v.round().toString();
      }
      var text = v.abs() >= 100 ? v.toStringAsFixed(1) : v.toStringAsFixed(3);
      text = text.replaceFirst(RegExp(r'0+$'), '');
      return text.replaceFirst(RegExp(r'\.$'), '');
    }

    return 'That is about ${n(grams)} grams (${n(kg)} kilograms), or ${n(oz)} ounces (${n(lb)} pounds). These are approximate.';
  }

  static TipResult tip({
    required double bill,
    required double tipPercent,
    int people = 1,
  }) {
    final tipAmount = bill * tipPercent / 100;
    final total = bill + tipAmount;
    return TipResult(
      tipAmount: tipAmount,
      total: total,
      perPerson: people > 1 ? total / people : null,
    );
  }

  static double _convertTemperature(String fromId, String toId, double value) {
    final celsius = switch (fromId) {
      'c' => value,
      'f' => (value - 32) * 5 / 9,
      'k' => value - 273.15,
      _ => throw ArgumentError('Unknown temperature unit $fromId'),
    };
    return switch (toId) {
      'c' => celsius,
      'f' => celsius * 9 / 5 + 32,
      'k' => celsius + 273.15,
      _ => throw ArgumentError('Unknown temperature unit $toId'),
    };
  }

  // Cooking measures (US). Base: millilitre.
  static const _cooking = [
    ConvertUnit(id: 'ml', name: 'Millilitre', symbol: 'mL', toBase: 1),
    ConvertUnit(id: 'tsp', name: 'Teaspoon', symbol: 'tsp', toBase: 4.92892159375),
    ConvertUnit(id: 'tbsp', name: 'Tablespoon', symbol: 'tbsp', toBase: 14.78676478125),
    ConvertUnit(id: 'cup', name: 'Cup', symbol: 'cup', toBase: 236.5882365),
    ConvertUnit(id: 'floz', name: 'Fluid ounce', symbol: 'fl oz', toBase: 29.5735295625),
    ConvertUnit(id: 'l', name: 'Litre', symbol: 'L', toBase: 1000),
    ConvertUnit(id: 'pint', name: 'US pint', symbol: 'pt', toBase: 473.176473),
  ];

  // Base: square meter
  static const _area = [
    ConvertUnit(id: 'm2', name: 'Square meter', symbol: 'm²', toBase: 1),
    ConvertUnit(id: 'km2', name: 'Square kilometer', symbol: 'km²', toBase: 1e6),
    ConvertUnit(id: 'cm2', name: 'Square centimeter', symbol: 'cm²', toBase: 1e-4),
    ConvertUnit(id: 'mm2', name: 'Square millimeter', symbol: 'mm²', toBase: 1e-6),
    ConvertUnit(id: 'ha', name: 'Hectare', symbol: 'ha', toBase: 1e4),
    ConvertUnit(id: 'acre', name: 'Acre', symbol: 'ac', toBase: 4046.8564224),
    ConvertUnit(id: 'ft2', name: 'Square foot', symbol: 'ft²', toBase: 0.09290304),
    ConvertUnit(id: 'in2', name: 'Square inch', symbol: 'in²', toBase: 0.00064516),
    ConvertUnit(id: 'yd2', name: 'Square yard', symbol: 'yd²', toBase: 0.83612736),
  ];

  // Base: meter
  static const _length = [
    ConvertUnit(id: 'm', name: 'Meter', symbol: 'm', toBase: 1),
    ConvertUnit(id: 'km', name: 'Kilometer', symbol: 'km', toBase: 1000),
    ConvertUnit(id: 'cm', name: 'Centimeter', symbol: 'cm', toBase: 0.01),
    ConvertUnit(id: 'mm', name: 'Millimeter', symbol: 'mm', toBase: 0.001),
    ConvertUnit(id: 'mi', name: 'Mile', symbol: 'mi', toBase: 1609.344),
    ConvertUnit(id: 'yd', name: 'Yard', symbol: 'yd', toBase: 0.9144),
    ConvertUnit(id: 'ft', name: 'Foot', symbol: 'ft', toBase: 0.3048),
    ConvertUnit(id: 'in', name: 'Inch', symbol: 'in', toBase: 0.0254),
    ConvertUnit(id: 'nmi', name: 'Nautical mile', symbol: 'nmi', toBase: 1852),
  ];

  static const _temperature = [
    ConvertUnit(id: 'c', name: 'Celsius', symbol: '°C', toBase: 1),
    ConvertUnit(id: 'f', name: 'Fahrenheit', symbol: '°F', toBase: 1),
    ConvertUnit(id: 'k', name: 'Kelvin', symbol: 'K', toBase: 1),
  ];

  // Base: cubic meter
  static const _volume = [
    ConvertUnit(id: 'm3', name: 'Cubic meter', symbol: 'm³', toBase: 1),
    ConvertUnit(id: 'l', name: 'Liter', symbol: 'L', toBase: 0.001),
    ConvertUnit(id: 'ml', name: 'Milliliter', symbol: 'mL', toBase: 1e-6),
    ConvertUnit(id: 'gal', name: 'US gallon', symbol: 'gal', toBase: 0.003785411784),
    ConvertUnit(id: 'qt', name: 'US quart', symbol: 'qt', toBase: 0.000946352946),
    ConvertUnit(id: 'pt', name: 'US pint', symbol: 'pt', toBase: 0.000473176473),
    ConvertUnit(id: 'cup', name: 'US cup', symbol: 'cup', toBase: 0.0002365882365),
    ConvertUnit(id: 'floz', name: 'US fluid ounce', symbol: 'fl oz', toBase: 2.95735295625e-5),
    ConvertUnit(id: 'igal', name: 'Imperial gallon', symbol: 'imp gal', toBase: 0.00454609),
  ];

  // Base: kilogram
  static const _mass = [
    ConvertUnit(id: 'kg', name: 'Kilogram', symbol: 'kg', toBase: 1),
    ConvertUnit(id: 'g', name: 'Gram', symbol: 'g', toBase: 0.001),
    ConvertUnit(id: 'mg', name: 'Milligram', symbol: 'mg', toBase: 1e-6),
    ConvertUnit(id: 'lb', name: 'Pound', symbol: 'lb', toBase: 0.45359237),
    ConvertUnit(id: 'oz', name: 'Ounce', symbol: 'oz', toBase: 0.028349523125),
    ConvertUnit(id: 't', name: 'Metric ton', symbol: 't', toBase: 1000),
  ];

  // Base: byte (decimal SI prefixes; kibibyte family uses 1024)
  static const _data = [
    ConvertUnit(id: 'B', name: 'Byte', symbol: 'B', toBase: 1),
    ConvertUnit(id: 'kB', name: 'Kilobyte', symbol: 'kB', toBase: 1000),
    ConvertUnit(id: 'MB', name: 'Megabyte', symbol: 'MB', toBase: 1e6),
    ConvertUnit(id: 'GB', name: 'Gigabyte', symbol: 'GB', toBase: 1e9),
    ConvertUnit(id: 'TB', name: 'Terabyte', symbol: 'TB', toBase: 1e12),
    ConvertUnit(id: 'KiB', name: 'Kibibyte', symbol: 'KiB', toBase: 1024),
    ConvertUnit(id: 'MiB', name: 'Mebibyte', symbol: 'MiB', toBase: 1024 * 1024),
    ConvertUnit(id: 'GiB', name: 'Gibibyte', symbol: 'GiB', toBase: 1024 * 1024 * 1024),
  ];

  // Base: meters per second
  static const _speed = [
    ConvertUnit(id: 'mps', name: 'Meters per second', symbol: 'm/s', toBase: 1),
    ConvertUnit(id: 'kmh', name: 'Kilometers per hour', symbol: 'km/h', toBase: 1 / 3.6),
    ConvertUnit(id: 'mph', name: 'Miles per hour', symbol: 'mph', toBase: 0.44704),
    ConvertUnit(id: 'fps', name: 'Feet per second', symbol: 'ft/s', toBase: 0.3048),
    ConvertUnit(id: 'kn', name: 'Knot', symbol: 'kn', toBase: 0.514444),
  ];

  // Base: second
  static const _time = [
    ConvertUnit(id: 'ms', name: 'Millisecond', symbol: 'ms', toBase: 0.001),
    ConvertUnit(id: 's', name: 'Second', symbol: 's', toBase: 1),
    ConvertUnit(id: 'min', name: 'Minute', symbol: 'min', toBase: 60),
    ConvertUnit(id: 'h', name: 'Hour', symbol: 'h', toBase: 3600),
    ConvertUnit(id: 'd', name: 'Day', symbol: 'd', toBase: 86400),
    ConvertUnit(id: 'wk', name: 'Week', symbol: 'wk', toBase: 604800),
  ];
}
