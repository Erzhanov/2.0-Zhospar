import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _storageKey = 'zhospar_language';
  String _currentLocale = 'kk';

  String get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null && (saved == 'kk' || saved == 'ru' || saved == 'en')) {
      _currentLocale = saved;
      notifyListeners();
    }
  }

  Future<void> setLocale(String lang) async {
    if (lang != 'kk' && lang != 'ru' && lang != 'en') return;
    _currentLocale = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, lang);
    notifyListeners();
  }

  String t(String key) {
    return AppStrings.get(key, _currentLocale);
  }

  List<String> getDayNames() {
    return [
      t('day.mon'),
      t('day.tue'),
      t('day.wed'),
      t('day.thu'),
      t('day.fri'),
      t('day.sat'),
      t('day.sun'),
    ];
  }

  List<String> getDayShort() {
    return [
      t('day.mon_s'),
      t('day.tue_s'),
      t('day.wed_s'),
      t('day.thu_s'),
      t('day.fri_s'),
      t('day.sat_s'),
      t('day.sun_s'),
    ];
  }
}
