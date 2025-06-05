import 'dart:math';

/// Utility class for handling icon to emoji mapping
class IconUtils {
  /// Map of technical icon names to emojis
  static const Map<String, String> _iconToEmojiMap = {
    // Bills and receipts
    'receipt_long': '🧾',
    'receipt': '🧾',
    'bill': '📄',
    'invoice': '📋',

    // Categories
    'home': '🏠',
    'house': '🏠',
    'rent': '🏠',
    'utilities': '⚡',
    'electricity': '⚡',
    'water': '💧',
    'gas': '🔥',
    'internet': '📶',
    'wifi': '📶',
    'phone': '📱',
    'mobile': '📱',
    'transport': '🚗',
    'car': '🚗',
    'fuel': '⛽',
    'food': '🍔',
    'groceries': '🛒',
    'shopping': '🛒',
    'restaurant': '🍽️',
    'entertainment': '🎬',
    'movies': '🎬',
    'music': '🎵',
    'games': '🎮',
    'health': '🏥',
    'medical': '💊',
    'fitness': '💪',
    'education': '📚',
    'books': '📚',
    'school': '🎓',
    'work': '💼',
    'office': '💼',
    'salary': '💰',
    'income': '💰',
    'investment': '📈',
    'savings': '🏦',
    'bank': '🏦',
    'cash': '💵',
    'credit_card': '💳',
    'insurance': '🛡️',
    'tax': '📊',
    'gift': '🎁',
    'donation': '❤️',
    'travel': '✈️',
    'vacation': '🏖️',
    'clothing': '👕',
    'beauty': '💄',
    'pets': '🐕',
    'children': '👶',
    'other': '📂',
    'miscellaneous': '📂',
  };

  /// Default emojis for different categories
  static const Map<String, String> _categoryDefaultEmojis = {
    'vivienda': '🏠',
    'servicios': '⚡',
    'transporte': '🚗',
    'alimentación': '🍔',
    'entretenimiento': '🎬',
    'salud': '🏥',
    'educación': '📚',
    'trabajo': '💼',
    'ingresos': '💰',
    'ahorros': '🏦',
    'otros': '📂',
    // English versions
    'housing': '🏠',
    'utilities': '⚡',
    'transport': '🚗',
    'food': '🍔',
    'entertainment': '🎬',
    'health': '🏥',
    'education': '📚',
    'work': '💼',
    'income': '💰',
    'savings': '🏦',
    'other': '📂',
  };

  /// Convert a technical icon name to an emoji
  static String iconNameToEmoji(String iconName) {
    if (iconName.isEmpty) {
      return '🧾'; // Default bill emoji
    }

    // Clean the icon name (remove underscores, convert to lowercase)
    final cleanName = iconName.toLowerCase().replaceAll('_', '');

    // Try direct mapping first
    if (_iconToEmojiMap.containsKey(iconName.toLowerCase())) {
      return _iconToEmojiMap[iconName.toLowerCase()]!;
    }

    // Try cleaned name
    if (_iconToEmojiMap.containsKey(cleanName)) {
      return _iconToEmojiMap[cleanName]!;
    }

    // If it's already an emoji, return it
    if (_isEmoji(iconName)) {
      return iconName;
    }

    // Default fallback
    return '🧾';
  }

  /// Get emoji for a category name
  static String getCategoryEmoji(String categoryName) {
    if (categoryName.isEmpty) {
      return '📂';
    }

    final cleanName = categoryName.toLowerCase().trim();

    // Try direct mapping
    if (_categoryDefaultEmojis.containsKey(cleanName)) {
      return _categoryDefaultEmojis[cleanName]!;
    }

    // Try partial matching
    for (final entry in _categoryDefaultEmojis.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return entry.value;
      }
    }

    // If it's already an emoji, return it
    if (_isEmoji(categoryName)) {
      return categoryName;
    }

    // Default fallback
    return '📂';
  }

  /// Get a random emoji for bills/invoices
  static String getRandomBillEmoji() {
    final billEmojis = ['🧾', '📄', '📋', '💳', '💰', '📊'];
    final random = Random();
    return billEmojis[random.nextInt(billEmojis.length)];
  }

  /// Check if a string is likely an emoji
  static bool _isEmoji(String text) {
    if (text.isEmpty) return false;

    // Check if the string contains non-ASCII characters (emojis are Unicode)
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) > 127) {
        return true;
      }
    }
    return false;
  }

  /// Convert emoji back to a technical icon name (for storage)
  static String emojiToIconName(String emoji) {
    // Find the key for this emoji value
    for (final entry in _iconToEmojiMap.entries) {
      if (entry.value == emoji) {
        return entry.key;
      }
    }

    // If no mapping found, return the emoji itself
    return emoji;
  }

  /// Get appropriate emoji based on category and fallback to icon name
  static String getAppropriateEmoji({
    String? categoryName,
    String? iconName,
    String? categoryEmoji,
  }) {
    // Priority 1: Use category emoji if available and valid
    if (categoryEmoji != null &&
        categoryEmoji.isNotEmpty &&
        _isEmoji(categoryEmoji)) {
      return categoryEmoji;
    }

    // Priority 2: Get emoji from category name
    if (categoryName != null && categoryName.isNotEmpty) {
      final categoryBasedEmoji = getCategoryEmoji(categoryName);
      if (categoryBasedEmoji != '📂') {
        // Not the default fallback
        return categoryBasedEmoji;
      }
    }

    // Priority 3: Convert icon name to emoji
    if (iconName != null && iconName.isNotEmpty) {
      return iconNameToEmoji(iconName);
    }

    // Final fallback
    return '🧾';
  }
}
