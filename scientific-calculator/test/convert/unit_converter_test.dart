import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/convert/unit.dart';
import 'package:scientific_calculator/convert/unit_catalog.dart';
import 'package:scientific_calculator/convert/unit_converter.dart';
import 'package:scientific_calculator/engine/number/number.dart';

void main() {
  const converter = UnitConverter();

  NumberValue convert(String amount, String from, String to) =>
      converter.convertNamed(NumberValue.parse(amount), from, to).value;

  double approx(String amount, String from, String to) =>
      convert(amount, from, to).toDouble();

  group('conversions between exactly-defined units stay exact', () {
    test('a mile is 5280 feet, not 5279.999999999999', () {
      final feet = convert('1', 'mile', 'foot');
      expect(feet, RationalValue.fromInt(5280));
      expect(feet.isExact, isTrue);
    });

    test('an acre is 43560 square feet', () {
      final result = convert('1', 'acre', 'square foot');
      expect(result, RationalValue.fromInt(43560));
      expect(result.isExact, isTrue);
    });

    test('a US gallon is 128 fluid ounces and 16 cups', () {
      expect(convert('1', 'gallon', 'fluid ounce'), RationalValue.fromInt(128));
      expect(convert('1', 'gallon', 'cup'), RationalValue.fromInt(16));
    });

    test('a pound is 16 ounces and 7000 grains', () {
      expect(convert('1', 'pound', 'ounce'), RationalValue.fromInt(16));
      expect(convert('1', 'pound', 'grain'), RationalValue.fromInt(7000));
    });

    test('a kilobyte is 1000 bytes and a kibibyte is 1024', () {
      expect(convert('1', 'kilobyte', 'byte'), RationalValue.fromInt(1000));
      expect(convert('1', 'kibibyte', 'byte'), RationalValue.fromInt(1024));
    });

    test('a day is 86400 seconds and a week is 7 days', () {
      expect(convert('1', 'day', 'second'), RationalValue.fromInt(86400));
      expect(convert('1', 'week', 'day'), RationalValue.fromInt(7));
    });

    test('exactness survives a chain through the base unit', () {
      // Inches → metres → yards. Both legs are exact rationals, so the
      // round trip lands back on exactly 1 rather than near it.
      expect(convert('36', 'inch', 'yard'), RationalValue.fromInt(1));
      expect(convert('1', 'yard', 'inch'), RationalValue.fromInt(36));
    });
  });

  group('temperature is affine, not proportional', () {
    test('the famous fixed points come out exactly', () {
      expect(convert('100', 'celsius', 'fahrenheit'), RationalValue.fromInt(212));
      expect(convert('0', 'celsius', 'fahrenheit'), RationalValue.fromInt(32));
      expect(convert('32', 'fahrenheit', 'celsius'), RationalValue.fromInt(0));
      // The one temperature that reads the same on both scales.
      expect(convert('-40', 'celsius', 'fahrenheit'), RationalValue.fromInt(-40));
    });

    test('absolute zero lines up on every scale', () {
      expect(convert('0', 'kelvin', 'celsius'),
          NumberValue.parse('-273.15'));
      expect(convert('0', 'kelvin', 'rankine'), RationalValue.fromInt(0));
      expect(approx('0', 'kelvin', 'fahrenheit'), closeTo(-459.67, 1e-9));
    });

    test('body temperature converts the way a thermometer does', () {
      expect(approx('37', 'celsius', 'fahrenheit'), closeTo(98.6, 1e-9));
    });

    test('a temperature below absolute zero is computed but flagged', () {
      final result = converter.convertNamed(
          NumberValue.parse('-500'), 'celsius', 'fahrenheit');
      expect(result.value.toDouble(), closeTo(-868, 1e-9));
      expect(result.warning, contains('absolute zero'));
    });

    test('an ordinary temperature carries no warning', () {
      final result = converter.convertNamed(
          NumberValue.parse('20'), 'celsius', 'fahrenheit');
      expect(result.warning, isNull);
    });
  });

  group('units defined through π are approximate, and honestly so', () {
    test('degrees to radians', () {
      expect(approx('180', 'degree', 'radian'), closeTo(3.14159265358979, 1e-12));
      expect(convert('180', 'degree', 'radian').isExact, isFalse);
    });

    test('but a whole turn is still 360 degrees', () {
      expect(approx('1', 'turn', 'degree'), closeTo(360, 1e-9));
      expect(approx('1', 'degree', 'arcminute'), closeTo(60, 1e-9));
      expect(approx('1', 'arcminute', 'arcsecond'), closeTo(60, 1e-9));
    });
  });

  group('the conversions people actually look up', () {
    test('everyday length', () {
      expect(approx('1', 'inch', 'centimetre'), closeTo(2.54, 1e-12));
      expect(approx('5', 'kilometre', 'mile'), closeTo(3.106855961, 1e-9));
      expect(approx('6', 'foot', 'metre'), closeTo(1.8288, 1e-12));
    });

    test('weight', () {
      expect(approx('1', 'kilogram', 'pound'), closeTo(2.2046226218, 1e-9));
      expect(approx('70', 'kilogram', 'stone'), closeTo(11.0231131092, 1e-9));
      expect(approx('1', 'troy ounce', 'ounce'), closeTo(192 / 175, 1e-12));
    });

    test('speed', () {
      expect(approx('1', 'mile per hour', 'kilometre per hour'),
          closeTo(1.609344, 1e-12));
      expect(approx('1', 'knot', 'kilometre per hour'), closeTo(1.852, 1e-12));
      expect(approx('100', 'kilometre per hour', 'metre per second'),
          closeTo(27.7777777778, 1e-9));
    });

    test('pressure', () {
      expect(approx('1', 'atmosphere', 'psi'), closeTo(14.6959487755, 1e-9));
      expect(approx('1', 'bar', 'kilopascal'), closeTo(100, 1e-12));
    });

    test('a torr is exactly 1/760 atm, but a millimetre of mercury is not', () {
      // The torr is *defined* as a 760th of an atmosphere, so this is
      // exact. The mmHg is defined from the density of mercury instead
      // and misses 760 in the seventh figure — which is why the catalog
      // keeps them as two units rather than aliasing one to the other.
      expect(convert('1', 'atmosphere', 'torr'), RationalValue.fromInt(760));
      expect(approx('1', 'atmosphere', 'millimetre of mercury'),
          closeTo(759.99989, 1e-5));
    });

    test('energy and power', () {
      expect(approx('1', 'kilowatt hour', 'megajoule'), closeTo(3.6, 1e-12));
      expect(approx('1', 'horsepower', 'watt'), closeTo(745.6998715823, 1e-9));
      expect(approx('1', 'metric horsepower', 'watt'), closeTo(735.49875, 1e-9));
      expect(approx('2000', 'kilocalorie', 'kilojoule'), closeTo(8368, 1e-9));
    });

    test('the storage gap that makes a 1 TB drive look like 931 GB', () {
      expect(approx('1', 'terabyte', 'gibibyte'), closeTo(931.3225746155, 1e-9));
    });

    test('a 100 Mbps line downloads at 12.5 MB/s', () {
      expect(convert('100', 'megabit per second', 'megabyte per second'),
          NumberValue.parse('12.5'));
    });
  });

  group('cooking, where the traps live', () {
    test('a US cup is not a metric cup', () {
      expect(approx('1', 'cup', 'millilitre'), closeTo(236.5882365, 1e-9));
      expect(convert('1', 'metric cup', 'millilitre'), RationalValue.fromInt(250));
      expect(convert('1', 'legal cup', 'millilitre'), RationalValue.fromInt(240));
    });

    test('an Australian tablespoon is a third bigger than everyone else\'s', () {
      expect(convert('1', 'metric tablespoon', 'millilitre'),
          RationalValue.fromInt(15));
      expect(convert('1', 'australian tablespoon', 'millilitre'),
          RationalValue.fromInt(20));
      expect(approx('1', 'tablespoon', 'millilitre'), closeTo(14.78676478, 1e-8));
    });

    test('the spoon relationships hold exactly', () {
      expect(convert('1', 'tablespoon', 'teaspoon'), RationalValue.fromInt(3));
      expect(convert('1', 'cup', 'tablespoon'), RationalValue.fromInt(16));
      expect(convert('1', 'metric tablespoon', 'metric teaspoon'),
          RationalValue.fromInt(3));
    });

    test('the ambiguous units carry a note explaining themselves', () {
      final result =
          converter.convertNamed(NumberValue.parse('2'), 'cup', 'millilitre');
      expect(result.notes.single, contains('236.6 mL'));
      expect(result.notes.single, contains('240 mL'));
    });

    test('a fluid ounce is a volume and an ounce is a mass', () {
      expect(
        () => convert('1', 'fluid ounce', 'ounce'),
        throwsA(isA<ConversionError>()),
      );
    });
  });

  group('mixing categories is refused, with a reason', () {
    test('kilograms into metres has no answer', () {
      expect(
        () => convert('1', 'kilogram', 'metre'),
        throwsA(
          isA<ConversionError>().having(
            (e) => e.message,
            'message',
            allOf(contains('mass'), contains('length')),
          ),
        ),
      );
    });

    test('an unknown unit is named back', () {
      expect(
        () => convert('1', 'metre', 'smoot'),
        throwsA(isA<ConversionError>()
            .having((e) => e.message, 'message', contains('smoot'))),
      );
    });
  });

  group('finding a unit from what was typed', () {
    test('by name, plural, symbol and alias', () {
      expect(UnitCatalog.find('kilometre')?.id, 'kilometre');
      expect(UnitCatalog.find('kilometers')?.id, 'kilometre');
      expect(UnitCatalog.find('km')?.id, 'kilometre');
      expect(UnitCatalog.find('KILOMETRE')?.id, 'kilometre');
      expect(UnitCatalog.find('square feet')?.id, 'square_foot');
      expect(UnitCatalog.find('square-feet')?.id, 'square_foot');
    });

    test('symbol case is respected, because SI says it means something', () {
      // A factor of a billion separates these two.
      expect(UnitCatalog.find('mW')?.id, 'milliwatt');
      expect(UnitCatalog.find('MW')?.id, 'megawatt');
      expect(UnitCatalog.find('B')?.id, 'byte');
    });

    test('a category narrows an otherwise ambiguous abbreviation', () {
      // "pt" is a typographic point and also a pint.
      expect(UnitCatalog.find('pt')?.id, 'point');
      expect(UnitCatalog.find('pt', category: UnitCategory.volume)?.id,
          'pint_us');
      expect(UnitCatalog.find('b', category: UnitCategory.digitalStorage)?.id,
          'bit');
    });

    test('a target is resolved inside the source\'s system', () {
      // Both gallons hold 8 of their own pints. Getting this right means
      // reading "pint" differently depending on where it came from.
      expect(convert('1', 'imperial gallon', 'pint'), RationalValue.fromInt(8));
      expect(convert('1', 'gallon', 'pint'), RationalValue.fromInt(8));
      // The two pints really are different: 20% apart.
      expect(approx('1', 'imperial pint', 'us pint'), closeTo(1.2009499, 1e-6));
      // A metric tablespoon holds 3 metric teaspoons, a US one holds 3
      // US teaspoons, and an Australian one holds 4 metric teaspoons.
      expect(convert('1', 'australian tablespoon', 'metric teaspoon'),
          RationalValue.fromInt(4));
      expect(approx('1', 'imperial gallon', 'litre'), closeTo(4.54609, 1e-12));
      expect(approx('1', 'gallon', 'litre'), closeTo(3.785411784, 1e-12));
    });

    test('an unknown name is null rather than a guess', () {
      expect(UnitCatalog.find('banana'), isNull);
    });

    test('search finds units by fragment', () {
      final found = UnitCatalog.search('tablespoon');
      expect(found.map((u) => u.id), contains('tablespoon_australian'));
      expect(found.every((u) => u.category == UnitCategory.volume), isTrue);
    });
  });

  group('the catalog itself is well formed', () {
    test('every unit id is unique', () {
      final ids = UnitCatalog.all.map((u) => u.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every category has exactly one base unit', () {
      for (final category in UnitCategory.values) {
        final units = UnitCatalog.inCategory(category);
        expect(units, isNotEmpty, reason: '${category.name} has no units');
        final bases =
            units.where((u) => u.toBase == '1' && u.offsetToBase == '0');
        expect(bases.length, 1,
            reason: '${category.name} should have one base unit');
      }
    });

    test('every factor parses and is positive', () {
      for (final unit in UnitCatalog.all) {
        expect(unit.factorValue.toDouble(), greaterThan(0),
            reason: '${unit.id} has a non-positive factor');
        expect(unit.offsetValue.toDouble().isFinite, isTrue,
            reason: '${unit.id} has a bad offset');
      }
    });

    test('no two units of one category and system share an alias', () {
      // Units from different systems may share a name — "pint" is both
      // US and imperial — and the system is what resolves it. Within one
      // system a shared alias would be genuinely ambiguous.
      final seen = <String, String>{};
      for (final unit in UnitCatalog.all) {
        final keys = {
          for (final alias in [unit.name, unit.id, ...unit.aliases])
            alias.toLowerCase().replaceAll(RegExp(r'[_\-]'), ' '),
        };
        for (final alias in keys) {
          final key = '${unit.category.name}/${unit.system.name}/$alias';
          final previous = seen[key];
          expect(previous, isNull,
              reason: '"$alias" is claimed by both $previous and ${unit.id}');
          seen[key] = unit.id;
        }
      }
    });

    test('every unit round trips through its base', () {
      final value = NumberValue.parse('7.5');
      for (final unit in UnitCatalog.all) {
        final base = UnitCatalog.baseOf(unit.category);
        final there = converter.convert(value, unit, base).value;
        final back = converter.convert(there, base, unit).value;
        expect(back.toDouble(), closeTo(7.5, 1e-9),
            reason: '${unit.id} does not round trip');
      }
    });

    test('converting to all of a category skips the source unit', () {
      final metre = UnitCatalog.byId('metre')!;
      final all = converter.convertToAll(NumberValue.parse('1'), metre);
      expect(all.map((r) => r.to.id), isNot(contains('metre')));
      expect(all.length, UnitCatalog.inCategory(UnitCategory.length).length - 1);
      final centimetres = all.firstWhere((r) => r.to.id == 'centimetre');
      expect(centimetres.value, RationalValue.fromInt(100));
    });

    test('the cooking shortlist is drawn from real categories', () {
      expect(UnitCatalog.cookingUnits.map((u) => u.id), contains('cup_metric'));
      expect(
        UnitCatalog.cookingUnits.map((u) => u.category).toSet(),
        {UnitCategory.volume, UnitCategory.mass, UnitCategory.temperature},
      );
    });
  });
}
