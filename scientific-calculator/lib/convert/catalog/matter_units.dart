/// Mass, force, pressure, energy, power and temperature.
///
/// The imperial units here all descend from two exact definitions: the
/// pound is exactly 0.45359237 kg, and standard gravity is exactly
/// 9.80665 m/s². Everything from the pound-force to the psi to the
/// horsepower is written out from those, so the chain stays exact.
library;

import '../unit.dart';

/// The pound-force in newtons: one pound under standard gravity.
/// Exact, and the root of psi, horsepower and foot-pounds below.
const _poundForce = '0.45359237*9.80665';

const massUnits = <Unit>[
  Unit(
    id: 'kilogram',
    name: 'Kilogram',
    symbol: 'kg',
    system: UnitSystem.metric,
    category: UnitCategory.mass,
    toBase: '1',
    aliases: ['kilograms', 'kilo', 'kilos', 'kg'],
  ),
  Unit(
    id: 'gram',
    name: 'Gram',
    symbol: 'g',
    system: UnitSystem.metric,
    category: UnitCategory.mass,
    toBase: '0.001',
    aliases: ['grams', 'gramme', 'grammes', 'g'],
  ),
  Unit(
    id: 'milligram',
    name: 'Milligram',
    symbol: 'mg',
    system: UnitSystem.metric,
    category: UnitCategory.mass,
    toBase: '0.000001',
    aliases: ['milligrams', 'mg'],
  ),
  Unit(
    id: 'microgram',
    name: 'Microgram',
    symbol: 'µg',
    system: UnitSystem.metric,
    category: UnitCategory.mass,
    toBase: '1/10^9',
    aliases: ['micrograms', 'ug', 'mcg'],
  ),
  Unit(
    id: 'tonne',
    name: 'Tonne',
    symbol: 't',
    system: UnitSystem.metric,
    category: UnitCategory.mass,
    toBase: '1000',
    aliases: ['tonnes', 'metric ton', 'metric tons', 'megagram'],
  ),
  Unit(
    id: 'pound',
    name: 'Pound',
    symbol: 'lb',
    category: UnitCategory.mass,
    toBase: '0.45359237',
    aliases: ['pounds', 'lb', 'lbs'],
  ),
  Unit(
    id: 'ounce',
    name: 'Ounce',
    symbol: 'oz',
    category: UnitCategory.mass,
    toBase: '0.45359237/16',
    aliases: ['ounces', 'oz'],
    note: 'This is the weight ounce. A fluid ounce measures volume, not '
        'mass, and lives under Volume.',
  ),
  Unit(
    id: 'stone',
    name: 'Stone',
    symbol: 'st',
    system: UnitSystem.imperial,
    category: UnitCategory.mass,
    toBase: '14*0.45359237',
    aliases: ['stones', 'st'],
  ),
  Unit(
    id: 'ton_short',
    name: 'Ton (US, short)',
    symbol: 'tn',
    system: UnitSystem.us,
    category: UnitCategory.mass,
    toBase: '2000*0.45359237',
    aliases: ['short ton', 'short tons', 'us ton', 'ton', 'tons'],
  ),
  Unit(
    id: 'ton_long',
    name: 'Ton (imperial, long)',
    symbol: 'LT',
    system: UnitSystem.imperial,
    category: UnitCategory.mass,
    toBase: '2240*0.45359237',
    aliases: ['ton', 'tons', 'long ton', 'long tons', 'imperial ton'],
  ),
  Unit(
    id: 'grain',
    name: 'Grain',
    symbol: 'gr',
    category: UnitCategory.mass,
    toBase: '0.45359237/7000',
    aliases: ['grains'],
  ),
  Unit(
    id: 'carat',
    name: 'Carat',
    symbol: 'ct',
    category: UnitCategory.mass,
    toBase: '0.0002',
    aliases: ['carats', 'ct'],
    note: 'The metric carat, 200 mg. Not karat, which measures gold '
        'purity and is not a mass at all.',
  ),
  Unit(
    id: 'troy_ounce',
    name: 'Troy ounce',
    symbol: 'ozt',
    category: UnitCategory.mass,
    toBase: '0.0311034768',
    aliases: ['troy ounces', 'ozt'],
    note: 'Used for precious metals, and about 10% heavier than the '
        'ordinary ounce.',
  ),
  Unit(
    id: 'pennyweight',
    name: 'Pennyweight',
    symbol: 'dwt',
    category: UnitCategory.mass,
    toBase: '0.0311034768/20',
    aliases: ['pennyweights', 'dwt'],
  ),
  Unit(
    id: 'slug',
    name: 'Slug',
    symbol: 'slug',
    category: UnitCategory.mass,
    toBase: '$_poundForce/(12*0.0254)',
    aliases: ['slugs'],
  ),
  Unit(
    id: 'dalton',
    name: 'Dalton',
    symbol: 'Da',
    category: UnitCategory.mass,
    // A measured constant, not a definition, so this one is approximate.
    toBase: '1.66053906892/10^27',
    aliases: ['daltons', 'atomic mass unit', 'amu', 'u'],
  ),
];

