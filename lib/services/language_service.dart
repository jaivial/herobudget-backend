import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class LanguageService {
  static String get baseUrl => ApiConfig.languageServiceUrl;
  static const String languagePreferenceKey = 'preferred_language';

  // Save language to both server (cookie) and local storage
  static Future<bool> saveLanguagePreference(String locale) async {
    try {
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
        return true;
      } else {
        // If server fails, still try to save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(languagePreferenceKey, locale);
        return true;
      }
    } catch (e) {
      // On error, try to save locally as fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(languagePreferenceKey, locale);
        return true;
      } catch (_) {
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
        return storedLocale;
      }

      // If not in local storage, try to get from server (cookie)
      final response = await http.get(Uri.parse('$baseUrl/language/get'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] &&
            data['locale'] != null &&
            data['locale'].isNotEmpty) {
          // Save to local storage for next time
          await prefs.setString(languagePreferenceKey, data['locale']);
          return data['locale'];
        }
      }

      // If all fails, return null
      return null;
    } catch (e) {
      // On error, just return null
      return null;
    }
  }

  // Clear language preference
  static Future<bool> clearLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(languagePreferenceKey);
      return true;
    } catch (e) {
      return false;
    }
  }
}
