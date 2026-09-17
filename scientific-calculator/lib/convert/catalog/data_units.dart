/// Digital storage and data rate.
///
/// The decimal and binary prefixes are both here and both correct, for
/// different things: drive manufacturers and network engineers count in
/// powers of 1000, operating systems report powers of 1024. That gap is
/// why a "1 TB" drive shows up as 931 GB, and this catalog keeps the two
/// apart rather than picking a side.
library;

import '../unit.dart';

const digitalStorageUnits = <Unit>[
  Unit(
    id: 'bit',
    name: 'Bit',
    symbol: 'bit',
    category: UnitCategory.digitalStorage,
    toBase: '1/8',
    aliases: ['bits', 'b'],
  ),
  Unit(
    id: 'byte',
    name: 'Byte',
    symbol: 'B',
    category: UnitCategory.digitalStorage,
    toBase: '1',
    aliases: ['bytes'],
  ),
  Unit(
    id: 'kilobyte',
    name: 'Kilobyte',
    symbol: 'kB',
    category: UnitCategory.digitalStorage,
    toBase: '1000',
    aliases: ['kilobytes', 'kb'],
  ),
  Unit(
    id: 'kibibyte',
    name: 'Kibibyte',
    symbol: 'KiB',
    category: UnitCategory.digitalStorage,
    toBase: '1024',
    aliases: ['kibibytes', 'kib'],
    note: 'The binary kilobyte, 1024 bytes. This is what most operating '
        'systems mean when they write "KB".',
  ),
  Unit(
    id: 'megabyte',
    name: 'Megabyte',
    symbol: 'MB',
    category: UnitCategory.digitalStorage,
    toBase: '1000^2',
    aliases: ['megabytes'],
  ),
  Unit(
    id: 'mebibyte',
    name: 'Mebibyte',
    symbol: 'MiB',
    category: UnitCategory.digitalStorage,
    toBase: '1024^2',
    aliases: ['mebibytes', 'mib'],
  ),
  Unit(
    id: 'gigabyte',
    name: 'Gigabyte',
    symbol: 'GB',
    category: UnitCategory.digitalStorage,
    toBase: '1000^3',
    aliases: ['gigabytes', 'gb'],
  ),
  Unit(
    id: 'gibibyte',
    name: 'Gibibyte',
    symbol: 'GiB',
    category: UnitCategory.digitalStorage,
    toBase: '1024^3',
    aliases: ['gibibytes', 'gib'],
  ),
  Unit(
    id: 'terabyte',
    name: 'Terabyte',
    symbol: 'TB',
    category: UnitCategory.digitalStorage,
    toBase: '1000^4',
    aliases: ['terabytes', 'tb'],
  ),
  Unit(
    id: 'tebibyte',
    name: 'Tebibyte',
    symbol: 'TiB',
    category: UnitCategory.digitalStorage,
    toBase: '1024^4',
    aliases: ['tebibytes', 'tib'],
  ),
  Unit(
    id: 'petabyte',
    name: 'Petabyte',
    symbol: 'PB',
    category: UnitCategory.digitalStorage,
    toBase: '1000^5',
    aliases: ['petabytes', 'pb'],
  ),
  Unit(
    id: 'pebibyte',
    name: 'Pebibyte',
    symbol: 'PiB',
    category: UnitCategory.digitalStorage,
    toBase: '1024^5',
    aliases: ['pebibytes', 'pib'],
  ),
];

const dataRateUnits = <Unit>[
  Unit(
    id: 'bit_per_second',
    name: 'Bit per second',
    symbol: 'bit/s',
    category: UnitCategory.dataRate,
    toBase: '1',
    aliases: ['bits per second', 'bps'],
  ),
  Unit(
    id: 'kilobit_per_second',
    name: 'Kilobit per second',
    symbol: 'kbit/s',
    category: UnitCategory.dataRate,
    toBase: '1000',
    aliases: ['kilobits per second', 'kbps', 'kbit/s'],
  ),
  Unit(
    id: 'megabit_per_second',
    name: 'Megabit per second',
    symbol: 'Mbit/s',
    category: UnitCategory.dataRate,
    toBase: '1000^2',
    aliases: ['megabits per second', 'mbps', 'mbit/s'],
    note: 'Broadband is sold in megabits. A 100 Mbps line downloads at '
        'about 12.5 MB/s, because a byte is eight bits.',
  ),
  Unit(
    id: 'gigabit_per_second',
    name: 'Gigabit per second',
    symbol: 'Gbit/s',
    category: UnitCategory.dataRate,
    toBase: '1000^3',
    aliases: ['gigabits per second', 'gbps', 'gbit/s'],
  ),
  Unit(
    id: 'byte_per_second',
    name: 'Byte per second',
    symbol: 'B/s',
    category: UnitCategory.dataRate,
    toBase: '8',
    aliases: ['bytes per second'],
  ),
  Unit(
    id: 'kilobyte_per_second',
    name: 'Kilobyte per second',
    symbol: 'kB/s',
    category: UnitCategory.dataRate,
    toBase: '8000',
    aliases: ['kilobytes per second', 'kb/s'],
  ),
  Unit(
    id: 'megabyte_per_second',
    name: 'Megabyte per second',
    symbol: 'MB/s',
    category: UnitCategory.dataRate,
    toBase: '8*1000^2',
    aliases: ['megabytes per second', 'mb/s'],
  ),
  Unit(
    id: 'gigabyte_per_second',
    name: 'Gigabyte per second',
    symbol: 'GB/s',
    category: UnitCategory.dataRate,
    toBase: '8*1000^3',
    aliases: ['gigabytes per second', 'gb/s'],
  ),
];
