import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/layout_style.dart';

const _kLayoutStyleKey = 'layout_style';
const _kSoundEnabledKey = 'sound_enabled';
const _kHapticsEnabledKey = 'haptics_enabled';

/// User-configurable app settings (layout skin, button-press feedback),
/// persisted across launches via [SharedPreferences].
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs)
      : _layoutStyle = LayoutStyle.values.firstWhere(
          (s) => s.name == _prefs.getString(_kLayoutStyleKey),
          orElse: () => LayoutStyle.classic,
        ),
        _soundEnabled = _prefs.getBool(_kSoundEnabledKey) ?? false,
        _hapticsEnabled = _prefs.getBool(_kHapticsEnabledKey) ?? true;

  static Future<SettingsController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController(prefs);
  }

  final SharedPreferences _prefs;

  LayoutStyle _layoutStyle;
  bool _soundEnabled;
  bool _hapticsEnabled;

  LayoutStyle get layoutStyle => _layoutStyle;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> setLayoutStyle(LayoutStyle style) async {
    _layoutStyle = style;
    notifyListeners();
    await _prefs.setString(_kLayoutStyleKey, style.name);
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
}
