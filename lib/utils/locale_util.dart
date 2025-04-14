import 'package:flutter/material.dart';

class LocaleUtil {
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
    'it': 'Italian (Italiano)',
    'el': 'Greek (Ελληνικά)',
    'pl': 'Polish (Polski)',
    'ru': 'Russian (Русский)',
    'ro': 'Romanian (Română)',
    'pt': 'Portuguese (Português)',
    'pt-BR': 'Brazilian Portuguese (Português Brasileiro)',
    'zh': 'Chinese (中文)',
    'ja': 'Japanese (日本語)',
  };
  
  static const Map<String, String> countryCodes = {
    'en': 'US', // English - United States
    'es': 'ES', // Spanish - Spain
    'fr': 'FR', // French - France
    'it': 'IT', // Italian - Italy
    'el': 'GR', // Greek - Greece
    'pl': 'PL', // Polish - Poland
    'ru': 'RU', // Russian - Russia
    'ro': 'RO', // Romanian - Romania
    'pt': 'PT', // Portuguese - Portugal
    'pt-BR': 'BR', // Brazilian Portuguese - Brazil
    'zh': 'CN', // Chinese - China
    'ja': 'JP', // Japanese - Japan
  };
  
  static const Map<String, String> regionNames = {
    'US': 'United States',
    'ES': 'Spain',
    'FR': 'France',
    'IT': 'Italy',
    'GR': 'Greece',
    'PL': 'Poland',
    'RU': 'Russia',
    'RO': 'Romania',
    'PT': 'Portugal',
    'BR': 'Brazil',
    'CN': 'China',
    'JP': 'Japan',
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
    String countryCode = locale.countryCode ?? 
        countryCodes[languageCode] ?? 
        'US';  // Default to US
    
    // Special case for Brazilian Portuguese
    if (languageCode == 'pt' && countryCode == 'BR') {
      return 'pt-BR';
    }
    
    return '$languageCode-$countryCode';
  }
  
  // Get flag emoji from locale
  static String getRegionFlag(String locale) {
    final countryCode = locale.split('-').last.toUpperCase();
    
    // Convert country code to flag emoji
    // Each country code character is converted to a regional indicator symbol emoji
    final flagEmoji = String.fromCharCodes(
      countryCode.runes.map((rune) => rune + 127397),
    );
    
    return flagEmoji;
  }
  
  // Get region name from locale
  static String getRegionName(String locale) {
    final countryCode = locale.split('-').last.toUpperCase();
    return regionNames[countryCode] ?? countryCode;
  }
  
  // Get a list of all supported languages with their details
  static List<Map<String, String>> getSupportedLanguagesList() {
    final List<Map<String, String>> languages = [];
    
    supportedLanguages.forEach((langCode, langName) {
      final countryCode = countryCodes[langCode] ?? 'US';
      final localeString = countryCode == 'BR' ? 'pt-BR' : '$langCode-$countryCode';
      
      languages.add({
        'code': localeString,
        'name': langName,
        'flag': getRegionFlag(localeString),
        'region': regionNames[countryCode] ?? countryCode,
      });
    });
    
    return languages;
  }
} 