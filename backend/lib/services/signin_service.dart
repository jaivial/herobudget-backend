import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SignInService {
  static String get baseUrl => ApiConfig.signinServiceUrl;
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';

  // Sign in with email and password
  static Future<Map<String, dynamic>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signinEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Save user data to local storage on successful sign in
        final prefs = await SharedPreferences.getInstance();
        final userData = data['user'];

        await prefs.setString(userIdKey, userData['id'].toString());
        await prefs.setString(userDataKey, jsonEncode(userData));

        return {'success': true, 'user_data': userData};
      } else {
        // Check if the error is due to unverified email
        // Look for user data in the response even if login failed
        if (data.containsKey('user') && data['user'] != null) {
          final userData = data['user'];
          final bool isEmailVerified = userData['verified_email'] ?? false;

          if (!isEmailVerified) {
            // User exists but email is not verified
            return {
              'success': false,
              'error_type': 'email_not_verified',
              'user_data': userData,
              'message': data['message'] ?? 'Email not verified',
            };
          }
        }

        return {
          'success': false,
          'error_type': 'invalid_credentials',
          'message': data['message'] ?? 'An error occurred during sign in',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error_type': 'connection_error',
        'message': 'Connection error: $e',
      };
    }
  }

  // Check if user is signed in
  static Future<bool> isSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(userIdKey);
      final userDataExists = prefs.getString(userDataKey) != null;

      return userId != null && userId.isNotEmpty && userDataExists;
    } catch (e) {
      print('Error checking sign in status: $e');
      return false;
    }
  }

  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(userDataKey);

      if (userDataStr != null && userDataStr.isNotEmpty) {
        return jsonDecode(userDataStr);
      }

      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Sign out
  static Future<bool> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userIdKey);
      await prefs.remove(userDataKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if email already exists
  static Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signinCheckEmailEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
