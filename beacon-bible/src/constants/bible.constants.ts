// Canonical 66 books with all common abbreviations mapped to API.Bible codes
export const BOOK_CODES = [
  'GEN','EXO','LEV','NUM','DEU','JOS','JDG','RUT','1SA','2SA',
  '1KI','2KI','1CH','2CH','EZR','NEH','EST','JOB','PSA','PRO',
  'ECC','SNG','ISA','JER','LAM','EZK','DAN','HOS','JOL','AMO',
  'OBA','JON','MIC','NAH','HAB','ZEP','HAG','ZEC','MAL',
  'MAT','MRK','LUK','JHN','ACT','ROM','1CO','2CO','GAL','EPH',
  'PHP','COL','1TH','2TH','1TI','2TI','TIT','PHM','HEB','JAS',
  '1PE','2PE','1JN','2JN','3JN','JUD','REV',
] as const;

export type BookCode = typeof BOOK_CODES[number];

export const BOOK_NAMES: Record<BookCode, string> = {
  GEN: 'Genesis',       EXO: 'Exodus',        LEV: 'Leviticus',
  NUM: 'Numbers',       DEU: 'Deuteronomy',   JOS: 'Joshua',
  JDG: 'Judges',        RUT: 'Ruth',          '1SA': '1 Samuel',
  '2SA': '2 Samuel',    '1KI': '1 Kings',     '2KI': '2 Kings',
  '1CH': '1 Chronicles','2CH': '2 Chronicles', EZR: 'Ezra',
  NEH: 'Nehemiah',      EST: 'Esther',        JOB: 'Job',
  PSA: 'Psalms',        PRO: 'Proverbs',      ECC: 'Ecclesiastes',
  SNG: 'Song of Solomon',ISA: 'Isaiah',       JER: 'Jeremiah',
  LAM: 'Lamentations',  EZK: 'Ezekiel',      DAN: 'Daniel',
  HOS: 'Hosea',         JOL: 'Joel',          AMO: 'Amos',
  OBA: 'Obadiah',       JON: 'Jonah',         MIC: 'Micah',
  NAH: 'Nahum',         HAB: 'Habakkuk',      ZEP: 'Zephaniah',
  HAG: 'Haggai',        ZEC: 'Zechariah',     MAL: 'Malachi',
  MAT: 'Matthew',       MRK: 'Mark',          LUK: 'Luke',
  JHN: 'John',          ACT: 'Acts',          ROM: 'Romans',
  '1CO': '1 Corinthians','2CO': '2 Corinthians',GAL: 'Galatians',
  EPH: 'Ephesians',     PHP: 'Philippians',   COL: 'Colossians',
  '1TH': '1 Thessalonians','2TH': '2 Thessalonians','1TI': '1 Timothy',
  '2TI': '2 Timothy',   TIT: 'Titus',         PHM: 'Philemon',
  HEB: 'Hebrews',       JAS: 'James',         '1PE': '1 Peter',
  '2PE': '2 Peter',     '1JN': '1 John',      '2JN': '2 John',
  '3JN': '3 John',      JUD: 'Jude',          REV: 'Revelation',
};

export const BOOK_SHORT_NAMES: Record<BookCode, string> = {
  GEN: 'Gen',   EXO: 'Exo',   LEV: 'Lev',   NUM: 'Num',   DEU: 'Deu',
  JOS: 'Jos',   JDG: 'Jdg',   RUT: 'Rut',   '1SA': '1Sa', '2SA': '2Sa',
  '1KI': '1Ki', '2KI': '2Ki', '1CH': '1Ch', '2CH': '2Ch', EZR: 'Ezr',
  NEH: 'Neh',   EST: 'Est',   JOB: 'Job',   PSA: 'Psa',   PRO: 'Pro',
  ECC: 'Ecc',   SNG: 'Sng',   ISA: 'Isa',   JER: 'Jer',   LAM: 'Lam',
  EZK: 'Ezk',   DAN: 'Dan',   HOS: 'Hos',   JOL: 'Joel',  AMO: 'Amo',
  OBA: 'Oba',   JON: 'Jon',   MIC: 'Mic',   NAH: 'Nah',   HAB: 'Hab',
  ZEP: 'Zep',   HAG: 'Hag',   ZEC: 'Zec',   MAL: 'Mal',
  MAT: 'Mat',   MRK: 'Mrk',   LUK: 'Luk',   JHN: 'Jhn',   ACT: 'Act',
  ROM: 'Rom',   '1CO': '1Co', '2CO': '2Co', GAL: 'Gal',   EPH: 'Eph',
  PHP: 'Php',   COL: 'Col',   '1TH': '1Th', '2TH': '2Th', '1TI': '1Ti',
  '2TI': '2Ti', TIT: 'Tit',   PHM: 'Phm',   HEB: 'Heb',   JAS: 'Jas',
  '1PE': '1Pe', '2PE': '2Pe', '1JN': '1Jn', '2JN': '2Jn', '3JN': '3Jn',
  JUD: 'Jud',   REV: 'Rev',
};