const forceUnits = <Unit>[
  Unit(
    id: 'newton',
    name: 'Newton',
    symbol: 'N',
    category: UnitCategory.force,
    toBase: '1',
    aliases: ['newtons', 'n'],
  ),
  Unit(
    id: 'kilonewton',
    name: 'Kilonewton',
    symbol: 'kN',
    category: UnitCategory.force,
    toBase: '1000',
    aliases: ['kilonewtons', 'kn'],
  ),
  Unit(
    id: 'dyne',
    name: 'Dyne',
    symbol: 'dyn',
    category: UnitCategory.force,
    toBase: '1/10^5',
    aliases: ['dynes'],
  ),
  Unit(
    id: 'kilogram_force',
    name: 'Kilogram-force',
    symbol: 'kgf',
    category: UnitCategory.force,
    toBase: '9.80665',
    aliases: ['kilogram force', 'kilopond', 'kgf'],
  ),
  Unit(
    id: 'pound_force',
    name: 'Pound-force',
    symbol: 'lbf',
    category: UnitCategory.force,
    toBase: _poundForce,
    aliases: ['pound force', 'pounds force', 'lbf'],
  ),
  Unit(
    id: 'poundal',
    name: 'Poundal',
    symbol: 'pdl',
    category: UnitCategory.force,
    toBase: '0.45359237*12*0.0254',
    aliases: ['poundals'],
  ),
];

const pressureUnits = <Unit>[
  Unit(
    id: 'pascal',
    name: 'Pascal',
    symbol: 'Pa',
    category: UnitCategory.pressure,
    toBase: '1',
    aliases: ['pascals', 'pa'],
  ),
  Unit(
    id: 'hectopascal',
    name: 'Hectopascal',
    symbol: 'hPa',
    category: UnitCategory.pressure,
    toBase: '100',
    aliases: ['hectopascals', 'hpa'],
  ),
  Unit(
    id: 'kilopascal',
    name: 'Kilopascal',
    symbol: 'kPa',
    category: UnitCategory.pressure,
    toBase: '1000',
    aliases: ['kilopascals', 'kpa'],
  ),
  Unit(
    id: 'megapascal',
    name: 'Megapascal',
    symbol: 'MPa',
    category: UnitCategory.pressure,
    toBase: '1000000',
    aliases: ['megapascals', 'mpa'],
  ),
  Unit(
    id: 'bar',
    name: 'Bar',
    symbol: 'bar',
    category: UnitCategory.pressure,
    toBase: '100000',
    aliases: ['bars'],
  ),
  Unit(
    id: 'millibar',
    name: 'Millibar',
    symbol: 'mbar',
    category: UnitCategory.pressure,
    toBase: '100',
    aliases: ['millibars', 'mb', 'mbar'],
  ),
  Unit(
    id: 'atmosphere',
    name: 'Atmosphere',
    symbol: 'atm',
    category: UnitCategory.pressure,
    toBase: '101325',
    aliases: ['atmospheres', 'atm', 'standard atmosphere'],
  ),
  Unit(
    id: 'torr',
    name: 'Torr',
    symbol: 'Torr',
    category: UnitCategory.pressure,
    toBase: '101325/760',
    aliases: ['torrs'],
  ),
  Unit(
    id: 'millimetre_of_mercury',
    name: 'Millimetre of mercury',
    symbol: 'mmHg',
    category: UnitCategory.pressure,
    toBase: '133.322387415',
    aliases: ['millimeter of mercury', 'mmhg', 'mm hg'],
    note: 'Almost but not exactly a torr — they differ in the eighth '
        'significant figure.',
  ),
  Unit(
    id: 'inch_of_mercury',
    name: 'Inch of mercury',
    symbol: 'inHg',
    category: UnitCategory.pressure,
    toBase: '133.322387415*25.4',
    aliases: ['inches of mercury', 'inhg', 'in hg'],
  ),
  Unit(
    id: 'psi',
    name: 'Pound per square inch',
    symbol: 'psi',
    category: UnitCategory.pressure,
    toBase: '$_poundForce/0.0254^2',
    aliases: ['pounds per square inch', 'lb/in2', 'psi'],
  ),
];

