import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'zhospar_theme';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool isDarkActive(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
      notifyListeners();
    } else if (saved == 'light') {
      _themeMode = ThemeMode.light;
      notifyListeners();
    } else if (saved == 'system') {
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final serialized = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeKey, serialized);
  }

  Future<void> toggleTheme([Brightness? currentBrightness]) async {
    final currentlyDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            currentBrightness == Brightness.dark);
    await setTheme(currentlyDark ? ThemeMode.light : ThemeMode.dark);
  }
}
