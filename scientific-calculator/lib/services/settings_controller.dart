import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/calculator_mode.dart';
import '../l10n/app_language.dart';
import '../theme/color_story.dart';
import '../theme/layout_style.dart';
import '../theme/type_voice.dart';
import '../theme/vision_profile.dart';

const _kLayoutStyleKey = 'layout_style';
const _kSoundEnabledKey = 'sound_enabled';
const _kHapticsEnabledKey = 'haptics_enabled';
const _kVisionProfileKey = 'vision_profile';
const _kTextScaleKey = 'text_scale';
const _kLastModeKey = 'last_calculator_mode';
const _kOpenLastModeKey = 'open_last_mode';
const _kLanguageKey = 'language_code';
const _kColorStoryKey = 'color_story';
const _kTypeVoiceKey = 'type_voice';
const _kScientificKeypadKey = 'scientific_keypad';
const _kChooserMoreExpandedKey = 'chooser_more_expanded';

/// User-configurable app settings, persisted via [SharedPreferences].
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs)
      : _layoutStyle = LayoutStyle.values.firstWhere(
          (s) => s.name == _prefs.getString(_kLayoutStyleKey),
          orElse: () => LayoutStyle.classic,
        ),
        _visionProfile = VisionProfile.values.firstWhere(
          (s) => s.name == _prefs.getString(_kVisionProfileKey),
          orElse: () => VisionProfile.standard,
        ),
        _soundEnabled = _prefs.getBool(_kSoundEnabledKey) ?? false,
        _hapticsEnabled = _prefs.getBool(_kHapticsEnabledKey) ?? true,
        _textScale = _prefs.getDouble(_kTextScaleKey) ?? 1.0,
        _openLastMode = _prefs.getBool(_kOpenLastModeKey) ?? false,
        _lastMode = _parseMode(_prefs.getString(_kLastModeKey)),
        _language = _parseLanguage(_prefs.getString(_kLanguageKey)),
        _colorStory = ColorStory.values.firstWhere(
          (s) => s.name == _prefs.getString(_kColorStoryKey),
          orElse: () => ColorStory.panther,
        ),
        _typeVoice = TypeVoice.values.firstWhere(
          (s) => s.name == _prefs.getString(_kTypeVoiceKey),
          orElse: () => TypeVoice.laboratory,
        ),
        _scientificKeypad = _prefs.getBool(_kScientificKeypadKey) ?? false,
        _chooserMoreExpanded = _prefs.getBool(_kChooserMoreExpandedKey) ?? false;

  static Future<SettingsController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController(prefs);
  }

  static AppLanguage? _parseLanguage(String? code) {
    if (code == null) return null;
    for (final lang in AppLanguage.supported) {
      if (lang.code == code) return lang;
    }
    return null;
  }

  static CalculatorMode? _parseMode(String? name) {
    if (name == null) return null;
    for (final mode in CalculatorMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }

  final SharedPreferences _prefs;

  LayoutStyle _layoutStyle;
  VisionProfile _visionProfile;
  bool _soundEnabled;
  bool _hapticsEnabled;
  double _textScale;
  bool _openLastMode;
  CalculatorMode? _lastMode;
  AppLanguage? _language;
  ColorStory _colorStory;
  TypeVoice _typeVoice;
  bool _scientificKeypad;
  bool _chooserMoreExpanded;

  LayoutStyle get layoutStyle => _layoutStyle;
  VisionProfile get visionProfile => _visionProfile;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  double get textScale => _textScale;
  bool get openLastMode => _openLastMode;
  CalculatorMode? get lastMode => _lastMode;
  AppLanguage? get language => _language;
  ColorStory get colorStory => _colorStory;
  TypeVoice get typeVoice => _typeVoice;
  bool get scientificKeypad => _scientificKeypad;
  bool get chooserMoreExpanded => _chooserMoreExpanded;
  SharedPreferences get prefs => _prefs;

  Future<void> setLayoutStyle(LayoutStyle style) async {
    _layoutStyle = style;
    notifyListeners();
    await _prefs.setString(_kLayoutStyleKey, style.name);
  }

  Future<void> setVisionProfile(VisionProfile profile) async {
    _visionProfile = profile;
    notifyListeners();
    await _prefs.setString(_kVisionProfileKey, profile.name);
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    notifyListeners();
    await _prefs.setDouble(_kTextScaleKey, scale);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_kSoundEnabledKey, enabled);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_kHapticsEnabledKey, enabled);
  }

  Future<void> setOpenLastMode(bool enabled) async {
    _openLastMode = enabled;
    notifyListeners();
    await _prefs.setBool(_kOpenLastModeKey, enabled);
  }

  Future<void> setLastMode(CalculatorMode mode) async {
    _lastMode = mode;
    notifyListeners();
    await _prefs.setString(_kLastModeKey, mode.name);
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    await _prefs.setString(_kLanguageKey, language.code);
  }

  Future<void> setColorStory(ColorStory story) async {
    _colorStory = story;
    notifyListeners();
    await _prefs.setString(_kColorStoryKey, story.name);
  }

  Future<void> setTypeVoice(TypeVoice voice) async {
    _typeVoice = voice;
    notifyListeners();
    await _prefs.setString(_kTypeVoiceKey, voice.name);
  }

  Future<void> setScientificKeypad(bool enabled) async {
    _scientificKeypad = enabled;
    notifyListeners();
    await _prefs.setBool(_kScientificKeypadKey, enabled);
  }

  Future<void> setChooserMoreExpanded(bool expanded) async {
    _chooserMoreExpanded = expanded;
    notifyListeners();
    await _prefs.setBool(_kChooserMoreExpandedKey, expanded);
  }
}
