import 'app_language.dart';
import 'mode_l10n.dart';

/// Chrome strings. Full translations for a core set; others fall back to
/// English while still getting locale decimal/keypad overlays from [AppLanguage].
class AppStrings {
  const AppStrings(this._m);

  final Map<String, String> _m;

  String _t(String key) => _m[key] ?? _en[key] ?? key;

  String get chooseCalculator => _t('chooseCalculator');
  String get chooseCalculatorHint => _t('chooseCalculatorHint');
  String get lastUsed => _t('lastUsed');
  String get settings => _t('settings');
  String get layout => _t('layout');
  String get vision => _t('vision');
  String get textSize => _t('textSize');
  String get look => _t('look');
  String get lookHint => _t('lookHint');
  String get lookPaused => _t('lookPaused');
  String get typeface => _t('typeface');
  String get typefaceHint => _t('typefaceHint');
  String get language => _t('language');
  String get languageHint => _t('languageHint');
  String get searchLanguages => _t('searchLanguages');
  String get noLanguages => _t('noLanguages');
  String get sound => _t('sound');
  String get haptics => _t('haptics');
  String get openLast => _t('openLast');
  String get openLastHint => _t('openLastHint');
  String get history => _t('history');
  String get noEquations => _t('noEquations');
  String get pin => _t('pin');
  String get unpin => _t('unpin');
  String get hide => _t('hide');
  String get delete => _t('delete');
  String get clear => _t('clear');
  String get clearAll => _t('clearAll');
  String get backspace => _t('backspace');
  String get cursorLeft => _t('cursorLeft');
  String get cursorRight => _t('cursorRight');
  String get numbersOnly => _t('numbersOnly');
  String get numbersAndCommas => _t('numbersAndCommas');
  String get switchCalculator => _t('switchCalculator');
  String get about => _t('about');
  String get privacy => _t('privacy');
  String get version => _t('version');
  String get result => _t('result');
  String get error => _t('error');
  String get angleMode => _t('angleMode');
  String get howWeGotThis => _t('howWeGotThis');
  String get howWeGotThisHint => _t('howWeGotThisHint');
  String get readEquation => _t('readEquation');
  String get scientificKeypad => _t('scientificKeypad');
  String get scientificKeypadOn => _t('scientificKeypadOn');
  String get scientificKeypadOff => _t('scientificKeypadOff');

  String groupLabel(String id) => _t('group_$id');
  String modeLabel(String id) => _t('mode_$id');
  String modeDescription(String id) => _t('modeDesc_$id');
  String convertLabel(String id) => _t('convert_$id');
  String convertDescription(String id) => _t('convertDesc_$id');
  String get convertAsk => _t('convertAsk');
  String get convertPick => _t('convertPick');
  String geometryTool(String id) => _t('geo_$id');
  String geometryHint(String id) => _t('geoHint_$id');

  static AppStrings of(AppLanguage language) {
    return AppStrings({
      ..._en,
      ...toolStrings('en'),
      ...?_tables[language.code],
      ...toolStrings(language.code),
    });
  }

