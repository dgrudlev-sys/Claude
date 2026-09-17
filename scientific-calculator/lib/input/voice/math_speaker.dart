import '../../engine/number/number.dart';
import '../../expression/expression.dart';
import '../../expression/render/speech_renderer.dart';
import '../platform/speech_ports.dart';

/// Speaks expressions and results aloud.
///
/// The words come from [SpeechRenderer] — the same renderer that
/// produces screen-reader labels — so what a blind user hears from
/// VoiceOver and what any user hears from the "read it back" button are
/// the same sentence, produced once. Only the delivery differs.
class MathSpeaker {
  const MathSpeaker(this._tts, {this.renderer = const SpeechRenderer()});

  final TextToSpeechPort _tts;
  final SpeechRenderer renderer;

  /// Reads back what is currently written down.
  Future<void> speakExpression(
    ExpressionNode expression, {
    String? voiceId,
    String? localeTag,
  }) {
    return _tts.speak(
      renderer.render(expression),
      voiceId: voiceId,
      localeTag: localeTag,
      // Maths is read more slowly than prose — the listener is holding
      // structure in their head, not following a narrative.
      rate: 0.45,
      pitch: 1.0,
    );
  }

  /// Reads an expression and its result together: "3 plus 4, equals 7".
  Future<void> speakResult(
    ExpressionNode expression,
    NumberValue result, {
    String? voiceId,
    String? localeTag,
  }) {
    final spokenExpression = renderer.render(expression);
    final spokenResult = _spokenValue(result);
    return _tts.speak(
      '$spokenExpression, equals $spokenResult',
      voiceId: voiceId,
      localeTag: localeTag,
      rate: 0.45,
      pitch: 1.0,
    );
  }

  Future<void> stop() => _tts.stop();

  /// Values are spoken as the kind of thing they are: an exact fraction
  /// is read as a fraction, not as its decimal approximation, because
  /// that's the information the user asked to keep.
  String _spokenValue(NumberValue value) {
    if (value is RationalValue) {
      if (value.isInteger) return value.numerator.toString();
      final mixed = value.toMixedNumber();
      if (mixed != null) {
        return '${mixed.whole} and '
            '${renderer.render(FractionNode(
              NumberNode(mixed.fraction.numerator.toString()),
              NumberNode(mixed.fraction.denominator.toString()),
            ))}';
      }
      return renderer.render(FractionNode(
        NumberNode(value.numerator.toString()),
        NumberNode(value.denominator.toString()),
      ));
    }

    if (value is ComplexValue) {
      final sign = value.imaginary is RationalValue &&
              (value.imaginary as RationalValue).isNegative
          ? 'minus'
          : 'plus';
      final magnitude = value.imaginary is RationalValue &&
              (value.imaginary as RationalValue).isNegative
          ? value.imaginary.negate()
          : value.imaginary;
      return '${_spokenValue(value.real)} $sign ${_spokenValue(magnitude)} i';
    }

    return renderer.render(NumberNode(_trimDouble(value.toDouble())));
  }

  String _trimDouble(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    var text = value.toStringAsPrecision(10);
    if (text.contains('.') && !text.contains('e')) {
      text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }
}
