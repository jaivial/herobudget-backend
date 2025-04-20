import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};
  final Set<String> _reportedMissingKeys = {};
  static final Map<String, String> _englishFallbacks = {
    'app_name': 'Hero Budget',
    'welcome': 'Welcome to Hero Budget',
    'welcome_desc': 'The smart way to manage your finances',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'login': 'Login',
    'select_language': 'Select Language',
    'or_sign_in_with': 'Or sign in with',
    'continue_with_google': 'Continue with Google',
    'cancel': 'Cancel',
  };

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('it'), // Italian
    Locale('de'), // German
    Locale('el'), // Greek
    Locale('nl'), // Dutch
    Locale('da'), // Danish
    Locale('ru'), // Russian
    Locale('pt'), // Portuguese
    Locale('zh'), // Chinese
    Locale('ja'), // Japanese
    Locale('hi'), // Hindi
  ];

  // Load the JSON language file from the "l10n" folder
  Future<bool> load() async {
    try {
      final String languageCode = locale.languageCode;

      try {
        // Try to load the file for the specific language
        String jsonString = await rootBundle.loadString(
          'assets/l10n/$languageCode.json',
        );

        // If we reach here, the file was found and loaded
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

        // Convert to a map with String keys and String values
        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });

        return true;
      } catch (e) {
        print(
          'Failed to load language file for ${locale.languageCode}. Error: $e',
        );

        // Create default strings with common values to prevent app crash
        _localizedStrings = {
          'app_name': 'Hero Budget',
          'welcome': 'Welcome to Hero Budget',
          'select_language': 'Select Language',
          'cancel': 'Cancel',
        };

        // Try to load the English file as fallback
        try {
          String jsonString = await rootBundle.loadString(
            'assets/l10n/en.json',
          );
          final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
          _localizedStrings = jsonMap.map((key, value) {
            return MapEntry(key, value.toString());
          });
          return true;
        } catch (fallbackError) {
          print('Failed to load fallback language file. Error: $fallbackError');
          // We already set basic defaults above, so we can continue
          return true;
        }
      }
    } catch (e) {
      print('Unexpected error in load(): $e');
      // Create minimum set of defaults to keep app functioning
      _localizedStrings = {
        'app_name': 'Hero Budget',
        'welcome': 'Welcome to Hero Budget',
        'select_language': 'Select Language',
        'cancel': 'Cancel',
      };
      return true;
    }
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    final text = _localizedStrings[key];
    if (text == null) {
      // Only print in debug mode or once per key
      if (!_reportedMissingKeys.contains(key)) {
        _reportedMissingKeys.add(key);
        print(
          'Warning: Missing translation for key "$key" in locale ${locale.toString()}',
        );
      }

      // Try to return English version for missing keys if available and we're not already in English
      if (locale.languageCode != 'en' && _englishFallbacks.containsKey(key)) {
        return _englishFallbacks[key]!;
      }

      // Return the key itself as last resort
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
    return AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    print('Loading localizations for: ${locale.toString()}');

    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// Extension to make it easier to use AppLocalizations
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this);
}
