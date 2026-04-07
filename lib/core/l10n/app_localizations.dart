import 'package:flutter/material.dart';

/// Simple localization delegate — maps keys to AR/EN strings
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Royal Baloot',
      'home': 'Home',
      'store': 'Store',
      'tournament': 'Tournament',
      'community': 'Community',
      'chat': 'Chat',
      'play_now': 'Play Now',
      'welcome': 'Welcome to Royal Baloot',
      'switch_language': 'العربية',
      'vip_lobby': 'VIP Lobby',
      'quick_match': 'Quick Match',
      'create_room': 'Create Room',
      'join_room': 'Join Room',
      'leaderboard': 'Leaderboard',
      'settings': 'Settings',
      'profile': 'Profile',
      'coming_soon': 'Coming Soon',
    },
    'ar': {
      'app_name': 'بلوت الملكي',
      'home': 'الرئيسية',
      'store': 'المتجر',
      'tournament': 'البطولة',
      'community': 'المجتمع',
      'chat': 'الدردشة',
      'play_now': 'العب الآن',
      'welcome': 'مرحباً بك في بلوت الملكي',
      'switch_language': 'English',
      'vip_lobby': 'صالة VIP',
      'quick_match': 'مباراة سريعة',
      'create_room': 'إنشاء غرفة',
      'join_room': 'انضم لغرفة',
      'leaderboard': 'المتصدرين',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'coming_soon': 'قريباً',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
