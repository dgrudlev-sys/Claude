import 'package:flutter/foundation.dart';

import 'angle_mode.dart';
import 'calculator_engine.dart';

/// One evaluated line, kept for the on-screen history strip.
class HistoryEntry {
  const HistoryEntry(this.expression, this.result);

  final String expression;
  final String result;
}

/// Holds the calculator's live UI state (current expression, last result,
/// angle mode, history) and drives it through [CalculatorEngine].
class CalculatorController extends ChangeNotifier {
  CalculatorController({CalculatorEngine? engine})
      : _engine = engine ?? CalculatorEngine();

  final CalculatorEngine _engine;

  String _expression = '';
  String _display = '0';
  String? _errorMessage;
  AngleMode _angleMode = AngleMode.degrees;
  final List<HistoryEntry> _history = [];

  String get expression => _expression;
  String get display => _display;
  String? get errorMessage => _errorMessage;
  AngleMode get angleMode => _angleMode;
  List<HistoryEntry> get history => List.unmodifiable(_history);

  void input(String token) {
    _errorMessage = null;
    _expression += token;
    _display = _expression.isEmpty ? '0' : _expression;
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
    _display = _expression;
    notifyListeners();
  }

  void backspace() {
    if (_expression.isEmpty) return;
    _errorMessage = null;
    _expression = _expression.substring(0, _expression.length - 1);
    _display = _expression.isEmpty ? '0' : _expression;
    notifyListeners();
  }

  void clear() {
    _expression = '';
    _display = '0';
    _errorMessage = null;
    notifyListeners();
  }

  void toggleAngleMode() {
    _angleMode = _angleMode.toggled;
    notifyListeners();
  }

  void evaluate() {
    if (_expression.isEmpty) return;
    try {
      final value = _engine.evaluate(_expression, _angleMode);
      final formatted = _formatResult(value);
      _history.insert(0, HistoryEntry(_expression, formatted));
      if (_history.length > 50) _history.removeLast();
      _display = formatted;
      _expression = formatted;
      _errorMessage = null;
    } on CalculatorError catch (e) {
      _errorMessage = e.message;
    }
    notifyListeners();
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
