import 'package:flutter/material.dart';

class LocaleUtil {
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
    'it': 'Italian (Italiano)',
    'de': 'German (Deutsch)',
    'el': 'Greek (Ελληνικά)',
    'nl': 'Dutch (Nederlands)',
    'da': 'Danish (Dansk)',
    'ru': 'Russian (Русский)',
    'pt': 'Portuguese (Português)',
    'pt-BR': 'Brazilian Portuguese (Português Brasileiro)',
    'zh': 'Chinese (中文)',
    'ja': 'Japanese (日本語)',
    'hi': 'Hindi (हिन्दी)',
    'ca': 'Catalan (Català)',
    'no': 'Norwegian (Norsk)',
  };

  static const Map<String, String> countryCodes = {
    'en-US': 'US', // English - United States
    'en-GB': 'GB', // English - United Kingdom
    'es-ES': 'ES', // Spanish - Spain
    'es-MX': 'MX', // Spanish - Mexico
    'es-AR': 'AR', // Spanish - Argentina
    'fr-FR': 'FR', // French - France
    'it-IT': 'IT', // Italian - Italy
    'de-DE': 'DE', // German - Germany
    'el-GR': 'GR', // Greek - Greece
    'nl-NL': 'NL', // Dutch - Netherlands
    'da-DK': 'DK', // Danish - Denmark
    'ru-RU': 'RU', // Russian - Russia
    'pt-PT': 'PT', // Portuguese - Portugal
    'pt-BR': 'BR', // Brazilian Portuguese - Brazil
    'zh-CN': 'CN', // Chinese - China
    'ja-JP': 'JP', // Japanese - Japan
    'hi-IN': 'IN', // Hindi - India
    'ca-ES': 'ES', // Catalan - Spain
    'no-NO': 'NO', // Norwegian - Norway
    'de-CH': 'CH', // German - Switzerland
  };

  static const Map<String, String> regionNames = {
    'US': 'United States',
    'GB': 'Great Britain',
    'ES': 'Spain',
    'MX': 'Mexico',
    'AR': 'Argentina',
    'FR': 'France',
    'IT': 'Italy',
    'DE': 'Germany',
    'GR': 'Greece',
    'NL': 'Netherlands',
    'DK': 'Denmark',
    'RU': 'Russia',
    'PT': 'Portugal',
    'BR': 'Brazil',
    'CN': 'China',
    'JP': 'Japan',
    'IN': 'India',
    'CH': 'Switzerland',
    'NO': 'Norway',
  };

  // Map full locale codes to language and country codes
  static const Map<String, Map<String, String>> localeMapping = {
    'en-US': {'languageCode': 'en', 'countryCode': 'US'},
    'en-GB': {'languageCode': 'en', 'countryCode': 'GB'},
    'es-ES': {'languageCode': 'es', 'countryCode': 'ES'},
    'es-MX': {'languageCode': 'es', 'countryCode': 'MX'},
    'es-AR': {'languageCode': 'es', 'countryCode': 'AR'},
    'fr-FR': {'languageCode': 'fr', 'countryCode': 'FR'},
    'it-IT': {'languageCode': 'it', 'countryCode': 'IT'},
    'de-DE': {'languageCode': 'de', 'countryCode': 'DE'},
    'de-CH': {'languageCode': 'de', 'countryCode': 'CH'},
    'el-GR': {'languageCode': 'el', 'countryCode': 'GR'},
    'nl-NL': {'languageCode': 'nl', 'countryCode': 'NL'},
    'da-DK': {'languageCode': 'da', 'countryCode': 'DK'},
    'ru-RU': {'languageCode': 'ru', 'countryCode': 'RU'},
    'pt-PT': {'languageCode': 'pt', 'countryCode': 'PT'},
    'pt-BR': {'languageCode': 'pt', 'countryCode': 'BR'},
    'zh-CN': {'languageCode': 'zh', 'countryCode': 'CN'},
    'ja-JP': {'languageCode': 'ja', 'countryCode': 'JP'},
    'hi-IN': {'languageCode': 'hi', 'countryCode': 'IN'},
    'ca-ES': {'languageCode': 'ca', 'countryCode': 'ES'},
    'no-NO': {'languageCode': 'no', 'countryCode': 'NO'},
  };

  // Detect device locale
  static String detectDeviceLocale(BuildContext? context) {
    Locale locale;

    if (context != null) {
      locale = Localizations.localeOf(context);
    } else {
      locale = WidgetsBinding.instance.platformDispatcher.locale;
    }

    final String languageCode = locale.languageCode;
    final String? countryCode = locale.countryCode;

    if (countryCode != null && countryCode.isNotEmpty) {
      final String fullLocale = '$languageCode-$countryCode';

      // Check if this exact locale is supported
      if (localeMapping.containsKey(fullLocale)) {
        return fullLocale;
      }
    }

    // Handle special cases
    if (languageCode == 'es') {
      return 'es-ES'; // Default Spanish to Spain
    } else if (languageCode == 'en') {
      return 'en-US'; // Default English to US
    } else if (languageCode == 'pt') {
      return countryCode == 'BR' ? 'pt-BR' : 'pt-PT';
    }

    // Try to find a matching language with any country
    for (final entry in localeMapping.entries) {
      if (entry.value['languageCode'] == languageCode) {
        return entry.key;
      }
    }

    // Default to English (US) if no match found
    return 'en-US';
  }

  // Get flag emoji from locale
  static String getRegionFlag(String locale) {
    String countryCode;

    if (locale.contains('-')) {
      countryCode = locale.split('-').last.toUpperCase();
    } else {
      countryCode = countryCodes['$locale-$locale'.toUpperCase()] ?? 'US';
    }

    // Convert country code to flag emoji
    // Each country code character is converted to a regional indicator symbol emoji
    final flagEmoji = String.fromCharCodes(
      countryCode.runes.map((rune) => rune + 127397),
    );

    return flagEmoji;
  }

  // Get region name from locale
  static String getRegionName(String locale) {
    String countryCode;

    if (locale.contains('-')) {
      countryCode = locale.split('-').last.toUpperCase();
    } else {
      // Default country code if not specified
      countryCode = countryCodes['$locale-$locale'.toUpperCase()] ?? 'US';
    }

    return regionNames[countryCode] ?? countryCode;
  }

  // Get a list of all supported languages with their details
  static List<Map<String, String>> getSupportedLanguagesList() {
    final List<Map<String, String>> languages = [];

    // Add all the full locale codes with their corresponding names
    localeMapping.forEach((localeCode, codeMap) {
      final languageCode = codeMap['languageCode']!;
      final countryCode = codeMap['countryCode']!;

      // Get the language name
      String? languageName;
      if (languageCode == 'pt' && countryCode == 'BR') {
        languageName = supportedLanguages['pt-BR'];
      } else {
        languageName = supportedLanguages[languageCode];
      }

      if (languageName != null) {
        languages.add({
          'code': localeCode,
          'name': languageName,
          'flag': getRegionFlag(localeCode),
          'region': regionNames[countryCode] ?? countryCode,
        });
      }
    });

    // Sort the list by language name
    languages.sort((a, b) => a['name']!.compareTo(b['name']!));

    return languages;
  }

  // Convert string locale to Locale object
  static Locale stringToLocale(String localeString) {
    if (localeString.isEmpty) {
      return const Locale('en', 'US');
    }

    final parts = localeString.split('-');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale(parts[0]);
    }
  }
}
