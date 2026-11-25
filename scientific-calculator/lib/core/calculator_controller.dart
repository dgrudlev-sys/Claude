import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'angle_mode.dart';
import 'calculator_engine.dart';
import 'explanation.dart';
import 'expression_explainer.dart';

const _kHistoryKey = 'calculator_history_v1';
const _maxVisibleHistory = 30;

/// One evaluated line. Pinned entries stay in the bar; hidden ones are
/// omitted from the list without being deleted; delete removes them.
class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.expression,
    required this.result,
    this.pinned = false,
    this.hidden = false,
  });

  final String id;
  final String expression;
  final String result;
  final bool pinned;
  final bool hidden;

  HistoryEntry copyWith({bool? pinned, bool? hidden}) => HistoryEntry(
        id: id,
        expression: expression,
        result: result,
        pinned: pinned ?? this.pinned,
        hidden: hidden ?? this.hidden,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'expression': expression,
        'result': result,
        'pinned': pinned,
        'hidden': hidden,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        expression: json['expression'] as String,
        result: json['result'] as String,
        pinned: json['pinned'] as bool? ?? false,
        hidden: json['hidden'] as bool? ?? false,
      );
}

/// Holds the calculator's live UI state (current expression, last result,
/// angle mode, history, cursor) and drives it through [CalculatorEngine].
class CalculatorController extends ChangeNotifier {
  CalculatorController({CalculatorEngine? engine, SharedPreferences? prefs})
      : _engine = engine ?? CalculatorEngine(),
        _prefs = prefs {
    _loadHistory();
  }

  final CalculatorEngine _engine;
  final SharedPreferences? _prefs;

  String _expression = '';
  String _display = '0';
  String? _errorMessage;
  AngleMode _angleMode = AngleMode.degrees;
  int _cursor = 0;
  String? _announcement;
  int _historySeq = 0;
  final List<HistoryEntry> _history = [];

  String get expression => _expression;
  String get display => _display;
  String? get errorMessage => _errorMessage;
  AngleMode get angleMode => _angleMode;
  int get cursor => _cursor;
  String? get announcement => _announcement;
  List<HistoryEntry> get history => List.unmodifiable(_history);

  /// Pinned first, then recent unhidden, capped at 30.
  List<HistoryEntry> get visibleHistory {
    final pinned = _history.where((e) => e.pinned && !e.hidden);
    final rest = _history.where((e) => !e.pinned && !e.hidden);
    return [...pinned, ...rest].take(_maxVisibleHistory).toList();
  }

  /// Steps for the most recent successful equals, if they can be explained.
  Explanation? get lastExplanation {
    final last = _history.where((e) => !e.hidden).firstOrNull;
    if (last == null) return null;
    final explanation = ExpressionExplainer(engine: _engine).explain(last.expression, _angleMode);
    return explanation.isEmpty ? null : explanation;
  }

  /// Expression with a pipe at the caret, for the on-screen editor.
  String get expressionWithCursor {
    if (_expression.isEmpty) return '|';
    final i = _cursor.clamp(0, _expression.length);
    return '${_expression.substring(0, i)}|${_expression.substring(i)}';
  }

  String get cursorAnnouncement {
    if (_expression.isEmpty) {
      return 'Empty expression, cursor at start';
    }
    final i = _cursor.clamp(0, _expression.length);
    final before = i == 0 ? 'start' : _expression.substring(0, i);
    final after = i >= _expression.length ? 'end' : _expression.substring(i);
    return 'Cursor between $before and $after';
  }

  void input(String token) {
    _errorMessage = null;
    final i = _cursor.clamp(0, _expression.length);
    _expression = _expression.substring(0, i) + token + _expression.substring(i);
    _cursor = i + token.length;
    _display = _expression.isEmpty ? '0' : _expression;
    _announcement = 'Inserted $token. $cursorAnnouncement';
    notifyListeners();
  }

  /// Wraps the whole current expression in [prefix]/[suffix] — used for
  /// postfix-style unary operations (square, square root, reciprocal,
  /// negate) that apply to "everything typed so far" rather than
  /// continuing the expression like a binary operator would.
  void wrap(String prefix, String suffix) {
    if (_expression.isEmpty) {
      if (prefix == '-(') input('-');
      return;
    }
    _errorMessage = null;
    _expression = '$prefix$_expression$suffix';
    _cursor = _expression.length;
    _display = _expression;
    _announcement = 'Wrapped expression. $cursorAnnouncement';
    notifyListeners();
  }

