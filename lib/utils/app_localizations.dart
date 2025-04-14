import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'locale_util.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English (United States)
    Locale('en', 'GB'), // English (United Kingdom)
    Locale('es', 'ES'), // Spanish (Spain)
    Locale('es', 'MX'), // Spanish (Mexico)
    Locale('es', 'AR'), // Spanish (Argentina)
    Locale('fr', 'FR'), // French
    Locale('nl', 'NL'), // Dutch (Netherlands)
    Locale('da', 'DK'), // Danish
    Locale('de', 'DE'), // German
    Locale('de', 'CH'), // Swiss German
    Locale('it', 'IT'), // Italian
    Locale('el', 'GR'), // Greek
    Locale('ru', 'RU'), // Russian
    Locale('pt', 'PT'), // Portuguese (Portugal)
    Locale('pt', 'BR'), // Portuguese (Brazil)
    Locale('zh', 'CN'), // Chinese
    Locale('ja', 'JP'), // Japanese
    Locale('hi', 'IN'), // Hindi
    Locale('ca', 'ES'), // Catalan
    Locale('no', 'NO'), // Norwegian
  ];

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en', 'US'));
  }

  // Static method to determine if a locale is supported
  static bool isLocaleSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return true;
      }
    }

    // If country code doesn't match, check just the language
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }

    return false;
  }

  // Find closest supported locale
  static Locale findClosestSupportedLocale(Locale locale) {
    // First try exact match
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return supportedLocale;
      }
    }

    // Then try language match with any country
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    // Default to English (US)
    return const Locale('en', 'US');
  }

  // Load the JSON language file from the "lang" folder
  Future<bool> load() async {
    try {
      // Determine which translation file to load
      String jsonFileName = 'assets/lang/';

      // Build the file path using language and country code (e.g., en_US.json)
      jsonFileName += '${locale.languageCode}_${locale.countryCode}.json';

      print('Loading translation file: $jsonFileName');

      try {
        // First try to load the exact locale file
        String jsonString = await rootBundle.loadString(jsonFileName);
        Map<String, dynamic> jsonMap = json.decode(jsonString);

        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });

        print('Successfully loaded translation file: $jsonFileName');
        return true;
      } catch (e) {
        print('Failed to load specific locale file: $jsonFileName, error: $e');

        // Try to load a file for the language without specifying the country
        try {
          // Find any file for this language
          bool foundLanguageMatch = false;

          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              // Try with this country code
              String fallbackFileName =
                  'assets/lang/${locale.languageCode}_${supportedLocale.countryCode}.json';

              try {
                String jsonString = await rootBundle.loadString(
                  fallbackFileName,
                );
                Map<String, dynamic> jsonMap = json.decode(jsonString);

                _localizedStrings = jsonMap.map((key, value) {
                  return MapEntry(key, value.toString());
                });

                print('Loaded fallback translation file: $fallbackFileName');
                foundLanguageMatch = true;
                break;
              } catch (e) {
                // Continue to the next potential locale
                print('Failed to load fallback: $fallbackFileName');
              }
            }
          }

          if (foundLanguageMatch) {
            return true;
          }
        } catch (e) {
          print('Error while trying to find language match: $e');
        }

        // If all language-specific attempts fail, fall back to English (US)
        print('Falling back to English (US) translations');
        String jsonString = await rootBundle.loadString(
          'assets/lang/en_US.json',
        );
        Map<String, dynamic> jsonMap = json.decode(jsonString);

        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });

        return true;
      }
    } catch (e) {
      print('Critical error loading translations: $e');
      return false;
    }
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    final text = _localizedStrings[key];
    if (text == null) {
      print(
        'Warning: Missing translation for key "$key" in locale ${locale.toString()}',
      );
      return key;
    }
    return text;
  }
}

// LocalizationsDelegate is a factory for a set of localized resources
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.isLocaleSupported(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    print('Loading localizations for: ${locale.toString()}');

    // Find the closest supported locale
    final Locale closestLocale = AppLocalizations.findClosestSupportedLocale(
      locale,
    );

    // Create a new instance of the AppLocalizations class
    AppLocalizations localizations = AppLocalizations(closestLocale);

    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
