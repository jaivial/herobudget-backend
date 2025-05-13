import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, dynamic> _localizedStrings = {};
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
    Locale('gsw'), // Swiss German
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

      // Pre-load the English translations as fallback
      String englishJsonString = '';
      try {
        englishJsonString = await rootBundle.loadString('assets/l10n/en.json');
        final Map<String, dynamic> englishJsonMap = jsonDecode(
          englishJsonString,
        );

        // Store the English fallbacks - don't convert values to strings yet
        _localizedStrings = Map<String, dynamic>.from(englishJsonMap);
      } catch (e) {
        print('Failed to load English fallback file. Error: $e');
        // Create minimum default strings
        _localizedStrings = {
          'app_name': 'Hero Budget',
          'welcome': 'Welcome to Hero Budget',
          'select_language': 'Select Language',
          'cancel': 'Cancel',
        };
      }

      // If we're not loading English, try to load the requested language
      if (languageCode != 'en') {
        try {
          // Try to load the file for the specific language
          String jsonString = await rootBundle.loadString(
            'assets/l10n/$languageCode.json',
          );

          // If we reach here, the file was found and loaded
          final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

          // Merge with the English fallbacks - preserving types for plurals and params
          jsonMap.forEach((key, value) {
            _localizedStrings[key] = value;
          });
        } catch (e) {
          print(
            'Failed to load language file for ${locale.languageCode}. Using English fallback. Error: $e',
          );
          // We already loaded English fallbacks above, so we can continue
        }
      }

      return true;
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

  // Basic translation method for simple strings
  String translate(String key) {
    final dynamic text = _localizedStrings[key];
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

    // If the text is not a string (might be a map for plurals), return a string version
    if (text is! String) {
      return text.toString();
    }

    return text;
  }

  // Extended translation with parameter replacement
  String translateWithParams(String key, Map<String, dynamic> params) {
    String text = translate(key);

    // Replace each parameter in the text
    params.forEach((paramKey, paramValue) {
      text = text.replaceAll('{$paramKey}', paramValue.toString());
    });

    return text;
  }

  // Pluralization support
  String translatePlural(String key, int count) {
    final dynamic plural = _localizedStrings[key];

    if (plural == null) {
      if (!_reportedMissingKeys.contains(key)) {
        _reportedMissingKeys.add(key);
        print(
          'Warning: Missing plural translation for key "$key" in locale ${locale.toString()}',
        );
      }
      return key;
    }

    // If it's a simple string, just return it
    if (plural is String) {
      return plural;
    }

    // If it's a map with plural forms
    if (plural is Map) {
      // Try to find the right plural form
      String? form;

      // Simple English-style pluralization as fallback
      if (count == 1) {
        form = plural['one']?.toString();
      } else {
        form = plural['other']?.toString();
      }

      // If we found a form, replace the {count} parameter
      if (form != null) {
        return form.replaceAll('{count}', count.toString());
      }
    }

    // Fallback to key
    return key;
  }

  // Currency formatting based on the current locale
  String formatCurrency(double amount, {String? symbol}) {
    try {
      final String localeCode = locale.toString();
      final NumberFormat formatter = NumberFormat.currency(
        locale: localeCode,
        symbol: symbol ?? '\$',
      );
      return formatter.format(amount);
    } catch (e) {
      // Fallback for unsupported locales
      final NumberFormat formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: symbol ?? '\$',
      );
      return formatter.format(amount);
    }
  }

  // Date formatting based on the current locale
  String formatDate(DateTime date, {String? pattern}) {
    try {
      final String localeCode = locale.toString();
      if (pattern != null) {
        final DateFormat formatter = DateFormat(pattern, localeCode);
        return formatter.format(date);
      } else {
        // Default to short date format
        final DateFormat formatter = DateFormat.yMd(localeCode);
        return formatter.format(date);
      }
    } catch (e) {
      // Fallback for unsupported locales
      if (pattern != null) {
        final DateFormat formatter = DateFormat(pattern, 'en_US');
        return formatter.format(date);
      } else {
        final DateFormat formatter = DateFormat.yMd('en_US');
        return formatter.format(date);
      }
    }
  }

  // Relative time formatting (e.g. "2 days ago", "in 3 hours")
  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Future date
    if (dateTime.isAfter(now)) {
      if (difference.inSeconds.abs() < 60) {
        return translateWithParams('in_seconds', {
          'count': difference.inSeconds.abs(),
        });
      } else if (difference.inMinutes.abs() < 60) {
        return translateWithParams('in_minutes', {
          'count': difference.inMinutes.abs(),
        });
      } else if (difference.inHours.abs() < 24) {
        return translateWithParams('in_hours', {
          'count': difference.inHours.abs(),
        });
      } else if (difference.inDays.abs() < 30) {
        return translateWithParams('in_days', {
          'count': difference.inDays.abs(),
        });
      } else {
        return formatDate(dateTime);
      }
    }
    // Past date
    else {
      if (difference.inSeconds < 60) {
        return translate('just_now');
      } else if (difference.inMinutes < 60) {
        return translateWithParams('minutes_ago', {
          'count': difference.inMinutes,
        });
      } else if (difference.inHours < 24) {
        return translateWithParams('hours_ago', {'count': difference.inHours});
      } else if (difference.inDays < 30) {
        return translateWithParams('days_ago', {'count': difference.inDays});
      } else {
        return formatDate(dateTime);
      }
    }
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