  void backspace() {
    if (_cursor <= 0 || _expression.isEmpty) return;
    _errorMessage = null;
    final i = _cursor;
    final removed = _expression.substring(i - 1, i);
    _expression = _expression.substring(0, i - 1) + _expression.substring(i);
    _cursor = i - 1;
    _display = _expression.isEmpty ? '0' : _expression;
    _announcement = 'Deleted $removed. $cursorAnnouncement';
    notifyListeners();
  }

  void moveCursorLeft() {
    if (_cursor <= 0) return;
    _cursor -= 1;
    _announcement = cursorAnnouncement;
    notifyListeners();
  }

  void moveCursorRight() {
    if (_cursor >= _expression.length) return;
    _cursor += 1;
    _announcement = cursorAnnouncement;
    notifyListeners();
  }

  void clear() {
    _expression = '';
    _display = '0';
    _errorMessage = null;
    _cursor = 0;
    _announcement = 'Display cleared';
    notifyListeners();
  }

  void toggleAngleMode() {
    _angleMode = _angleMode.toggled;
    _announcement = 'Angle mode ${_angleMode.label}';
    notifyListeners();
  }

  /// Last evaluated result, for the Ans key.
  String? get lastAnswer => visibleHistory.firstOrNull?.result;

  /// Inserts the last result at the cursor. No-op when history is empty.
  void insertAns() {
    final ans = lastAnswer;
    if (ans == null) return;
    input(ans);
  }

  void evaluate() {
    if (_expression.isEmpty) return;
    try {
      final value = _engine.evaluate(_expression, _angleMode);
      final formatted = _formatResult(value);
      _history.insert(
        0,
        HistoryEntry(
          id: 'h${DateTime.now().microsecondsSinceEpoch}_${_historySeq++}',
          expression: _expression,
          result: formatted,
        ),
      );
      _trimHistory();
      _display = formatted;
      _expression = formatted;
      _cursor = _expression.length;
      _errorMessage = null;
      _announcement = 'Result $formatted';
      _saveHistory();
    } on CalculatorError catch (e) {
      _errorMessage = e.message;
      _announcement = 'Error: ${e.message}';
    }
    notifyListeners();
  }

  void recall(HistoryEntry entry) {
    _errorMessage = null;
    _expression = entry.result;
    _display = entry.result;
    _cursor = _expression.length;
    _announcement = 'Recalled ${entry.expression} equals ${entry.result}';
    notifyListeners();
  }

  void pinHistory(String id) {
    _updateEntry(id, (e) => e.copyWith(pinned: true));
  }

  void unpinHistory(String id) {
    _updateEntry(id, (e) => e.copyWith(pinned: false));
  }

  void hideHistory(String id) {
    _updateEntry(id, (e) => e.copyWith(hidden: true, pinned: false));
  }

  void deleteHistory(String id) {
    _history.removeWhere((e) => e.id == id);
    _saveHistory();
    _announcement = 'History entry deleted';
    notifyListeners();
  }

  void _updateEntry(String id, HistoryEntry Function(HistoryEntry) update) {
    final i = _history.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _history[i] = update(_history[i]);
    _saveHistory();
    notifyListeners();
  }

  void _trimHistory() {
    final pinned = _history.where((e) => e.pinned && !e.hidden).toList();
    final rest = _history.where((e) => !e.pinned).toList();
    final keptRest = rest.take(_maxVisibleHistory).toList();
    _history
      ..clear()
      ..addAll(pinned)
      ..addAll(keptRest);
  }

  void _loadHistory() {
    final raw = _prefs?.getString(_kHistoryKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _history
        ..clear()
        ..addAll(list.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      // Corrupt prefs should not brick the calculator.
    }
  }

  Future<void> _saveHistory() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(_history.map((e) => e.toJson()).toList()),
    );
  }

  String _formatResult(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    var text = value.toStringAsPrecision(10);
    if (text.contains('.') && !text.contains('e')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }
}
