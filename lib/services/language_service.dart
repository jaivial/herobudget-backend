import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:flutter/material.dart';
import '../utils/extensions.dart';
import 'language_update_service.dart';

// Notificador para cambios en el idioma
class LanguageChangeNotifier extends ChangeNotifier {
  static final LanguageChangeNotifier _instance =
      LanguageChangeNotifier._internal();

  factory LanguageChangeNotifier() {
    return _instance;
  }

  LanguageChangeNotifier._internal();

  // Último idioma seleccionado
  String _lastLanguage = 'en';
  String get lastLanguage => _lastLanguage;

  // Método para notificar a la UI sobre el cambio de idioma
  void notifyLanguageChanged(String newLanguage) {
    _lastLanguage = newLanguage;
    notifyListeners();
  }
}

// Instancia global del notificador
final languageNotifier = LanguageChangeNotifier();

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

      // Almacenar el idioma previo antes de hacer el cambio
      final String? prevLanguage = await getLanguagePreference();

      // Si es el mismo idioma, no hacer nada para evitar bucles
      if (prevLanguage == languageCode) {
        print('Language already set to $languageCode, skipping');
        return true;
      }

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

      // Actualizar el idioma en la base de datos de usuarios si hay un usuario logueado
      try {
        // Intentar actualizar el idioma en la base de datos
        await LanguageUpdateService.updateUserLocaleInDatabase(languageCode);
      } catch (e) {
        // Ignorar silenciosamente errores al actualizar la base de datos
        print('Error updating locale in database: $e');
      }

      // Notificar a la UI sobre el cambio de idioma solo si realmente cambió
      if (prevLanguage != languageCode) {
        // Usar el notificador correcto
        languageNotifier.notifyLanguageChanged(languageCode);
      }

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

  // Muestra una notificación cuando el idioma cambia
  static void showLanguageChangeNotification(
    BuildContext context,
    String languageCode,
  ) {
    try {
      // Verificar si hay un ScaffoldMessenger disponible
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger == null) {
        print('No ScaffoldMessenger available in context');
        return;
      }

      // Obtener el nombre del idioma para mostrar en la notificación
      final String languageName =
          supportedLanguages[languageCode]?.split(' ')[0] ?? 'Unknown';

      // Obtener traducciones
      final localizations = context.tr;

      // Buscar la clave "language_changed" que debería estar traducida a cada idioma
      String notificationText = localizations.translate('language_changed');

      // Mostrar SnackBar con animación
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(getLanguageFlag(languageCode)),
              const SizedBox(width: 8),
              Text(notificationText),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              scaffoldMessenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      print('Error showing language change notification: $e');
    }
  }
}