  static const _en = {
    'chooseCalculator': 'Choose a calculator',
    'chooseCalculatorHint': 'Calculator is home. Convert, percentages, and the other tools are one tap away.',
    'group_more': 'More',
    'catalog.housing': 'Housing',
    'catalog.food': 'Food & dining',
    'catalog.activity': 'Lifestyle',
    'catalog.travel': 'Travel',
    'catalog.transport': 'Transport',
    'catalog.care': 'Health & care',
    'catalog.goals': 'Goals',
    'catalog.money': 'Money',
    'catalog.home': 'Housing',
    'catalog.everyday': 'Food & dining',
    'group_graphs': 'Graphs and shapes',
    'group_school': 'More math',
    'house.expense.restaurants': 'Restaurants',
    'house.expense.coffee': 'Coffee',
    'house.expense.takeout': 'Takeout',
    'group_money': 'Money',
    'openLastHint': 'When on, the app opens the last tool instead of Calculator.',
    'lastUsed': 'Last used',
    'settings': 'Settings',
    'layout': 'Layout',
    'vision': 'Vision',
    'textSize': 'Text size',
    'look': 'Look',
    'lookHint': 'Eighty percent the field, fifteen supporting, five a single highlight. Nature first; colour-vision looks underneath.',
    'lookPaused':
        'Large layout and the high-contrast profile use their own colours so nothing is told by hue alone. Your look returns when those are off.',
    'typeface': 'Type',
    'typefaceHint':
        'Laboratory for instruments. Manuscript for the page. Clearest when every letter must be unmistakable.',
    'language': 'Language',
    'languageHint': 'Search in English or in the language’s own name.',
    'searchLanguages': 'Search languages',
    'noLanguages': 'No languages match that search',
    'sound': 'Sound on key press',
    'haptics': 'Vibration on key press',
    'openLast': 'Open last tool',
    'history': 'History',
    'noEquations': 'No calculations yet.',
    'pin': 'Pin',
    'unpin': 'Unpin',
    'hide': 'Hide',
    'delete': 'Delete',
    'clear': 'Clear',
    'clearAll': 'Clear all, delete everything',
    'backspace': 'Backspace, delete character before cursor',
    'cursorLeft': 'Move cursor left',
    'cursorRight': 'Move cursor right',
    'numbersOnly': 'Numbers only',
    'numbersAndCommas': 'Numbers and commas only',
    'switchCalculator': 'Choose a different calculator',
    'about': 'About',
    'privacy': 'Privacy policy',
    'version': 'Version',
    'result': 'Result',
    'error': 'Error',
    'angleMode': 'Angle mode',
    'howWeGotThis': 'How this was worked out',
    'howWeGotThisHint': 'Plain language, with the arithmetic beside it.',
    'readEquation': 'Read the equation',
    'scientificKeypad': 'SCI',
    'scientificKeypadOn': 'Scientific keypad, on',
    'scientificKeypadOff': 'Scientific keypad, off',
    'mode_calculator': 'Calculator',
    'mode_convert': 'Convert',
    'mode_graph': 'Graph',
    'mode_surface3d': '3D',
    'mode_geometry': 'Geometry',
    'mode_matrix': 'Matrix',
    'mode_statistics': 'Statistics',
    'mode_finance': 'Finance',
    'mode_solve': 'Solve',
    'modeDesc_calculator': 'Arithmetic, powers, trig. History keeps recent results.',
    'modeDesc_convert': 'Units, currency, cooking, tip.',
    'modeDesc_graph': 'Plot a formula. Table of values.',
    'modeDesc_surface3d': 'Plot z = f(x, y).',
    'modeDesc_geometry': 'Points, lines, circles, measure.',
    'modeDesc_matrix': 'Add, multiply, det, inverse.',
    'modeDesc_statistics': 'Mean, spread, fit, distributions.',
    'modeDesc_finance': 'Interest, loans, savings, and monthly payments.',
    'modeDesc_solve': 'Find x, polynomial roots, derivative.',
    'geo_select': 'Move',
    'geo_point': 'Point',
    'geo_segment': 'Segment',
    'geo_line': 'Line',
    'geo_circle': 'Circle',
    'geo_midpoint': 'Midpoint',
    'geo_measureDistance': 'Measure distance',
    'geo_measureAngle': 'Measure angle',
    'geoHint_select': 'Drag a point to move it, or drag empty space to pan.',
    'geoHint_point': 'Add a point: tap the picture, or type numbers.',
    'geoHint_segment': 'Tap two points to draw a segment.',
    'geoHint_line': 'Tap two points to draw an infinite line.',
    'geoHint_circle': 'Tap the center, then a point on the circle.',
    'geoHint_midpoint': 'Tap two points to place their midpoint.',
    'geoHint_measureDistance': 'Tap two points to measure the distance.',
    'geoHint_measureAngle': 'Tap the vertex, then two more points to measure the angle.',
  };

  static const _fr = {
    'chooseCalculator': 'Choisir une calculatrice',
    'chooseCalculatorHint': 'Choisissez l’outil. Vous pourrez changer ensuite depuis la barre du haut.',
    'group_graphs': 'Graphiques et formes',
    'group_school': 'Plus de maths',
    'group_money': 'Argent',
    'group_more': 'Plus',
    'lastUsed': 'Dernier utilisé',
    'settings': 'Réglages',
    'layout': 'Disposition',
    'vision': 'Vision',
    'textSize': 'Taille du texte',
    'language': 'Langue',
    'languageHint': 'Recherchez en anglais ou dans le nom natif.',
    'searchLanguages': 'Rechercher une langue',
    'noLanguages': 'Aucune langue ne correspond',
    'sound': 'Son à chaque touche',
    'haptics': 'Vibration à chaque touche',
    'openLast': 'Ouvrir la dernière calculatrice au démarrage',
    'history': 'Historique',
    'noEquations': 'Aucune équation',
    'pin': 'Épingler',
    'unpin': 'Désépingler',
    'hide': 'Masquer',
    'delete': 'Supprimer',
    'clear': 'Effacer',
    'clearAll': 'Tout effacer',
    'backspace': 'Retour arrière',
    'cursorLeft': 'Curseur à gauche',
    'cursorRight': 'Curseur à droite',
    'numbersOnly': 'Chiffres uniquement',
    'switchCalculator': 'Choisir une autre calculatrice',
    'about': 'À propos',
    'privacy': 'Politique de confidentialité',
    'result': 'Résultat',
    'error': 'Erreur',
    'angleMode': 'Mode d’angle',
    'scientificKeypad': 'SCI',
    'scientificKeypadOn': 'Clavier scientifique, activé',
    'scientificKeypadOff': 'Clavier scientifique, désactivé',
  };

