import '../engine/number/number.dart';
import '../expression/evaluator.dart';
import '../expression/parse/expression_parser.dart';

/// The kinds of quantity that can be converted.
///
/// Conversion only ever happens within one category — that is the whole
/// safety property of this design. Asking for kilograms in metres is a
/// question with no answer, and the converter says so instead of
/// returning a number.
enum UnitCategory {
  length,
  mass,
  area,
  volume,
  temperature,
  time,
  speed,
  digitalStorage,
  dataRate,
  pressure,
  energy,
  power,
  angle,
  frequency,
  force,
}

extension UnitCategoryDisplay on UnitCategory {
  String get displayName => switch (this) {
        UnitCategory.length => 'Length',
        UnitCategory.mass => 'Mass',
        UnitCategory.area => 'Area',
        UnitCategory.volume => 'Volume',
        UnitCategory.temperature => 'Temperature',
        UnitCategory.time => 'Time',
        UnitCategory.speed => 'Speed',
        UnitCategory.digitalStorage => 'Data',
        UnitCategory.dataRate => 'Data rate',
        UnitCategory.pressure => 'Pressure',
        UnitCategory.energy => 'Energy',
        UnitCategory.power => 'Power',
        UnitCategory.angle => 'Angle',
        UnitCategory.frequency => 'Frequency',
        UnitCategory.force => 'Force',
      };
}

/// Which measurement system a unit belongs to.
///
/// This exists because the category alone is not enough to resolve a
/// name. "One imperial gallon in pints" must give imperial pints — the
/// answer 8, not 9.6 — and both pints are volumes, so only the system
/// tells them apart. Units shared across systems, like the inch and the
/// pound since 1959, are [none].
enum UnitSystem { none, metric, us, imperial, australian }

/// One unit, defined by how it relates to its category's base unit.
///
/// The relationship is affine rather than merely proportional, because
/// temperature is: 0 °C is not 0 K. Everything else leaves [offsetToBase]
/// at zero and the affine form collapses to a plain multiplication.
///
///     base = value × factor + offset
///
/// [toBase] and [offsetToBase] are written as *expressions*, not as
/// pre-multiplied decimals, and are evaluated by the same engine the
/// calculator uses. Two reasons:
///
///  1. The table then reads like the definition it is encoding. A US
///     gallon is defined as 231 cubic inches, so it is written
///     `'231 * 0.0254^3'` — which anyone can check against the standard —
///     rather than as the opaque literal 0.003785411784.
///  2. The arithmetic stays *exact*. Those factors are exact rationals,
///     so 1 mile converts to exactly 5280 feet rather than to
///     5279.999999999999. Units whose definition genuinely involves π,
///     like the degree or the parsec, come out approximate — which is
///     honest, because they are.
class Unit {
  const Unit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.category,
    required this.toBase,
    this.offsetToBase = '0',
    this.system = UnitSystem.none,
    this.aliases = const [],
    this.note,
  });

  /// Stable identifier, e.g. `'foot'`. Used in saved history, so it must
  /// not change once shipped.
  final String id;

  final String name;
  final String symbol;
  final UnitCategory category;

  /// How many base units one of this unit is, as an expression.
  final String toBase;

  /// What to add after scaling, as an expression. Non-zero only for
  /// temperature scales, whose zero points differ.
  final String offsetToBase;

  /// The measurement system this unit belongs to, used to resolve a name
  /// that several systems share.
  final UnitSystem system;

  /// Other spellings and symbols people type or say, all lowercase.
  ///
  /// Units from different systems may share an alias — "pint" names both
  /// the US and the imperial pint — and [system] is what picks between
  /// them. Two units in the same category *and* the same system must
  /// never share one.
  final List<String> aliases;

  /// Shown in the UI where a unit is commonly misunderstood — the US cup
  /// having two different legal definitions, for instance. Silence about
  /// this would produce confidently wrong recipes.
  final String? note;

  NumberValue get factorValue => _valueOf(toBase);
  NumberValue get offsetValue => _valueOf(offsetToBase);

  /// Parsed factors are cached because the tables are constant: the same
  /// handful of expressions would otherwise be re-parsed on every
  /// keystroke of a live conversion.
  static final Map<String, NumberValue> _cache = {};

  static NumberValue _valueOf(String expression) =>
      _cache[expression] ??= const Evaluator()
          .evaluate(const ExpressionParser().parse(expression));

  @override
  String toString() => '$name ($symbol)';
}
