import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:flutter/material.dart';

class LanguageService {
  static String get baseUrl => ApiConfig.languageServiceUrl;
  static const String languagePreferenceKey = 'preferred_language';

  // Map language codes to their display names
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
    'it': 'Italian (Italiano)',
    'de': 'German (Deutsch)',
    'gsw': 'Swiss German (Schwiizerdütsch)',
    'el': 'Greek (Ελληνικά)',
    'nl': 'Dutch (Nederlands)',
    'da': 'Danish (Dansk)',
    'ru': 'Russian (Русский)',
    'pt': 'Portuguese (Português)',
    'zh': 'Chinese (中文)',
    'ja': 'Japanese (日本語)',
    'hi': 'Hindi (हिन्दी)',
  };

  // Map language codes to country/region flags
  static String getLanguageFlag(String languageCode) {
    // Define flag emoji based on language code
    final Map<String, String> langToFlag = {
      'en': '🇺🇸', // English - US flag
      'es': '🇪🇸', // Spanish - Spain flag
      'fr': '🇫🇷', // French - France flag
      'it': '🇮🇹', // Italian - Italy flag
      'de': '🇩🇪', // German - Germany flag
      'gsw': '🇨🇭', // Swiss German - Switzerland flag
      'el': '🇬🇷', // Greek - Greece flag
      'nl': '🇳🇱', // Dutch - Netherlands flag
      'da': '🇩🇰', // Danish - Denmark flag
      'ru': '🇷🇺', // Russian - Russia flag
      'pt': '🇵🇹', // Portuguese - Portugal flag
      'zh': '🇨🇳', // Chinese - China flag
      'ja': '🇯🇵', // Japanese - Japan flag
      'hi': '🇮🇳', // Hindi - India flag
    };

    return langToFlag[languageCode] ?? '🌐';
  }

  // Save language to both server (cookie) and local storage
  static Future<bool> saveLanguagePreference(String languageCode) async {
    try {
      print('Saving language preference: $languageCode');

      // First, try to save on the server (sets cookie) but with a quick timeout
      // Wrapped in a try-catch with silent failure to avoid excessive error logs
      try {
        // Only attempt server connection if we're not in development mode
        bool isLocalDevelopment = true; // Set to false in production

        if (!isLocalDevelopment) {
          final response = await http
              .post(
                Uri.parse('$baseUrl/language/set'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'locale': languageCode}),
              )
              .timeout(
                const Duration(milliseconds: 500),
                onTimeout: () {
                  // Silently timeout with no error message
                  return http.Response(
                    '{"success": false, "error": "timeout"}',
                    408,
                  );
                },
              );

          if (response.statusCode != 200) {
            // Silently ignore non-200 responses in development
          }
        }
      } catch (e) {
        // Silently ignore network errors in development
      }

      // Save in local storage regardless of server response
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(languagePreferenceKey, languageCode);
      print('Language preference saved to local storage: $languageCode');
      return true;
    } catch (e) {
      print('Failed to save language preference: $languageCode, error: $e');
      return false;
    }
  }

  // Get language from local storage
  static Future<String?> getLanguagePreference() async {
    try {
      // Check local storage
      final prefs = await SharedPreferences.getInstance();
      final storedLocale = prefs.getString(languagePreferenceKey);

      if (storedLocale != null && storedLocale.isNotEmpty) {
        // If the stored locale has a country code (old format), extract just the language code
        if (storedLocale.contains('-')) {
          final parts = storedLocale.split('-');
          return parts[0];
        }
        return storedLocale;
      }

      // If not found, detect device locale
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      return deviceLocale.languageCode;
    } catch (e) {
      print('Error in getLanguagePreference: $e');
      return 'en'; // Default to English
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

  // Get the current locale
  static Future<Locale> getCurrentLocale() async {
    String languageCode = await getLanguagePreference() ?? 'en';
    return Locale(languageCode);
  }

  // Get a list of all supported languages with their details
  static List<Map<String, String>> getSupportedLanguagesList() {
    final List<Map<String, String>> languages = [];

    supportedLanguages.forEach((languageCode, languageName) {
      languages.add({
        'code': languageCode,
        'name': languageName,
        'flag': getLanguageFlag(languageCode),
      });
    });

    // Sort the list by language name
    languages.sort((a, b) => a['name']!.compareTo(b['name']!));

    return languages;
  }

  // Check if the user's locale is supported
  static Future<bool> isUserLocaleSupported() async {
    final userLocale = await getLanguagePreference();
    return userLocale != null && supportedLanguages.containsKey(userLocale);
  }
}
