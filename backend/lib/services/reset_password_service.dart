import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'language_service.dart';

class ResetPasswordService {
  static String get baseUrl => ApiConfig.resetPasswordServiceUrl;

  // Step 1: Check if email exists
  static Future<Map<String, dynamic>> checkEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordCheckEmailEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'exists': data['exists'] ?? false,
          'user_id': data['user_id'] ?? 0,
          'name': data['name'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to check email. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('Error checking email: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Step 2: Request password reset with user language
  static Future<Map<String, dynamic>> requestReset(String email) async {
    try {
      // Get the current user's language preference
      final userLanguage =
          await LanguageService.getLanguagePreference() ?? 'en';

      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordRequestEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'language': userLanguage, // Include user's language
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset email sent',
          'user_id': data['user_id'] ?? 0,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No account found with this email address.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to request password reset. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('Error requesting password reset: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Step 3: Validate reset token
  static Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordValidateTokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'valid': data['valid'] ?? false,
          'user_id': data['user_id'] ?? 0,
          'email': data['email'] ?? '',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message':
              'Invalid or expired token. Please request a new password reset.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to validate reset token. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('Error validating token: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Step 4: Update password
  static Future<Map<String, dynamic>> updatePassword(
    String token,
    int userId,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordUpdateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'user_id': userId,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              data['message'] ?? 'Password has been successfully updated',
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to update password',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Invalid token or user ID. Please try again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update password. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('Error updating password: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}