const energyUnits = <Unit>[
  Unit(
    id: 'joule',
    name: 'Joule',
    symbol: 'J',
    category: UnitCategory.energy,
    toBase: '1',
    aliases: ['joules', 'j'],
  ),
  Unit(
    id: 'kilojoule',
    name: 'Kilojoule',
    symbol: 'kJ',
    category: UnitCategory.energy,
    toBase: '1000',
    aliases: ['kilojoules', 'kj'],
  ),
  Unit(
    id: 'megajoule',
    name: 'Megajoule',
    symbol: 'MJ',
    category: UnitCategory.energy,
    toBase: '1000000',
    aliases: ['megajoules', 'mj'],
  ),
  Unit(
    id: 'calorie',
    name: 'Calorie (small)',
    symbol: 'cal',
    category: UnitCategory.energy,
    toBase: '4.184',
    aliases: ['calories', 'cal', 'gram calorie'],
    note: 'The small calorie. Food labels use the kilocalorie, which is '
        'a thousand of these and is confusingly also written "Calorie".',
  ),
  Unit(
    id: 'kilocalorie',
    name: 'Kilocalorie (food Calorie)',
    symbol: 'kcal',
    category: UnitCategory.energy,
    toBase: '4184',
    aliases: ['kilocalories', 'kcal', 'food calorie', 'food calories'],
  ),
  Unit(
    id: 'watt_hour',
    name: 'Watt-hour',
    symbol: 'Wh',
    category: UnitCategory.energy,
    toBase: '3600',
    aliases: ['watt hour', 'watt hours', 'wh'],
  ),
  Unit(
    id: 'kilowatt_hour',
    name: 'Kilowatt-hour',
    symbol: 'kWh',
    category: UnitCategory.energy,
    toBase: '3600000',
    aliases: ['kilowatt hour', 'kilowatt hours', 'kwh'],
  ),
  Unit(
    id: 'btu',
    name: 'British thermal unit',
    symbol: 'BTU',
    category: UnitCategory.energy,
    toBase: '1055.05585262',
    aliases: ['british thermal unit', 'british thermal units', 'btu', 'btus'],
  ),
  Unit(
    id: 'therm',
    name: 'Therm',
    symbol: 'thm',
    category: UnitCategory.energy,
    toBase: '100000*1055.05585262',
    aliases: ['therms'],
  ),
  Unit(
    id: 'electronvolt',
    name: 'Electronvolt',
    symbol: 'eV',
    category: UnitCategory.energy,
    // Exact since the 2019 SI redefinition fixed the elementary charge.
    toBase: '1.602176634/10^19',
    aliases: ['electron volt', 'electronvolts', 'ev'],
  ),
  Unit(
    id: 'erg',
    name: 'Erg',
    symbol: 'erg',
    category: UnitCategory.energy,
    toBase: '1/10^7',
    aliases: ['ergs'],
  ),
  Unit(
    id: 'foot_pound',
    name: 'Foot-pound',
    symbol: 'ft⋅lbf',
    category: UnitCategory.energy,
    toBase: '$_poundForce*12*0.0254',
    aliases: ['foot pound', 'foot pounds', 'ft lb', 'ftlb'],
  ),
  Unit(
    id: 'ton_of_tnt',
    name: 'Tonne of TNT',
    symbol: 'tTNT',
    category: UnitCategory.energy,
    toBase: '4184000000',
    aliases: ['ton of tnt', 'tons of tnt', 'tnt'],
  ),
];