  static const _es = {
    'chooseCalculator': 'Elegir una calculadora',
    'group_graphs': 'Gráficos y formas',
    'group_school': 'Más matemáticas',
    'group_money': 'Dinero',
    'group_more': 'Más',
    'settings': 'Ajustes',
    'language': 'Idioma',
    'searchLanguages': 'Buscar idiomas',
    'history': 'Historial',
    'pin': 'Fijar',
    'hide': 'Ocultar',
    'delete': 'Eliminar',
    'switchCalculator': 'Elegir otra calculadora',
    'result': 'Resultado',
    'error': 'Error',
    'clear': 'Borrar',
    'clearAll': 'Borrar todo',
    'scientificKeypad': 'SCI',
    'scientificKeypadOn': 'Teclado científico, activado',
    'scientificKeypadOff': 'Teclado científico, desactivado',
  };

  static const _de = {
    'chooseCalculator': 'Taschenrechner wählen',
    'group_graphs': 'Grafiken und Formen',
    'group_school': 'Mehr Mathematik',
    'group_money': 'Geld',
    'group_more': 'Mehr',
    'settings': 'Einstellungen',
    'language': 'Sprache',
    'searchLanguages': 'Sprachen suchen',
    'history': 'Verlauf',
    'pin': 'Anheften',
    'hide': 'Ausblenden',
    'delete': 'Löschen',
    'switchCalculator': 'Anderen Rechner wählen',
    'result': 'Ergebnis',
    'error': 'Fehler',
    'clear': 'Löschen',
    'clearAll': 'Alles löschen',
    'scientificKeypad': 'SCI',
    'scientificKeypadOn': 'Wissenschaftliches Tastenfeld, an',
    'scientificKeypadOff': 'Wissenschaftliches Tastenfeld, aus',
  };

  static const _bg = {
    'chooseCalculator': 'Изберете калкулатор',
    'chooseCalculatorHint': 'Изберете инструмента. Можете да смените по-късно от горната лента.',
    'group_graphs': 'Графики и фигури',
    'group_school': 'Още математика',
    'group_money': 'Пари',
    'group_more': 'Още',
    'lastUsed': 'Последно използван',
    'settings': 'Настройки',
    'layout': 'Изглед',
    'vision': 'Зрение',
    'textSize': 'Размер на текста',
    'language': 'Език',
    'languageHint': 'Търсете на английски или на собственото име на езика.',
    'searchLanguages': 'Търсене на езици',
    'noLanguages': 'Няма съвпадения',
    'sound': 'Звук при натискане',
    'haptics': 'Вибрация при натискане',
    'openLast': 'Отваряй последния калкулатор при старт',
    'history': 'История',
    'noEquations': 'Все още няма уравнения',
    'pin': 'Закачи',
    'unpin': 'Откачи',
    'hide': 'Скрий',
    'delete': 'Изтрий',
    'clear': 'Изчисти',
    'clearAll': 'Изчисти всичко',
    'backspace': 'Изтрий знака преди курсора',
    'cursorLeft': 'Курсор наляво',
    'cursorRight': 'Курсор надясно',
    'numbersOnly': 'Само числа',
    'switchCalculator': 'Изберете друг калкулатор',
    'about': 'Относно',
    'privacy': 'Политика за поверителност',
    'result': 'Резултат',
    'error': 'Грешка',
    'angleMode': 'Режим на ъгли',
    'scientificKeypad': 'SCI',
    'scientificKeypadOn': 'Научна клавиатура, включена',
    'scientificKeypadOff': 'Научна клавиатура, изключена',
  };

  static const _ru = {
    'chooseCalculator': 'Выберите калькулятор',
    'group_graphs': 'Графики и фигуры',
    'group_school': 'Ещё математика',
    'group_money': 'Деньги',
    'group_more': 'Ещё',
    'settings': 'Настройки',
    'language': 'Язык',
    'searchLanguages': 'Поиск языка',
    'history': 'История',
    'pin': 'Закрепить',
    'hide': 'Скрыть',
    'delete': 'Удалить',
    'switchCalculator': 'Выбрать другой калькулятор',
    'result': 'Результат',
    'error': 'Ошибка',
    'clear': 'Очистить',
    'clearAll': 'Очистить всё',
    'scientificKeypad': 'SCI',
    'scientificKeypadOn': 'Научная клавиатура, включена',
    'scientificKeypadOff': 'Научная клавиатура, выключена',
  };

  static const _tables = {
    'en': _en,
    'fr': _fr,
    'es': _es,
    'de': _de,
    'bg': _bg,
    'ru': _ru,
    'pt': _es,
  };
}
