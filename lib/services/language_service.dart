import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/locale_util.dart';
import 'package:flutter/material.dart';

class LanguageService {
  static String get baseUrl => ApiConfig.languageServiceUrl;
  static const String languagePreferenceKey = 'preferred_language';

  // Save language to both server (cookie) and local storage
  static Future<bool> saveLanguagePreference(String locale) async {
    try {
      print('Saving language preference: $locale');

      // First, try to save on the server (sets cookie)
      final response = await http.post(
        Uri.parse('$baseUrl/language/set'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'locale': locale}),
      );

      if (response.statusCode == 200) {
        // Then save in local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(languagePreferenceKey, locale);
        print('Language preference saved to server and local storage: $locale');
        return true;
      } else {
        // If server fails, still try to save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(languagePreferenceKey, locale);
        print('Language preference saved to local storage only: $locale');
        return true;
      }
    } catch (e) {
      // On error, try to save locally as fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(languagePreferenceKey, locale);
        print(
          'Language preference saved to local storage (after error): $locale',
        );
        return true;
      } catch (_) {
        print('Failed to save language preference: $locale');
        return false;
      }
    }
  }

  // Get language from local storage first, then try server
  static Future<String?> getLanguagePreference() async {
    try {
      // First check local storage
      final prefs = await SharedPreferences.getInstance();
      final storedLocale = prefs.getString(languagePreferenceKey);

      if (storedLocale != null && storedLocale.isNotEmpty) {
        print(
          'Retrieved language preference from local storage: $storedLocale',
        );
        return storedLocale;
      }

      // If not in local storage, try to get from server (cookie)
      try {
        final response = await http.get(Uri.parse('$baseUrl/language/get'));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          if (data['success'] &&
              data['locale'] != null &&
              data['locale'].isNotEmpty) {
            // Save to local storage for next time
            await prefs.setString(languagePreferenceKey, data['locale']);
            print(
              'Retrieved language preference from server: ${data['locale']}',
            );
            return data['locale'];
          }
        }
      } catch (e) {
        print('Error getting language from server: $e');
        // Continue with the function rather than returning null here
      }

      // If all fails, try to detect the device locale
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final deviceLocaleStr = LocaleUtil.detectDeviceLocale(null);

      print(
        'No stored preference found, using device locale: $deviceLocaleStr',
      );
      return deviceLocaleStr;
    } catch (e) {
      print('Error in getLanguagePreference: $e');
      // On error, just return null
      return null;
    }
  }

  // Clear language preference
  static Future<bool> clearLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(languagePreferenceKey);
      print('Language preference cleared');
      return true;
    } catch (e) {
      print('Failed to clear language preference: $e');
      return false;
    }
  }

  // Check if the user's locale is supported
  static Future<bool> isUserLocaleSupported() async {
    final userLocale = await getLanguagePreference();

    if (userLocale == null || userLocale.isEmpty) {
      // If we have no stored preference, we'll check the device locale
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final deviceLocaleStr =
          '${deviceLocale.languageCode}-${deviceLocale.countryCode ?? 'US'}';

      // Check if device locale is supported
      for (var supportedLocale in LocaleUtil.localeMapping.keys) {
        if (supportedLocale.toLowerCase() == deviceLocaleStr.toLowerCase()) {
          print('Device locale $deviceLocaleStr is supported');
          return true;
        }
      }

      // Check just language match
      for (var supportedLocale in LocaleUtil.localeMapping.keys) {
        final parts = supportedLocale.split('-');
        if (parts[0].toLowerCase() == deviceLocale.languageCode.toLowerCase()) {
          print('Device language ${deviceLocale.languageCode} is supported');
          return true;
        }
      }

      print('Device locale $deviceLocaleStr is not supported');
      return false;
    }

    // Convert string locale to Locale object
    final locale = LocaleUtil.stringToLocale(userLocale);

    // Check if this exact locale is in the list of supported locales
    for (var supportedLocale in LocaleUtil.localeMapping.keys) {
      final parts = supportedLocale.split('-');
      if (locale.languageCode.toLowerCase() == parts[0].toLowerCase() &&
          locale.countryCode?.toLowerCase() == parts[1].toLowerCase()) {
        print('User locale $userLocale is supported (exact match)');
        return true;
      }
    }

    // Check just language match
    for (var supportedLocale in LocaleUtil.localeMapping.keys) {
      final parts = supportedLocale.split('-');
      if (locale.languageCode.toLowerCase() == parts[0].toLowerCase()) {
        print('User language ${locale.languageCode} is supported');
        return true;
      }
    }

    print('User locale $userLocale is not supported');
    return false;
  }

  // Get the current locale as a Locale object
  static Future<Locale> getCurrentLocale() async {
    String? localeString = await getLanguagePreference();

    if (localeString == null || localeString.isEmpty) {
      // Use device locale
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      localeString =
          '${deviceLocale.languageCode}-${deviceLocale.countryCode ?? 'US'}';
      print('Using device locale: $localeString');
    } else {
      print('Using saved locale preference: $localeString');
    }

    return LocaleUtil.stringToLocale(localeString);
  }

  // Get the best matching locale for the user
  static Future<Locale> getBestMatchingLocale() async {
    String? userLocale = await getLanguagePreference();

    if (userLocale == null || userLocale.isEmpty) {
      // If no saved preference, use device locale
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      userLocale =
          '${deviceLocale.languageCode}-${deviceLocale.countryCode ?? 'US'}';
    }

    // Check for exact match
    for (var supportedLocale in LocaleUtil.localeMapping.keys) {
      if (supportedLocale.toLowerCase() == userLocale.toLowerCase()) {
        return LocaleUtil.stringToLocale(supportedLocale);
      }
    }

    // Check for language match with any country
    final userLanguage = userLocale.split('-')[0].toLowerCase();
    for (var supportedLocale in LocaleUtil.localeMapping.keys) {
      final parts = supportedLocale.split('-');
      if (parts[0].toLowerCase() == userLanguage) {
        return LocaleUtil.stringToLocale(supportedLocale);
      }
    }

    // Default to English (US) if no match
    return LocaleUtil.stringToLocale('en-US');
  }
}
