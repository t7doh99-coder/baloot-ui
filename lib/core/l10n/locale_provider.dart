import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides locale management — toggling between Arabic and English
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _prefsKey = 'selected_locale';

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);
    if (savedCode != null && savedCode != _locale.languageCode) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  void toggleLocale() {
    setLocale(isArabic ? const Locale('en') : const Locale('ar'));
  }
}