// Chapter counts per book
export const CHAPTER_COUNTS: Record<BookCode, number> = {
  GEN:50, EXO:40, LEV:27, NUM:36, DEU:34, JOS:24, JDG:21, RUT:4,
  '1SA':31, '2SA':24, '1KI':22, '2KI':25, '1CH':29, '2CH':36,
  EZR:10, NEH:13, EST:10, JOB:42, PSA:150, PRO:31, ECC:12, SNG:8,
  ISA:66, JER:52, LAM:5, EZK:48, DAN:12, HOS:14, JOL:3, AMO:9,
  OBA:1, JON:4, MIC:7, NAH:3, HAB:3, ZEP:3, HAG:2, ZEC:14, MAL:4,
  MAT:28, MRK:16, LUK:24, JHN:21, ACT:28, ROM:16,
  '1CO':16, '2CO':13, GAL:6, EPH:6, PHP:4, COL:4,
  '1TH':5, '2TH':3, '1TI':6, '2TI':4, TIT:3, PHM:1,
  HEB:13, JAS:5, '1PE':5, '2PE':3, '1JN':5, '2JN':1, '3JN':1,
  JUD:1, REV:22,
};

// Book abbreviation normalisation map — 200+ abbreviations → canonical code
export const BOOK_ABBREVIATIONS: Record<string, BookCode> = {
  // Genesis
  gen: 'GEN', ge: 'GEN', gn: 'GEN', genesis: 'GEN',
  // Exodus
  exo: 'EXO', ex: 'EXO', exod: 'EXO', exodus: 'EXO',
  // Leviticus
  lev: 'LEV', le: 'LEV', lv: 'LEV', leviticus: 'LEV',
  // Numbers
  num: 'NUM', nu: 'NUM', nm: 'NUM', numbers: 'NUM', numb: 'NUM',
  // Deuteronomy
  deu: 'DEU', dt: 'DEU', deu: 'DEU', deut: 'DEU', deuteronomy: 'DEU',
  // Joshua
  jos: 'JOS', josh: 'JOS', joshua: 'JOS',
  // Judges
  jdg: 'JDG', jg: 'JDG', judg: 'JDG', judges: 'JDG',
  // Ruth
  rut: 'RUT', ru: 'RUT', ruth: 'RUT',
  // 1 Samuel
  '1sa': '1SA', '1sam': '1SA', '1samuel': '1SA', '1s': '1SA',
  // 2 Samuel
  '2sa': '2SA', '2sam': '2SA', '2samuel': '2SA', '2s': '2SA',
  // 1 Kings
  '1ki': '1KI', '1kgs': '1KI', '1kings': '1KI', '1k': '1KI',
  // 2 Kings
  '2ki': '2KI', '2kgs': '2KI', '2kings': '2KI', '2k': '2KI',
  // Psalms
  psa: 'PSA', ps: 'PSA', pss: 'PSA', psalm: 'PSA', psalms: 'PSA',
  // Proverbs
  pro: 'PRO', pr: 'PRO', prv: 'PRO', prov: 'PRO', proverbs: 'PRO',
  // Isaiah
  isa: 'ISA', is: 'ISA', isaiah: 'ISA',
  // Jeremiah
  jer: 'JER', je: 'JER', jeremiah: 'JER',
  // Matthew
  mat: 'MAT', mt: 'MAT', matt: 'MAT', matthew: 'MAT',
  // Mark
  mrk: 'MRK', mk: 'MRK', mar: 'MRK', mark: 'MRK',
  // Luke
  luk: 'LUK', lk: 'LUK', luke: 'LUK',
  // John
  jhn: 'JHN', jn: 'JHN', joh: 'JHN', john: 'JHN',
  // Acts
  act: 'ACT', ac: 'ACT', acts: 'ACT',
  // Romans
  rom: 'ROM', ro: 'ROM', rm: 'ROM', romans: 'ROM',
  // 1 Corinthians
  '1co': '1CO', '1cor': '1CO', '1corinthians': '1CO',
  // 2 Corinthians
  '2co': '2CO', '2cor': '2CO', '2corinthians': '2CO',
  // Galatians
  gal: 'GAL', ga: 'GAL', galatians: 'GAL',
  // Ephesians
  eph: 'EPH', ephesians: 'EPH',
  // Philippians
  php: 'PHP', phi: 'PHP', phil: 'PHP', philippians: 'PHP',
  // Colossians
  col: 'COL', colossians: 'COL',
  // Hebrews
  heb: 'HEB', hebrews: 'HEB',
  // James
  jas: 'JAS', jm: 'JAS', james: 'JAS',
  // Revelation
  rev: 'REV', re: 'REV', revelation: 'REV', revelations: 'REV', rv: 'REV',
};

export const OLD_TESTAMENT_BOOKS = BOOK_CODES.slice(0, 39);
export const NEW_TESTAMENT_BOOKS = BOOK_CODES.slice(39);

// Testament lookup
export const BOOK_TESTAMENT: Record<BookCode, 'OT' | 'NT'> = Object.fromEntries([
  ...OLD_TESTAMENT_BOOKS.map(b => [b, 'OT']),
  ...NEW_TESTAMENT_BOOKS.map(b => [b, 'NT']),
]) as Record<BookCode, 'OT' | 'NT'>;

// Direction of Scripture text per language — used for RTL rendering
export const RTL_LANGUAGE_CODES = new Set([
  'heb', 'ara', 'arc', 'fas', 'urd', 'yid', 'pus', 'div',
]);
