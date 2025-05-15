import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for currency-related operations
class CurrencyUtils {
  /// Map of language codes to their corresponding currency symbols
  static const Map<String, String> languageToCurrencySymbol = {
    'en': '\$', // English - US Dollar
    'es': '€', // Spanish - Euro
    'fr': '€', // French - Euro
    'it': '€', // Italian - Euro
    'de': '€', // German - Euro
    'gsw': 'CHF', // Swiss German - Swiss Franc
    'el': '€', // Greek - Euro
    'nl': '€', // Dutch - Euro
    'da': 'kr', // Danish - Danish Krone
    'ru': '₽', // Russian - Ruble
    'pt': '€', // Portuguese - Euro
    'zh': '¥', // Chinese - Yuan
    'ja': '¥', // Japanese - Yen
    'hi': '₹', // Hindi - Indian Rupee
  };

  /// Returns the currency symbol for the given language code
  /// Falls back to $ if the language is not found
  static String getCurrencySymbolForLanguage(String languageCode) {
    return languageToCurrencySymbol[languageCode] ?? '\$';
  }

  /// Returns the currency symbol for the given locale
  static String getCurrencySymbolForLocale(Locale locale) {
    return getCurrencySymbolForLanguage(locale.languageCode);
  }

  /// Formats a number as currency using the appropriate symbol for the locale
  static String formatCurrency(double amount, Locale locale) {
    final String currencySymbol = getCurrencySymbolForLocale(locale);

    try {
      final String localeCode = locale.toString();
      final NumberFormat formatter = NumberFormat.currency(
        locale: localeCode,
        symbol: currencySymbol,
      );
      return formatter.format(amount);
    } catch (e) {
      // Fallback for unsupported locales
      final NumberFormat formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: currencySymbol,
      );
      return formatter.format(amount);
    }
  }
}
