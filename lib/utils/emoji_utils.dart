import 'dart:convert';

/// Utility class for handling emoji encoding/decoding
class EmojiUtils {
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
}
