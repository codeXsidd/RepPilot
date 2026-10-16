import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'theme_mode';

  ThemeMode _themeMode;
  final SharedPreferences _prefs;

  ThemeController._(this._prefs, this._themeMode);

  static Future<ThemeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    final mode = _parseThemeMode(stored);
    return ThemeController._(prefs, mode);
  }

  factory ThemeController.withPrefs(SharedPreferences prefs) {
    final stored = prefs.getString(_prefKey);
    final mode = _parseThemeMode(stored);
    return ThemeController._(prefs, mode);
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_prefKey, mode.name);
    notifyListeners();
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
