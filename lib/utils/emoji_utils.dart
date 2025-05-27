import 'dart:convert';

/// Utility class for handling emoji encoding/decoding
class EmojiUtils {
  /// Map of corrupted emoji encodings to correct emojis
  static const Map<String, String> _corruptedEmojiMap = {
    'ð°': '💰', // Money bag
    'ð³': '💳', // Credit card
    'ð¦': '🏦', // Bank
    'â¡': '⚡', // High voltage
    'ð¬': '🎬', // Movie camera
    'ð¥': '🏥', // Hospital
    'ð¼': '💼', // Briefcase
    'ð¾': '🧾', // Receipt
    'ð±': '📱', // Mobile phone
    'ð¶': '📶', // Antenna bars
    'â½': '⛽', // Fuel pump
    'ðµ': '🎵', // Musical note
    'ð®': '🎮', // Video game
    'ðª': '💪', // Flexed biceps
    'ð¡': '🛡️', // Shield
    'â¤': '❤️', // Red heart
    'â': '✈️', // Airplane
  };

  /// Check if a string contains emojis
  static bool containsEmoji(String text) {
    // Check if string contains any non-ASCII characters (which would include emojis)
    for (var rune in text.runes) {
      if (rune > 127) {
        return true;
      }
    }
    return false;
  }

  /// Encode an emoji to Base64 with prefix for backend storage
  static String encodeEmoji(String emoji) {
    if (emoji.isEmpty) {
      return '📊'; // Default emoji
    }

    // Only encode if it appears to be an emoji
    if (containsEmoji(emoji)) {
      try {
        final encoded = base64.encode(utf8.encode(emoji));
        return 'BASE64:$encoded';
      } catch (e) {
        print('ERROR - Failed to encode emoji: $e');
        return '📊';
      }
    }

    return emoji;
  }

  /// Decode a possibly Base64-encoded emoji from backend
  static String decodeEmoji(String encodedEmoji) {
    // If empty or default emoji, return as is
    if (encodedEmoji.isEmpty || encodedEmoji == '📊') {
      return encodedEmoji;
    }

    // If it's Base64 encoded, decode it
    if (encodedEmoji.startsWith('BASE64:')) {
      try {
        final base64String = encodedEmoji.substring(
          7,
        ); // Remove 'BASE64:' prefix
        final decoded = utf8.decode(base64.decode(base64String));
        print('DEBUG - Successfully decoded emoji: $encodedEmoji -> $decoded');
        return decoded;
      } catch (e) {
        print('ERROR - Failed to decode emoji: $e');
        return '📊'; // Return default emoji on error
      }
    }

    // Check for known corrupted emoji patterns
    if (encodedEmoji == 'ð' ||
        encodedEmoji == 'ð ' ||
        encodedEmoji.contains('ð') ||
        encodedEmoji.contains('â')) {
      print('DEBUG - Corrupted emoji detected: $encodedEmoji, using default');
      return '📊';
    }

    return encodedEmoji;
  }

  /// Prepare emoji for display (handle any decoding if needed)
  static String prepareForDisplay(String emoji) {
    // First try to decode in case it's encoded
    return decodeEmoji(emoji);
  }

  /// Prepare emoji for storage (encode if needed)
  static String prepareForStorage(String emoji) {
    return encodeEmoji(emoji);
  }

  /// Clean corrupted emoji encoding
  static String cleanEmoji(String emoji) {
    if (emoji.isEmpty) return '🧾'; // Default receipt emoji

    // Check if it's in our corrupted emoji map
    if (_corruptedEmojiMap.containsKey(emoji)) {
      return _corruptedEmojiMap[emoji]!;
    }

    // Try to handle UTF-8 encoding issues
    try {
      // If the emoji looks corrupted, try to decode it properly
      if (emoji.contains('ð') || emoji.contains('â')) {
        // Try different encoding approaches
        List<int> bytes = emoji.codeUnits;
        String decoded = utf8.decode(bytes, allowMalformed: true);
        if (isValidEmoji(decoded) && decoded != emoji) {
          return decoded;
        }
      }
    } catch (e) {
      print('Error decoding emoji: $e');
    }

    // If it's already a valid emoji, return as is
    if (isValidEmoji(emoji)) {
      return emoji;
    }

    // Default fallback
    return '🧾';
  }

  /// Check if a string contains valid emoji characters
  static bool isValidEmoji(String text) {
    if (text.isEmpty) return false;

    // Comprehensive emoji regex pattern
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|' // Emoticons
      r'[\u{1F300}-\u{1F5FF}]|' // Misc Symbols and Pictographs
      r'[\u{1F680}-\u{1F6FF}]|' // Transport and Map
      r'[\u{1F1E0}-\u{1F1FF}]|' // Regional indicator
      r'[\u{2600}-\u{26FF}]|' // Misc symbols
      r'[\u{2700}-\u{27BF}]|' // Dingbats
      r'[\u{1F900}-\u{1F9FF}]|' // Supplemental Symbols and Pictographs
      r'[\u{1FA70}-\u{1FAFF}]', // Symbols and Pictographs Extended-A
      unicode: true,
    );

    return emojiRegex.hasMatch(text);
  }

  /// Get emoji for category name with fallback
  static String getEmojiForCategory(String categoryName) {
    final category = categoryName.toLowerCase();

    // Spanish categories
    if (category.contains('sueldo') || category.contains('salario'))
      return '💰';
    if (category.contains('vivienda') || category.contains('casa')) return '🏠';
    if (category.contains('servicios') || category.contains('utilidades'))
      return '⚡';
    if (category.contains('transporte') || category.contains('coche'))
      return '🚗';
    if (category.contains('alimentación') || category.contains('comida'))
      return '🍔';
    if (category.contains('entretenimiento')) return '🎬';
    if (category.contains('salud') || category.contains('médico')) return '🏥';
    if (category.contains('educación')) return '📚';
    if (category.contains('trabajo')) return '💼';

    // English categories
    if (category.contains('salary') || category.contains('income')) return '💰';
    if (category.contains('housing') || category.contains('rent')) return '🏠';
    if (category.contains('utilities')) return '⚡';
    if (category.contains('transport') || category.contains('car')) return '🚗';
    if (category.contains('food') || category.contains('groceries'))
      return '🍔';
    if (category.contains('entertainment')) return '🎬';
    if (category.contains('health') || category.contains('medical'))
      return '🏥';
    if (category.contains('education')) return '📚';
    if (category.contains('work') || category.contains('office')) return '💼';

    // Default fallback
    return '📂';
  }
}