const powerUnits = <Unit>[
  Unit(
    id: 'watt',
    name: 'Watt',
    symbol: 'W',
    category: UnitCategory.power,
    toBase: '1',
    aliases: ['watts', 'w'],
  ),
  Unit(
    id: 'milliwatt',
    name: 'Milliwatt',
    symbol: 'mW',
    category: UnitCategory.power,
    toBase: '0.001',
    // No lowercase "mw" alias: mW and MW differ by a factor of a
    // billion, so that abbreviation has to stay case-sensitive.
    aliases: ['milliwatts'],
  ),
  Unit(
    id: 'kilowatt',
    name: 'Kilowatt',
    symbol: 'kW',
    category: UnitCategory.power,
    toBase: '1000',
    aliases: ['kilowatts', 'kw'],
  ),
  Unit(
    id: 'megawatt',
    name: 'Megawatt',
    symbol: 'MW',
    category: UnitCategory.power,
    toBase: '1000000',
    aliases: ['megawatts'],
  ),
  Unit(
    id: 'gigawatt',
    name: 'Gigawatt',
    symbol: 'GW',
    category: UnitCategory.power,
    toBase: '10^9',
    aliases: ['gigawatts', 'gw'],
  ),
  Unit(
    id: 'horsepower_mechanical',
    name: 'Horsepower (mechanical)',
    symbol: 'hp',
    category: UnitCategory.power,
    // 550 foot-pounds per second.
    toBase: '550*$_poundForce*12*0.0254',
    aliases: ['horsepower', 'hp', 'bhp'],
  ),
  Unit(
    id: 'horsepower_metric',
    name: 'Horsepower (metric)',
    symbol: 'PS',
    category: UnitCategory.power,
    toBase: '75*9.80665',
    aliases: ['metric horsepower', 'ps', 'cv'],
    note: 'European car figures are usually metric horsepower, which is '
        'about 1.4% smaller than the mechanical kind.',
  ),
  Unit(
    id: 'btu_per_hour',
    name: 'BTU per hour',
    symbol: 'BTU/h',
    category: UnitCategory.power,
    toBase: '1055.05585262/3600',
    aliases: ['btu per hour', 'btu/h', 'btuh'],
  ),
];

/// Temperature is the only category here that is not proportional: the
/// scales disagree about where zero is, so each unit carries an offset as
/// well as a factor and the conversion is affine.
const temperatureUnits = <Unit>[
  Unit(
    id: 'kelvin',
    name: 'Kelvin',
    symbol: 'K',
    category: UnitCategory.temperature,
    toBase: '1',
    aliases: ['kelvins', 'k'],
  ),
  Unit(
    id: 'celsius',
    name: 'Celsius',
    symbol: '°C',
    category: UnitCategory.temperature,
    toBase: '1',
    offsetToBase: '273.15',
    aliases: ['celsius', 'centigrade', 'c', 'degrees celsius'],
  ),
  Unit(
    id: 'fahrenheit',
    name: 'Fahrenheit',
    symbol: '°F',
    category: UnitCategory.temperature,
    toBase: '5/9',
    // Kept as an expression because 459.67 × 5/9 is not a finite
    // decimal — but it is an exact rational, so 100 °C still lands on
    // exactly 212 °F rather than 211.99999999999997.
    offsetToBase: '459.67*5/9',
    aliases: ['fahrenheit', 'f', 'degrees fahrenheit'],
  ),
  Unit(
    id: 'rankine',
    name: 'Rankine',
    symbol: '°R',
    category: UnitCategory.temperature,
    toBase: '5/9',
    aliases: ['rankine', 'r', 'degrees rankine'],
  ),
];
