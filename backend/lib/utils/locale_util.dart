import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for handling locale settings
class LocaleUtil {
  /// Get the current locale from SharedPreferences
  static Future<Locale> getCurrentLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    final countryCode = prefs.getString('countryCode');

    return Locale(languageCode, countryCode);
  }

  /// Save the current locale to SharedPreferences
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('countryCode', locale.countryCode!);
    } else {
      await prefs.remove('countryCode');
    }
  }

  /// Get a list of supported locales
  static List<Locale> getSupportedLocales() {
    return [
      const Locale('en', 'US'), // English
      const Locale('es', 'ES'), // Spanish
      const Locale('fr', 'FR'), // French
      const Locale('de', 'DE'), // German
    ];
  }

  /// Get the locale name for display
  static String getDisplayName(Locale locale) {
    final languageMap = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
    };

    return languageMap[locale.languageCode] ?? locale.languageCode;
  }
}
